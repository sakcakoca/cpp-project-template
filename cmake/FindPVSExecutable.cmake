# FindPVSExecutable.cmake
# ─────────────────────────────────────────────────────────────────────────────
# Locate the PVS-Studio analyser and log converter executables.
#
# Usage:
#   include(cmake/FindPVSExecutable.cmake)
#   find_PVS_executable(PVS_FOUND)
#   if(PVS_FOUND) ... endif()
#
# Sets in parent scope:
#   <result_var>                    - TRUE if both tools found
#   PVS_ANALYZER_EXECUTABLE         - path to the analyser
#   PVS_LOG_CONVERTER_EXECUTABLE    - path to the log converter
# ─────────────────────────────────────────────────────────────────────────────
include_guard(GLOBAL)

function(find_PVS_executable result_var)
  set(${result_var} FALSE PARENT_SCOPE)

  if(WIN32)
    set(_analyzer  "CompilerCommandsAnalyzer.exe")
    set(_converter "PlogConverter.exe")
  else()
    set(_analyzer  "pvs-studio-analyzer")
    set(_converter "plog-converter")
  endif()

  find_program(_pvs_analyzer  NAMES ${_analyzer})
  find_program(_pvs_converter NAMES ${_converter})

  if(_pvs_analyzer AND _pvs_converter)
    set(${result_var}                TRUE                PARENT_SCOPE)
    set(PVS_ANALYZER_EXECUTABLE      "${_pvs_analyzer}"  PARENT_SCOPE)
    set(PVS_LOG_CONVERTER_EXECUTABLE "${_pvs_converter}" PARENT_SCOPE)
    message(STATUS "[PVS] Analyser  : ${_pvs_analyzer}")
    message(STATUS "[PVS] Converter : ${_pvs_converter}")
  endif()
endfunction()
