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

function(_sanitizers_detect_compilers out_is_msvc out_is_clang)
  set(_is_msvc OFF)
  set(_is_clang OFF)

  if(MSVC
     OR CMAKE_C_COMPILER MATCHES "cl(\\.exe)?$"
     OR CMAKE_CXX_COMPILER MATCHES "cl(\\.exe)?$")
    set(_is_msvc ON)
  endif()

  if(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang"
     OR CMAKE_C_COMPILER MATCHES "clang(-[0-9]+)?(\\.exe)?$"
     OR CMAKE_CXX_COMPILER MATCHES "clang\\+\\+(-[0-9]+)?(\\.exe)?$")
    set(_is_clang ON)
  endif()

  set(${out_is_msvc} ${_is_msvc} PARENT_SCOPE)
  set(${out_is_clang} ${_is_clang} PARENT_SCOPE)
endfunction()

function(collect_enabled_sanitizers out_var)
  _sanitizers_detect_compilers(_is_msvc _is_clang)

  set(_sanitizers "")

  if(ENABLE_SANITIZER_ADDRESS)
    list(APPEND _sanitizers "address")
  endif()

  if(ENABLE_SANITIZER_UNDEFINED)
    if(_is_msvc)
      message(WARNING
        "[Sanitizers] MSVC does not support UndefinedBehaviorSanitizer - skipping")
    else()
      list(APPEND _sanitizers "undefined")
    endif()
  endif()

  if(ENABLE_SANITIZER_LEAK)
    if(_is_msvc)
      message(WARNING
        "[Sanitizers] MSVC does not support LeakSanitizer - skipping")
    elseif(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
      message(WARNING
        "[Sanitizers] LeakSanitizer is only reliable on Linux - skipping")
    else()
      list(APPEND _sanitizers "leak")
    endif()
  endif()

  if(ENABLE_SANITIZER_THREAD)
    if("address" IN_LIST _sanitizers OR "leak" IN_LIST _sanitizers)
      message(FATAL_ERROR
        "[Sanitizers] ThreadSanitizer is incompatible with Address/LeakSanitizer")
    endif()
    if(_is_msvc)
      message(WARNING
        "[Sanitizers] MSVC does not support ThreadSanitizer - skipping")
    else()
      list(APPEND _sanitizers "thread")
    endif()
  endif()

  if(ENABLE_SANITIZER_MEMORY)
    if("address" IN_LIST _sanitizers OR "thread" IN_LIST _sanitizers OR "leak" IN_LIST _sanitizers)
      message(FATAL_ERROR
        "[Sanitizers] MemorySanitizer is incompatible with Address/Thread/LeakSanitizer")
    endif()
    if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
      message(FATAL_ERROR "[Sanitizers] MemorySanitizer is supported on Linux only")
    endif()
    if(NOT _is_clang)
      message(FATAL_ERROR
        "[Sanitizers] MemorySanitizer requires Clang "
        "(found ${CMAKE_CXX_COMPILER_ID} / ${CMAKE_CXX_COMPILER})")
    endif()
    list(APPEND _sanitizers "memory")
  endif()

  set(${out_var} "${_sanitizers}" PARENT_SCOPE)
endfunction()

function(get_conan_sanitizer_conf out_var)
  collect_enabled_sanitizers(_sanitizers)
  _sanitizers_detect_compilers(_is_msvc _is_clang)

  set(_conf "")
  if(NOT _sanitizers)
    set(${out_var} "" PARENT_SCOPE)
    return()
  endif()

  if(_is_msvc)
    if("address" IN_LIST _sanitizers)
      set(_conf
        "--conf=tools.build:cflags+=[\"/fsanitize=address\"]"
        "--conf=tools.build:cxxflags+=[\"/fsanitize=address\"]"
        "--conf=tools.build:exelinkflags+=[\"/fsanitize=address\"]"
        "--conf=tools.build:sharedlinkflags+=[\"/fsanitize=address\"]"
      )
      message(STATUS "[Conan] Sanitizer flags: /fsanitize=address")
    endif()
  else()
    list(JOIN _sanitizers "," _san_joined)
    set(_san_flags "-fsanitize=${_san_joined} -fno-omit-frame-pointer -fno-optimize-sibling-calls")
    set(_conf
      "--conf=tools.build:cflags+=[\"${_san_flags}\"]"
      "--conf=tools.build:cxxflags+=[\"${_san_flags}\"]"
      "--conf=tools.build:exelinkflags+=[\"-fsanitize=${_san_joined}\"]"
      "--conf=tools.build:sharedlinkflags+=[\"-fsanitize=${_san_joined}\"]"
    )
    message(STATUS "[Conan] Sanitizer flags: -fsanitize=${_san_joined}")
  endif()

  set(${out_var} "${_conf}" PARENT_SCOPE)
endfunction()

function(enable_sanitizers target_name)
  collect_enabled_sanitizers(_sanitizers)
  _sanitizers_detect_compilers(_is_msvc _is_clang)

  # ── Apply flags ─────────────────────────────────────────────────────────
  list(LENGTH _sanitizers _san_count)
  if(_san_count EQUAL 0)
    return()
  endif()

  if(_is_msvc)
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
  collect_enabled_sanitizers(_sanitizers)
  _sanitizers_detect_compilers(_is_msvc _is_clang)

  list(LENGTH _sanitizers _san_count)
  if(_san_count EQUAL 0)
    return()
  endif()

  if(_is_msvc)
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
