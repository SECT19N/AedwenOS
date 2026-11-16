# aedwen-search: the Alt+Space search overlay (Desktop design: SEARCH).
add_executable(aedwen-search main.cpp suggestions.cpp)
target_link_libraries(aedwen-search PRIVATE
    Qt6::Gui Qt6::Qml Qt6::Quick
    KF6::DBusAddons KF6::ConfigCore KF6::Service KF6::KIOGui KF6::CoreAddons KF6::I18n)
target_compile_definitions(aedwen-search PRIVATE AEDWEN_SEARCH_QML="${KDE_INSTALL_FULL_DATADIR}/aedwen/search/Search.qml")
install(TARGETS aedwen-search ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(FILES Search.qml DESTINATION ${KDE_INSTALL_DATADIR}/aedwen/search)
install(FILES org.aedwen.search.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES org.aedwen.search.autostart.desktop DESTINATION ${KDE_INSTALL_AUTOSTARTDIR} RENAME org.aedwen.search.desktop)
install(FILES org.aedwen.search.service DESTINATION ${KDE_INSTALL_DBUSSERVICEDIR})
# kglobalacceld reads service shortcuts (X-KDE-Shortcuts) from here
install(FILES org.aedwen.search.desktop DESTINATION ${KDE_INSTALL_DATADIR}/kglobalaccel)
