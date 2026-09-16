pragma ComponentBehavior: Bound
import QtQuick
import ".." as Settings
import "../.." as Shell
import QtQuick.VectorImage
import QtQuick.Shapes

Item {
  id: root
  implicitWidth: 580; implicitHeight: 118
  property int hoveredContact: 0
  property int focusedContact: 0
  readonly property int activeContact: hoveredContact || focusedContact
  property var disappearDelays: []
  readonly property var hiddenCells: [[], [7,8,9,10,11,17,18,19], [2,3,4,15,16,17,18], [8,9,10,16,17,18,19], [4,5,8,9,10,11,12]]
  readonly property var contacts: [
    {key:1, label:"X / Twitter", x:158.8359375, y:35, size:25, plus:7, url:"https://x.com/bflycomputer"},
    {key:2, label:"Instagram", x:185, y:46, size:17, plus:5, url:"https://www.instagram.com/bflycomputer/"},
    {key:3, label:"Website", x:204, y:36, size:28, plus:6, url:"https://butterfly.so"},
    {key:4, label:"Email", x:193, y:65, size:24, plus:6, url:"mailto:hello@butterfly.so"}
  ]
  readonly property var labels: [
    {key:1, x:248, y:57, value:"@", accent:true},
    {key:1, x:270, y:57, value:"bflycomputer", accent:true},
    {key:1, x:306, y:77, value:"X / Twitter", accent:false},
    {key:2, x:286, y:37, value:"Instagram", accent:false},
    {key:2, x:264, y:77, value:"@bflycomputer", accent:true},
    {key:3, x:270, y:57, value:"Website", accent:false},
    {key:3, x:293, y:77, value:"butterfly.so", accent:true},
    {key:4, x:331, y:37, value:"Email", accent:false},
    {key:4, x:267, y:57, value:"hello@butterfly.so", accent:true}
  ]

  onActiveContactChanged: {
    // Only the affected cells disappear, in a fresh quick randomized order.
    const order = Array.from({length:21}, (_, i) => i);
    for (let i=order.length-1; i>0; --i) {
      const j=Math.floor(Math.random()*(i+1));
      const held=order[i]; order[i]=order[j]; order[j]=held;
    }
    const delays = [];
    order.forEach((cell, rank) => delays[cell] = rank * 3);
    disappearDelays = delays;
  }
  function openContact(contact) {
    Settings.State.close();
    Qt.openUrlExternally(contact.url);
  }
  VectorImage {
    x:30; y:31; width:60; height:60
    source: Qt.resolvedUrl("../../assets/information/pond.svg")
    preferredRendererType: VectorImage.CurveRenderer
  }
  Rectangle {
    x:98; y:31; width:40; height:18; radius:9
    color:"transparent"; border.width:1; border.color:"#4a4a4a"
    Label { x:9; capY:5; text:"V0.1" }
  }
  Label {
    x:98; capY:62; text:"Early\nPreview"
    font.family:Shell.Theme.titleFontFamily; font.styleName:"Book"; font.pixelSize:17
    font.letterSpacing:0
    lineHeightMode:Text.FixedHeight; lineHeight:17
  }
  // Qt's vector renderer omits SVG masks; the SVG image renderer retains them.
  Image {
    x:399; y:38; width:151.43209838867188; height:42.95694351196289
    source:Qt.resolvedUrl("../../assets/information/arch.svg")
    sourceSize.width:Math.ceil(width * Screen.devicePixelRatio)
    sourceSize.height:Math.ceil(height * Screen.devicePixelRatio)
  }
  VectorImage {
    x:155; y:31; width:80.8359375; height:61
    source:Qt.resolvedUrl("../../assets/information/icons.svg")
    preferredRendererType:VectorImage.CurveRenderer
  }
  Repeater {
    model:root.contacts
    delegate:Item {
      id:contact
      required property var modelData
      objectName:"informationContact" + modelData.key
      x:modelData.x; y:modelData.y; width:modelData.size; height:width
      activeFocusOnTab:true
      Accessible.role:Accessible.Link
      Accessible.name:modelData.label
      Accessible.onPressAction:root.openContact(modelData)
      Keys.onReturnPressed:root.openContact(modelData)
      Keys.onSpacePressed:root.openContact(modelData)
      onActiveFocusChanged: {
        if (activeFocus) root.focusedContact=modelData.key;
        else if (root.focusedContact===modelData.key) root.focusedContact=0;
      }
      Rectangle {
        anchors.fill:parent; radius:width/2
        color:"#cba6f7"
        opacity:root.activeContact===contact.modelData.key ? 1 : 0
        Behavior on opacity { NumberAnimation { duration:130; easing.type:Easing.OutCubic } }
        Plus {
          anchors.centerIn:parent
          scale:contact.modelData.plus/8
          ink:"#1d1d1d"
        }
      }
      MouseArea {
        anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
        containmentMask:QtObject {
          function contains(point: point): bool {
            const radius=contact.width/2;
            return Math.pow(point.x-radius,2)+Math.pow(point.y-radius,2)<=radius*radius;
          }
        }
        onEntered:root.hoveredContact=contact.modelData.key
        onExited:if (root.hoveredContact===contact.modelData.key) root.hoveredContact=0
        onClicked:root.openContact(contact.modelData)
      }
    }
  }
  Repeater {
    model:21
    delegate:Item {
      id:cell
      required property int index
      objectName:"informationPlus" + index
      x:244+(index%7)*20; y:31+Math.floor(index/7)*20
      width:20; height:20
      readonly property bool concealed:root.hiddenCells[root.activeContact].indexOf(index)>=0
      opacity:concealed ? 0 : 1
      Behavior on opacity {
        SequentialAnimation {
          PauseAnimation { duration:(root.disappearDelays[cell.index] || 0) }
          NumberAnimation { duration:80; easing.type:Easing.OutCubic }
        }
      }
      Plus {
        anchors.centerIn:parent
        ink:root.activeContact ? "#cba6f7" : "#777777"
      }
    }
  }
  Repeater {
    model:root.labels
    delegate:Label {
      required property var modelData
      objectName:"informationLabel" + modelData.key + "-" + modelData.value
      x:modelData.x; capY:modelData.y; text:modelData.value
      color:modelData.accent ? "#cba6f7" : "#777777"
      opacity:root.activeContact===modelData.key ? 1 : 0
      Behavior on opacity {
        SequentialAnimation {
          PauseAnimation { duration:50 }
          NumberAnimation { duration:110; easing.type:Easing.OutCubic }
        }
      }
    }
  }

  component Plus: Shape {
    id: root
    property color ink: "#777777"
    implicitWidth: 8; implicitHeight: 8
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: -1
      fillColor: root.ink
      PathSvg { path: "M4.44531 8L3.55642 8L3.55642 3.88544e-08L4.44531 0L4.44531 8Z M-5.96046e-08 4.44444V3.55556L8 3.55556V4.44444L-5.96046e-08 4.44444Z" }
    }
    Behavior on ink { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
  }
}
