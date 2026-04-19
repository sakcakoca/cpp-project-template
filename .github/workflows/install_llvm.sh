#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "" ]; then
  echo "Usage: $0 <llvm-major-version>"
  exit 1
fi

LLVM_MAJOR="$1"
PRIORITY=$((100 + LLVM_MAJOR))

register_alternative() {
  local name="$1"
  local target="$2"

  if [ ! -x "$target" ]; then
    echo "Skipping update-alternatives for $name (missing: $target)"
    return
  fi

  sudo update-alternatives --install "/usr/bin/$name" "$name" "$target" "$PRIORITY"
  sudo update-alternatives --set "$name" "$target"
}

sudo apt-get update
sudo apt-get install -y wget gnupg lsb-release software-properties-common

LLVM_INSTALLER=/tmp/llvm.sh
wget -q -O "$LLVM_INSTALLER" https://apt.llvm.org/llvm.sh
chmod +x "$LLVM_INSTALLER"
sudo "$LLVM_INSTALLER" "$LLVM_MAJOR" all

sudo apt-get update
sudo apt-get install -y \
  "clang-${LLVM_MAJOR}" \
  "clang-tools-${LLVM_MAJOR}" \
  "clang-tidy-${LLVM_MAJOR}" \
  "clang-format-${LLVM_MAJOR}" \
  "clangd-${LLVM_MAJOR}" \
  "lld-${LLVM_MAJOR}" \
  "llvm-${LLVM_MAJOR}" \
  "llvm-${LLVM_MAJOR}-tools"

register_alternative clang "/usr/bin/clang-${LLVM_MAJOR}"
register_alternative clang++ "/usr/bin/clang++-${LLVM_MAJOR}"
register_alternative cc "/usr/bin/clang-${LLVM_MAJOR}"
register_alternative c++ "/usr/bin/clang++-${LLVM_MAJOR}"
register_alternative clang-tidy "/usr/bin/clang-tidy-${LLVM_MAJOR}"
register_alternative clang-format "/usr/bin/clang-format-${LLVM_MAJOR}"
register_alternative clangd "/usr/bin/clangd-${LLVM_MAJOR}"
register_alternative ld.lld "/usr/bin/ld.lld-${LLVM_MAJOR}"
register_alternative llvm-ar "/usr/bin/llvm-ar-${LLVM_MAJOR}"
register_alternative llvm-ranlib "/usr/bin/llvm-ranlib-${LLVM_MAJOR}"
register_alternative llvm-nm "/usr/bin/llvm-nm-${LLVM_MAJOR}"
register_alternative llvm-objdump "/usr/bin/llvm-objdump-${LLVM_MAJOR}"
register_alternative llvm-objcopy "/usr/bin/llvm-objcopy-${LLVM_MAJOR}"
register_alternative llvm-readelf "/usr/bin/llvm-readelf-${LLVM_MAJOR}"
register_alternative llvm-strip "/usr/bin/llvm-strip-${LLVM_MAJOR}"
register_alternative llvm-cov "/usr/bin/llvm-cov-${LLVM_MAJOR}"
register_alternative llvm-profdata "/usr/bin/llvm-profdata-${LLVM_MAJOR}"


echo "Configured LLVM/Clang toolchain:"
clang --version | head -n 1
clang++ --version | head -n 1
clang-tidy --version | head -n 1
clang-format --version | head -n 1

