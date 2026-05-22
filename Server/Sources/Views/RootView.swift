import AppKit
import CryptoKit
import FirebaseAuth
import FirebaseCore
import SwiftUI

@MainActor
struct RootView: View {
    @StateObject private var viewModel = RootViewModel()

    var body: some View {
        Group {
            switch viewModel.phase {
            case .checkingSession:
                loadingView
            case .signedOut:
                signedOutView
            case .signedIn:
                MainAppContainer()
            case .failed(let message):
                errorView(message: message)
            }
        }
        .task {
            await viewModel.start()
        }
        .onOpenURL { url in
            viewModel.handleOpenURL(url)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Checking session...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var signedOutView: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Sign in with Google")
                .font(.title2.weight(.semibold))

            Text("Use your Google account to unlock Firestore-backed profiles and app data.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.signInWithGoogle()
                }
            } label: {
                Label("Continue with Google", systemImage: "g.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.orange)

            Text("Authentication error")
                .font(.title2.weight(.semibold))

            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            Button {
                Task {
                    await viewModel.start()
                }
            } label: {
                Text("Retry")
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

@MainActor
private struct MainAppContainer: View {
    @StateObject private var appModel: AppModel

    init() {
        let storedBasePort = UserDefaults.standard.integer(forKey: "mcpServer.basePort.v1")
        let basePort = (1024...65535).contains(storedBasePort) ? storedBasePort : 8080
        _appModel = StateObject(wrappedValue: AppModel(
            profile: .default,
            profileIndex: 0,
            basePort: basePort,
            primaryWhatsAppWebAccountId: nil,
            startupMode: .home
        ))
    }

    var body: some View {
        ProfilesHomeScreen()
            .environmentObject(appModel)
            .frame(minWidth: 980, minHeight: 680)
    }
}

@MainActor
final class RootViewModel: ObservableObject {
    enum Phase: Equatable {
        case checkingSession
        case signedOut
        case signedIn
        case failed(String)
    }

    @Published var phase: Phase = .checkingSession

    private var authStateDidChangeHandle: AuthStateDidChangeListenerHandle?
    private var pendingOAuthRequest: GoogleOAuthRequest?

    func start() async {
        FirebaseBootstrap.shared.configure()
        installAuthListener()
        updatePhaseFromCurrentUser()
    }

    func signInWithGoogle() async {
        FirebaseBootstrap.shared.configure()

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            phase = .failed("Missing Firebase client ID.")
            return
        }

        do {
            let request = try makeGoogleOAuthRequest(clientID: clientID)
            pendingOAuthRequest = request

            guard NSWorkspace.shared.open(request.authorizationURL) else {
                throw NSError(domain: "RootViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to open the local browser for Google sign-in."])
            }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func handleOpenURL(_ url: URL) {
        FirebaseBootstrap.shared.configure()

        guard let pendingOAuthRequest,
              url.scheme == pendingOAuthRequest.redirectScheme
        else {
            return
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            phase = .failed("Google sign-in returned an invalid callback URL.")
            return
        }

        let queryItems = components.queryItems ?? []
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            self.pendingOAuthRequest = nil
            phase = .failed("Google sign-in failed: \(error)")
            return
        }

        guard
            let code = queryItems.first(where: { $0.name == "code" })?.value,
            let returnedState = queryItems.first(where: { $0.name == "state" })?.value,
            returnedState == pendingOAuthRequest.state
        else {
            self.pendingOAuthRequest = nil
            phase = .failed("Google sign-in did not return a valid authorization code.")
            return
        }

        self.pendingOAuthRequest = nil

        Task {
            do {
                let tokenResponse = try await exchangeGoogleAuthorizationCode(
                    code,
                    clientID: pendingOAuthRequest.clientID,
                    codeVerifier: pendingOAuthRequest.codeVerifier,
                    redirectURI: pendingOAuthRequest.redirectURI
                )
                try await signInToFirebase(idToken: tokenResponse.idToken, accessToken: tokenResponse.accessToken)
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    private func installAuthListener() {
        guard authStateDidChangeHandle == nil else { return }
        authStateDidChangeHandle = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            Task { @MainActor in
                self?.updatePhaseFromCurrentUser()
            }
        }
    }

    private func makeGoogleOAuthRequest(clientID: String) throws -> GoogleOAuthRequest {
        let state = Self.randomURLSafeString(byteCount: 16)
        let codeVerifier = Self.randomURLSafeString(byteCount: 32)
        let codeChallenge = Self.codeChallenge(for: codeVerifier)
        let redirectURI = Self.googleRedirectURI

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI.absoluteString),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        guard let authorizationURL = components.url else {
            throw NSError(domain: "RootViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create the Google authorization URL."])
        }

        return GoogleOAuthRequest(
            clientID: clientID,
            state: state,
            codeVerifier: codeVerifier,
            redirectURI: redirectURI,
            authorizationURL: authorizationURL,
            redirectScheme: redirectURI.scheme ?? ""
        )
    }

    private func exchangeGoogleAuthorizationCode(_ code: String, clientID: String, codeVerifier: String, redirectURI: URL) async throws -> GoogleTokenResponse {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let formBody = [
            "code": code,
            "client_id": clientID,
            "code_verifier": codeVerifier,
            "redirect_uri": redirectURI.absoluteString,
            "grant_type": "authorization_code"
        ]
        request.httpBody = formBody
            .map { key, value in "\(Self.formEncode(key))=\(Self.formEncode(value))" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown token exchange failure."
            throw NSError(domain: "RootViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: body])
        }

        let tokenResponse = try JSONDecoder().decode(GoogleTokenResponse.self, from: data)
        guard !tokenResponse.idToken.isEmpty, !tokenResponse.accessToken.isEmpty else {
            throw NSError(domain: "RootViewModel", code: 4, userInfo: [NSLocalizedDescriptionKey: "Google token exchange did not return the expected tokens."])
        }

        return tokenResponse
    }

    private func signInToFirebase(idToken: String, accessToken: String) async throws {
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().signIn(with: credential) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        updatePhaseFromCurrentUser()
    }

    private func updatePhaseFromCurrentUser() {
        phase = Auth.auth().currentUser != nil ? .signedIn : .signedOut
    }

    private static func randomURLSafeString(byteCount: Int) -> String {
        let bytes = (0..<byteCount).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).base64URLEncodedString()
    }

    private static func codeChallenge(for codeVerifier: String) -> String {
        let digest = SHA256.hash(data: Data(codeVerifier.utf8))
        return Data(digest).base64URLEncodedString()
    }

    private static func formEncode(_ string: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=?")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }

    private static let googleRedirectURI = URL(string: "com.googleusercontent.apps.543757406815-r205r3ejokprmn3verjlesmlt3pqfe77:/oauthredirect")!

    private struct GoogleOAuthRequest {
        let clientID: String
        let state: String
        let codeVerifier: String
        let redirectURI: URL
        let authorizationURL: URL
        let redirectScheme: String
    }

    private struct GoogleTokenResponse: Decodable {
        let accessToken: String
        let idToken: String

        private enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case idToken = "id_token"
        }
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
