import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "utils/markdown.js" as Markdown
import "utils/palette.js" as Palette
import "utils/dimensions.js" as Dimensions

// The note editor. Loaded by PluginPanelSlot inside a SmartPanel (a real shell
// window), which is why it gets keyboard focus (AD-003). It reads the active note
// from the Main.qml store and writes back by index via updateWidgetData (AD-002).
Item {
  id: root
  property var pluginApi: null
  readonly property var store: pluginApi?.mainInstance

  // SmartPanel sizes the panel from these, not implicitWidth/implicitHeight.
  property int contentPreferredWidth: Math.round(560 * Style.uiScaleRatio)
  property int contentPreferredHeight: Math.round(640 * Style.uiScaleRatio)
  implicitWidth: contentPreferredWidth
  implicitHeight: contentPreferredHeight

  // The panel keeps the default (dark) surface so the themed sliders, labels and
  // pickers stay legible; the note color lives on the editing surface instead.

  // Open the editor centered on screen as a free-floating dialog, not docked to
  // the bar or anchored near the note (read by PluginPanelSlot -> SmartPanel).
  property bool panelAnchorHorizontalCenter: true
  property bool panelAnchorVerticalCenter: true
  property bool allowAttach: false

  readonly property string noteColor: store?.activeBgColor ?? "#FFF9C4"
  readonly property string noteTextColor: store?.activeTextColor ?? "#37474F"
  property bool editing: true

  function persist(props) {
    if (!store || store.activeWidgetIndex < 0)
      return;
    DesktopWidgetRegistry.updateWidgetData(store.activeScreenName, store.activeWidgetIndex, props);
  }

  function saveText() {
    persist({
      "text": editor.text
    });
  }

  function closeEditor() {
    saveText();
    if (root.pluginApi)
      root.pluginApi.closePanel(root.pluginApi.panelOpenScreen);
  }

  // Update the store (so the preview/panel retint live) AND persist the change.
  function setBg(hex) {
    if (store)
      store.activeBgColor = hex;
    persist({
      "bgColor": hex
    });
  }

  function setTextColor(hex) {
    if (store)
      store.activeTextColor = hex;
    persist({
      "textColor": hex
    });
  }

  function setFontSize(n) {
    if (store)
      store.activeFontSize = n;
    persist({
      "fontSize": n
    });
  }

  function setWidth(n) {
    if (store)
      store.activeWidth = n;
    persist({
      "noteWidth": n
    });
  }

  function setHeight(n) {
    if (store)
      store.activeHeight = n;
    persist({
      "noteHeight": n
    });
  }

  function colorToHex(c) {
    function h(x) {
      var s = Math.round(x * 255).toString(16);
      return s.length === 1 ? "0" + s : s;
    }
    return "#" + h(c.r) + h(c.g) + h(c.b);
  }

  // Load the active note's text and grab focus when the panel opens.
  Component.onCompleted: {
    if (root.store)
      editor.text = root.store.activeText;
    root.editing = true;
    focusTimer.restart();
  }

  Connections {
    target: root.store
    function onActiveChanged() {
      editor.text = root.store.activeText;
      root.editing = true;
      focusTimer.restart();
    }
  }

  // SmartPanel animates open, so defer focus a beat to ensure the window is mapped.
  Timer {
    id: focusTimer
    interval: 120
    onTriggered: if (root.editing)
      editor.forceActiveFocus()
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginM
    spacing: Style.marginS

    // Toolbar: edit/preview toggle + close.
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      Item {
        Layout.fillWidth: true
      }

      NIconButton {
        icon: root.editing ? "check" : "pencil"
        tooltipText: root.editing ? (root.pluginApi?.tr("editor.save-preview") ?? "Save & preview") : (root.pluginApi?.tr("editor.edit") ?? "Edit")
        onClicked: {
          if (root.editing) {
            root.saveText();
            root.editing = false;
          } else {
            root.editing = true;
            editor.forceActiveFocus();
            editor.cursorPosition = editor.text.length;
          }
        }
      }

      NIconButton {
        icon: "close"
        tooltipText: root.pluginApi?.tr("editor.save-close") ?? "Save & close"
        onClicked: root.closeEditor()
      }
    }

    // Editor / preview area.
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: Style.radiusM
      // The editing/preview surface carries the note color (WYSIWYG, readable
      // dark text); the surrounding panel chrome stays on the default dark surface.
      color: root.noteColor
      border.width: root.editing ? Style.borderM : Style.borderS
      border.color: root.editing ? (editor.activeFocus ? Qt.darker(Color.mPrimary, 1.35) : Color.mPrimary) : Qt.rgba(0, 0, 0, 0.08)

      Behavior on border.color {
        ColorAnimation {
          duration: 150
        }
      }

      Item {
        anchors.fill: parent
        anchors.margins: Style.marginS

        // Preview (read-only RichText).
        NScrollView {
          anchors.fill: parent
          visible: !root.editing
          ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

          TextArea {
            text: Markdown.render(editor.text, {
              "noteColor": root.noteColor
            })
            textFormat: TextEdit.RichText
            color: root.noteTextColor
            font.pointSize: Style.fontSizeM * Style.uiScaleRatio
            wrapMode: TextArea.Wrap
            readOnly: true
            selectByMouse: true
            background: Item {}
            onLinkActivated: link => Qt.openUrlExternally(link)
          }
        }

        // Editor.
        NScrollView {
          anchors.fill: parent
          visible: root.editing
          ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

          TextArea {
            id: editor
            color: "#3E2723"
            font.pointSize: Style.fontSizeM * Style.uiScaleRatio
            wrapMode: TextArea.Wrap
            selectByMouse: true
            selectByKeyboard: true
            persistentSelection: true
            placeholderText: root.pluginApi?.tr("editor.placeholder") ?? "Write in Markdown..."
            background: Item {}

            Shortcut {
              sequences: [StandardKey.Copy]
              enabled: editor.activeFocus
              onActivated: editor.copy()
            }
            Shortcut {
              sequences: [StandardKey.Cut]
              enabled: editor.activeFocus
              onActivated: editor.cut()
            }
            Shortcut {
              sequences: [StandardKey.Paste]
              enabled: editor.activeFocus
              onActivated: editor.paste()
            }
            Shortcut {
              sequences: [StandardKey.SelectAll]
              enabled: editor.activeFocus
              onActivated: editor.selectAll()
            }
            Shortcut {
              sequences: [StandardKey.Undo]
              enabled: editor.activeFocus
              onActivated: editor.undo()
            }
            Shortcut {
              sequences: [StandardKey.Redo]
              enabled: editor.activeFocus
              onActivated: editor.redo()
            }

            Keys.onPressed: event => {
              if (event.key === Qt.Key_S && (event.modifiers & Qt.ControlModifier)) {
                root.saveText();
                event.accepted = true;
              } else if (event.key === Qt.Key_Escape) {
                root.closeEditor();
                event.accepted = true;
              }
            }
          }
        }
      }
    }

    // Customization: background swatches + text color + font size.
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      Repeater {
        model: Palette.PALETTE

        delegate: Rectangle {
          required property string modelData
          width: Math.round(24 * Style.uiScaleRatio)
          height: width
          radius: width / 2
          color: modelData
          border.width: root.noteColor === modelData ? 2 : 1
          border.color: root.noteColor === modelData ? Color.mPrimary : Qt.rgba(0, 0, 0, 0.2)

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.setBg(parent.modelData)
          }
        }
      }

      Item {
        Layout.fillWidth: true
      }

      NColorPicker {
        selectedColor: root.noteTextColor
        onColorSelected: c => root.setTextColor(root.colorToHex(c))
      }
    }

    NValueSlider {
      Layout.fillWidth: true
      property real _value: root.store?.activeFontSize ?? 14

      from: 10
      to: 28
      stepSize: 1
      value: _value
      label: root.pluginApi?.tr("editor.font-size-label") ?? "Font size"
      text: root.pluginApi?.tr("editor.font-size", {
        "value": Math.round(_value)
      }) ?? `${Math.round(_value)} px`
      onMoved: v => _value = v
      onPressedChanged: (pressed, v) => {
        if (!pressed)
          root.setFontSize(Math.round(v));
      }
    }

    NValueSlider {
      Layout.fillWidth: true
      property real _value: root.store?.activeWidth ?? 200

      from: Dimensions.WIDTH_MIN
      to: Dimensions.WIDTH_MAX
      stepSize: 10
      value: _value
      label: root.pluginApi?.tr("editor.width-label") ?? "Width"
      text: `${Math.round(_value)} px`
      onMoved: v => _value = v
      onPressedChanged: (pressed, v) => {
        if (!pressed)
          root.setWidth(Math.round(v));
      }
    }

    NValueSlider {
      Layout.fillWidth: true
      property real _value: root.store?.activeHeight ?? 140

      from: Dimensions.HEIGHT_MIN
      to: Dimensions.HEIGHT_MAX
      stepSize: 10
      value: _value
      label: root.pluginApi?.tr("editor.height-label") ?? "Height"
      text: `${Math.round(_value)} px`
      onMoved: v => _value = v
      onPressedChanged: (pressed, v) => {
        if (!pressed)
          root.setHeight(Math.round(v));
      }
    }
  }
}
