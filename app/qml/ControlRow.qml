pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
// One row of the Rings or Toggles edit list. In the corner: handle, icon, name, value, Edit and Remove.
// Not in the corner: icon, name and Add.
FocusScope {
    id: controlRow
    required property var control
    required property var registry
    required property var store
    required property var theme
    property string forcedGroup: ""
    property bool inCorner: true
    property bool addEnabled: true
    property bool editing: false
    property bool moving: false
    readonly property string controlKey: cm.key
    readonly property alias controlModel: cm
    signal editRequested(string id)
    signal removed(string id)
    signal moveRequested(string id, int delta)
    signal moveModeToggled(string id)
    function focusHandle() { handle.forceActiveFocus(Qt.TabFocusReason) }
    signal dropRequested(string fromId, string toId)
    implicitHeight: 60
    Layout.fillWidth: true
    ControlModel { id: cm; control: controlRow.control; store: controlRow.store; registry: controlRow.registry; forcedGroup: controlRow.forcedGroup }
    Rectangle {
        anchors.fill: parent; radius: controlRow.theme.radius
        color: controlRow.editing ? controlRow.theme.off : controlRow.theme.clear
        border.width: controlRow.editing ? 2 : 0; border.color: controlRow.theme.accent
    }
    DropArea {
        anchors.fill: parent; enabled: controlRow.inCorner
        onDropped: function(drop) { controlRow.dropRequested(drop.source.controlKey, controlRow.controlKey); drop.acceptProposedAction() }
    }
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4; spacing: 6
        Item {
            id: handle; objectName: "moveHandle"; visible: controlRow.inCorner
            implicitWidth: 28; implicitHeight: 48
            focus: true; activeFocusOnTab: true
            Accessible.role: Accessible.Grip
            Accessible.name: qsTr("Move %1. Use the up and down arrow keys.").arg(cm.name)
            Keys.onUpPressed: controlRow.moveRequested(controlRow.controlKey,-1)
            Keys.onDownPressed: controlRow.moveRequested(controlRow.controlKey,1)
            Rectangle { anchors.fill: parent; radius: controlRow.theme.radius; color: controlRow.theme.clear; border.width: handle.activeFocus ? 2 : 0; border.color: controlRow.theme.accent }
            Label { anchors.centerIn: parent; text: "⠿"; font.pixelSize: 18; color: controlRow.theme.secondary }
            Item {
                id: dragProxy; width: 1; height: 1
                property string controlKey: controlRow.controlKey
                Drag.active: drag.active; Drag.source: dragProxy
                Drag.supportedActions: Qt.MoveAction
            }
            DragHandler { id: drag; target: dragProxy; onActiveChanged: if (!active) { dragProxy.Drag.drop(); dragProxy.x = 0; dragProxy.y = 0 } }
        }
        Repeater {
            model: controlRow.inCorner && (controlRow.activeFocus || controlRow.moving) ? [-1,1] : []
            ToolButton {
                required property int modelData
                implicitWidth: 40; focusPolicy: Qt.TabFocus
                text: modelData < 0 ? "↑" : "↓"
                Accessible.name: (modelData < 0 ? qsTr("Move %1 up") : qsTr("Move %1 down")).arg(cm.name)
                onClicked: controlRow.moveRequested(controlRow.controlKey,modelData)
            }
        }
        ControlIcon { theme: controlRow.theme; store: controlRow.store; name: cm.icon; Layout.leftMargin: controlRow.inCorner ? 0 : 8 }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            Label { Layout.fillWidth: true; text: cm.name; elide: Text.ElideRight; color: controlRow.theme.text; font.pixelSize: 15 }
            Label {
                Layout.fillWidth: true; elide: Text.ElideRight; color: controlRow.theme.secondary; font.pixelSize: 12
                visible: text.length > 0
                text: cm.group !== "readoutRings" ? cm.valueText : controlRow.control?.value == null ? qsTr("Display ring") : qsTr("Display ring, %1").arg(cm.valueText)
            }
            TapHandler { onLongPressed: controlRow.moveModeToggled(controlRow.controlKey) }
        }
        CircleButton {
            visible: controlRow.inCorner; theme: controlRow.theme; kind: "edit"
            text: qsTr("Edit %1").arg(cm.name)
            onClicked: controlRow.editRequested(controlRow.controlKey)
        }
        CircleButton {
            visible: controlRow.inCorner; theme: controlRow.theme; kind: "remove"
            text: qsTr("Remove %1 from the corner").arg(cm.name)
            onClicked: if (cm.setShown(false)) controlRow.removed(controlRow.controlKey)
        }
        CircleButton {
            visible: !controlRow.inCorner; enabled: controlRow.addEnabled; theme: controlRow.theme; kind: "add"
            text: qsTr("Add %1 to the corner").arg(cm.name)
            onClicked: cm.setShown(true)
        }
    }
}
