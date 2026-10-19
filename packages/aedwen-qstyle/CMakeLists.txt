# Aedwen widget style: Breeze with AedwenOS (Material 3 Expressive) context
# menus. See source/aedwenstyle.h.
cmake_minimum_required(VERSION 3.20)
project(aedwen-qstyle VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
include(GNUInstallDirs)

find_package(Qt6 6.6 REQUIRED COMPONENTS Widgets)
find_package(KF6ColorScheme REQUIRED)

add_library(aedwen6 MODULE
    source/aedwenstyle.cpp
    source/aedwenstyleplugin.cpp
)
target_link_libraries(aedwen6 PRIVATE Qt6::Widgets KF6::ColorScheme)
# Qt only scans <plugins>/styles; Breeze installs breeze6.so there too
install(TARGETS aedwen6 DESTINATION ${CMAKE_INSTALL_LIBDIR}/qt6/plugins/styles)
