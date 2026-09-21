cmake_minimum_required(VERSION 3.21)
project(pond_screenshot_drag LANGUAGES CXX)
find_package(Qt6 6.11 REQUIRED COMPONENTS Quick)
qt_standard_project_setup(REQUIRES 6.7)
qt_add_qml_module(pond_screenshot_drag
    URI Pond.Screenshot.Native
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/Pond/Screenshot/Native"
    SOURCES ScreenshotDrag.h
)
target_link_libraries(pond_screenshot_drag PRIVATE Qt6::Quick)
set_target_properties(pond_screenshot_dragplugin PROPERTIES INSTALL_RPATH "$ORIGIN")
install(TARGETS pond_screenshot_drag pond_screenshot_dragplugin
    LIBRARY DESTINATION lib/qt6/qml/Pond/Screenshot/Native)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/Pond/Screenshot/Native/qmldir"
    "${CMAKE_CURRENT_BINARY_DIR}/Pond/Screenshot/Native/pond_screenshot_drag.qmltypes"
    DESTINATION lib/qt6/qml/Pond/Screenshot/Native)
