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

# Run HTML preview
run:
    moon build src/cmd/moomaid --target js --release
    node bin/moomaid.js --html

# Build JS bundle
build:
    moon build --target js --release

# Run CLI (ASCII/SVG/HTML renderer)
cli *args:
    moon build src/cmd/moomaid --target js --release
    node bin/moomaid.js {{args}}

# Run CLI from stdin (pipe-friendly, via temp file)
cli-stdin *args:
    #!/usr/bin/env bash
    moon build src/cmd/moomaid --target js --release
    tmp=$(mktemp /tmp/moomaid-XXXXXX.mmd)
    cat > "$tmp"
    node bin/moomaid.js {{args}} "$tmp"
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

# Project dependency graph
graph *args:
    ./bin/moon-graph {{args}}

# Pre-release check
release-check: fmt info check test
