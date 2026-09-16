pragma ComponentBehavior: Bound
import QtQuick
import "." as Information
import ".." as Settings
import "../.." as Shell
import QtQuick.Controls

Settings.Modal {
  id:root
  objectName:"informationPanel"
  title:"Information"
  contentHeight:556
  onBackRequested:Settings.State.back()
  Keys.onEscapePressed:Settings.State.back()
  readonly property var rows: [
    {key:"os", label:"OS", y:92, line:130},
    {key:"host", label:"Host", y:144, line:184},
    {key:"board", label:"Board", y:198, line:236},
    {key:"cpu", label:"CPU", y:250, line:288},
    {key:"gpu", label:"GPU", y:302, line:340},
    {key:"memory", label:"Memory", y:354, line:392},
    {key:"disk", label:"Disk", y:406, line:0}
  ]
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
        x:54; capY:7; text:row.modelData.label
        font.pixelSize:15; font.weight:Font.Medium; font.letterSpacing:0
        color:"#99ffffff"
      }
      Information.Label {
        id:valueText
        objectName:"informationValue-" + row.modelData.key
        x:130; capY:6; width:390
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
    Accessible.name:"Manual"
    // The manual card will be connected in a later iteration.
    Behavior on color { ColorAnimation { duration:Settings.Style.hoverDuration; easing.type:Easing.OutCubic } }
    Information.Label {
      x:28; capY:26; text:"Manual"; color:"white"
      font.family:Shell.Theme.titleFontFamily; font.styleName:"Book"; font.pixelSize:17; font.letterSpacing:0
    }
    HoverHandler { id:manualHover; cursorShape:Qt.PointingHandCursor }
    TapHandler {}
  }
  Footer { objectName:"informationFooter"; y:438 }
}
