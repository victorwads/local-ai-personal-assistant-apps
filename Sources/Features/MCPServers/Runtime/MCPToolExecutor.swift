import Foundation

final class MCPToolExecutor: MCPToolExecutionProviding {
    private let registry: MCPToolRegistry
    private let context: MCPServerContext
    private let validators: [any MCPToolCallValidator]

    init(
        registry: MCPToolRegistry,
        context: MCPServerContext = MCPServerContext(),
        validators: [any MCPToolCallValidator] = []
    ) {
        self.registry = registry
        self.context = context
        self.validators = validators
    }

    func execute(_ call: MCPToolCall) async -> MCPToolExecutionResult {
        guard let definition = registry.definition(named: call.name) else {
            return .failure(toolName: call.name, error: .toolNotFound(call.name))
        }

        let validationErrors = await validate(call, definition: definition)
        if !validationErrors.isEmpty {
            return .failure(
                toolName: call.name,
                error: .validationFailed(validationErrors)
            )
        }

        return await definition.execute(call, context: context)
    }

    private func validate(
        _ call: MCPToolCall,
        definition: any MCPToolDefinition
    ) async -> [MCPToolValidationError] {
        let validationContext = MCPToolValidationContext(serverContext: context)
        let indexedErrors = await runValidators(
            call: call,
            definition: definition,
            validationContext: validationContext
        )
        return sortedValidationErrors(indexedErrors)
    }

    private func runValidators(
        call: MCPToolCall,
        definition: any MCPToolDefinition,
        validationContext: MCPToolValidationContext
    ) async -> [(index: Int, errors: [MCPToolValidationError])] {
        await withTaskGroup(
            of: (Int, [MCPToolValidationError]).self,
            returning: [(Int, [MCPToolValidationError])].self
        ) { group in
            for (index, validator) in validators.enumerated() {
                group.addTask {
                    let result = await validator.validate(
                        call: call,
                        definition: definition,
                        context: validationContext
                    )

                    switch result {
                    case .success:
                        return (index, [])
                    case let .failure(errors):
                        return (index, errors)
                    }
                }
            }

            var indexedErrors: [(Int, [MCPToolValidationError])] = []
            for await entry in group {
                indexedErrors.append(entry)
            }

            return indexedErrors
        }
    }

    private func sortedValidationErrors(
        _ indexedErrors: [(index: Int, errors: [MCPToolValidationError])]
    ) -> [MCPToolValidationError] {
        indexedErrors
            .sorted { lhs, rhs in
                lhs.index < rhs.index
            }
            .flatMap { indexedEntry in
                indexedEntry.errors.sorted { lhs, rhs in
                    if lhs.fieldPath != rhs.fieldPath {
                        return lhs.fieldPath < rhs.fieldPath
                    }
                    if lhs.validatorName != rhs.validatorName {
                        return lhs.validatorName < rhs.validatorName
                    }
                    if lhs.message != rhs.message {
                        return lhs.message < rhs.message
                    }
                    return lhs.suggestedAction < rhs.suggestedAction
                }
            }
    }
}
