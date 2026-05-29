#!/usr/bin/env bash
set -euo pipefail

# Linter orchestrator.
#
# If this script fails, fix the source files that violate the rule.
# Do not remove rules.
# Do not weaken rules.
# Do not rename forbidden words just to bypass the check.
# Do not edit linter scripts unless the user explicitly asks to change lint rules.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCES_DIR="$ROOT_DIR/Sources"
DOCS_ARCHITECTURE="$ROOT_DIR/Docs/Architecture.md"
THIS_SCRIPT="$SCRIPT_DIR/lint.sh"

ERRORS=()

add_error() {
  ERRORS+=("$1")
}

repo_relative_path() {
  local path="$1"
  echo "${path#"$ROOT_DIR/"}"
}

. "$SCRIPT_DIR/linters/fail_if_found.sh"
. "$SCRIPT_DIR/linters/architecture_docs.sh"
. "$SCRIPT_DIR/linters/forbidden_model_metadata.sh"
. "$SCRIPT_DIR/linters/firebase_import_boundary.sh"

check_linter_scripts_were_not_modified() {
  if ! git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi

  local status
  status="$(git -C "$ROOT_DIR" status --porcelain -uall -- scripts/lint.sh scripts/linters Scripts/lint.sh Scripts/linters)"

  if [[ -z "$status" ]]; then
    return 0
  fi

  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    add_error "This linter file is protected.
Restore this file before continuing.
Do not edit linter scripts.
Do not bypass lint rules.
Fix the reported source files instead.
  Git status: $line"
  done <<< "$status"
}

check_linter_scripts_were_not_modified
register_default_fail_if_found_rules
verify_fail_if_found_rules
check_source_architecture_docs_are_linked
check_forbidden_model_metadata
check_firebase_import_boundary

if (( ${#ERRORS[@]} > 0 )); then
  echo "Lint violations:"
  echo

  for error in "${ERRORS[@]}"; do
    echo "$error"
    echo
  done

  echo "How to fix:"
  echo "- Fix the reported source files."
  echo "- Do not remove, weaken, rename, or bypass linter rules."
  echo "- If a file is unused, delete it instead of marking it Legacy/Unused/Deprecated/Do not use."

  exit 1
fi

echo "Lint passed."
