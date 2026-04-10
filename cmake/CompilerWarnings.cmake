# CompilerWarnings.cmake
# ─────────────────────────────────────────────────────────────────────────────
# Populate an INTERFACE library target with a comprehensive set of warnings
# for GCC, Clang (including Apple Clang), and MSVC.
#
# Usage:
#   add_library(project_warnings INTERFACE)
#   set_project_warnings(project_warnings)
#   target_link_libraries(my_target PRIVATE project_warnings)
# ─────────────────────────────────────────────────────────────────────────────
include_guard(GLOBAL)

function(set_project_warnings project_name)

  option(WARNINGS_AS_ERRORS "Treat compiler warnings as errors" ON)

  # ── MSVC ────────────────────────────────────────────────────────────────
  set(MSVC_WARNINGS
    /W4                 # High baseline warning level
    /permissive-        # Standards-conformance mode

    # Specific useful warnings promoted to higher severity
    /w14242   # Narrowing conversion
    /w14254   # Bitfield conversion
    /w14263   # Member function does not override base virtual
    /w14265   # Class has virtual functions but non-virtual destructor
    /w14287   # Unsigned / negative constant mismatch
    /we4289   # Loop variable used outside for-loop scope
    /w14296   # Expression is always true/false
    /w14311   # Pointer truncation
    /w14545   # Expression before comma missing argument list
    /w14546   # Function call before comma missing argument list
    /w14547   # Operator before comma has no effect
    /w14549   # Operator before comma has no effect
    /w14555   # Expression has no effect
    /w14619   # Unknown pragma warning number
    /w14640   # Thread-unsafe static initialisation
    /w14826   # Sign-extended conversion
    /w14905   # Wide string literal cast to LPSTR
    /w14906   # String literal cast to LPWSTR
    /w14928   # Illegal copy-initialisation with multiple conversions

    # Security & quality
    /w14388   # Signed/unsigned comparison
    /w14365   # Signed/unsigned conversion in return
    /w15038   # Member initialiser order
    /w14868   # Left-to-right evaluation order not enforced in braced init
    /w15204   # Virtual function has non-virtual destructor
    /w15219   # Implicit conversion from integer to float
    /w15220   # Implicit conversion of unsigned to signed
  )

  # ── Clang / Apple Clang ─────────────────────────────────────────────────
  set(CLANG_WARNINGS
    -Wall
    -Wextra
    -Wpedantic

    # Correctness
    -Wshadow
    -Wnon-virtual-dtor
    -Woverloaded-virtual
    -Wnull-dereference
    -Wreturn-type
    -Wimplicit-fallthrough

    # Security / undefined behaviour
    -Wformat=2
    -Wformat-security
    -Warray-bounds
    -Wvla

    # Conversions
    -Wconversion
    -Wsign-conversion
    -Wdouble-promotion
    -Wfloat-equal

    # Style / quality
    -Wold-style-cast
    -Wcast-align
    -Wunused
    -Wextra-semi
    -Wzero-as-null-pointer-constant
    -Wdeprecated
    -Wimplicit-int-conversion

    # Disabled for C++26 compatibility
    # -Wno-c++98-compat
  )

  # ── GCC (inherits Clang set + GCC-specific additions) ───────────────────
  set(GCC_WARNINGS
    ${CLANG_WARNINGS}

    # GCC-only diagnostics
    -Wmisleading-indentation
    -Wduplicated-cond
    -Wduplicated-branches
    -Wlogical-op
    -Wuseless-cast
    -Wcast-qual
    -Wredundant-decls
    -Wsuggest-override
    -Wstrict-overflow=2
    -Wstringop-overflow=4
    -Wstack-usage=8192
  )

  # ── -Werror handling ────────────────────────────────────────────────────
  if(WARNINGS_AS_ERRORS)
    list(APPEND MSVC_WARNINGS  /WX)
    list(APPEND CLANG_WARNINGS -Werror)
    list(APPEND GCC_WARNINGS   -Werror)
  endif()

  # ── Pick the right set ─────────────────────────────────────────────────
  if(MSVC)
    set(_warnings ${MSVC_WARNINGS})
  elseif(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    set(_warnings ${CLANG_WARNINGS})
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(_warnings ${GCC_WARNINGS})
  else()
    message(AUTHOR_WARNING
      "No compiler warnings configured for '${CMAKE_CXX_COMPILER_ID}'")
    return()
  endif()

  target_compile_options(${project_name} INTERFACE ${_warnings})

  message(STATUS "Compiler warnings applied to ${project_name}")
endfunction()