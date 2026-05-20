import SwiftUI
import WebKit

struct WhatsAppWebYAMLTreeTesterScreen: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var model = WhatsAppWebYAMLTreeTesterViewModel()

    var body: some View {
        HSplitView {
            leftPane
                .frame(minWidth: 420, idealWidth: 560, maxWidth: .infinity, maxHeight: .infinity)

            rightPane
                .frame(minWidth: 420, idealWidth: 560, maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await model.loadBundledYAMLIfNeeded() }
        .onChange(of: model.yamlText) { _, _ in
            model.reparseYAML()
        }
    }

    private var leftPane: some View {
        VStack(spacing: 0) {
            HStack {
                Text("YAML (in-memory)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    Task { await model.loadBundledYAML(force: true) }
                } label: {
                    Label("Reload bundled", systemImage: "arrow.clockwise")
                }
                .controlSize(.small)

                Button {
                    Task { await runTest() }
                } label: {
                    Label("Test", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(appModel.selectedWhatsAppWebAccount == nil || model.isRunning)

                Button {
                    model.clearExecutionResults()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .controlSize(.small)
                .disabled(model.executionRoot == nil && model.resultJSON == nil)
            }
            .padding(12)

            Divider()

            TextEditor(text: $model.yamlText)
                .font(.system(.body, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var rightPane: some View {
        VStack(spacing: 0) {
            HStack {
                Text("YAML Tree")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    model.clearExecutionResults()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .controlSize(.small)
                .disabled(model.executionRoot == nil && model.resultJSON == nil)

                Button {
                    model.requestExpandAll()
                } label: {
                    Label("Expand All", systemImage: "arrow.down.right.and.arrow.up.left")
                }
                .controlSize(.small)
                .disabled(model.structureRoot == nil)

                Button {
                    model.requestCollapseAll()
                } label: {
                    Label("Collapse All", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .controlSize(.small)
                .disabled(model.structureRoot == nil)

                if model.isRunning {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(12)

            Divider()

            YAMLTreeBrowserView(
                structureRoot: model.structureRoot,
                rawStructureRoot: model.rawStructureRoot,
                executionRoot: model.executionRoot,
                parseError: model.parseError,
                rawJSON: model.resultJSON,
                expansionState: model.expansionState
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @MainActor
    private func runTest() async {
        guard let account = appModel.selectedWhatsAppWebAccount else {
            model.setError("No WhatsApp Web account selected.")
            return
        }
        let webView = appModel.whatsAppWebSessionStore.webView(for: account)
        await model.runTest(webView: webView)
    }
}

private struct YAMLTreeBrowserView: View {
    @State private var selectedPath: String?

    let structureRoot: YAMLStructureNode?
    let rawStructureRoot: YAMLStructureNode?
    let executionRoot: YAMLExecutionNode?
    let parseError: String?
    let rawJSON: String?
    @ObservedObject var expansionState: YAMLTreeExpansionState

    var body: some View {
        HStack(spacing: 0) {
            structureColumn
                .frame(minWidth: 360, idealWidth: 430, maxWidth: 520, maxHeight: .infinity)

            Divider()

            detailColumn
                .frame(minWidth: 320, idealWidth: 430, maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if selectedPath == nil {
                selectedPath = structureRoot?.children?.first?.path
            }
        }
        .onChange(of: expansionState.revision) { _, _ in
            if selectedPath == nil {
                selectedPath = structureRoot?.children?.first?.path
            }
        }
    }

    private var structureColumn: some View {
        Group {
            if let structureRoot {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        YAMLTreeNodeView(
                            node: structureRoot,
                            executionRoot: executionRoot,
                            expansionState: expansionState,
                            selectedPath: $selectedPath,
                            isRoot: true
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No YAML structure")
                        .font(.headline)
                    Text(parseError ?? "Load or fix the YAML to see the tree.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black.opacity(0.02))
    }

    private var detailColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if let parseError, !parseError.isEmpty {
                    Text(parseError)
                        .font(.callout)
                        .foregroundStyle(.red)
                }

                if let executionRoot, let executedNode = executionRoot.find(path: selectedPath), structureRoot?.find(path: selectedPath) == nil {
                    Text(executedNode.path)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Test Result")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(executedNode.summaryText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                } else if let rawStructureRoot, let selectedNode = rawStructureRoot.find(path: selectedPath) {
                    Text(selectedNode.path)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)

                    Text(selectedNode.summaryText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)

                    if let specDetails = YAMLSpecDetails.detailsText(from: selectedNode.any), !specDetails.isEmpty {
                        Divider().padding(.vertical, 4)
                        Text("Spec Details")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(specDetails)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }

                    if let executionRoot, let executedNode = executionRoot.find(path: selectedNode.path) {
                        Divider().padding(.vertical, 4)
                        Text("Test Result")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(executedNode.summaryText)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    } else {
                        Divider().padding(.vertical, 4)
                        Text("Press Test to run this tree against the current WebView.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Select a node to inspect its YAML and execution result.")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black.opacity(0.01))
    }
}

private enum YAMLSpecDetails {
    static func detailsText(from any: AnySendable) -> String? {
        guard case .object(let dict) = any else { return nil }

        let interestingKeys: [String] = [
            "type",
            "selector",
            "selectors",
            "requires_any",
            "text_includes_any",
            "value_from",
            "attribute",
            "fallback_number",
            "clip_max_chars",
            "extract"
        ]

        var lines: [String] = []
        for key in interestingKeys {
            guard let value = dict[key] else { continue }
            if key == "extract" {
                if case .object(let extractDict) = value {
                    let keys = extractDict.keys.sorted()
                    if !keys.isEmpty {
                        lines.append("extractKeys: [\(keys.joined(separator: ", "))]")
                    }
                }
                continue
            }
            lines.append("\(key): \(renderInline(value))")
        }

        return lines.isEmpty ? nil : lines.joined(separator: "\n")
    }

    private static func renderInline(_ any: AnySendable) -> String {
        switch any {
        case .null:
            return "null"
        case .bool(let v):
            return v ? "true" : "false"
        case .int(let v):
            return "\(v)"
        case .double(let v):
            return "\(v)"
        case .string(let v):
            return "\"\(v)\""
        case .array(let values):
            let rendered = values.map { renderInline($0) }.joined(separator: ", ")
            return "[\(rendered)]"
        case .object(let dict):
            let keys = dict.keys.sorted()
            return "{\(keys.count) keys}"
        }
    }
}

private struct YAMLTreeNodeView: View {
    let node: YAMLStructureNode
    let executionRoot: YAMLExecutionNode?
    @ObservedObject var expansionState: YAMLTreeExpansionState
    @Binding var selectedPath: String?
    let isRoot: Bool

    @State private var isExpanded: Bool

    init(
        node: YAMLStructureNode,
        executionRoot: YAMLExecutionNode?,
        expansionState: YAMLTreeExpansionState,
        selectedPath: Binding<String?>,
        isRoot: Bool = false
    ) {
        self.node = node
        self.executionRoot = executionRoot
        self.expansionState = expansionState
        self._selectedPath = selectedPath
        self.isRoot = isRoot
        self._isExpanded = State(initialValue: isRoot)
    }

    var body: some View {
        if let children = effectiveChildren, !children.isEmpty {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(children) { child in
                        switch child {
                        case .structure(let structure):
                            YAMLTreeNodeView(
                                node: structure,
                                executionRoot: executionRoot,
                                expansionState: expansionState,
                                selectedPath: $selectedPath
                            )
                        case .execution(let execution):
                            YAMLExecutionTreeNodeView(
                                node: execution,
                                expansionState: expansionState,
                                selectedPath: $selectedPath
                            )
                        }
                    }
                }
                .padding(.leading, 14)
            } label: {
                row
            }
            .onChange(of: expansionState.revision) { _, _ in
                applyGlobalExpansionState()
            }
            .onAppear {
                applyGlobalExpansionState()
            }
        } else {
            row
        }
    }

    private enum EffectiveChild: Identifiable {
        case structure(YAMLStructureNode)
        case execution(YAMLExecutionNode)

        var id: String {
            switch self {
            case .structure(let node): return "s:\(node.id)"
            case .execution(let node): return "e:\(node.id)"
            }
        }
    }

    private var effectiveChildren: [EffectiveChild]? {
        // Special-case `type: elements`: show per-item results (items[]) when available.
        if node.specType == "elements",
           let execNode = executionRoot?.find(path: node.path),
           let items = execNode.itemsChildren,
           !items.isEmpty
        {
            return items.map { .execution($0) }
        }

        guard let children = node.children, !children.isEmpty else { return nil }
        return children.map { .structure($0) }
    }

    private func applyGlobalExpansionState() {
        switch expansionState.mode {
        case .preserveExisting:
            if isRoot { isExpanded = true }
        case .expandAll:
            isExpanded = true
        case .collapseAll:
            isExpanded = false
        }
    }

    private var row: some View {
        let executionNode = executionRoot?.find(path: node.path)
        let isSelected = selectedPath == node.path
        let canExpand = (node.children?.isEmpty == false)

        return HStack(spacing: 8) {
            if let executionNode {
                if executionNode.isFound {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if executionNode.hasExplicitMiss {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                } else {
                    Image(systemName: "circle.dashed")
                        .foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: node.kind == .scalar ? "doc.text" : "circle.dashed")
                    .foregroundStyle(.secondary)
            }

            Text(node.title)
                .lineLimit(1)

            if let summary = node.inlineSummary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if let executionNode, let badge = executionNode.badge, !badge.isEmpty {
                Text(badge)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onTapGesture {
            selectedPath = node.path
        }
        .onTapGesture(count: 2) {
            guard canExpand else { return }
            isExpanded.toggle()
        }
    }
}

private struct YAMLExecutionTreeNodeView: View {
    let node: YAMLExecutionNode
    @ObservedObject var expansionState: YAMLTreeExpansionState
    @Binding var selectedPath: String?

    @State private var isExpanded: Bool = false

    var body: some View {
        if let children = node.children, !children.isEmpty {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(children) { child in
                        YAMLExecutionTreeNodeView(
                            node: child,
                            expansionState: expansionState,
                            selectedPath: $selectedPath
                        )
                    }
                }
                .padding(.leading, 14)
            } label: {
                row
            }
            .onChange(of: expansionState.revision) { _, _ in
                applyGlobalExpansionState()
            }
            .onAppear {
                applyGlobalExpansionState()
            }
        } else {
            row
        }
    }

    private func applyGlobalExpansionState() {
        switch expansionState.mode {
        case .preserveExisting:
            break
        case .expandAll:
            isExpanded = true
        case .collapseAll:
            isExpanded = false
        }
    }

    private var row: some View {
        let isSelected = selectedPath == node.path

        return HStack(spacing: 8) {
            if node.isFound {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if node.hasExplicitMiss {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            } else {
                Image(systemName: "circle.dashed")
                    .foregroundStyle(.secondary)
            }

            Text(node.title)
                .lineLimit(1)

            Spacer(minLength: 8)

            if let badge = node.badge, !badge.isEmpty {
                Text(badge)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onTapGesture {
            selectedPath = node.path
        }
        .onTapGesture(count: 2) {
            if node.children?.isEmpty == false {
                isExpanded.toggle()
            }
        }
    }
}

@MainActor
final class WhatsAppWebYAMLTreeTesterViewModel: ObservableObject {
    @Published var yamlText: String = ""
    @Published var isRunning = false
    @Published var lastError: String?
    @Published var parseError: String?
    @Published var structureRoot: YAMLStructureNode?
    @Published var rawStructureRoot: YAMLStructureNode?
    @Published var executionRoot: YAMLExecutionNode?
    @Published var resultJSON: String?
    let expansionState = YAMLTreeExpansionState()

    private var didLoadBundled = false
    private let runner = WhatsAppWebYAMLExtractionRunner()

    func loadBundledYAMLIfNeeded() async {
        guard !didLoadBundled else { return }
        didLoadBundled = true
        await loadBundledYAML(force: true)
    }

    func loadBundledYAML(force: Bool) async {
        guard force || yamlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let url = Bundle.main.url(forResource: "whatsapp_web_selectors", withExtension: "yaml"),
              let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else {
            setError("Could not load bundled YAML resource `whatsapp_web_selectors.yaml`.")
            return
        }

        yamlText = text
        reparseYAML()
        lastError = nil
    }

    func reparseYAML() {
        do {
            let tree = try YAMLTree.parse(yaml: yamlText)
            let raw = YAMLStructureNode.from(any: .object(tree.root), title: "root", path: "root")
            rawStructureRoot = raw
            structureRoot = YAMLStructureNode.semanticRoot(from: raw)
            parseError = nil
        } catch {
            structureRoot = nil
            rawStructureRoot = nil
            parseError = error.localizedDescription
        }
    }

    func runTest(webView: WKWebView) async {
        isRunning = true
        defer { isRunning = false }
        lastError = nil
        executionRoot = nil

        do {
            let tree = try YAMLTree.parse(yaml: yamlText)
            let result = try await runner.run(yamlTree: tree, webView: webView)
            resultJSON = result.json
            executionRoot = YAMLExecutionNode.from(any: result.tree, title: "root", path: "root")
        } catch {
            setError(error.localizedDescription)
        }
    }

    func clearExecutionResults() {
        executionRoot = nil
        resultJSON = nil
        lastError = nil
    }

    func requestExpandAll() {
        expansionState.requestExpandAll()
    }

    func requestCollapseAll() {
        expansionState.requestCollapseAll()
    }

    func setError(_ message: String) {
        lastError = message
        resultJSON = nil
    }
}

@MainActor
final class YAMLTreeExpansionState: ObservableObject {
    enum Mode: Equatable {
        case preserveExisting
        case expandAll
        case collapseAll
    }

    @Published var mode: Mode = .preserveExisting
    @Published var revision: Int = 0

    func requestExpandAll() {
        mode = .expandAll
        revision += 1
    }

    func requestCollapseAll() {
        mode = .collapseAll
        revision += 1
    }
}

struct YAMLStructureNode: Identifiable, Equatable {
    enum Kind: Equatable {
        case object
        case array
        case scalar
    }

    let id: String
    let title: String
    let path: String
    let any: AnySendable
    let kind: Kind
    let inlineSummary: String?
    let children: [YAMLStructureNode]?

    var summaryText: String {
        switch kind {
        case .object:
            return "{\(children?.count ?? 0) keys}"
        case .array:
            return "[\(children?.count ?? 0) items]"
        case .scalar:
            return valueSummary(from: any)
        }
    }

    var specType: String? {
        guard case .object(let dict) = any else { return nil }
        return dict["type"]?.stringValue
    }

    static func from(any: AnySendable, title: String, path: String) -> YAMLStructureNode {
        switch any {
        case .object(let dict):
            let children = dict.keys.sorted().map { key in
                let childAny = dict[key] ?? .null
                return YAMLStructureNode.from(any: childAny, title: key, path: "\(path).\(key)")
            }
            return YAMLStructureNode(
                id: path,
                title: title,
                path: path,
                any: any,
                kind: .object,
                inlineSummary: nil,
                children: children
            )
        case .array(let values):
            let children = values.enumerated().map { index, item in
                YAMLStructureNode.from(any: item, title: "[\(index)]", path: "\(path)[\(index)]")
            }
            return YAMLStructureNode(
                id: path,
                title: title,
                path: path,
                any: any,
                kind: .array,
                inlineSummary: "[\(children.count) items]",
                children: children
            )
        default:
            return YAMLStructureNode(
                id: path,
                title: title,
                path: path,
                any: any,
                kind: .scalar,
                inlineSummary: valueSummary(from: any),
                children: nil
            )
        }
    }

    func find(path: String?) -> YAMLStructureNode? {
        guard let path else { return self }
        if self.path == path { return self }
        for child in children ?? [] {
            if let found = child.find(path: path) {
                return found
            }
        }
        return nil
    }
}

private extension YAMLStructureNode {
    /// Builds a tree intended for browsing *effective* YAML behavior (not the raw schema object):
    /// - hides `schema_version` and `version` from the tree
    /// - hides technical keys (`type`, `selector(s)`, `extract`, `requires_any`, etc.) from the tree
    /// - flattens `extract` (children show as direct descendants)
    /// Note: nodes keep their original `path` so the details panel can still resolve the raw YAML node.
    static func semanticRoot(from rawRoot: YAMLStructureNode) -> YAMLStructureNode {
        guard case .object(let dict) = rawRoot.any else { return rawRoot }

        var children: [YAMLStructureNode] = []
        if let flows = dict["flows"] {
            children.append(semanticContainer(any: flows, title: "flows", path: "root.flows"))
        }
        if let web = dict["web"] {
            children.append(semanticContainer(any: web, title: "web", path: "root.web"))
        }

        return YAMLStructureNode(
            id: rawRoot.id,
            title: rawRoot.title,
            path: rawRoot.path,
            any: rawRoot.any,
            kind: .object,
            inlineSummary: nil,
            children: children.isEmpty ? nil : children
        )
    }

    private static func semanticContainer(any: AnySendable, title: String, path: String) -> YAMLStructureNode {
        guard case .object(let dict) = any else {
            return YAMLStructureNode.from(any: any, title: title, path: path)
        }

        let children: [YAMLStructureNode] = dict.keys.sorted().map { key in
            let childAny = dict[key] ?? .null
            return semanticNode(any: childAny, title: key, path: "\(path).\(key)")
        }

        return YAMLStructureNode(
            id: path,
            title: title,
            path: path,
            any: any,
            kind: .object,
            inlineSummary: nil,
            children: children.isEmpty ? nil : children
        )
    }

    private static func semanticNode(any: AnySendable, title: String, path: String) -> YAMLStructureNode {
        guard case .object(let dict) = any else {
            return YAMLStructureNode.from(any: any, title: title, path: path)
        }

        // This is a "spec node" if it has any of the known technical keys.
        let isSpecNode = dict["type"] != nil || dict["selector"] != nil || dict["selectors"] != nil || dict["extract"] != nil || dict["requires_any"] != nil

        if !isSpecNode {
            // Pure container object, keep walking.
            let children: [YAMLStructureNode] = dict.keys.sorted().map { key in
                semanticNode(any: dict[key] ?? .null, title: key, path: "\(path).\(key)")
            }
            return YAMLStructureNode(
                id: path,
                title: title,
                path: path,
                any: any,
                kind: .object,
                inlineSummary: nil,
                children: children.isEmpty ? nil : children
            )
        }

        // Spec node: show ONLY effective extracted children (flatten `extract`).
        var children: [YAMLStructureNode] = []
        if let extractAny = dict["extract"], case .object(let extractDict) = extractAny {
            for key in extractDict.keys.sorted() {
                let childAny = extractDict[key] ?? .null
                // Child path is the spec-node path plus the extracted key so selection can still map into raw YAML.
                // This keeps the tree representing extracted outputs rather than schema wrappers.
                children.append(semanticNode(any: childAny, title: key, path: "\(path).extract.\(key)"))
            }
        }

        // Inline show type (without exposing a `type` child node).
        let inlineSummary: String? = dict["type"]?.stringValue

        return YAMLStructureNode(
            id: path,
            title: title,
            path: path,
            any: any,
            kind: .object,
            inlineSummary: inlineSummary,
            children: children.isEmpty ? nil : children
        )
    }
}

struct YAMLExecutionNode: Identifiable, Equatable {
    let id: String
    let title: String
    let path: String
    let any: AnySendable
    let children: [YAMLExecutionNode]?

    var isFound: Bool {
        guard case .object(let dict) = any else { return false }
        if let found = dict["found"], case .bool(let value) = found { return value }
        if let ok = dict["ok"], case .bool(let value) = ok { return value }
        return false
    }

    var hasExplicitMiss: Bool {
        guard case .object(let dict) = any else { return false }
        if case .bool(let value)? = dict["found"] { return value == false }
        if case .bool(let value)? = dict["ok"] { return value == false }
        return false
    }

    var badge: String? {
        guard case .object(let dict) = any else { return nil }
        if let count = dict["count"]?.intValue { return "count=\(count)" }
        if dict["html"] != nil { return "html" }
        if dict["outerHTML"] != nil { return "html" }
        if let value = dict["value"] {
            return shortSummary(from: value)
        }
        return nil
    }

    var summaryText: String {
        guard case .object(let dict) = any else {
            return valueSummary(from: any)
        }
        if let count = dict["count"]?.intValue { return "count=\(count)" }
        if let value = dict["value"] { return valueSummary(from: value) }
        if let html = dict["html"] { return valueSummary(from: html) }
        if let outerHTML = dict["outerHTML"] { return valueSummary(from: outerHTML) }
        return "{\(children?.count ?? 0) keys}"
    }

    static func from(any: AnySendable, title: String, path: String) -> YAMLExecutionNode {
        let children = buildChildren(any: any, basePath: path)
        return YAMLExecutionNode(id: path, title: title, path: path, any: any, children: children)
    }

    static func buildChildren(any: AnySendable, basePath: String) -> [YAMLExecutionNode]? {
        guard case .object(let dict) = any else { return nil }
        var out: [YAMLExecutionNode] = []

        // Hide top-level metadata keys from the tree (still visible in details).
        let hiddenKeys: Set<String> = [
            "schema_version",
            "version",
            // technical payload keys (keep in details, not in the tree)
            "type",
            "ok",
            "found",
            "count",
            "html",
            "outerHTML",
            "value",
            "composerSelector",
            "activeElementTag"
        ]

        // Make `items[]` navigable (used by `type: elements`).
        if let itemsAny = dict["items"], case .array(let items) = itemsAny {
            let itemNodes: [YAMLExecutionNode] = items.enumerated().map { index, itemAny in
                YAMLExecutionNode.from(any: itemAny, title: "[\(index)]", path: "\(basePath).items[\(index)]")
            }
            if !itemNodes.isEmpty {
                out.append(YAMLExecutionNode(id: "\(basePath).items", title: "items", path: "\(basePath).items", any: itemsAny, children: itemNodes))
            }
        }

        // Flatten `extract` wrapper: show extracted keys as direct children.
        if let extractAny = dict["extract"], case .object(let extractDict) = extractAny {
            for key in extractDict.keys.sorted() {
                let childAny = extractDict[key] ?? .null
                out.append(YAMLExecutionNode.from(any: childAny, title: key, path: "\(basePath).extract.\(key)"))
            }
        }

        // Other keys (excluding items/extract so we don't duplicate it).
        for key in dict.keys.sorted() where key != "items" && key != "extract" && !hiddenKeys.contains(key) {
            let childAny = dict[key] ?? .null
            out.append(YAMLExecutionNode.from(any: childAny, title: key, path: "\(basePath).\(key)"))
        }

        return out.isEmpty ? nil : out
    }

    func find(path: String?) -> YAMLExecutionNode? {
        guard let path else { return self }
        if self.path == path { return self }
        for child in children ?? [] {
            if let found = child.find(path: path) {
                return found
            }
        }
        return nil
    }
}

private extension YAMLExecutionNode {
    var itemsChildren: [YAMLExecutionNode]? {
        children?.first(where: { $0.title == "items" })?.children
    }
}

private func valueSummary(from any: AnySendable) -> String {
    switch any {
    case .null:
        return "null"
    case .bool(let value):
        return value ? "true" : "false"
    case .int(let value):
        return "\(value)"
    case .double(let value):
        return "\(value)"
    case .string(let value):
        return value
    case .array(let values):
        return "[\(values.count) items]"
    case .object(let dict):
        return "{\(dict.count) keys}"
    }
}

private func shortSummary(from any: AnySendable, maxLength: Int = 60) -> String {
    let text: String
    switch any {
    case .null:
        text = "null"
    case .bool(let value):
        text = value ? "true" : "false"
    case .int(let value):
        text = "\(value)"
    case .double(let value):
        text = "\(value)"
    case .string(let value):
        text = value.replacingOccurrences(of: "\n", with: " ")
    case .array(let values):
        text = "[\(values.count) items]"
    case .object(let dict):
        text = "{\(dict.count) keys}"
    }

    if text.count <= maxLength { return text }
    return String(text.prefix(maxLength - 1)) + "…"
}

private extension AnySendable {
    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }
}
