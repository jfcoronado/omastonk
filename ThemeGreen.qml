import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Reads the active theme's green from colors.toml so rising prices can be shown
// in green. The shell's Color singleton only exposes red (urgent), not green.
// Falls back to `fallback` (the plain bar text color) when the theme has none.
Item {
  id: root
  visible: false

  property color fallback: Color.bar.text
  property string themeGreen: ""
  readonly property color color: themeGreen !== "" ? themeGreen : fallback

  function parse(raw) {
    var green = ""
    var color2 = ""
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var match = lines[i].match(/^\s*([A-Za-z0-9_-]+)\s*=\s*["']?(#[0-9A-Fa-f]{6})/)
      if (!match) continue
      if (match[1] === "green") green = match[2]
      else if (match[1] === "color2") color2 = match[2]
    }
    themeGreen = green !== "" ? green : color2
  }

  FileView {
    id: colorsFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/colors.toml"
    watchChanges: true
    printErrors: false
    onLoaded: root.parse(text())
    onFileChanged: reload()
    onLoadFailed: root.themeGreen = ""
  }

  // Theme switches replace the theme folder and push new colors to the shell
  // over IPC, so the file watch can miss them. Re-read whenever the shell's
  // palette changes.
  Connections {
    target: Color
    function onUrgentChanged() { colorsFile.reload() }
    function onForegroundChanged() { colorsFile.reload() }
  }
}
