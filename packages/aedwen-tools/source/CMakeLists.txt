cmake_minimum_required(VERSION 3.20)
project(aedwen-tools VERSION 0.1.0 LANGUAGES CXX)

set(QT_MIN_VERSION 6.7)
set(KF_MIN_VERSION 6.10)

find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)
list(APPEND CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Core Gui DBus Qml Quick)
find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS Config CoreAddons DBusAddons I18n KIO Service KCMUtils)

add_subdirectory(search)
add_subdirectory(config)
add_subdirectory(appearance)
