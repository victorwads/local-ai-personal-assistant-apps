# Agent Rules

- Never edit `.xcodeproj` manually. Use XcodeGen only.
- Never modify YAML selector files unless explicitly requested.
- Domain models must be data-only.
- Domain models must not contain repository/upsert/merge behavior.
- Firebase audit metadata is injected by FirebaseRepository, not stored in every model.
- Feature repositories should be thin wrappers over FirebaseRepository.
- Do not create new architecture when a small change solves the issue.
- Delete unused files instead of marking them Legacy/Unused.
- Prefer changing the smallest number of files.
- Before adding a new abstraction, explain why an existing one cannot be used.
