pragma ComponentBehavior: Bound
import QtQuick
import "." as Information
import ".." as Settings
import "../.." as Shell
import QtQuick.Controls

Settings.Modal {
  id:root
  objectName:"informationPanel"
  title:qsTrId("pond.information")
  contentHeight:556
  onBackRequested:Settings.State.back()
  Keys.onEscapePressed:Settings.State.back()
  readonly property var rows: [
    {key:"os", label:qsTrId("pond.os"), y:92, line:130},
    {key:"host", label:qsTrId("pond.host"), y:144, line:184},
    {key:"board", label:qsTrId("pond.board"), y:198, line:236},
    {key:"cpu", label:qsTrId("pond.cpu"), y:250, line:288},
    {key:"gpu", label:qsTrId("pond.gpu"), y:302, line:340},
    {key:"memory", label:qsTrId("pond.memory"), y:354, line:392},
    {key:"disk", label:qsTrId("pond.disk"), y:406, line:0}
  ]
  FontMetrics {
    id: labelMetrics
    font.family: Shell.Theme.fontFamily
    font.pixelSize: 15
    font.weight: Font.Medium
  }
  readonly property real valueColumnX: Math.min(300, Math.max(130,
      54 + Math.max(...rows.map(row => labelMetrics.advanceWidth(row.label))) + 16))
  Repeater {
    model:root.rows
    delegate: Item {
      id:row
      required property var modelData
      required property int index
      x:30; y:modelData.y-82; width:520; height:24
      Rectangle {
        width:24; height:24; radius:12
        color:"transparent"; border.width:1; border.color:"#343434"
        Information.Label {
          x:0; width:24; capY:8; text:row.index+1
          font.family:"IBM Plex Mono"; font.weight:Font.DemiBold; font.letterSpacing:-0.22
          horizontalAlignment:Text.AlignHCenter; color:"#80ffffff"
        }
      }
      Information.Label {
        objectName:"informationLabel-" + row.modelData.key
        x:54; capY:7; width:root.valueColumnX - x - 16
        text:row.modelData.label; elide:Text.ElideRight
        ToolTip.visible:labelHover.hovered && truncated
        ToolTip.text:text
        HoverHandler { id:labelHover }
        font.pixelSize:15; font.weight:Font.Medium; font.letterSpacing:0
        color:"#99ffffff"
      }
      Information.Label {
        id:valueText
        objectName:"informationValue-" + row.modelData.key
        x:root.valueColumnX; capY:6; width:Math.max(0, row.width - x)
        text:Information.State.value(row.modelData.key)
        font.family:Shell.Theme.titleFontFamily; font.styleName:"Book"; font.pixelSize:17
        font.letterSpacing:0; color:"white"; elide:Text.ElideRight
        ToolTip.visible:valueHover.hovered && truncated
        ToolTip.text:text
        HoverHandler { id:valueHover }
      }
      Rectangle {
        visible:row.modelData.line>0
        y:row.modelData.line-row.modelData.y-1; width:520; height:1
        color:"#343434"
      }
    }
  }
  Rectangle {
    id:manual
    objectName:"informationManual"
    x:30; y:376; width:520; height:64; radius:12
    // Stay opaque while easing so transparent black cannot darken the midpoint.
    color:manualHover.hovered || activeFocus ? Settings.Style.hover : root.color
    border.width:1; border.color:"#343434"
    activeFocusOnTab:true
    Accessible.role:Accessible.Button
    Accessible.name:qsTrId("pond.manual")
    Accessible.onPressAction:Settings.State.openPage("manual")
    Keys.onReturnPressed:Settings.State.openPage("manual")
    Keys.onSpacePressed:Settings.State.openPage("manual")
    Behavior on color { ColorAnimation { duration:Settings.Style.hoverDuration; easing.type:Easing.OutCubic } }
    Image {
      x:20; y:20; width:24; height:24
      source:Qt.resolvedUrl("../../assets/manual/book.svg")
    }
    Information.Label {
      x:54; capY:26; text:qsTrId("pond.manual"); color:"white"
      font.family:Shell.Theme.titleFontFamily; font.styleName:"Book"; font.pixelSize:17; font.letterSpacing:0
    }
    HoverHandler { id:manualHover; cursorShape:Qt.PointingHandCursor }
    TapHandler { onTapped:Settings.State.openPage("manual") }
  }
  Footer { objectName:"informationFooter"; y:438 }
}
