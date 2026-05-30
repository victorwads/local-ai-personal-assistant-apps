# Shared UI Architecture

This folder owns the small shared SwiftUI foundation used by feature screens.

Keep this layer lightweight:

- Prefer native SwiftUI and platform styles.
- Add reusable views only when more than one feature screen can reasonably use them.
- Do not introduce a broad design system, custom color palette, theme engine, or feature-specific logic here.
- Shared UI components must not import Firebase or feature infrastructure.
- Feature screens own their data loading, state, and actions.

Shared UI contains reusable visual primitives used by multiple features.
Feature screens should not duplicate card, badge, empty state, code block, or master-detail presentation patterns when an equivalent shared primitive already exists.
Feature-specific views may compose shared UI components, but they must not move feature logic into `Shared/UI`.

Shared UI must not know feature models, repositories, Firebase, MCP runtime internals, or app services.

Preferred shared components:

- Use `DSFeatureHeader` for feature screen titles with trailing actions.
- Use `DSRefreshButton` for simple refresh actions.
- Use `DSTitledSection` when a section title should sit outside the content card.
- Use `DSBadge` for pills, groups, traits, and status metadata.
- Use `DSMessageBubbleRow` for chat-like conversation UIs and voice interaction histories.
- Use `DSListCardRow` for consistent list and card rows across feature indexes.

The current shared primitives are intended for screens such as:

- MCP Tools Browser
- Chats
- Issues
- Memories
- Sensitive Data

Master-detail guidance:

- Screens with a left list and right detail pane should prefer `NavigationSplitView`.
- The left pane should own filtering, search, and selection.
- The right pane should render the selected item's detail state.
- Keep master-detail structure consistent with the MCP Tools Browser when a feature fits this pattern.
- Do not create a generic master-detail abstraction yet.
- Future Chats screens should prefer `NavigationSplitView` plus `DSMessageBubbleRow`.
- Future Client Voice screens should reuse `DSMessageBubbleRow`.

Preview rule:

- Every shared UI component in this folder must be represented in `Previews.swift`.
- When adding or changing a component, update `Previews.swift` with at least one realistic example.
- Keep previews useful as a visual catalog for Xcode, not as production screen composition.
