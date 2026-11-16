# kcm_aedwen_appearance: System Settings > Colours & Themes > Appearance
# (System Surfaces design: the Settings window's Appearance page).
kcmutils_add_qml_kcm(kcm_aedwen_appearance SOURCES appearance.cpp appearance.h oklch.h)
target_link_libraries(kcm_aedwen_appearance PRIVATE
    Qt6::Quick Qt6::DBus KF6::KCMUtilsQuick KF6::ConfigCore KF6::CoreAddons KF6::I18n)

# the launcher entry (kcmutils' generated one is NoDisplay)
install(FILES org.aedwen.appearance.desktop DESTINATION ${KDE_INSTALL_APPDIR})
# root helper for the boot splash and Limine colours, and its polkit action
install(PROGRAMS aedwen-boot-accent DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/aedwen)
install(FILES org.aedwen.boot-accent.policy DESTINATION ${KDE_INSTALL_DATADIR}/polkit-1/actions)
