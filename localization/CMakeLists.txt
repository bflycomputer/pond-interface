file(GLOB POND_CATALOGS CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/translations/*.json")
qt_add_qml_module(pond_localization
    URI Pond.Localization VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Pond/Localization"
    SOURCES Localization.h Localization.cpp JsonTranslator.h)
target_link_libraries(pond_localization PRIVATE Qt6::Core Qt6::Qml)
foreach(catalog IN LISTS POND_CATALOGS)
    get_filename_component(filename "${catalog}" NAME)
    set_source_files_properties("${catalog}" PROPERTIES QT_RESOURCE_ALIAS "${filename}")
endforeach()
qt_add_resources(pond_localization pond_translations PREFIX "/pond/translations" FILES ${POND_CATALOGS})
set_target_properties(pond_localizationplugin PROPERTIES INSTALL_RPATH "$ORIGIN")
install(TARGETS pond_localization pond_localizationplugin LIBRARY DESTINATION lib/qt6/qml/Pond/Localization)
install(FILES "${CMAKE_BINARY_DIR}/Pond/Localization/qmldir"
    "${CMAKE_BINARY_DIR}/Pond/Localization/pond_localization.qmltypes"
    DESTINATION lib/qt6/qml/Pond/Localization)
