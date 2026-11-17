QT += core gui qml quick quickcontrols2 testlib
CONFIG += c++17 testcase
TARGET = settings-tests
SOURCES += settings_tests.cpp ../src/backend.cpp ../src/theme.cpp ../src/translator.cpp
HEADERS += ../src/backend.h ../src/theme.h ../src/translator.h
INCLUDEPATH += ../src
RESOURCES += ../resources.qrc
