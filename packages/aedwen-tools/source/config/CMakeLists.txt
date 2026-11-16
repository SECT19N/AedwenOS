# org.aedwen.config: the AedwenOS appearance settings (kdeglobals
# [AedwenOS]) for QML, live. org.aedwen.ui Theme creates an AedwenConfig
# dynamically to pick the Material 3 or Expressive token set.
include(ECMQmlModule)
ecm_add_qml_module(aedwenconfig URI org.aedwen.config VERSION 1.0 GENERATE_PLUGIN_SOURCE)
target_sources(aedwenconfig PRIVATE aedwenconfig.cpp aedwenconfig.h)
target_link_libraries(aedwenconfig PRIVATE Qt6::Qml KF6::ConfigCore)
ecm_finalize_qml_module(aedwenconfig DESTINATION ${KDE_INSTALL_QMLDIR})
