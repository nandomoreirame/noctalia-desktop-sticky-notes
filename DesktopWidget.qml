import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Services.UI
import qs.Widgets
import "utils/markdown.js" as Markdown
import "utils/scroll.js" as Scroll
import "utils/dimensions.js" as Dimensions
import "utils/palette.js" as Palette
import "utils/filepath.js" as FilePath

// One sticky note on the desktop. Per-instance state lives in widgetData
// (text, bgColor, textColor, fontSize). Persistence goes through the base class
// updateWidgetData() -> DesktopWidgetRegistry. See docs/specs (AD-001/AD-002).
DraggableDesktopWidget {
  id: root
  property var pluginApi: null

  // The note paints its own square post-it background, so the base chrome
  // (background + rounded corners) is always off (C-001).
  showBackground: false
  roundedCorners: false

  // Defaults are single-sourced from the manifest (metadata.defaultSettings),
  // with hardcoded fallbacks so a missing field never breaks the render (REQ-008).
  readonly property var _defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})

  // Optional .md file backing this note (REQ-011/AD-006). When set, the file is
  // the source of truth: its content is rendered instead of widgetData.text, and
  // it is watched for external edits (REQ-013). The leading ~ is expanded to $HOME.
  readonly property string noteFilePath: FilePath.expandPath(widgetData?.filePath ?? "", Quickshell.env("HOME") || "")
  readonly property bool linked: FilePath.isLinked(noteFilePath)
  property string fileContent: ""

  // File content wins when linked; otherwise the inline text (C-009, backward compatible).
  readonly property string noteText: FilePath.resolveNoteText(noteFilePath, fileContent, widgetData?.text ?? "")
  readonly property color noteBg: widgetData?.bgColor ?? _defaults.defaultBgColor ?? "#FFF9C4"
  readonly property color noteTextColor: widgetData?.textColor ?? _defaults.defaultTextColor ?? "#37474F"
  readonly property int noteFontSize: widgetData?.fontSize ?? _defaults.defaultFontSize ?? 14
  readonly property int notePadding: Dimensions.clampDimension(widgetData?.padding ?? _defaults.defaultPadding ?? 12, Dimensions.PADDING_MIN, Dimensions.PADDING_MAX)

  // Hex STRINGS (not color objects) for markdown.js theming: the parser reads
  // them as strings to derive the quote background and adapt to dark/light.
  readonly property string noteBgHex: widgetData?.bgColor ?? _defaults.defaultBgColor ?? "#FFF9C4"
  readonly property string noteFgHex: widgetData?.textColor ?? _defaults.defaultTextColor ?? "#37474F"

  // Independent base width/height per note (REQ-009 spirit). The base class still
  // multiplies by widgetScale (uniform corner-scale), so the corner handle zooms
  // both while these sliders set the proportions. Clamped against corrupt data.
  readonly property int noteWidth: Dimensions.clampDimension(widgetData?.noteWidth ?? _defaults.defaultWidth ?? 200, Dimensions.WIDTH_MIN, Dimensions.WIDTH_MAX)
  readonly property int noteHeight: Dimensions.clampDimension(widgetData?.noteHeight ?? _defaults.defaultHeight ?? 140, Dimensions.HEIGHT_MIN, Dimensions.HEIGHT_MAX)
  implicitWidth: Math.round(noteWidth * widgetScale)
  implicitHeight: Math.round(noteHeight * widgetScale)
  width: implicitWidth
  height: implicitHeight

  // Reads the linked .md file (REQ-011) and watches it for external edits (REQ-013).
  // Read-only: it never calls setText, so watchChanges can never self-trigger a
  // reload loop (AD-006/C-008). A missing file (error 2) just leaves the note empty.
  FileView {
    id: noteFile
    path: root.linked ? root.noteFilePath : ""
    watchChanges: root.linked
    printErrors: false
    onLoaded: root.fileContent = noteFile.text()
    onFileChanged: {
      noteFile.reload();
      root.fileContent = noteFile.text();
    }
    onLoadFailed: function (error) {
      root.fileContent = "";
    }
  }

  Rectangle {
    anchors.fill: parent
    // Square corners: real post-its are not rounded.
    radius: 0
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
      // Font does NOT scale with widgetScale (REQ-009): scaling the box reveals
      // more/less text at a constant readable size, it does not magnify text.
      pointSize: Style.fontSizeM
    }

    // Read-only Markdown preview inside a wheel-scrollable Flickable (long notes).
    // The Flickable is non-interactive so it never grabs drags: clicks reach the
    // MouseArea below (edit) and drags reach the base drag/scale handles in edit
    // mode (C-002). Scrolling is driven by the MouseArea's wheel handler.
    Flickable {
      id: noteFlick
      anchors.fill: parent
      anchors.margins: Math.round(root.notePadding * root.widgetScale)
      visible: root.noteText !== ""
      interactive: false
      clip: true
      contentWidth: width
      contentHeight: notePreview.implicitHeight
      boundsBehavior: Flickable.StopAtBounds

      // Visual indicator only (drag is intercepted by the edit MouseArea above);
      // shown whenever the content overflows. Scrolling is driven by the wheel.
      ScrollBar.vertical: ScrollBar {
        policy: noteFlick.contentHeight > noteFlick.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        width: Math.round(6 * root.widgetScale)
      }

      Text {
        id: notePreview
        width: noteFlick.width
        text: Markdown.render(root.noteText, Palette.markdownTheme(root.noteBgHex, root.noteFgHex))
        textFormat: Text.RichText
        color: root.noteTextColor
        // Constant font size, independent of widgetScale (REQ-009). The note box
        // grows with widgetScale (more room for text), the text stays readable.
        font.pointSize: root.noteFontSize
        wrapMode: Text.Wrap
        verticalAlignment: Text.AlignTop
      }
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
          // When linked, hand the file content to the editor (file wins, REQ-014).
          "text": root.noteText,
          "filePath": root.noteFilePath,
          "bgColor": root.widgetData?.bgColor ?? "#FFF9C4",
          "textColor": root.widgetData?.textColor ?? "#37474F",
          "fontSize": root.widgetData?.fontSize ?? 14,
          "noteWidth": root.noteWidth,
          "noteHeight": root.noteHeight,
          "padding": root.notePadding
        });
      }
      root.pluginApi?.openPanel(root.screen);
    }
    onWheel: wheel => {
      noteFlick.contentY = Scroll.clampScroll(noteFlick.contentY - wheel.angleDelta.y, noteFlick.contentHeight, noteFlick.height);
    }
  }
}
