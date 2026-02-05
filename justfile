# MoonBit Project Commands

# Default target (js for browser compatibility)
target := "js"

# Default task: check and test
default: check test

# Format code
fmt:
    moon fmt

# Type check
check:
    moon check --deny-warn --target {{target}}

# Run tests
test:
    moon test --target {{target}}

# Update snapshot tests
test-update:
    moon test --update --target {{target}}

# Run main (HTML preview)
run:
    moon run src/main --target {{target}}

# Build JS bundle
build:
    moon build --target js

# Run CLI (ASCII/SVG renderer)
cli *args:
    moon build src/cli --target js
    node _build/js/release/build/cli/cli.js {{args}}

# Run CLI from stdin (pipe-friendly, via temp file)
cli-stdin *args:
    #!/usr/bin/env bash
    moon build src/cli --target js
    tmp=$(mktemp /tmp/moomaid-XXXXXX.mmd)
    cat > "$tmp"
    node _build/js/release/build/cli/cli.js {{args}} "$tmp"
    rm -f "$tmp"

# Run TUI viewer
tui:
    moon run src/tui --target {{target}}

# Generate type definition files
info:
    moon info

# Clean build artifacts
clean:
    moon clean

# Pre-release check
release-check: fmt info check test
