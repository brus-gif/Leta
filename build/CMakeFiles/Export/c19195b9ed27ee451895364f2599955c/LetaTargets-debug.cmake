#----------------------------------------------------------------
# Generated CMake target import file for configuration "Debug".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "Leta::Leta" for configuration "Debug"
set_property(TARGET Leta::Leta APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(Leta::Leta PROPERTIES
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/lib/libLeta.a"
  )

list(APPEND _cmake_import_check_targets Leta::Leta )
list(APPEND _cmake_import_check_files_for_Leta::Leta "${_IMPORT_PREFIX}/lib/libLeta.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
