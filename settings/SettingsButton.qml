pragma ComponentBehavior: Bound
import QtQuick
import qs.Ui as Ui
Ui.Button {
    required property var theme
    foreground: theme.text
    background: theme.off
    accent: theme.accent
    fontFamily: theme.font
    focusable: true
    bordered: true
    Accessible.name: text
}
