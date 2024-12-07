# This file controls Flutter-level build steps. It should not be edited.
cmake_minimum_required(VERSION 3.10)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake)

# TODO: Move the rest of this into files in ephemeral. See
# https://github.com/flutter/flutter/issues/57146.

# Serves the same purpose as list(TRANSFORM ... PREPEND ...),
# which isn't available in 3.10.
message("Current list before prepend: ${LIST_NAME}")
function(list_prepend LIST_NAME PREFIX)
    set(NEW_LIST "")
    foreach(element ${${LIST_NAME}})
        if(NOT element MATCHES "^${PREFIX}")
            list(APPEND NEW_LIST "${PREFIX}${element}")
        else()
            list(APPEND NEW_LIST "${element}")  # Ako već sadrži prefiks, dodaj ga bez promene
        endif()
    endforeach(element)
    set(${LIST_NAME} "${NEW_LIST}" PARENT_SCOPE)
endfunction()
message("Current list after prepend: ${LIST_NAME}")

# === Flutter Library ===
# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)
pkg_check_modules(GLIB REQUIRED IMPORTED_TARGET glib-2.0)
pkg_check_modules(GIO REQUIRED IMPORTED_TARGET gio-2.0)

set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/libflutter_linux_gtk.so")

# Published to parent scope for install step.
set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)
set(PROJECT_DIR "${CMAKE_SOURCE_DIR}" PARENT_SCOPE)
set(PROJECT_BUILD_DIR "${PROJECT_DIR}/build/" PARENT_SCOPE)
# string(REPLACE "splitcat/splitcat" "splitcat" PROJECT_DIR "${PROJECT_DIR}")
# string(REPLACE "splitcat/splitcat" "splitcat" PROJECT_BUILD_DIR "${PROJECT_BUILD_DIR}")
set(AOT_LIBRARY "${PROJECT_DIR}/build/lib/libapp.so" PARENT_SCOPE)

list(APPEND FLUTTER_LIBRARY_HEADERS
  "fl_basic_message_channel.h"
  "fl_binary_codec.h"
  "fl_binary_messenger.h"
  "fl_dart_project.h"
  "fl_engine.h"
  "fl_json_message_codec.h"
  "fl_json_method_codec.h"
  "fl_message_codec.h"
  "fl_method_call.h"
  "fl_method_channel.h"
  "fl_method_codec.h"
  "fl_method_response.h"
  "fl_plugin_registrar.h"
  "fl_plugin_registry.h"
  "fl_standard_message_codec.h"
  "fl_standard_method_codec.h"
  "fl_string_codec.h"
  "fl_value.h"
  "fl_view.h"
  "flutter_linux.h"
)
list_prepend(FLUTTER_LIBRARY_HEADERS "${EPHEMERAL_DIR}/flutter_linux/")
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
)
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}")
target_link_libraries(flutter INTERFACE
  PkgConfig::GTK
  PkgConfig::GLIB
  PkgConfig::GIO
)
add_dependencies(flutter flutter_assemble)

# === Flutter tool backend ===
# _phony_ is a non-existent file to force this command to run every time,
# since currently there's no way to get a full input/output list from the
# flutter tool.
add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS}
    ${CMAKE_CURRENT_BINARY_DIR}/_phony_
  COMMAND ${CMAKE_COMMAND} -E env
    ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.sh"
      ${FLUTTER_TARGET_PLATFORM} ${CMAKE_BUILD_TYPE}
  VERBATIM
)
add_custom_target(flutter_assemble DEPENDS
  "${FLUTTER_LIBRARY}"
  ${FLUTTER_LIBRARY_HEADERS}
)

# install(FILES
#   ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/16x16/icon.png DESTINATION share/icons/hicolor/16x16/apps)
# install(FILES
#   ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/32x32/icon.png DESTINATION share/icons/hicolor/32x32/apps)
# install(FILES
#   ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/48x48/icon.png DESTINATION share/icons/hicolor/48x48/apps)
# install(FILES
#   ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/64x64/icon.png DESTINATION share/icons/hicolor/64x64/apps)
# install(FILES
#   ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/128x128/icon.png DESTINATION share/icons/hicolor/128x128/apps)
# install(FILES
#   ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/256x256/icon.png DESTINATION share/icons/hicolor/256x256/apps)
# install(FILES
#   ${PROJECT_DIR}/linux/packaging/deb/make-config.yaml DESTINATION linux/packaging/deb)
# install(FILES
#   ${PROJECT_DIR}/linux/packaging/rpm/make_config.yaml DESTINATION linux/packaging/rpm)