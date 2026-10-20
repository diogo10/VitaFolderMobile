#!/usr/bin/env bash
# Installs the pinned OpenCode CLI that the CI review workflow runs.
#
# Why this exists instead of `curl -fsSL https://opencode.ai/v2/install | bash`:
# that URL always serves the *newest* installer script, so its checksum
# changes every time upstream edits it. Pinning the checksum of a file that
# keeps moving breaks CI on every upstream release - that is exactly how the
# `call-bob` job started failing on every pull request ("sha256sum: WARNING:
# 1 computed checksum did NOT match").
#
# This script installs an immutable artifact instead: the npm tarball for a
# fixed version and platform. The tarball's Subresource Integrity hash
# (sha512) and the sha256 of the binary inside it are pinned below, so the
# download is reproducible and verified before anything is executed. The
# installed binary is re-verified on every run, so a restored CI cache entry
# cannot smuggle in a different binary either.
#
# Usage:
#   tool/install_opencode_cli.sh                    # install into $HOME/.opencode/bin
#   tool/install_opencode_cli.sh --print-target     # print "<target> <version> <sha256>"
#
# Requires: bash, curl, tar, python3 (all present on GitHub-hosted runners).
set -euo pipefail

readonly OPENCODE_VERSION="2.0.15"

# Subresource Integrity (sha512, base64) of the published npm tarball.
readonly INTEGRITY_LINUX_X64="sha512-PGVHuIb6uDgCx19zbD3wGwDYBZLeZnZY89c28SCcB87ckAgfOp+L2o7rra1TMbyQVLhZAqccbymWDeqrynfOCA=="
readonly INTEGRITY_LINUX_X64_BASELINE="sha512-ZT9TxDqUAGrjvIcRVXOlx78v+J7pQd7K3WeI94/KYTTjKkgGs7JQyc060VdCML5URIN6rUlWb7midq4EhPX3BQ=="
readonly INTEGRITY_LINUX_ARM64="sha512-AAowG3XMBi7RwhEp/j2oaa4GuNZB0bEUe/fyFKMgkoKKbqssPkjKB+U3ZeEzXCzb/zgR1kgi/+OiUVzTd4iv1w=="

# sha256 of the `package/bin/opencode` binary inside each tarball.
readonly SHA256_LINUX_X64="b8ed44e893a3307cf23b4e0c83a4bb52b2c38d580fff33d3d9ec16477efb6077"
readonly SHA256_LINUX_X64_BASELINE="4aaa3a7157f6c9e85fea7274c34e7a172f2fae06302e1d3a879838e9eed78650"
readonly SHA256_LINUX_ARM64="82111710ae34fa7f2af0835b9fba0f9fb89f62e903f186d0582c9ff0e2c98806"

INSTALL_DIR="${OPENCODE_INSTALL_DIR:-$HOME/.opencode/bin}"
TMP_DIR=""

say() { printf '%s\n' "$*"; }
fail() { printf '::error::%s\n' "$*" >&2; exit 1; }

cleanup() {
  if [[ -n "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

# Resolves the npm package target for this machine. The default x64 build
# needs AVX2; upstream ships a baseline build for CPUs without it.
detect_target() {
  local os arch
  os="$(uname -s)"
  [[ "$os" == "Linux" ]] || fail "unsupported OS: $os (this installer supports Linux)"
  arch="$(uname -m)"
  case "$arch" in
    x86_64 | amd64) arch="x64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *) fail "unsupported architecture: $arch" ;;
  esac
  if [[ "$arch" == "x64" ]] && ! grep -qwi avx2 /proc/cpuinfo 2>/dev/null; then
    echo "linux-x64-baseline"
  else
    echo "linux-$arch"
  fi
}

target_integrity() {
  case "$1" in
    linux-x64) echo "$INTEGRITY_LINUX_X64" ;;
    linux-x64-baseline) echo "$INTEGRITY_LINUX_X64_BASELINE" ;;
    linux-arm64) echo "$INTEGRITY_LINUX_ARM64" ;;
    *) fail "no pinned integrity for target: $1" ;;
  esac
}

target_sha256() {
  case "$1" in
    linux-x64) echo "$SHA256_LINUX_X64" ;;
    linux-x64-baseline) echo "$SHA256_LINUX_X64_BASELINE" ;;
    linux-arm64) echo "$SHA256_LINUX_ARM64" ;;
    *) fail "no pinned checksum for target: $1" ;;
  esac
}

# Subresource Integrity check: sha512 of the file, base64 encoded.
# Subresource Integrity digest of a file: "sha512-<base64>".
sri_of() {
  python3 - "$1" <<'PY'
import base64
import hashlib
import sys

digest = hashlib.sha512()
with open(sys.argv[1], "rb") as handle:
    for chunk in iter(lambda: handle.read(1024 * 1024), b""):
        digest.update(chunk)
print("sha512-" + base64.b64encode(digest.digest()).decode())
PY
}

# Hex sha256 digest of a file.
sha256_of() {
  python3 - "$1" <<'PY'
import hashlib
import sys

digest = hashlib.sha256()
with open(sys.argv[1], "rb") as handle:
    for chunk in iter(lambda: handle.read(1024 * 1024), b""):
        digest.update(chunk)
print(digest.hexdigest())
PY
}

verify_sri() {
  local file="$1" expected="$2" actual
  actual="$(sri_of "$file")"
  [[ "$actual" == "$expected" ]] ||
    fail "integrity mismatch for $file (expected $expected, got $actual)"
}

verify_sha256() {
  local file="$1" expected="$2" actual
  actual="$(sha256_of "$file")"
  [[ "$actual" == "$expected" ]] ||
    fail "checksum mismatch for $file (expected $expected, got $actual)"
}

install_cli() {
  local target="$1" integrity sha256 url binary
  integrity="$(target_integrity "$target")"
  sha256="$(target_sha256 "$target")"
  url="https://registry.npmjs.org/@opencode/cli-${target}/-/cli-${target}-${OPENCODE_VERSION}.tgz"

  TMP_DIR="$(mktemp -d)"

  say "Downloading OpenCode $OPENCODE_VERSION ($target)..."
  curl -fsSL --retry 3 --retry-delay 2 -o "$TMP_DIR/cli.tgz" "$url"
  verify_sri "$TMP_DIR/cli.tgz" "$integrity"

  tar -xzf "$TMP_DIR/cli.tgz" -C "$TMP_DIR"
  binary="$TMP_DIR/package/bin/opencode"
  [[ -f "$binary" ]] || fail "tarball did not contain package/bin/opencode"
  verify_sha256 "$binary" "$sha256"

  mkdir -p "$INSTALL_DIR"
  install -m 0755 "$binary" "$INSTALL_DIR/opencode"
  say "Installed $INSTALL_DIR/opencode"
}

main() {
  local target
  target="$(detect_target)"

  if [[ "${1:-}" == "--print-target" ]]; then
    echo "$target $OPENCODE_VERSION $(target_sha256 "$target")"
    return 0
  fi

  # A cached install is reused only when it still matches the pinned
  # checksum, so a poisoned cache entry can never be executed.
  if [[ -x "$INSTALL_DIR/opencode" ]]; then
    if [[ "$(sha256_of "$INSTALL_DIR/opencode")" == "$(target_sha256 "$target")" ]]; then
      say "OpenCode $OPENCODE_VERSION already installed at $INSTALL_DIR/opencode"
      "$INSTALL_DIR/opencode" --version
      return 0
    fi
    say "Cached OpenCode binary does not match the pinned checksum; reinstalling."
  fi

  install_cli "$target"
  "$INSTALL_DIR/opencode" --version
}

main "$@"
