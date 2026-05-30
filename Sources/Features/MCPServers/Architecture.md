# MCP Servers Architecture

This document owns MCP server composition, tool registry boundaries, and the current tool surface index.

## Current tool surface

The registered tool list is assembled from concrete tool instances that conform to `MCPToolDefinition` and stored by `Sources/Features/MCPServers/Registry/MCPToolRegistry.swift`.

Each concrete tool lives under `Sources/Features/**/MCP/`.
Those Swift files are the source of truth for tool names, schemas, descriptions, and execution behavior.
Tool grouping is a plain string owned by the feature that instantiates the tool.

## Tools Browser integration

The Tools Browser UI lives in `Sources/Features/ToolsBrowser/` and consumes MCP Servers through public `MCPServersFeature` APIs.

`MCPServersFeature` exposes:

- `listToolDefinitions()`
- `executeToolCall(_:)`

`executeToolCall(_:)` is backed by `Runtime/MCPToolExecutor.swift`, which is the official manual tool execution path.
Tool definitions are never executed directly from UI/ViewModel code.

## Validation pipeline

`MCPToolExecutor` is the only official tool execution path for:

- Tools Browser manual execution
- future AI Connection tool-calling execution
- future tests/integration flows that execute tool calls

Execution flow:

1. Resolve tool definition from `MCPToolRegistry`.
2. Build `MCPToolValidationContext`.
3. Run all validators from `Validation/` (`MCPToolCallValidator`) before execution (concurrently).
4. Aggregate all validation failures from all validators.
5. Sort errors deterministically (validator registration order, then fieldPath, validatorName, message, suggestedAction).
6. If any validation errors exist, block execution and return all of them together.
7. If all validators pass, execute the tool definition.

Rules:

- Validators are registered in order, but validation work may run concurrently.
- Any validation error blocks tool execution.
- Validation failures are aggregated and returned together (no short-circuit on first error).
- Validation errors retain debug metadata (`toolName`, `validatorName`, `fieldPath`) for logs/diagnostics.
- All `MCPToolValidationError` fields are required: `message`, `suggestedAction`, `fieldPath`, `validatorName`, `toolName`.
- AI-facing validation output exposes only `message` and `suggestedAction`.
- Use `fieldPath: "$"` for root-level/call-level validation errors; use direct paths like `issueId`, `messages[0]`, or `arguments` for field-specific errors.
- Validators must always provide a non-empty `suggestedAction` that tells the AI how to fix the tool call.
- `MCPToolExecutor.execute(_:)` should remain small; validation orchestration belongs in private helper methods.
- Tool definitions should not duplicate shared, generic validation concerns.
- The current validation pipeline defaults to zero validators; real validators will be added later.

Planned shared validators include:

- required fields validation
- unknown fields validation
- type validation
- enum validation
- issueId validation
- permission validation
- sensitive data validation
- audit/confirmation validation

The current tool groups are:

### Chats (read-only tools)

- `list_chats_by_search`
- `list_unhandled_chats`
- `list_chat_messages`
- `send_message`
- `wait_for_event`

### Client voice tools

- `speak_to_client`
- `ask_to_client`

### Memory tools

- `create_memory`
- `get_memory`
- `search_memories`
- `list_memories`
- `delete_memory`

### Sensitive data tools

- `save_sensitive_data`
- `get_sensitive_data`
- `search_sensitive_data`
- `list_sensitive_data`
- `update_sensitive_data`
- `delete_sensitive_data`

### Issue tools

- `create_issue`
- `update_issue`
- `get_issue`
- `list_active_issues`
- `resolve_issue`
- `cancel_issue`

### Utility tools

- `get_current_datetime`

## Ownership updates

- `get_current_datetime` is the only date/time utility owned by `MCPServersFeature`.
- `get_assistant_name` is owned and registered by `SentMessagesFeature`.
- `wait_for_event` is deferred runtime/orchestration work and is not registered by `ChatsFeature`.
- `send_message` remains a deferred transport placeholder; real sending stays channel-owned and will be added later.

When changing or documenting tool behavior, check the corresponding `*Tool.swift` implementation first.
