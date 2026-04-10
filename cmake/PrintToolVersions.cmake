# PrintToolVersions.cmake
# ─────────────────────────────────────────────────────────────────────────────
# Prints a concise diagnostic banner showing versions of the build toolchain
# and any detected optional tools.
#
# Include this AFTER project() so the compiler is known.
# ─────────────────────────────────────────────────────────────────────────────
include_guard(GLOBAL)

function(print_tool_versions)
  message(STATUS "")
  message(STATUS "──────────── Toolchain & Dependencies ────────────")

  # ── CMake ────────────────────────────────────────────────────────────────
  message(STATUS "  CMake        : ${CMAKE_VERSION}")

  # ── Generator ────────────────────────────────────────────────────────────
  message(STATUS "  Generator    : ${CMAKE_GENERATOR}")

  # ── C++ Compiler ─────────────────────────────────────────────────────────
  if(CMAKE_CXX_COMPILER_ID AND CMAKE_CXX_COMPILER_VERSION)
    message(STATUS "  C++ Compiler : ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION} (${CMAKE_CXX_COMPILER})")
  else()
    message(STATUS "  C++ Compiler : ${CMAKE_CXX_COMPILER}")
  endif()

  # ── Build type ───────────────────────────────────────────────────────────
  message(STATUS "  Build type   : ${CMAKE_BUILD_TYPE}")

  # ── C++ Standard ─────────────────────────────────────────────────────────
  message(STATUS "  C++ Standard : ${CMAKE_CXX_STANDARD}")

  # ── Conan (already checked in ExecuteConanInstall.cmake) ─────────────────
  find_program(_PTV_CONAN NAMES conan)
  if(_PTV_CONAN)
    execute_process(
      COMMAND "${_PTV_CONAN}" --version
      OUTPUT_VARIABLE _PTV_CONAN_VER
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_QUIET
    )
    message(STATUS "  Conan        : ${_PTV_CONAN_VER}")
  else()
    message(STATUS "  Conan        : not found")
  endif()

  # ── Ninja (report version if it is the active generator) ─────────────────
  if(CMAKE_GENERATOR MATCHES "Ninja")
    find_program(_PTV_NINJA NAMES ninja ninja-build)
    if(_PTV_NINJA)
      execute_process(
        COMMAND "${_PTV_NINJA}" --version
        OUTPUT_VARIABLE _PTV_NINJA_VER
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
      )
      message(STATUS "  Ninja        : ${_PTV_NINJA_VER}")
    else()
      message(STATUS "  Ninja        : not found (but Ninja generator requested!)")
    endif()
  endif()

  # ── Doxygen ──────────────────────────────────────────────────────────────
  if(Doxygen_FOUND)
    message(STATUS "  Doxygen      : ${DOXYGEN_VERSION}")
  else()
    find_package(Doxygen QUIET)
    if(Doxygen_FOUND)
      message(STATUS "  Doxygen      : ${DOXYGEN_VERSION}")
    else()
      message(STATUS "  Doxygen      : not found")
    endif()
  endif()

  # ── Valgrind ─────────────────────────────────────────────────────────────
  if(MEMORYCHECK_COMMAND)
    execute_process(
      COMMAND "${MEMORYCHECK_COMMAND}" --version
      OUTPUT_VARIABLE _PTV_VALGRIND_VER
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_QUIET
    )
    # valgrind --version prints "valgrind-X.Y.Z", strip the prefix
    string(REGEX REPLACE "^valgrind-" "" _PTV_VALGRIND_VER "${_PTV_VALGRIND_VER}")
    message(STATUS "  Valgrind     : ${_PTV_VALGRIND_VER}")
  else()
    message(STATUS "  Valgrind     : not found")
  endif()

  # ── PVS-Studio ───────────────────────────────────────────────────────────
  if(PVS_ANALYZER_EXECUTABLE)
    execute_process(
      COMMAND "${PVS_ANALYZER_EXECUTABLE}" --version
      OUTPUT_VARIABLE _PTV_PVS_VER
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_QUIET
    )
    message(STATUS "  PVS-Studio   : ${_PTV_PVS_VER}")
  else()
    message(STATUS "  PVS-Studio   : not found")
  endif()

  message(STATUS "──────────────────────────────────────────────────")
  message(STATUS "")
endfunction()
