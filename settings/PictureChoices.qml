pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../logic/Labels.js" as Labels
ColumnLayout {
    id: pictureChoices
    required property var theme
    required property var store
    required property string path
    required property string label
    required property var choices
    required property var pictures
    property string styleKey: ""
    Layout.fillWidth: true
    HelpText { theme: pictureChoices.theme; text: pictureChoices.label }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Layout.preferredHeight: childrenRect.height  // Flow.implicitHeight is read-only
        Repeater {
            model: pictureChoices.choices
            ColumnLayout {
                id: pictureOption
                required property var modelData
                required property int index
                StylePicture { visible: !!pictureChoices.styleKey; theme: pictureChoices.theme; styleKey: pictureChoices.styleKey; choice: pictureOption.modelData; Layout.alignment: Qt.AlignHCenter }
                SettingsButton {
                theme: pictureChoices.theme
                text: pictureChoices.pictures[pictureOption.index] + "  " + Labels.label(pictureOption.modelData)
                selected: pictureChoices.store.value(pictureChoices.path) === pictureOption.modelData
                onClicked: pictureChoices.store.set(pictureChoices.path, pictureOption.modelData)
                }
            }
        }
    }
}
