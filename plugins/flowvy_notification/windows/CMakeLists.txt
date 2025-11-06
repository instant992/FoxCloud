cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "flowvy_notification")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "flowvy_notification_plugin")

add_library(${PLUGIN_NAME} SHARED
  "flowvy_notification_plugin_c_api.cpp"
  "notification_plugin.cpp"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

target_link_libraries(${PLUGIN_NAME} PRIVATE "windowsapp.lib")
target_compile_options(${PLUGIN_NAME} PRIVATE /await)

set(flowvy_notification_bundled_libraries
  ""
  PARENT_SCOPE
)
