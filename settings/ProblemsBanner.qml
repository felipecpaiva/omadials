pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../logic/Labels.js" as Labels
ColumnLayout {
    id: problemsBanner
    required property var store
    required property var registry
    required property var theme
    property int page: 0
    function owner(path) {
        if (/^(corner|size|outputs|trigger.push|tabStyle)/.test(path)) return 0;
        if (/^(ringStyle|dials|readoutRings)/.test(path)) return 1;
        if (/^toggles/.test(path)) return 2;
        if (/^controls/.test(path)) {
            const id = path.split(".")[1];
            const meta = (registry.catalog || []).find(c => c.id === id);
            return meta && meta.placements.indexOf("arc") >= 0 ? 2 : 1;
        }
        if (/^(behavior|dialInteraction|options|themePair|gameMode)/.test(path)) return 3;
        return 4;
    }
    readonly property var problems: store.errors.filter(e => problemsBanner.owner(e.path) === problemsBanner.page)
    visible: problems.length > 0
    Repeater {
        model: problemsBanner.problems
        RowLayout {
            id: problemRow
            required property var modelData
            Layout.fillWidth: true
            HelpText { theme: problemsBanner.theme; color: problemsBanner.theme.warn; text: Labels.label(problemRow.modelData.path.split(".").pop()) + ": " + problemRow.modelData.message }
            SettingsButton { theme: problemsBanner.theme; text: "Use the default"; enabled: !problemsBanner.store.readOnly && problemRow.modelData.code !== "io_error"; onClicked: problemsBanner.store.reset([problemRow.modelData.path.split(".")[0]]) }
        }
    }
}
