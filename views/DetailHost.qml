pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import "../logic/Motion.js" as Motion

Item {
    id: host
    required property var theme
    required property var model
    required property string corner
    required property real fanRadius
    required property real screenWidth
    required property real screenHeight
    property var shownControl: null
    property var previousFocus: null
    Connections {
        target: host.model
        function onDetailControlChanged() {
            if (host.model.detailControl) {
                if (!host.model.detail) host.previousFocus = host.Window.window ? host.Window.window.activeFocusItem : null
                host.shownControl = host.model.detailControl
                if (host.model.wantsKeyboard) focusBack.restart()
            } else if (host.previousFocus) host.previousFocus.forceActiveFocus()
        }
    }
    Timer { id: focusBack; interval: host.theme.duration(Motion.TIMES.detailOut); onTriggered: backButton.forceActiveFocus() }
    x: corner.indexOf("right") >= 0 ? screenWidth-fanRadius : 0
    y: corner.indexOf("top") >= 0 ? 0 : screenHeight-fanRadius
    width: fanRadius; height: fanRadius
    opacity: detailMotion.value; visible: opacity > 0
    MotionValue { id: detailMotion; theme: host.theme; target: host.model.detail ? 1 : 0; base: host.model.detail ? Motion.TIMES.detailIn : Motion.TIMES.detailOut; delay: host.model.detail ? Motion.TIMES.detailOut : 0 }
    ReadoutButton { id: backButton; theme: host.theme; box: ({x:16,y:16,width:48,height:48}); text: "←"; onClicked: host.model.closeDetail() }
    Text {
        id: heading
        x: 76; y: 16; width: parent.width-92
        text: host.shownControl ? host.shownControl.label : ""
        textFormat: Text.PlainText
        wrapMode: Text.Wrap; color: host.theme.text; font.family: host.theme.font; font.pixelSize: 18
    }
    Flickable {
        x: 16; y: Math.max(80,heading.y+heading.implicitHeight+16); width: parent.width-32; height: Math.max(0,parent.height-y-16)
        clip: true; contentHeight: customLoader.active ? customLoader.height : rows.height
        Loader {
            id: customLoader
            width: parent.width
            asynchronous: true
            property var selected: host.shownControl
            active: host.visible && !!selected && selected.detailKind === "custom"
            function loadDetail() {
                if (active) {
                    source = ""
                    setSource(selected.detailComponent, {control: selected, theme: host.theme, model: host.model})
                }
                else source = ""
            }
            onActiveChanged: loadDetail()
            onSelectedChanged: loadDetail()
        }
        Text {
            visible: customLoader.active && customLoader.status !== Loader.Ready
            text: customLoader.status === Loader.Error ? "Unable to load detail" : "Loading"
            textFormat: Text.PlainText; color: host.theme.text; font.family: host.theme.font; font.pixelSize: 14
        }
        Column {
            visible: !customLoader.active
            id: rows; width: parent.width; spacing: 8
            Repeater {
                model: host.shownControl ? host.shownControl.detailRows : []
                DetailRow {
                    required property var modelData
                    width: rows.width; height: implicitHeight
                    theme: host.theme; control: host.shownControl; rowData: modelData; model: host.model
                }
            }
            Text {
                width: parent.width
                visible: host.shownControl && host.shownControl.detailRows.length === 0
                textFormat: Text.PlainText
                text: host.shownControl ? host.shownControl.valueText : ""
                color: host.theme.text; font.family: host.theme.font; font.pixelSize: 14; wrapMode: Text.Wrap
            }
        }
    }
}
