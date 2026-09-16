import QtQuick

Item {
  id: root
  property string label: ""
  property string value: "—"
  implicitWidth: 276
  implicitHeight: 30

  Text {
    x: 0
    y: 0
    text: root.label
    color: "white"
    font.family: Theme.fontFamily
    font.weight: Font.Medium
    font.pixelSize: 15
  }
  Text {
    x: 0
    y: 21
    width: parent.width
    elide: Text.ElideRight
    text: root.value
    color: "white"
    opacity: 0.7
    font.family: Theme.fontFamily
    font.weight: Font.Normal
    font.pixelSize: 13
  }
}
