#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"

# Check dependencies
for cmd in moon node; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is required but not found" >&2
    exit 1
  fi
done

echo "Building moomaid..."
moon build src/cmd/moomaid --target js --release

echo "Installing to $PREFIX ..."
mkdir -p "$PREFIX/lib/moomaid" "$PREFIX/bin"

cp _build/js/release/build/cmd/moomaid/moomaid.js "$PREFIX/lib/moomaid/moomaid.js"

cat > "$PREFIX/bin/moomaid" <<'WRAPPER'
#!/usr/bin/env node
import { createRequire } from "node:module";
globalThis.require = createRequire(import.meta.url);
WRAPPER

# Append the import with the resolved path
echo "await import(\"$PREFIX/lib/moomaid/moomaid.js\");" >> "$PREFIX/bin/moomaid"

chmod +x "$PREFIX/bin/moomaid"

echo "Installed moomaid to $PREFIX/bin/moomaid"
echo "Make sure $PREFIX/bin is in your PATH"
