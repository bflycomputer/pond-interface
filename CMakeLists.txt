cmake_minimum_required(VERSION 3.21)
project(pond-interface LANGUAGES CXX)
find_package(Qt6 6.11 REQUIRED COMPONENTS Qml DBus)
find_package(KF6NetworkManagerQt REQUIRED)
qt_standard_project_setup(REQUIRES 6.7)
qt_add_qml_module(pond_system
    URI Pond.System
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Pond/System"
    SOURCES lockscreen/frontend/system/NetworkStatus.h lockscreen/frontend/system/Logind.h
)
target_include_directories(pond_system PRIVATE lockscreen/frontend/system)
target_link_libraries(pond_system PRIVATE KF6::NetworkManagerQt Qt6::DBus)
set_target_properties(pond_systemplugin PROPERTIES INSTALL_RPATH "$ORIGIN")

add_subdirectory(localization)

add_subdirectory(screenshot/native)
install(TARGETS pond_system pond_systemplugin
    LIBRARY DESTINATION lib/qt6/qml/Pond/System)
install(FILES "${CMAKE_BINARY_DIR}/Pond/System/qmldir"
    "${CMAKE_BINARY_DIR}/Pond/System/pond_system.qmltypes"
    DESTINATION lib/qt6/qml/Pond/System)
install(DIRECTORY shell lockscreen DESTINATION share/pond-interface
    PATTERN "__pycache__" EXCLUDE)
install(DIRECTORY screenshot/ DESTINATION lib/qt6/qml/Pond/Screenshot
    PATTERN "native" EXCLUDE PATTERN "__pycache__" EXCLUDE)
install(DIRECTORY wallpaper/ DESTINATION lib/qt6/qml/Pond/Wallpaper
    PATTERN "daylight" EXCLUDE)
install(DIRECTORY wallpaper/daylight/ DESTINATION lib/qt6/qml/Pond/Daylight)
