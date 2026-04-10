# ┌─────────────────────────────────────────────────────────────────────────┐
# │  TEMPLATE: Add your source and header files explicitly below.          │
# │  Rename files and the library target to match your project.            │
# └─────────────────────────────────────────────────────────────────────────┘

# List source files explicitly (do NOT use file(GLOB) — new files won't be
# detected until CMake is re-run manually).
set(SOURCES
  myproject.cpp
)

set(HEADERS
  ${PROJECT_SOURCE_DIR}/include/myproject/myproject.hpp
)

# Make an automatic library - will be static or dynamic based on user setting
add_library(myproject_library ${SOURCES} ${HEADERS})

# We need this directory, and users of our library will need it too
# Consumers include as: #include <myproject/myproject.hpp>
target_include_directories(myproject_library PUBLIC
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

# All users of this library will need at least C++23
target_compile_features(myproject_library PUBLIC cxx_std_23)

# Apply project-wide warnings
target_link_libraries(myproject_library PRIVATE project_warnings)

# IDEs should put the headers in a nice place
source_group(
  TREE "${PROJECT_SOURCE_DIR}/include/myproject"
  PREFIX "Header Files"
  FILES ${HEADERS})
