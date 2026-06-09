import QtQuick
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Services.UI
import qs.Widgets

// One sticky note on the desktop. Per-instance state lives in widgetData
// (text, bgColor, ...). Persistence goes through the base class
// updateWidgetData() -> DesktopWidgetRegistry. See docs/specs (AD-001/AD-002).
DraggableDesktopWidget {
  id: root
  property var pluginApi: null

  // The note paints its own post-it background, so disable the base chrome.
  showBackground: false

  readonly property string noteText: widgetData?.text ?? ""
  readonly property color noteBg: widgetData?.bgColor ?? "#FFF9C4"

  readonly property int baseW: 200
  readonly property int baseH: 140
  implicitWidth: Math.round(baseW * widgetScale)
  implicitHeight: Math.round(baseH * widgetScale)
  width: implicitWidth
  height: implicitHeight

  Rectangle {
    anchors.fill: parent
    radius: Math.round(Style.radiusM * root.widgetScale)
    color: root.noteBg
    border.width: 1
    border.color: Qt.darker(root.noteBg, 1.08)

    NText {
      anchors.centerIn: parent
      text: root.noteText !== "" ? root.noteText : "Sticky note"
      color: "#37474F"
      pointSize: Math.round(Style.fontSizeM * root.widgetScale)
    }
  }

  // Spike (Task 4): clicking the note outside edit mode opens the editor Panel.
  // Hidden in edit mode so it never steals the base drag/scale handles (C-002).
  MouseArea {
    anchors.fill: parent
    visible: !DesktopWidgetRegistry.editMode
    acceptedButtons: Qt.LeftButton
    onClicked: {
      if (root.pluginApi?.mainInstance) {
        root.pluginApi.mainInstance.setActive(root.screen.name, root.widgetIndex);
      }
      root.pluginApi?.openPanel(root.screen);
    }
  }
}
