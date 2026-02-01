#!/usr/bin/env bash

# Update VT Code agent.json with all platform binaries from GitHub Release
# Usage: ./update-vtcode-binaries.sh v0.74.3

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    printf '%b\n' "${BLUE}INFO:${NC} $1"
}

print_success() {
    printf '%b\n' "${GREEN}SUCCESS:${NC} $1"
}

print_error() {
    printf '%b\n' "${RED}ERROR:${NC} $1"
}

if [[ $# -ne 1 ]]; then
    print_error "Usage: $0 <version>"
    print_info "Example: $0 v0.74.3"
    exit 1
fi

VERSION="$1"
AGENT_JSON="./vtcode/agent.json"

# Validate version format
if ! [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format: $VERSION (expected v0.74.3)"
    exit 1
fi

# Extract version number without 'v'
VERSION_NUM="${VERSION#v}"

print_info "Updating agent.json for version $VERSION"

# Define all platforms and their URLs
declare -A PLATFORMS=(
    ["darwin-aarch64"]="https://github.com/vinhnx/vtcode/releases/download/$VERSION/vtcode-$VERSION-aarch64-apple-darwin.tar.gz"
    ["darwin-x86_64"]="https://github.com/vinhnx/vtcode/releases/download/$VERSION/vtcode-$VERSION-x86_64-apple-darwin.tar.gz"
    ["linux-x86_64"]="https://github.com/vinhnx/vtcode/releases/download/$VERSION/vtcode-$VERSION-x86_64-unknown-linux-gnu.tar.gz"
    ["linux-aarch64"]="https://github.com/vinhnx/vtcode/releases/download/$VERSION/vtcode-$VERSION-aarch64-unknown-linux-gnu.tar.gz"
    ["windows-x86_64"]="https://github.com/vinhnx/vtcode/releases/download/$VERSION/vtcode-$VERSION-x86_64-pc-windows-msvc.tar.gz"
    ["windows-aarch64"]="https://github.com/vinhnx/vtcode/releases/download/$VERSION/vtcode-$VERSION-aarch64-pc-windows-msvc.tar.gz"
)

# Verify binaries exist
print_info "Verifying binaries exist on GitHub Release..."
for platform in "${!PLATFORMS[@]}"; do
    url="${PLATFORMS[$platform]}"
    if curl -s -I "$url" | grep -q "200\|302"; then
        print_success "✓ $platform"
    else
        print_error "✗ $platform not found: $url"
        exit 1
    fi
done

# Build new agent.json with updated version and all platforms
print_info "Generating new agent.json..."

cat > "$AGENT_JSON" << 'EOF'
{
  "id": "vtcode",
  "name": "VT Code",
  "version": "VERSION_PLACEHOLDER",
  "description": "Rust-based terminal coding agent with Tree-sitter semantic intelligence and multi-LLM support",
  "repository": "https://github.com/vinhnx/vtcode",
  "authors": ["Vinh Nguyen <vinhnguyen2308@gmail.com>"],
  "license": "MIT",
  "distribution": {
    "binary": {
      "darwin-aarch64": {
        "archive": "DARWIN_AARCH64_PLACEHOLDER",
        "cmd": "./vtcode",
        "args": ["--acp"]
      },
      "darwin-x86_64": {
        "archive": "DARWIN_X86_64_PLACEHOLDER",
        "cmd": "./vtcode",
        "args": ["--acp"]
      },
      "linux-x86_64": {
        "archive": "LINUX_X86_64_PLACEHOLDER",
        "cmd": "./vtcode",
        "args": ["--acp"]
      },
      "linux-aarch64": {
        "archive": "LINUX_AARCH64_PLACEHOLDER",
        "cmd": "./vtcode",
        "args": ["--acp"]
      },
      "windows-x86_64": {
        "archive": "WINDOWS_X86_64_PLACEHOLDER",
        "cmd": ".\\vtcode.exe",
        "args": ["--acp"]
      },
      "windows-aarch64": {
        "archive": "WINDOWS_AARCH64_PLACEHOLDER",
        "cmd": ".\\vtcode.exe",
        "args": ["--acp"]
      }
    }
  }
}
EOF

# Replace placeholders
sed -i.bak "s|VERSION_PLACEHOLDER|$VERSION_NUM|g" "$AGENT_JSON"
sed -i.bak "s|DARWIN_AARCH64_PLACEHOLDER|${PLATFORMS[darwin-aarch64]}|g" "$AGENT_JSON"
sed -i.bak "s|DARWIN_X86_64_PLACEHOLDER|${PLATFORMS[darwin-x86_64]}|g" "$AGENT_JSON"
sed -i.bak "s|LINUX_X86_64_PLACEHOLDER|${PLATFORMS[linux-x86_64]}|g" "$AGENT_JSON"
sed -i.bak "s|LINUX_AARCH64_PLACEHOLDER|${PLATFORMS[linux-aarch64]}|g" "$AGENT_JSON"
sed -i.bak "s|WINDOWS_X86_64_PLACEHOLDER|${PLATFORMS[windows-x86_64]}|g" "$AGENT_JSON"
sed -i.bak "s|WINDOWS_AARCH64_PLACEHOLDER|${PLATFORMS[windows-aarch64]}|g" "$AGENT_JSON"

# Clean up backup
rm -f "$AGENT_JSON.bak"

print_success "Updated $AGENT_JSON with all 6 platform binaries"
print_info "Next steps:"
print_info "1. Validate registry: uv run --with jsonschema .github/workflows/build_registry.py"
print_info "2. Commit changes: git add vtcode/ && git commit -m 'chore: update vtcode binaries to $VERSION'"
print_info "3. Push changes: git push origin main"
