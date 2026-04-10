include(FetchContent)
FetchContent_Declare(
    PVS_CMakeModule
    GIT_REPOSITORY "https://github.com/viva64/pvs-studio-cmake-module.git"
    GIT_TAG        "master" 
)
FetchContent_MakeAvailable(PVS_CMakeModule)
include("${pvs_cmakemodule_SOURCE_DIR}/PVS-Studio.cmake")

pvs_studio_add_target(TARGET pvs_analyze ALL # Define target named pvs_analyze and compile it when ALL target is compiled
                      COMPILE_COMMANDS       # Use compile_commands.json which is created by cmake
                      OUTPUT                 # Print output to build screen
                      FORMAT json            # Format of report file is json
                      MODE GA:1,2
                      LOG pvs_analyze.json   # Name of report file
                      LICENSE "$ENV{HOME}/.config/PVS-Studio/PVS-Studio.lic"  # PVS license file path
                      ARGS -e "${PROJECT_SOURCE_DIR}/test") #Excluded directory