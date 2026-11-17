import QtQuick
// The app's colours come from the current Omarchy theme (colors.toml) and follow a theme switch live. The literals are
// only fallbacks for a theme file that lacks a key.
QtObject {
    readonly property var c: desktopTheme.colors || ({})
    function pick(key, fallback) { return c[key] !== undefined ? c[key] : fallback }
    property color background: pick("background", "#0e0e10")
    property color surface: pick("lighter_background", pick("background", "#171719"))
    property color text: pick("bright_foreground", pick("foreground", "#eeeeee"))
    property color secondary: pick("foreground", "#aaaaae")
    property color warn: pick("red", "#ffb86c")
    property color off: pick("selection", "#252528")
    property color edge: pick("muted", "#444448")
    property color track: pick("muted", "#555558")
    property color clear: "transparent"
    property color accent: desktopTheme.accent
    property color ink: desktopTheme.accentForeground
    property int radius: desktopTheme.radius
    property string font: "sans-serif"
}
