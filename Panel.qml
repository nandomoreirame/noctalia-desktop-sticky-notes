import QtQuick
import qs.Commons
import qs.Services.UI
import qs.Widgets

// Spike editor (Task 4): a minimal focused popup that writes a single field back
// to the active note via updateWidgetData. Loaded by PluginPanelSlot inside a
// SmartPanel (a real shell window), which is why it gets keyboard focus (AD-003).
// Replaced by the full editor in Task 7.
Item {
  id: root
  property var pluginApi: null
  readonly property var store: pluginApi?.mainInstance

  // SmartPanel sizes the panel from these, not implicitWidth/implicitHeight.
  property int contentPreferredWidth: 420
  property int contentPreferredHeight: 240
  implicitWidth: contentPreferredWidth
  implicitHeight: contentPreferredHeight

  Rectangle {
    anchors.fill: parent
    color: Color.mSurface
    radius: Style.radiusL

    Column {
      anchors.centerIn: parent
      spacing: Style.marginM

      NTextInput {
        id: input
        width: 320
        text: ""
      }

      NButton {
        text: "Save"
        onClicked: {
          var s = root.store;
          if (s && s.activeWidgetIndex >= 0) {
            DesktopWidgetRegistry.updateWidgetData(s.activeScreenName, s.activeWidgetIndex, {
              "text": input.text
            });
          }
          // closePanel needs the ShellScreen the panel is open on, not null.
          if (root.pluginApi) {
            root.pluginApi.closePanel(root.pluginApi.panelOpenScreen);
          }
        }
      }
    }
  }
}
