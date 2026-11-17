# aedwen-welcome: the first-run Welcome app (System Surfaces design, section 07).
add_executable(aedwen-welcome main.cpp controller.cpp)
target_link_libraries(aedwen-welcome PRIVATE
    Qt6::Gui Qt6::Qml Qt6::Quick
    KF6::DBusAddons KF6::ConfigCore KF6::CoreAddons KF6::I18n)
target_compile_definitions(aedwen-welcome PRIVATE AEDWEN_WELCOME_QML="${KDE_INSTALL_FULL_DATADIR}/aedwen/welcome/Welcome.qml")
install(TARGETS aedwen-welcome ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(FILES Welcome.qml DESTINATION ${KDE_INSTALL_DATADIR}/aedwen/welcome)
install(FILES org.aedwen.welcome.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES org.aedwen.welcome.autostart.desktop DESTINATION ${KDE_INSTALL_AUTOSTARTDIR} RENAME org.aedwen.welcome.desktop)
