# StandardProjectSettings.cmake
# ─────────────────────────────────────────────────────────────────────────────
# Common project-wide compiler and build settings.
# Include this AFTER cmake_minimum_required() but BEFORE project().
# ─────────────────────────────────────────────────────────────────────────────
include_guard(GLOBAL)

# -- Build type default -------------------------------------------------------
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to 'RelWithDebInfo' as none was specified.")
  set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID}  Build type: ${CMAKE_BUILD_TYPE}")

# -- Coloured diagnostics (cached so users can turn it off) -------------------
option(FORCE_COLORED_OUTPUT "Always produce coloured compiler diagnostics." ON)

if(FORCE_COLORED_OUTPUT)
  if(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    add_compile_options(-fcolor-diagnostics)
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_compile_options(-fdiagnostics-color=always)
  endif()
endif()

# -- MSVC conformance --------------------------------------------------------
if(MSVC)
  # Report correct __cplusplus value (MSVC defaults to 199711L otherwise)
  add_compile_options(/Zc:__cplusplus)
  # Use UTF-8 source and execution character sets
  add_compile_options(/utf-8)
  # Conform to the standard regarding extern constexpr
  add_compile_options(/Zc:externConstexpr)
  # Enable standard-conforming two-phase lookup
  add_compile_options(/Zc:twoPhase-)
  # Set the MSVC runtime library policy (CMake 3.15+)
  if(POLICY CMP0091)
    cmake_policy(SET CMP0091 NEW)
  endif()
endif()

# -- Inter-Procedural Optimisation (LTO) for Release builds -------------------
# NOTE: This option is declared here but the actual check must happen
# AFTER project() because CheckIPOSupported needs a compiler set.
# See the enable_ipo() function below — call it from CMakeLists.txt.
option(ENABLE_IPO "Enable inter-procedural / link-time optimisation for Release builds" OFF)

function(enable_ipo)
  if(NOT ENABLE_IPO)
    return()
  endif()

  include(CheckIPOSupported)
  check_ipo_supported(RESULT _ipo_supported OUTPUT _ipo_output)
  if(_ipo_supported)
    message(STATUS "IPO / LTO enabled")
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE        ON PARENT_SCOPE)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELWITHDEBINFO ON PARENT_SCOPE)
  else()
    message(WARNING "IPO requested but not supported: ${_ipo_output}")
  endif()
endfunction()