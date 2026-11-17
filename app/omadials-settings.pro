QT += core gui qml quick quickcontrols2
CONFIG += c++17 release
TARGET = omadials-settings
TEMPLATE = app
HEADERS += src/backend.h src/theme.h src/translator.h
SOURCES += src/main.cpp src/backend.cpp src/theme.cpp src/translator.cpp
!system(python3 $$PWD/prepare.py): error(Resource preparation failed)
RESOURCES += resources.qrc

QMAKE_INTERNAL_INCLUDED_FILES += $$files($$PWD/../logic/*.js) $$PWD/../controls/catalog.json
