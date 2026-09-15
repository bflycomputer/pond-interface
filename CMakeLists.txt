cmake_minimum_required(VERSION 3.21)
project(pond-interface LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
find_package(Qt6 6.11 REQUIRED COMPONENTS Qml ShaderTools)
find_package(KF6NetworkManagerQt REQUIRED)
qt_standard_project_setup(REQUIRES 6.7)
qt_add_qml_module(pond_system
    URI Pond.System
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Pond/System"
    SOURCES lockscreen/frontend/system/NetworkStatus.h
)
target_include_directories(pond_system PRIVATE lockscreen/frontend/system)
target_link_libraries(pond_system PRIVATE KF6::NetworkManagerQt)
set_target_properties(pond_systemplugin PROPERTIES INSTALL_RPATH "$ORIGIN")
install(TARGETS pond_system pond_systemplugin LIBRARY DESTINATION lib/qt6/qml/Pond/System COMPONENT Native)
install(FILES "${CMAKE_BINARY_DIR}/Pond/System/qmldir"
    "${CMAKE_BINARY_DIR}/Pond/System/pond_system.qmltypes" DESTINATION lib/qt6/qml/Pond/System COMPONENT Native)
install(DIRECTORY lockscreen/ DESTINATION share/pond-interface/lockscreen
    FILES_MATCHING PATTERN "*.qml" PATTERN "*.js" PATTERN "*.png" PATTERN "*.svg" PATTERN "*.qsb")
install(FILES lockscreen/greeter/metadata.desktop lockscreen/greeter/niri.kdl
    DESTINATION share/pond-interface/lockscreen/greeter)
install(FILES lockscreen/greeter/sddm.conf
    DESTINATION lib/sddm/sddm.conf.d RENAME pond-interface.conf)

set(daylight_module "${CMAKE_BINARY_DIR}/Pond/Daylight")
file(MAKE_DIRECTORY "${daylight_module}")
foreach(daylight_file Sky.qml SkyState.js qmldir)
    file(CREATE_LINK "${CMAKE_CURRENT_SOURCE_DIR}/wallpaper/daylight/${daylight_file}"
        "${daylight_module}/${daylight_file}" SYMBOLIC)
    install(FILES "wallpaper/daylight/${daylight_file}"
        DESTINATION lib/qt6/qml/Pond/Daylight COMPONENT Native)
endforeach()
add_custom_command(OUTPUT "${daylight_module}/sky.frag.qsb"
    COMMAND Qt6::qsb --qt6 -o "${daylight_module}/sky.frag.qsb"
        "${CMAKE_CURRENT_SOURCE_DIR}/wallpaper/daylight/sky.frag"
    DEPENDS wallpaper/daylight/sky.frag VERBATIM)
add_custom_target(daylight_shader ALL DEPENDS "${daylight_module}/sky.frag.qsb")
install(FILES "${daylight_module}/sky.frag.qsb" DESTINATION lib/qt6/qml/Pond/Daylight COMPONENT Native)
install(FILES wallpaper/daylight/shell.qml DESTINATION share/pond-interface/wallpaper/daylight)
