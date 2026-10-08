import QtQuick
import QtQuick.Controls as Controls
import ".."

Flickable {
  id: root
  clip: true
  boundsBehavior: Flickable.StopAtBounds
  ScrollWheel { view: root }
  Controls.ScrollBar.vertical: Controls.ScrollBar {
    anchors.right: parent.right
    anchors.rightMargin: 5
    width: 2
    padding: 0
    policy: size < 1 ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff
    contentItem: Rectangle { radius: 2; color: Qt.rgba(1, 1, 1, 0.2) }
    background: null
  }

  function reveal(field) {
    const top = field.mapToItem(contentItem, 0, -21).y;
    const bottom = top + 21 + field.height;
    const next = top < contentY ? top
        : bottom > contentY + height ? bottom - height : contentY;
    contentY = Math.max(0, Math.min(Math.max(0, contentHeight - height), next));
  }
}
