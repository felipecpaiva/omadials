pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: settingsPanel
    required property var registry
    required property var store
    required property var theme
    // The panel loader supplies the matching service after creation.
    property var service: null
    registry: service ? service.registry : null
    store: service ? service.configStore : null
    theme: service ? service.theme : null
    property var shell: null
    property var manifest: null
    property string omarchyPath: ""
    property bool opened: false
    property int page: 0
    property Component previewComponent: null
    signal focusRequested
    signal scrollResetRequested
    signal showOnScreen
    function open(payloadJson) {
        if (store)
            store.reload();
        page = 0;
        opened = true;
        Qt.callLater(function () {
            settingsPanel.focusRequested();
        });
    }
    function close() {
        opened = false;
    }
    onOpenedChanged: if (registry && "settingsOpen" in registry)
        registry.settingsOpen = opened
    onRegistryChanged: if (registry && "settingsOpen" in registry)
        registry.settingsOpen = opened
    Component.onDestruction: if (registry && "settingsOpen" in registry)
        registry.settingsOpen = false
    function dismiss() {
        if (shell && typeof shell.hide === "function")
            shell.hide("io.github.felipecpaiva.omadials");
        else
            close();
    }
    function showFanOnScreen() {
        // The panel can be unloaded synchronously by hide(), so keep the service reference.
        let shared = service;
        showOnScreen();
        dismiss();
        if (shared && shared.showFan) shared.showFan();
    }
    function toggle() {
        if (opened)
            dismiss();
        else
            open("{}");
    }
    Loader {
        id: windowLoader
        active: !!settingsPanel.store && !!settingsPanel.registry && !!settingsPanel.theme
        sourceComponent: Component {
            SettingsWindow { panelHost: settingsPanel }
        }
    }
    Loader {
        active: settingsPanel.opened && !!settingsPanel.registry && !!settingsPanel.store
        sourceComponent: SettingsResources { registry: settingsPanel.registry; store: settingsPanel.store }
    }
    onPageChanged: scrollResetRequested()
}
