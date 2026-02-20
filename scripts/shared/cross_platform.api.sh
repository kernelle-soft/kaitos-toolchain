#!/usr/bin/env bash
eval "${CI_ENVRC:-}"

: <<'DOC'
  Returns the platform-appropriate rust shared library filename for a given name.

  Usage:
    shared_lib_filename godot
    # => libgodot.so  (Linux)
    # => libgodot.dylib (macOS)
DOC
function shared_lib_filename() {
  local name="$1"
  case "$(uname -s)" in
    Darwin) echo "lib${name}.dylib" ;;
    *)      echo "lib${name}.so" ;;
  esac
}
