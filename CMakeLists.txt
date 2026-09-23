cmake_minimum_required(VERSION 3.21)
project(pond-interface LANGUAGES CXX)
find_package(Qt6 6.11 REQUIRED COMPONENTS Qml)
find_package(KF6NetworkManagerQt REQUIRED)
qt_standard_project_setup(REQUIRES 6.7)
qt_add_qml_module(pond_wifi_status
    URI Pond.WifiStatus
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Pond/WifiStatus"
    SOURCES lockscreen/frontend/system/NetworkStatus.h
)
target_include_directories(pond_wifi_status PRIVATE lockscreen/frontend/system)
target_link_libraries(pond_wifi_status PRIVATE KF6::NetworkManagerQt)
set_target_properties(pond_wifi_statusplugin PROPERTIES INSTALL_RPATH "$ORIGIN")
