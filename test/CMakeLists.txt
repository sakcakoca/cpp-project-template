# ┌─────────────────────────────────────────────────────────────────────────┐
# │  TEMPLATE: Replace myproject_library and test executable/source names. │
# └─────────────────────────────────────────────────────────────────────────┘

# Find Google Test package
find_package(GTest REQUIRED COMPONENTS gtest gmock gtest_main gmock_main)

# Tests need to be added as executables first
set(TEST_EXECUTABLE_NAME "MyProjectTest")
add_executable(${TEST_EXECUTABLE_NAME} myproject_test.cpp)

target_compile_features(${TEST_EXECUTABLE_NAME} PRIVATE cxx_std_23)

# Link to the main library and GoogleTest
target_link_libraries(${TEST_EXECUTABLE_NAME} PRIVATE myproject_library GTest::gtest GTest::gtest_main project_warnings)

# Discover tests for ctest
include(GoogleTest)
gtest_add_tests(
  TARGET ${TEST_EXECUTABLE_NAME}
  SOURCES myproject_test.cpp
)
