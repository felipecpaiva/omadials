pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Ui as Ui
import "../views" as Views
import "../logic/Glyphs.js" as Glyphs
import "../logic/Labels.js" as Labels
import "../logic/Gesture.js" as Gesture
// Built-in glyphs as a grid of real icons, plus a typed icon name. Never lists installed icons (docs/performance.md).
ColumnLayout {
    id: iconGrid
    required property var theme
    required property var store
    required property string path
    required property string fallback
    readonly property string current: store.value(path) || "default"
    function useTyped() { const name = typedName.text.trim(); if (name) iconGrid.store.set(iconGrid.path, name); }
    Layout.fillWidth: true
    HelpText { theme: iconGrid.theme; text: "Icon" }
    Flow {
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height  // Flow.implicitHeight is read-only
        spacing: 6
        Repeater {
            model: ["default"].concat(Object.keys(Glyphs.GLYPHS))
            SettingsButton {
                id: glyphButton
                required property string modelData
                theme: iconGrid.theme; text: ""
                implicitWidth: Gesture.TARGET; implicitHeight: Gesture.TARGET
                selected: iconGrid.current === modelData
                tooltipText: modelData === "default" ? "Default" : Labels.label(modelData)
                Accessible.name: tooltipText
                onClicked: iconGrid.store.set(iconGrid.path, modelData)
                Views.ControlIcon { anchors.centerIn: parent; width: 22; height: 22; theme: iconGrid.theme; name: glyphButton.modelData === "default" ? iconGrid.fallback : glyphButton.modelData }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Ui.TextField {
            id: typedName
            Layout.fillWidth: true
            placeholderText: "Type an icon name"
            text: iconGrid.current === "default" || iconGrid.current in Glyphs.GLYPHS ? "" : iconGrid.current
            foreground: iconGrid.theme.text; accent: iconGrid.theme.accent
            font.family: iconGrid.theme.font
            Accessible.name: "Type an icon name"
            onAccepted: iconGrid.useTyped()
        }
        SettingsButton { theme: iconGrid.theme; text: "Use"; onClicked: iconGrid.useTyped() }
    }
    HelpText { theme: iconGrid.theme; text: "Any installed icon name works, for example audio-volume-high." }
}
