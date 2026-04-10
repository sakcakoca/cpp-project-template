# ExecuteConanInstall.cmake
# ─────────────────────────────────────────────────────────────────────────────
# Runs `conan install` during CMake configure when needed.
#
# Behaviour
#   1. If conan_toolchain.cmake already exists in CMAKE_BINARY_DIR the step
#      is skipped (supports a manual `conan install` workflow).
#   2. Set SKIP_CONAN_INSTALL=ON to always skip (e.g. in CI after a
#      separate conan step).
#
# Environment variables (typically set by CMake presets):
#   CONAN_HOST_PROFILE  - path to host profile   (default: "default")
#   CONAN_BUILD_PROFILE - path to build profile   (default: "default")
# ─────────────────────────────────────────────────────────────────────────────
include_guard(GLOBAL)

option(SKIP_CONAN_INSTALL
  "Skip the automatic conan install step (use when running conan manually)" OFF)

set(_CONAN_TOOLCHAIN "${CMAKE_BINARY_DIR}/conan_toolchain.cmake")

# ── Fast-path exits ─────────────────────────────────────────────────────────
if(SKIP_CONAN_INSTALL)
  message(STATUS "[Conan] Skipping (SKIP_CONAN_INSTALL=ON)")
elseif(EXISTS "${_CONAN_TOOLCHAIN}")
  message(STATUS "[Conan] conan_toolchain.cmake exists — skipping install")
else()
  # ── Verify Conan 2 ──────────────────────────────────────────────────────
  find_program(_CONAN_EXE NAMES conan)
  if(NOT _CONAN_EXE)
    message(FATAL_ERROR
      "[Conan] 'conan' not found on PATH. Install Conan 2: pip install conan")
  endif()

  execute_process(
    COMMAND "${_CONAN_EXE}" --version
    OUTPUT_VARIABLE _CONAN_VER_OUT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE _CONAN_VER_RC
  )
  if(NOT _CONAN_VER_RC EQUAL 0)
    message(FATAL_ERROR "[Conan] 'conan --version' failed (rc=${_CONAN_VER_RC})")
  endif()

  string(REGEX MATCH "([0-9]+)\\.[0-9]+\\.[0-9]+" _CONAN_FULL_VER "${_CONAN_VER_OUT}")
  string(REGEX REPLACE "\\..*" "" _CONAN_MAJOR "${_CONAN_FULL_VER}")
  if(NOT _CONAN_MAJOR STREQUAL "2")
    message(FATAL_ERROR
      "[Conan] Conan 2 required (found ${_CONAN_VER_OUT}). "
      "Upgrade: pip install conan --upgrade")
  endif()
  message(STATUS "[Conan] ${_CONAN_VER_OUT}")

  # ── Ensure the default profile exists ──────────────────────────────────
  execute_process(
    COMMAND "${_CONAN_EXE}" profile path default
    RESULT_VARIABLE _CONAN_PROF_RC
    OUTPUT_QUIET ERROR_QUIET
  )
  if(NOT _CONAN_PROF_RC EQUAL 0)
    message(STATUS "[Conan] Default profile missing — running 'conan profile detect'")
    execute_process(COMMAND "${_CONAN_EXE}" profile detect --force)
  endif()

  # ── Resolve profiles from environment ──────────────────────────────────
  if(DEFINED ENV{CONAN_HOST_PROFILE})
    set(_HOST_PROFILE "$ENV{CONAN_HOST_PROFILE}")
  else()
    set(_HOST_PROFILE "default")
  endif()

  if(DEFINED ENV{CONAN_BUILD_PROFILE})
    set(_BUILD_PROFILE "$ENV{CONAN_BUILD_PROFILE}")
  else()
    set(_BUILD_PROFILE "default")
  endif()

  # ── Build type ─────────────────────────────────────────────────────────
  if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
  endif()

  message(STATUS "[Conan] Host profile : ${_HOST_PROFILE}")
  message(STATUS "[Conan] Build profile: ${_BUILD_PROFILE}")
  message(STATUS "[Conan] Build type   : ${CMAKE_BUILD_TYPE}")

  # ── Run conan install ──────────────────────────────────────────────────
  execute_process(
    COMMAND "${_CONAN_EXE}" install "${CMAKE_SOURCE_DIR}"
      "--output-folder=${CMAKE_BINARY_DIR}"
      --build=missing
      "-pr:h" "${_HOST_PROFILE}"
      "-pr:b" "${_BUILD_PROFILE}"
      "-s:h"  "build_type=${CMAKE_BUILD_TYPE}"
    RESULT_VARIABLE _CONAN_RC
  )
  if(NOT _CONAN_RC EQUAL 0)
    message(FATAL_ERROR "[Conan] install failed (exit code ${_CONAN_RC})")
  endif()

  # ── Remove Conan-generated CMakeUserPresets.json ───────────────────────
  # Conan's CMakeToolchain generator creates a CMakeUserPresets.json in the
  # source dir that includes presets from the build dir.  When multiple
  # configurations are built side-by-side (e.g. debug + asan) the included
  # preset names collide ("conan-debug"), causing a "Duplicate preset" error.
  # We already have our own CMakePresets.json with all presets, so the
  # Conan-generated user presets file is unnecessary.
  set(_CONAN_USER_PRESETS "${CMAKE_SOURCE_DIR}/CMakeUserPresets.json")
  if(EXISTS "${_CONAN_USER_PRESETS}")
    file(REMOVE "${_CONAN_USER_PRESETS}")
    message(STATUS "[Conan] Removed Conan-generated CMakeUserPresets.json")
  endif()
  unset(_CONAN_USER_PRESETS)
endif()

# ── Point CMake at the generated toolchain ───────────────────────────────────
if(EXISTS "${_CONAN_TOOLCHAIN}" AND NOT CMAKE_TOOLCHAIN_FILE)
  set(CMAKE_TOOLCHAIN_FILE "${_CONAN_TOOLCHAIN}"
    CACHE PATH "Conan-generated toolchain file" FORCE)
  message(STATUS "[Conan] Toolchain: ${CMAKE_TOOLCHAIN_FILE}")
elseif(NOT EXISTS "${_CONAN_TOOLCHAIN}")
  message(WARNING
    "[Conan] conan_toolchain.cmake not found at ${_CONAN_TOOLCHAIN}. "
    "Run conan install manually or remove SKIP_CONAN_INSTALL.")
endif()

# Clean up local variables
unset(_CONAN_TOOLCHAIN)
