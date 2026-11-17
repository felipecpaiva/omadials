pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: aboutPage
    required property var store
    required property var theme
    Text {
        Layout.fillWidth: true
        text: "omadials Settings 0.7.0\nQuick settings in a screen corner.\nConfig: " + aboutPage.store.path
        textFormat: Text.PlainText; wrapMode: Text.WrapAnywhere
        color: aboutPage.theme.text; font.family: aboutPage.theme.font
    }
    SettingsButton { theme: aboutPage.theme; text: "Reset all"; onClicked: aboutPage.store.reset() }
    Text {
        text: "Reset applies immediately. Undo restores the exact previous file for 10 seconds."
        Layout.fillWidth: true; wrapMode: Text.WordWrap
        color: aboutPage.theme.secondary; font.family: aboutPage.theme.font
    }
}
