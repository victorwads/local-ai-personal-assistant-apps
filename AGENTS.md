# Agent Rules

* Read this file before making changes.
* Read `Docs/Architecture.md` before making architecture-sensitive changes.
* When changing a feature or infrastructure area, also read the nearest `Architecture.md` file under that folder.
* Never edit `.xcodeproj`, `.xcworkspace`, generated schemes, or `project.pbxproj` manually. Use XcodeGen only.
* Never modify YAML selector files unless explicitly requested.
* Validate builds with `scripts/check_build_and_restart.sh`. Do not run `xcodebuild` manually.
* Validate architecture rules with `scripts/check_architecture_rules.sh`.
* Domain models must be data-only.
* Domain models must not contain repository, upsert, merge, or persistence behavior.
* Feature repositories should extend `FirestoreRepository` when default CRUD behavior is enough.
* Use wrapper/composition repositories only when the feature truly coordinates multiple stores or has feature-specific persistence rules.
* Do not create new architecture when a small change solves the issue.
* Delete unused files instead of marking them Legacy, Unused, Deprecated, or Do not use.
* Prefer changing the smallest number of files.
* Before adding a new abstraction, explain why an existing one cannot be used.
