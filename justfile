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

# Run CLI (ASCII/SVG renderer)
cli *args:
    moon run src/cli --target {{target}} -- {{args}}

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
