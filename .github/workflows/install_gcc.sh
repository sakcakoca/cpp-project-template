#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "" ]; then
  echo "Usage: $0 <gcc-major-version>"
  exit 1
fi

GCC_MAJOR="$1"
PRIORITY=$((100 + GCC_MAJOR))

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
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt-get update
sudo apt-get install -y \
  "gcc-${GCC_MAJOR}" \
  "g++-${GCC_MAJOR}" \
  "cpp-${GCC_MAJOR}" \
  "gcc-${GCC_MAJOR}-base"

register_alternative gcc "/usr/bin/gcc-${GCC_MAJOR}"
register_alternative g++ "/usr/bin/g++-${GCC_MAJOR}"
register_alternative cc "/usr/bin/gcc-${GCC_MAJOR}"
register_alternative c++ "/usr/bin/g++-${GCC_MAJOR}"
register_alternative gcov "/usr/bin/gcov-${GCC_MAJOR}"
register_alternative gcov-dump "/usr/bin/gcov-dump-${GCC_MAJOR}"
register_alternative gcov-tool "/usr/bin/gcov-tool-${GCC_MAJOR}"
register_alternative gcc-ar "/usr/bin/gcc-ar-${GCC_MAJOR}"
register_alternative gcc-nm "/usr/bin/gcc-nm-${GCC_MAJOR}"
register_alternative gcc-ranlib "/usr/bin/gcc-ranlib-${GCC_MAJOR}"


echo "Configured GCC toolchain:"
gcc --version | head -n 1
g++ --version | head -n 1
gcov --version | head -n 1

