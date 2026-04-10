# ┌─────────────────────────────────────────────────────────────────────────┐
# │  TEMPLATE: Replace myproject_library with your library target name.    │
# └─────────────────────────────────────────────────────────────────────────┘
find_package(fmt REQUIRED)

add_executable(app app.cpp)
target_compile_features(app PRIVATE cxx_std_23)

target_link_libraries(app PRIVATE myproject_library fmt::fmt project_warnings)
