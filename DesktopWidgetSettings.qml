import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets
import "utils/palette.js" as Palette
import "utils/filepath.js" as FilePath

// Per-instance customization shown in the desktop widget context menu (edit mode):
// background color, text color, font size and the optional base background.
// Text content itself is owned by the Panel editor, not here.
ColumnLayout {
  id: root
  spacing: Style.marginM

  property var pluginApi: null
  property var widgetSettings: null

  property string bgColor: widgetSettings?.data?.bgColor ?? widgetSettings?.metadata?.defaultBgColor ?? "#FFF9C4"
  property string textColor: widgetSettings?.data?.textColor ?? widgetSettings?.metadata?.defaultTextColor ?? "#37474F"
  property int fontSize: widgetSettings?.data?.fontSize ?? widgetSettings?.metadata?.defaultFontSize ?? 14
  // Optional .md file backing this note. Empty = inline text (REQ-010/AD-005).
  property string filePath: widgetSettings?.data?.filePath ?? widgetSettings?.metadata?.defaultFilePath ?? ""

  function colorToHex(c) {
    function h(x) {
      var s = Math.round(x * 255).toString(16);
      return s.length === 1 ? "0" + s : s;
    }
    return "#" + h(c.r) + h(c.g) + h(c.b);
  }

  function saveSettings() {
    if (widgetSettings == undefined || widgetSettings.data == undefined)
      return;
    widgetSettings.data.bgColor = bgColor;
    widgetSettings.data.textColor = textColor;
    widgetSettings.data.fontSize = fontSize;
    widgetSettings.data.filePath = filePath;
    widgetSettings.save();
  }

  // Markdown file source: link this note to a .md file on disk (REQ-010). Empty
  // keeps the note's text inline (default). Text field accepts any path (~ allowed);
  // the picker filters to markdown/text; the clear button unlinks (file is kept).
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: root.pluginApi?.tr("settings.file-source-label") ?? "Markdown file"
      description: root.pluginApi?.tr("settings.file-source-description") ?? "Back this note with a .md file. Leave empty to store the text inline."
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NTextInput {
        Layout.fillWidth: true
        text: root.filePath
        placeholderText: "~/notes/todo.md"
        onEditingFinished: {
          root.filePath = text;
          root.saveSettings();
        }
      }

      NIconButton {
        icon: "wallpaper-selector"
        tooltipText: root.pluginApi?.tr("settings.file-source-pick") ?? "Choose a file"
        onClicked: filePicker.openFilePicker()
      }

      NIconButton {
        icon: "close"
        enabled: FilePath.isLinked(root.filePath)
        tooltipText: root.pluginApi?.tr("settings.file-source-clear") ?? "Unlink file"
        onClicked: {
          root.filePath = "";
          root.saveSettings();
        }
      }
    }

    NFilePicker {
      id: filePicker
      selectionMode: "files"
      nameFilters: ["*.md", "*.markdown", "*.txt"]
      title: root.pluginApi?.tr("settings.file-source-label") ?? "Markdown file"
      onAccepted: paths => {
        if (paths.length > 0) {
          root.filePath = paths[0];
          root.saveSettings();
        }
      }
    }
  }

  // Background color swatches.
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: root.pluginApi?.tr("settings.background-label") ?? "Background color"
      description: root.pluginApi?.tr("settings.background-description") ?? "Pick a post-it color for the note."
    }

    RowLayout {
      spacing: Style.marginS

      Repeater {
        model: Palette.PALETTE

        delegate: Rectangle {
          required property string modelData
          width: Math.round(26 * Style.uiScaleRatio)
          height: width
          radius: width / 2
          color: modelData
          border.width: root.bgColor === modelData ? 2 : 1
          border.color: root.bgColor === modelData ? Color.mPrimary : Qt.rgba(0, 0, 0, 0.2)

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.bgColor = parent.modelData;
              root.saveSettings();
            }
          }
        }
      }
    }
  }

  // Text color.
  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.text-color-label") ?? "Text color"
      description: root.pluginApi?.tr("settings.text-color-description") ?? "Color of the note text."
    }

    NColorPicker {
      selectedColor: root.textColor
      onColorSelected: c => {
        root.textColor = root.colorToHex(c);
        root.saveSettings();
      }
    }
  }

  // Font size.
  NValueSlider {
    Layout.fillWidth: true
    property real _value: root.fontSize

    from: 10
    to: 28
    stepSize: 1
    value: _value
    text: `${Math.round(_value)} px`
    label: root.pluginApi?.tr("settings.font-size-label") ?? "Font size"
    description: root.pluginApi?.tr("settings.font-size-description") ?? "Text size, independent of the widget scale."
    onMoved: v => _value = v
    onPressedChanged: (pressed, v) => {
      if (!pressed) {
        root.fontSize = Math.round(v);
        root.saveSettings();
      }
    }
  }

}
