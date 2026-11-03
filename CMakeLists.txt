cmake_minimum_required(VERSION 3.21)
project(pond-interface LANGUAGES CXX)
find_package(Qt6 6.12 REQUIRED COMPONENTS Gui Qml DBus)
find_package(KF6NetworkManagerQt REQUIRED)
qt_standard_project_setup(REQUIRES 6.7)
qt_add_qml_module(pond_system
    URI Pond.System
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Pond/System"
    SOURCES lockscreen/frontend/system/NetworkStatus.h lockscreen/frontend/system/Logind.h lockscreen/frontend/system/CapsLock.h
)
target_include_directories(pond_system PRIVATE lockscreen/frontend/system)
target_link_libraries(pond_system PRIVATE KF6::NetworkManagerQt Qt6::DBus Qt6::Gui wayland-client)
set_target_properties(pond_systemplugin PROPERTIES INSTALL_RPATH "$ORIGIN")
