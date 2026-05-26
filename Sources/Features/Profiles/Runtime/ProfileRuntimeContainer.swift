import Foundation

/// Future home for the profile-scoped service bubble.
///
/// Each running profile will eventually own its own repositories, MCP server,
/// WhatsApp runtime, assistant loop, settings, logs, and cancellation state here.
/// For now this is a lightweight placeholder so the architecture has the right
/// place to grow into.
///
/// TODO: Render CommandCenter from this running profile container once the
/// runtime bubble is real. The container should hold profile context,
/// profile-scoped repositories, MCP server runtime, WhatsApp runtime, assistant
/// loop, settings observer, logs/debug services, and AI connection/runtime
/// services without making CommandCenter own those lifecycles.
struct ProfileRuntimeContainer: Sendable {
    let context: ProfileContext
}
