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
  color: Qt.rgba(1, 1, 1, 0.5)
  FontMetrics { id: metrics; font: root.font }
}
