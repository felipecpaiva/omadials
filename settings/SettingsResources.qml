pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
Item {
    id: resources
    required property var registry
    required property var store
    property bool loadIcons: true
    property bool loadPens: false
    property var penDevices: []
    readonly property var themeBackend: registry.byId("theme")
    readonly property var themes: themeBackend ? (themeBackend.detailRows || []).map(r => r.key) : []
    onThemesChanged: if (themes.length) store.validationResources = Object.assign({},store.validationResources,{themes:themes})
    function discover() {
        if (loadIcons && themeBackend) themeBackend.refresh();
        if (loadPens) registry.runner.run("settings:pens", ["upower", "-e"], 5000, (out, code, error) => {
            if (code) return;
            out.trim().split("\n").filter(path => /\/org\/freedesktop\/UPower\/devices\//.test(path)).forEach(path => {
                registry.runner.run("settings:pen:" + path, ["upower", "-i", path], 5000, (info, result, problem) => {
                    if (result || !/type:\s*(pen|stylus)/i.test(info)) return;
                    const name = /model:\s*(.+)/.exec(info);
                    resources.penDevices = resources.penDevices.concat([{value:path,label:name ? name[1].trim() : "Pen"}]);
                });
            });
        });
    }
    Component.onCompleted: discover()
}
