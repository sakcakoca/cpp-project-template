set(DOXYGEN_EXTRACT_ALL YES)
set(DOXYGEN_BUILTIN_STL_SUPPORT YES)

# ┌─────────────────────────────────────────────────────────────────────────┐
# │  TEMPLATE: Update the header path and mainpage.md reference below.     │
# └─────────────────────────────────────────────────────────────────────────┘
doxygen_add_docs(docs "${PROJECT_SOURCE_DIR}/include/myproject" "${CMAKE_CURRENT_SOURCE_DIR}/mainpage.md"
		ALL
                WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}/include"
                COMMENT "Building doxygen documentation")
