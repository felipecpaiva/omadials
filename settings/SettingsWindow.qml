pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Quickshell resolves the platform window at runtime; its generic qmltypes mark it abstract.
// qmllint disable uncreatable-type
PanelWindow {
    id: panelWindow
    required property var panelHost
    readonly property bool wide: width >= 1000
    Connections {
        target: panelWindow.panelHost
        function onFocusRequested() {
            panelContent.forceActiveFocus();
        }
        function onScrollResetRequested() {
            pageScroll.contentY = 0;
        }
    }
    function focusContent() {
        panelContent.forceActiveFocus();
    }
    visible: panelWindow.panelHost.opened
    onVisibleChanged: if (visible)
        Qt.callLater(focusContent)
    anchors {
        top: true; bottom: true; left: true; right: true
    }
    color: Qt.alpha(panelWindow.panelHost.theme.surface, 0); exclusionMode: ExclusionMode.Ignore; WlrLayershell.namespace: "omadials-settings"
    WlrLayershell.layer: WlrLayer.Overlay; WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    Rectangle {
        anchors.fill: parent; color: Qt.alpha(panelWindow.panelHost.theme.surface, 0.65)
        MouseArea {
            anchors.fill: parent
            onClicked: panelWindow.panelHost.dismiss()
        }
    }
    Rectangle {
        anchors.centerIn: parent; width: Math.min(1080, panelWindow.width - 32); height: Math.min(800, panelWindow.height - 32)
        color: panelWindow.panelHost.theme.surface; border.color: panelWindow.panelHost.theme.edge
        MouseArea {
            anchors.fill: parent
        }
        Item {
            id: panelContent; anchors.fill: parent; anchors.margins: 16; focus: true
            Keys.onEscapePressed: {
                if (panelWindow.panelHost.editing)
                    panelWindow.panelHost.editing = "";
                else if (panelWindow.panelHost.page)
                    panelWindow.panelHost.page = 0;
                else
                    panelWindow.panelHost.dismiss();
            }
            ColumnLayout {
                anchors.fill: parent
                RowLayout {
                    Text {
                        Layout.fillWidth: true; text: "omadials settings"; color: panelWindow.panelHost.theme.text; font.family: panelWindow.panelHost.theme.font
                    }
                SettingsButton {
                        theme: panelWindow.panelHost.theme; text: "Close"
                        onClicked: panelWindow.panelHost.dismiss()
                    }
                }
                RowLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: 110
                        Repeater {
                            model: ["Corner", "Rings", "Toggles", "Behavior", "About"]
                            SettingsButton {
                                required property string modelData
                                required property int index
                                Layout.fillWidth: true
                                theme: panelWindow.panelHost.theme; text: modelData
                                selected: panelWindow.panelHost.page === index
                                onClicked: panelWindow.panelHost.page = index
                            }
                        }
                    }
                    GridLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        columns: panelWindow.wide ? 2 : 1
                        ColumnLayout {
                            Layout.row: 0; Layout.column: panelWindow.wide ? 1 : 0
                            Layout.preferredWidth: 300; Layout.fillWidth: !panelWindow.wide; Layout.fillHeight: panelWindow.wide
                            Layout.alignment: Qt.AlignTop
                            PreviewPane {
                                Layout.fillWidth: true
                                theme: panelWindow.panelHost.theme; store: panelWindow.panelHost.store
                                registry: panelWindow.panelHost.registry; fanComponent: panelWindow.panelHost.previewComponent
                                highlightId: panelWindow.panelHost.editing
                                onShowOnScreen: panelWindow.panelHost.showFanOnScreen()
                                onEditRequested: (id, toggle) => { panelWindow.panelHost.page = toggle ? 2 : 1; panelWindow.panelHost.edit(id); }
                            }
                            // Side sheet under the preview drawing, so the highlight stays visible.
                            Loader { Layout.fillWidth: true; Layout.fillHeight: panelWindow.wide; active: panelWindow.wide && !!panelWindow.panelHost.editing; sourceComponent: editSheetComponent }
                        }
                        Flickable {
                            id: pageScroll
                            Layout.row: panelWindow.wide ? 0 : 1; Layout.column: 0
                            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 580
                            clip: true; contentWidth: width; contentHeight: pageColumn.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds
                            ColumnLayout {
                                id: pageColumn; width: pageScroll.width; spacing: 16
                                ProblemsBanner { Layout.fillWidth: true; theme: panelWindow.panelHost.theme; store: panelWindow.panelHost.store; registry: panelWindow.panelHost.registry; page: panelWindow.panelHost.page }
                                Loader { Layout.fillWidth: true; sourceComponent: [cornerComponent,ringsComponent,togglesComponent,behaviorComponent,aboutComponent][panelWindow.panelHost.page] }
                            }
                        }
                    }
                }
                UndoBar {
                    Layout.fillWidth: true; theme: panelWindow.panelHost.theme; store: panelWindow.panelHost.store
                }
            }
            // Bottom sheet when narrow.
            Loader { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: parent.height * 0.55; z: 2; active: !panelWindow.wide && !!panelWindow.panelHost.editing; sourceComponent: editSheetComponent }
        }
    }
    Component { id: cornerComponent; CornerPage { theme: panelWindow.panelHost.theme; store: panelWindow.panelHost.store } }
    Component { id: ringsComponent; ControlsPage { theme: panelWindow.panelHost.theme; store: panelWindow.panelHost.store; registry: panelWindow.panelHost.registry; host: panelWindow.panelHost } }
    Component { id: togglesComponent; ControlsPage { theme: panelWindow.panelHost.theme; store: panelWindow.panelHost.store; registry: panelWindow.panelHost.registry; host: panelWindow.panelHost; togglesOnly: true } }
    Component { id: behaviorComponent; BehaviorPage { registry: panelWindow.panelHost.registry; theme: panelWindow.panelHost.theme; store: panelWindow.panelHost.store } }
    Component { id: aboutComponent; AboutPage { theme: panelWindow.panelHost.theme; store: panelWindow.panelHost.store; registry: panelWindow.panelHost.registry } }
    Component {
        id: editSheetComponent
        EditSheet {
            theme: panelWindow.panelHost.theme; store: panelWindow.panelHost.store; registry: panelWindow.panelHost.registry
            controlId: panelWindow.panelHost.editing; toggle: panelWindow.panelHost.page === 2
            onCloseRequested: panelWindow.panelHost.editing = ""
        }
    }
}
// qmllint enable uncreatable-type
