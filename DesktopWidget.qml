import QtQuick
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Services.UI
import qs.Widgets
import "utils/markdown.js" as Markdown

// One sticky note on the desktop. Per-instance state lives in widgetData
// (text, bgColor, textColor, fontSize). Persistence goes through the base class
// updateWidgetData() -> DesktopWidgetRegistry. See docs/specs (AD-001/AD-002).
DraggableDesktopWidget {
  id: root
  property var pluginApi: null

  // The note paints its own post-it background, so the base chrome is off by
  // default (C-001). The widget settings can still opt it back in per instance.
  showBackground: widgetData?.showBackground ?? false

  // Defaults are single-sourced from the manifest (metadata.defaultSettings),
  // with hardcoded fallbacks so a missing field never breaks the render (REQ-008).
  readonly property var _defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})

  readonly property string noteText: widgetData?.text ?? ""
  readonly property color noteBg: widgetData?.bgColor ?? _defaults.defaultBgColor ?? "#FFF9C4"
  readonly property color noteTextColor: widgetData?.textColor ?? _defaults.defaultTextColor ?? "#37474F"
  readonly property int noteFontSize: widgetData?.fontSize ?? _defaults.defaultFontSize ?? 14

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
    clip: true

    // Hint shown on an empty note (still clickable to open the editor).
    NText {
      anchors.centerIn: parent
      visible: root.noteText === ""
      text: root.pluginApi?.tr("widget.empty-hint") ?? "Click to edit"
      color: Qt.rgba(root.noteTextColor.r, root.noteTextColor.g, root.noteTextColor.b, 0.5)
      pointSize: Math.round(Style.fontSizeM * root.widgetScale)
    }

    // Read-only Markdown preview. Text (not TextArea) so it never captures the
    // mouse: clicks reach the MouseArea below (edit) and drags reach the base
    // class drag/scale handles in edit mode (C-002).
    Text {
      anchors.fill: parent
      anchors.margins: Math.round(Style.marginM * root.widgetScale)
      visible: root.noteText !== ""
      text: Markdown.render(root.noteText, {
        "noteColor": root.noteBg
      })
      textFormat: Text.RichText
      color: root.noteTextColor
      font.pointSize: Math.round(root.noteFontSize * root.widgetScale)
      wrapMode: Text.Wrap
      verticalAlignment: Text.AlignTop
    }
  }

  // Clicking the note outside edit mode opens the editor Panel. Declared last so
  // it sits on top and reliably receives the click; hidden in edit mode so it
  // never steals the base drag/scale handles.
  MouseArea {
    anchors.fill: parent
    visible: !DesktopWidgetRegistry.editMode
    acceptedButtons: Qt.LeftButton
    onClicked: {
      if (root.pluginApi?.mainInstance) {
        root.pluginApi.mainInstance.setActive(root.screen.name, root.widgetIndex, {
          "text": root.widgetData?.text ?? "",
          "bgColor": root.widgetData?.bgColor ?? "#FFF9C4",
          "textColor": root.widgetData?.textColor ?? "#37474F",
          "fontSize": root.widgetData?.fontSize ?? 14
        });
      }
      root.pluginApi?.openPanel(root.screen);
    }
  }
}
