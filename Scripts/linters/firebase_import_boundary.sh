#!/usr/bin/env bash

FIREBASE_IMPORT_BOUNDARY_TERMS=(
  "import Firebase"
  "import FirebaseAuth"
  "import FirebaseCore"
  "import FirebaseFirestore"
  "import FirebaseStorage"
  "FirebaseApp"
  "FirebaseFirestore"
  "Firestore"
  "CollectionReference"
  "DocumentReference"
  "DocumentSnapshot"
  "QuerySnapshot"
  "ListenerRegistration"
  "FieldValue"
)

firebase_import_boundary_regex_for_term() {
  local term="$1"

  case "$term" in
    "import Firebase")
      printf '^import[[:space:]]+Firebase([[:space:]]|$)'
      ;;
    import\ *)
      local module="${term#import }"
      printf '^import[[:space:]]+%s([[:space:]]|$)' "$module"
      ;;
    *)
      printf '(^|[^A-Za-z0-9_])%s([^A-Za-z0-9_]|$)' "$term"
      ;;
  esac
}

check_firebase_import_boundary() {
  if [[ ! -d "$SOURCES_DIR" ]]; then
    return 0
  fi

  local swift_file
  while IFS= read -r swift_file; do
    [[ -z "$swift_file" ]] && continue

    local relative_file
    relative_file="$(repo_relative_path "$swift_file")"

    local term
    for term in "${FIREBASE_IMPORT_BOUNDARY_TERMS[@]}"; do
      local regex
      regex="$(firebase_import_boundary_regex_for_term "$term")"

      local matches
      matches="$(grep -n -E -- "$regex" "$swift_file" || true)"

      if [[ -n "$matches" ]]; then
        add_error "$(cat <<EOF
Firebase SDK usage is only allowed inside Sources/Infrastructure. Feature code must depend on Infrastructure repositories/services, not Firebase SDK types directly. Move this Firebase usage behind an Infrastructure abstraction.
  File: $relative_file
  Matched term: $term
$(echo "$matches" | sed 's/^/  Line: /')
EOF
)"
      fi
    done
  done < <(find "$SOURCES_DIR" -type f -name '*.swift' ! -path "$SOURCES_DIR/Infrastructure/*")
}
