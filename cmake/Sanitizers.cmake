# Sanitizers.cmake
# ─────────────────────────────────────────────────────────────────────────────
# Populate an INTERFACE library target with sanitizer compile/link flags.
#
# Cache options (typically set via CMake presets):
#   ENABLE_SANITIZER_ADDRESS   - AddressSanitizer  (GCC, Clang, MSVC)
#   ENABLE_SANITIZER_UNDEFINED - UndefinedBehaviorSanitizer (GCC, Clang)
#   ENABLE_SANITIZER_LEAK      - LeakSanitizer     (GCC, Clang on Linux)
#   ENABLE_SANITIZER_THREAD    - ThreadSanitizer    (GCC, Clang)
#   ENABLE_SANITIZER_MEMORY    - MemorySanitizer    (Clang only)
#
# Compatibility matrix:
#   ASan  + UBSan  = OK
#   ASan  + LSan   = OK (LSan is built into ASan on Linux by default)
#   TSan           = standalone only (incompatible with ASan, MSan, LSan)
#   MSan           = standalone only (incompatible with ASan, TSan, LSan)
#
# Usage (INTERFACE library — explicit per-target linking):
#   add_library(project_sanitizers INTERFACE)
#   enable_sanitizers(project_sanitizers)
#   target_link_libraries(my_target PRIVATE project_sanitizers)
#
# Usage (global — applies to ALL targets, recommended):
#   enable_sanitizers_global()
# ─────────────────────────────────────────────────────────────────────────────
include_guard(GLOBAL)

option(ENABLE_SANITIZER_ADDRESS   "Enable AddressSanitizer"                        OFF)
option(ENABLE_SANITIZER_UNDEFINED "Enable UndefinedBehaviorSanitizer"              OFF)
option(ENABLE_SANITIZER_LEAK      "Enable LeakSanitizer (Linux GCC/Clang)"         OFF)
option(ENABLE_SANITIZER_THREAD    "Enable ThreadSanitizer"                         OFF)
option(ENABLE_SANITIZER_MEMORY    "Enable MemorySanitizer (Clang only)"            OFF)

function(enable_sanitizers target_name)
  # Collect the sanitiser names requested
  set(_sanitizers "")

  # ── AddressSanitizer ────────────────────────────────────────────────────
  if(ENABLE_SANITIZER_ADDRESS)
    list(APPEND _sanitizers "address")
  endif()

  # ── UndefinedBehaviorSanitizer ──────────────────────────────────────────
  if(ENABLE_SANITIZER_UNDEFINED)
    if(MSVC)
      message(WARNING
        "[Sanitizers] MSVC does not support UndefinedBehaviorSanitizer — skipping")
    else()
      list(APPEND _sanitizers "undefined")
    endif()
  endif()

  # ── LeakSanitizer ──────────────────────────────────────────────────────
  if(ENABLE_SANITIZER_LEAK)
    if(MSVC)
      message(WARNING
        "[Sanitizers] MSVC does not support LeakSanitizer — skipping")
    elseif(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
      message(WARNING
        "[Sanitizers] LeakSanitizer is only reliable on Linux — skipping")
    else()
      list(APPEND _sanitizers "leak")
    endif()
  endif()

  # ── ThreadSanitizer (exclusive) ─────────────────────────────────────────
  if(ENABLE_SANITIZER_THREAD)
    if("address" IN_LIST _sanitizers)
      message(FATAL_ERROR
        "[Sanitizers] ThreadSanitizer is incompatible with AddressSanitizer")
    endif()
    if("leak" IN_LIST _sanitizers)
      message(FATAL_ERROR
        "[Sanitizers] ThreadSanitizer is incompatible with LeakSanitizer")
    endif()
    if(MSVC)
      message(WARNING
        "[Sanitizers] MSVC does not support ThreadSanitizer — skipping")
    else()
      list(APPEND _sanitizers "thread")
    endif()
  endif()

  # ── MemorySanitizer (Clang only, exclusive) ─────────────────────────────
  if(ENABLE_SANITIZER_MEMORY)
    if("address" IN_LIST _sanitizers)
      message(FATAL_ERROR
        "[Sanitizers] MemorySanitizer is incompatible with AddressSanitizer")
    endif()
    if("thread" IN_LIST _sanitizers)
      message(FATAL_ERROR
        "[Sanitizers] MemorySanitizer is incompatible with ThreadSanitizer")
    endif()
    if("leak" IN_LIST _sanitizers)
      message(FATAL_ERROR
        "[Sanitizers] MemorySanitizer is incompatible with LeakSanitizer")
    endif()
    if(NOT CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
      message(FATAL_ERROR
        "[Sanitizers] MemorySanitizer requires Clang "
        "(found ${CMAKE_CXX_COMPILER_ID})")
    endif()
    list(APPEND _sanitizers "memory")
  endif()

  # ── Apply flags ─────────────────────────────────────────────────────────
  list(LENGTH _sanitizers _san_count)
  if(_san_count EQUAL 0)
    return()
  endif()

  if(MSVC)
    # MSVC only supports /fsanitize=address
    if("address" IN_LIST _sanitizers)
      target_compile_options(${target_name} INTERFACE /fsanitize=address)
      # MSVC ASan requires /Zi (debug info) and no /RTC (incompatible)
      target_compile_options(${target_name} INTERFACE /Zi)
      target_link_options(${target_name} INTERFACE /DEBUG)
      message(STATUS "[Sanitizers] MSVC: /fsanitize=address /Zi")
    endif()
  else()
    list(JOIN _sanitizers "," _san_list)
    target_compile_options(${target_name} INTERFACE
      -fsanitize=${_san_list}
      -fno-omit-frame-pointer
      -fno-optimize-sibling-calls
    )
    target_link_options(${target_name} INTERFACE
      -fsanitize=${_san_list}
    )
    message(STATUS "[Sanitizers] -fsanitize=${_san_list}")
  endif()
endfunction()

# ─────────────────────────────────────────────────────────────────────────────
# Global variant: applies sanitizer flags to ALL targets via
# add_compile_options / add_link_options. No per-target linking needed.
# ─────────────────────────────────────────────────────────────────────────────
function(enable_sanitizers_global)
  # Re-use the same option checks
  set(_sanitizers "")

  if(ENABLE_SANITIZER_ADDRESS)
    list(APPEND _sanitizers "address")
  endif()
  if(ENABLE_SANITIZER_UNDEFINED AND NOT MSVC)
    list(APPEND _sanitizers "undefined")
  endif()
  if(ENABLE_SANITIZER_LEAK AND NOT MSVC AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
    list(APPEND _sanitizers "leak")
  endif()
  if(ENABLE_SANITIZER_THREAD)
    if("address" IN_LIST _sanitizers OR "leak" IN_LIST _sanitizers)
      message(FATAL_ERROR "[Sanitizers] ThreadSanitizer is incompatible with ASan/LSan")
    endif()
    if(NOT MSVC)
      list(APPEND _sanitizers "thread")
    endif()
  endif()
  if(ENABLE_SANITIZER_MEMORY)
    if("address" IN_LIST _sanitizers OR "thread" IN_LIST _sanitizers OR "leak" IN_LIST _sanitizers)
      message(FATAL_ERROR "[Sanitizers] MemorySanitizer is incompatible with ASan/TSan/LSan")
    endif()
    if(NOT CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
      message(FATAL_ERROR "[Sanitizers] MemorySanitizer requires Clang")
    endif()
    list(APPEND _sanitizers "memory")
  endif()

  list(LENGTH _sanitizers _san_count)
  if(_san_count EQUAL 0)
    return()
  endif()

  if(MSVC)
    if("address" IN_LIST _sanitizers)
      add_compile_options(/fsanitize=address /Zi)
      add_link_options(/DEBUG)
      message(STATUS "[Sanitizers] Global MSVC: /fsanitize=address /Zi")
    endif()
  else()
    list(JOIN _sanitizers "," _san_list)
    add_compile_options(-fsanitize=${_san_list} -fno-omit-frame-pointer -fno-optimize-sibling-calls)
    add_link_options(-fsanitize=${_san_list})
    message(STATUS "[Sanitizers] Global: -fsanitize=${_san_list}")
  endif()
endfunction()
