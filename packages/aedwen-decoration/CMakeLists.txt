# AedwenOS window decoration (KDecoration3): the title bars of
# scripts/generate-aurorae-theme.py as C++, so KWin rounds all four corners
# (Aurorae has no border radius API). See source/aedwendecoration.h.
cmake_minimum_required(VERSION 3.20)
project(aedwen-decoration VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
include(GNUInstallDirs)

find_package(Qt6 6.6 REQUIRED COMPONENTS Gui)
find_package(KDecoration3 REQUIRED)
find_package(KF6CoreAddons REQUIRED)
find_package(KF6Config REQUIRED)
find_package(KF6ColorScheme REQUIRED)

add_library(org.kde.aedwen MODULE
    source/aedwendecoration.cpp
    source/aedwenplugin.cpp
)
set_target_properties(org.kde.aedwen PROPERTIES PREFIX "")
target_link_libraries(org.kde.aedwen PRIVATE
    Qt6::Gui KDecoration3::KDecoration KF6::CoreAddons KF6::ConfigCore KF6::ColorScheme)
# KWin loads decorations from <plugins>/org.kde.kdecoration3 and matches
# kwinrc [org.kde.kdecoration2] library= against the plugin id (aedwen.json)
install(TARGETS org.kde.aedwen DESTINATION ${CMAKE_INSTALL_LIBDIR}/qt6/plugins/org.kde.kdecoration3)
