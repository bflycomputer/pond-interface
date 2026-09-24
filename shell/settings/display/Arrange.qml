pragma ComponentBehavior: Bound
import QtQuick
import "." as Display
import ".." as Settings
import "../.." as Shell
import "Geometry.js" as Geometry

Settings.Modal {
  id: root
  objectName: "displayArrangePanel"
  implicitWidth: 570; title: "Arrange"; closeLabel: "Cancel arrangement and return to Display"; bodyTop: 77
  contentHeight: 570 + (errorText.visible ? errorText.height + 12 : 0)
  property var baselineSnapshot: []
  property var draft: []
  Component.onCompleted: { baselineSnapshot = JSON.parse(JSON.stringify(Display.State.geometry)); draft = JSON.parse(JSON.stringify(baselineSnapshot)); }
  property var viewport: Geometry.fit(baselineSnapshot,510,470,56,230)
  property int draggingIndex: -1
  readonly property bool stale: JSON.stringify(baselineSnapshot) !== JSON.stringify(Display.State.geometry)
  onBackRequested: if (!Display.State.busy) Settings.State.back()
  Keys.onEscapePressed: if (!Display.State.busy) Settings.State.back()
  Connections {
    target: Display.State
    function onArrangementApplied() { if (Settings.State.page === "arrange") Settings.State.back(); }
  }
  function moveMonitor(index, x, y) {
    if (stale || Display.State.busy) return;
    const next = draft.slice();
    next[index] = Geometry.snap(draft,index,x,y,10/viewport.scale);
    draft = next;
  }
  function fitDraft() { viewport = Geometry.fit(draft,510,470,56,230); }
  Rectangle {
    id: canvas
    objectName: "arrangeCanvas"
    x: 30; width: root.width-60; height: 470; radius: 16
    color: "transparent"; border.width: 1; border.color: "#303030"
    clip: true
    Canvas {
      anchors.fill: parent
      onPaint: {
        const c=getContext("2d"); c.clearRect(0,0,width,height); c.strokeStyle="#303030"; c.lineWidth=1;
        c.beginPath();
        for(let x=width/10;x<width;x+=width/10) {c.moveTo(x,0);c.lineTo(x,height);}
        for(let y=height/10;y<height;y+=height/10) {c.moveTo(0,y);c.lineTo(width,y);}
        c.stroke();
      }
    }
    Repeater {
      model: root.draft.length
      delegate: Display.Monitor {
        id: tile
        required property int index
        readonly property var rect: root.draft[index]
        objectName: "arrangeMonitor" + rect.name
        x: root.viewport.x + rect.x * root.viewport.scale + 4
        y: root.viewport.y + rect.y * root.viewport.scale + 4
        width: Math.max(20,rect.width * root.viewport.scale-8)
        height: Math.max(20,rect.height * root.viewport.scale-8)
        label: (Display.State.monitors.find(m=>m.name===rect.name) || {}).label || rect.name
        arranging: true; dragging: root.draggingIndex === index
        hovered: dragArea.containsMouse
        z: dragging ? 2 : 1
        enabled: !root.stale && !Display.State.busy
        activeFocusOnTab: enabled
        Accessible.role: Accessible.Button
        Accessible.name: label + ". Drag to arrange, or use arrow keys."
        function nudge(dx,dy) {
          const others = root.draft.filter((r,i)=>i!==index);
          if (!others.length) return;
          const anchor = others.sort((a,b)=>Math.hypot(a.x-rect.x,a.y-rect.y)-Math.hypot(b.x-rect.x,b.y-rect.y))[0];
          const x = dx < 0 ? anchor.x-rect.width : dx > 0 ? anchor.x+anchor.width : rect.x;
          const y = dy < 0 ? anchor.y-rect.height : dy > 0 ? anchor.y+anchor.height : rect.y;
          root.moveMonitor(index,x,y); root.fitDraft();
        }
        Keys.onLeftPressed: nudge(-1,0)
        Keys.onRightPressed: nudge(1,0)
        Keys.onUpPressed: nudge(0,-1)
        Keys.onDownPressed: nudge(0,1)
        MouseArea {
          id: dragArea
          anchors.fill: parent; hoverEnabled: true; preventStealing: true
          cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
          property point origin
          property point startPosition
          onPressed: mouse => {
            tile.forceActiveFocus();
            root.draggingIndex = tile.index;
            origin = mapToItem(canvas,mouse.x,mouse.y);
            startPosition = Qt.point(tile.rect.x,tile.rect.y);
          }
          onPositionChanged: mouse => {
            if (!pressed) return;
            const p=mapToItem(canvas,mouse.x,mouse.y);
            // The viewport stays fixed during a drag so the pointer never jumps.
            root.moveMonitor(tile.index,startPosition.x+(p.x-origin.x)/root.viewport.scale,startPosition.y+(p.y-origin.y)/root.viewport.scale);
          }
          onReleased: {root.draggingIndex=-1;root.fitDraft();}
          onCanceled: {root.draggingIndex=-1;root.fitDraft();}
        }
      }
    }
  }
  Rectangle {
    id: done
    objectName: "arrangeDone"
    x: 30; y: 490; width: root.width-60; height: 50; radius: 12
    color: doneHover.hovered || activeFocus ? "#d9bbfb" : "#cba6f7"
    opacity: enabled ? 1 : 0.4
    enabled: !root.stale && !Display.State.busy && Geometry.valid(root.draft)
    activeFocusOnTab: enabled
    function save() { Display.State.arrange(root.baselineSnapshot,root.draft); }
    Accessible.role: Accessible.Button; Accessible.name: "Apply display arrangement"
    Accessible.onPressAction: save()
    Keys.onReturnPressed: save()
    Keys.onSpacePressed: save()
    Text { anchors.centerIn: parent; text: Display.State.busy ? "Applying…" : "Done"; color: "#101010"; font.family: Shell.Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium }
    HoverHandler { id: doneHover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: done.save() }
  }
  Text {
    id: errorText
    x: 30; y: 552; width: root.width - 60
    visible: root.stale || !!Display.State.error
    text: root.stale ? "Displays changed. Close and reopen Arrange to use the current layout." : Display.State.error
    font.family: Shell.Theme.fontFamily; font.pixelSize: 13; color: "#ffb4ab"; wrapMode: Text.Wrap
  }
}
