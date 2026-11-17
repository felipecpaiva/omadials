pragma ComponentBehavior: Bound
import QtQuick
import "../logic/Labels.js" as Labels
SettingsCard {
    id: themePair
    required property var store
    required property var registry
    title: "Theme toggle"
    readonly property var backend: registry.byId("theme")
    readonly property var installed: backend ? (backend.detailRows || []).map(r => r.key) : []
    function fillPair() {
        if (!installed.length || store.saving) return;
        store.validationResources = Object.assign({}, store.validationResources, {themes:installed});
        const current = backend.currentTheme || installed[0];
        const light = installed.find(n => /light|latte|dawn|day/i.test(n)) || current;
        const dark = installed.find(n => n !== light && /dark|night|moon|mocha/i.test(n)) || installed.find(n => n !== light) || current;
        let changes = [];
        if (!store.config.themePair.light) changes.push({path:"themePair.light",value:light});
        if (!store.config.themePair.dark) changes.push({path:"themePair.dark",value:dark});
        if (changes.length) store.setMany(changes);
    }
    onInstalledChanged: fillPair()
    Component.onCompleted: { if (backend) backend.refresh(); fillPair() }
    SettingField { theme: themePair.theme; store: themePair.store; path: "themePair.light"; label: "Light theme"; hint: "Installed theme used for the light side of the toggle."; choices: themePair.installed }
    SettingField { theme: themePair.theme; store: themePair.store; path: "themePair.dark"; label: "Dark theme"; hint: "Installed theme used for the dark side of the toggle."; choices: themePair.installed }
    HelpText { theme: themePair.theme; visible: !themePair.installed.length; text: "Checking installed themes. Theme choices appear when the theme control is ready." }
}
