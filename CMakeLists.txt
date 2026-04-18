cmake_minimum_required(VERSION 3.21)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Set standard project settings
include(cmake/StandardProjectSettings.cmake)
include(cmake/PreventInSourceBuilds.cmake)

# Conan 2 integration (runs conan install before project() when needed)
include(cmake/ExecuteConanInstall.cmake)

# ┌─────────────────────────────────────────────────────────────────────────┐
# │  TEMPLATE: Change the project name, version, and description below.   │
# │  The project name is also used as a prefix for library/test targets.   │
# └─────────────────────────────────────────────────────────────────────────┘
project(
  MyProject
  VERSION 0.1
  DESCRIPTION "A new C++ project"
  LANGUAGES CXX)

# Only do these if this is the main project, and not if it is included through add_subdirectory
if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)

  set(CMAKE_CXX_STANDARD 23)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)

  # IPO / LTO (must be after project() so the compiler is known)
  enable_ipo()

  # Compiler warnings
  add_library(project_warnings INTERFACE)
  include(cmake/CompilerWarnings.cmake)
  set_project_warnings(project_warnings)

  # Sanitizers — applied globally so every target in the build is consistent.
  # Controlled via CMake presets / cache variables (e.g. ENABLE_SANITIZER_ADDRESS).
  include(cmake/Sanitizers.cmake)
  enable_sanitizers_global()

  # IDE folder support
  set_property(GLOBAL PROPERTY USE_FOLDERS ON)

  # Testing
  include(CTest)

  # Coverage (opt-in, GCC/Clang only — not supported on MSVC)
  option(ENABLE_COVERAGE "Enable code-coverage instrumentation (--coverage)" OFF)
  if(ENABLE_COVERAGE AND NOT MSVC)
    if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
      add_compile_options(-fprofile-instr-generate -fcoverage-mapping)
      add_link_options(-fprofile-instr-generate)
    elseif (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
      add_compile_options(--coverage)
      add_link_options(--coverage)
    endif()
  endif()

  # Valgrind / CTest memcheck
  find_program(MEMORYCHECK_COMMAND NAMES valgrind)
  if(MEMORYCHECK_COMMAND)
    set(MEMORYCHECK_COMMAND_OPTIONS
      "--trace-children=yes --leak-check=full --show-reachable=yes --error-exitcode=1"
      CACHE STRING "Valgrind options for ctest -T memcheck")
    message(STATUS "Valgrind found: ${MEMORYCHECK_COMMAND}")
  endif()

  # Doxygen
  find_package(Doxygen)
  if(Doxygen_FOUND)
    add_subdirectory(docs)
  else()
    message(STATUS "Doxygen not found, not building docs")
  endif()

  # PVS-Studio static analysis (creates a 'pvs_analysis' build target)
  include(cmake/FindPVSExecutable.cmake)
  find_PVS_executable(PVS_FOUND)
  if(PVS_FOUND)
    include(cmake/ExecutePVSAnalyzer.cmake)
    add_pvs_analysis_target()
  else()
    message(STATUS "PVS Studio not found, not creating pvs_analysis target")
  endif()

  # Print a diagnostic banner with all detected tool versions
  include(cmake/PrintToolVersions.cmake)
  print_tool_versions()

endif()

# The compiled library code is here
add_subdirectory(src)

# The executable code is here
add_subdirectory(apps)

# ┌─────────────────────────────────────────────────────────────────────────┐
# │  TEMPLATE: Update MYPROJECT_BUILD_TESTING to match your project name.  │
# └─────────────────────────────────────────────────────────────────────────┘
if((CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME OR MYPROJECT_BUILD_TESTING)
   AND BUILD_TESTING)
  add_subdirectory(test)
endif()
