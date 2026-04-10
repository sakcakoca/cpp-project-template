# PreventInSourceBuilds.cmake
# ─────────────────────────────────────────────────────────────────────────────
# Abort configure if the source and binary directories are the same, even
# through symlinks. Runs automatically on include.
# ─────────────────────────────────────────────────────────────────────────────
include_guard(GLOBAL)

function(_prevent_in_source_builds)
  get_filename_component(_src "${CMAKE_SOURCE_DIR}" REALPATH)
  get_filename_component(_bin "${CMAKE_BINARY_DIR}" REALPATH)

  if(_src STREQUAL _bin)
    message(FATAL_ERROR
      "\n"
      "  In-source builds are not allowed.\n"
      "\n"
      "  Create a separate build directory and run CMake from there, e.g.:\n"
      "\n"
      "    cmake -S . -B build\n"
      "\n"
      "  Remove the generated CMakeCache.txt and CMakeFiles/ directory first:\n"
      "\n"
      "    rm -rf CMakeCache.txt CMakeFiles/\n"
    )
  endif()
endfunction()

_prevent_in_source_builds()