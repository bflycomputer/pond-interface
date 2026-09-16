import QtQuick
import "../.." as Shell

Text {
  id: root
  property real capY: 0
  y: capY - baselineOffset + metrics.capitalHeight
  textFormat: Text.PlainText
  font.family: Shell.Theme.fontFamily
  font.pixelSize: 11
  font.letterSpacing: 0.11
  color: "#777777"
  FontMetrics { id: metrics; font: root.font }
}
