#!/usr/bin/env bash
set -euo pipefail

# Architecture guardrail script.
#
# If this script fails, fix the source files that violate the rule.
# Do not remove rules.
# Do not weaken rules.
# Do not rename forbidden words just to bypass the check.
# Do not edit this script unless the user explicitly asks to change architecture rules.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCES_DIR="$ROOT_DIR/Sources"
DOCS_ARCHITECTURE="$ROOT_DIR/Docs/Architecture.md"
THIS_SCRIPT="$SCRIPT_DIR/check_architecture_rules.sh"

ERRORS=()

RULE_PATTERNS=()
RULE_SCOPES=()
RULE_MESSAGES=()

TEMP_FILES=()

cleanup() {
  for file in "${TEMP_FILES[@]}"; do
    rm -f "$file"
  done
}

trap cleanup EXIT

add_error() {
  ERRORS+=("$1")
}

repo_relative_path() {
  local path="$1"
  echo "${path#"$ROOT_DIR/"}"
}

fail_if_found() {
  local pattern="$1"
  local message="$2"
  local scope="${3:-Sources}"

  RULE_PATTERNS+=("$pattern")
  RULE_SCOPES+=("$scope")
  RULE_MESSAGES+=("$message")
}

check_this_script_was_not_modified() {
  if ! git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi

  local relative_script
  relative_script="$(repo_relative_path "$THIS_SCRIPT")"

  local status
  status="$(git -C "$ROOT_DIR" status --porcelain -- "$relative_script")"

  if [[ -n "$status" ]]; then
    add_error "Architecture guardrail script was modified.
      File: $relative_script
      Git status: $status

      This file is protected.
      Restore this file before continuing.
      Do not edit this script.
      Do not bypass architecture rules.
      Fix the reported source files instead."
  fi
}

verify_fail_if_found_rules() {
  if [[ ${#RULE_PATTERNS[@]} -eq 0 ]]; then
    return 0
  fi

  if [[ ! -d "$SOURCES_DIR" ]]; then
    return 0
  fi

  local patterns_file
  patterns_file="$(mktemp)"
  TEMP_FILES+=("$patterns_file")

  local pattern
  for pattern in "${RULE_PATTERNS[@]}"; do
    printf '%s\n' "$pattern" >> "$patterns_file"
  done

  local matched_files_file
  matched_files_file="$(mktemp)"
  TEMP_FILES+=("$matched_files_file")

  grep -R -l -F -f "$patterns_file" "$SOURCES_DIR" > "$matched_files_file" || true

  local file
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    local relative_file
    relative_file="$(repo_relative_path "$file")"

    local index
    for (( index = 0; index < ${#RULE_PATTERNS[@]}; index++ )); do
      local rule_pattern="${RULE_PATTERNS[$index]}"
      local rule_scope="${RULE_SCOPES[$index]}"
      local rule_message="${RULE_MESSAGES[$index]}"

      local absolute_scope
      if [[ "$rule_scope" = /* ]]; then
        absolute_scope="$rule_scope"
      else
        absolute_scope="$ROOT_DIR/$rule_scope"
      fi

      if [[ "$file" != "$absolute_scope"* ]]; then
        continue
      fi

      local matches
      matches="$(grep -n -F -- "$rule_pattern" "$file" || true)"

      if [[ -n "$matches" ]]; then
        add_error "$(cat <<EOF
$rule_message
  File: $relative_file
  Pattern: $rule_pattern
$(echo "$matches" | sed 's/^/  Line: /')
  Fix the reported source file. Do not edit scripts/check_architecture_rules.sh to bypass this rule.
EOF
)"
      fi
    done
  done < "$matched_files_file"
}

check_source_architecture_docs_are_linked() {
  if [[ ! -f "$DOCS_ARCHITECTURE" ]]; then
    add_error "Docs/Architecture.md does not exist at $DOCS_ARCHITECTURE"
    return
  fi

  if [[ ! -d "$SOURCES_DIR" ]]; then
    return
  fi

  local architecture_file
  while IFS= read -r architecture_file; do
    [[ -z "$architecture_file" ]] && continue

    local basename
    basename="$(basename "$architecture_file")"

    local relative_path
    relative_path="$(repo_relative_path "$architecture_file")"

    if [[ "$basename" != "Architecture.md" ]]; then
      add_error "Architecture docs must be named exactly Architecture.md.
  Invalid file: $relative_path
  Rename this file to Architecture.md inside its owning folder.
  Do not use names like FirebaseArchitecture.md, architecture.md, ARCHITECTURE.md, or FeatureArchitecture.md."
      continue
    fi

    if ! grep -Fq "$relative_path" "$DOCS_ARCHITECTURE"; then
      add_error "Source architecture doc is not linked from Docs/Architecture.md.
  Missing path: $relative_path
  Add this repo-relative path to Docs/Architecture.md."
    fi
  done < <(find "$SOURCES_DIR" -type f -iname '*architecture*.md')
}

fail_if_found "mergingForUpsert" "Do not put merge/upsert behavior in models or model protocols."

fail_if_found "sourceMessageId" "Message ids must already include source prefix." "Sources/Features/Chats"
fail_if_found "sourceChatId" "Chat ids must already include source prefix." "Sources/Features/Chats"

fail_if_found "rawDateTimeAndAuthor" "Raw integration fields must not be stored in domain models." "Sources/Features/Chats/Models"
fail_if_found "rawTimeText" "Raw integration fields must not be stored in domain models." "Sources/Features/Chats/Models"

fail_if_found "Legacy" "Delete unused files instead of marking them Legacy."
fail_if_found "Unused" "Delete unused files instead of marking them Unused."
fail_if_found "Deprecated" "Delete unused files instead of marking them Deprecated."
fail_if_found "Do not use" "Delete unused files instead of marking them Do not use."
fail_if_found "DO NOT USE" "Delete unused files instead of marking them DO NOT USE."
fail_if_found "do not use" "Delete unused files instead of marking them do not use."

check_this_script_was_not_modified
verify_fail_if_found_rules
check_source_architecture_docs_are_linked

if (( ${#ERRORS[@]} > 0 )); then
  echo "Architecture rule violations:"
  echo

  for error in "${ERRORS[@]}"; do
    echo "$error"
    echo
  done

  echo "How to fix:"
  echo "- Fix the reported source files."
  echo "- Do not remove, weaken, rename, or bypass rules in scripts/check_architecture_rules.sh."
  echo "- If this script itself needs to change, do it intentionally and commit/review that change separately."
  echo "- If a file is unused, delete it instead of marking it Legacy/Unused/Deprecated/Do not use."

  exit 1
fi

echo "Architecture rules passed."
