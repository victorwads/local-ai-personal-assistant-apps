import XCTest

@testable import AssistantMCPServer

@MainActor
final class WhatsAppWebAccountsRepositoryTests: XCTestCase {
    func test_loadOrCreateAccounts_seedsDefaultProfilesWithStableIds() async {
        let suite = "dev.wads.AssistantMCPServer.unittests.whatsappWebAccounts.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let repo = WhatsAppWebAccountsRepository(defaults: defaults)
        let profiles = [
            AppProfile.default,
            AppProfile(id: "profile-2", displayName: "Profile 2", isDefault: false),
            AppProfile(id: "profile-3", displayName: "Profile 3", isDefault: false)
        ]

        let accounts = await repo.loadOrCreateAccounts(for: profiles)

        XCTAssertEqual(accounts.map(\.appProfileId), ["default", "profile-2", "profile-3"])
        XCTAssertEqual(accounts.map(\.name), ["Default", "Profile 2", "Profile 3"])
        XCTAssertEqual(AppProfile.forWhatsAppWebAccount(accounts[0], isDefault: false).id, "default")
        XCTAssertEqual(AppProfile.forWhatsAppWebAccount(accounts[1], isDefault: false).id, "profile-2")
        XCTAssertEqual(AppProfile.forWhatsAppWebAccount(accounts[2], isDefault: false).id, "profile-3")
    }
}
