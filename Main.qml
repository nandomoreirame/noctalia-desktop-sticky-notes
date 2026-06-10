import QtQuick

// Lightweight per-plugin store. There is a single shared Panel editor but N note
// instances, so the clicked note records its identity AND a snapshot of its data
// here; the Panel reads this to populate the editor and writes back by index
// via updateWidgetData (AD-002).
Item {
  id: root
  property var pluginApi: null

  // Identity of the note currently being edited.
  property string activeScreenName: ""
  property int activeWidgetIndex: -1

  // Snapshot of the active note's data, pushed by the widget on click.
  property string activeText: ""
  property string activeBgColor: "#FFF9C4"
  property string activeTextColor: "#37474F"
  property int activeFontSize: 14
  property int activeWidth: 200
  property int activeHeight: 140

  // Emitted on every setActive so an already-open Panel can reload.
  signal activeChanged

  function setActive(screenName, widgetIndex, data) {
    activeScreenName = screenName;
    activeWidgetIndex = widgetIndex;

    var d = data || {};
    activeText = (d.text !== undefined && d.text !== null) ? d.text : "";
    activeBgColor = d.bgColor || "#FFF9C4";
    activeTextColor = d.textColor || "#37474F";
    activeFontSize = (d.fontSize !== undefined && d.fontSize !== null) ? d.fontSize : 14;
    activeWidth = (d.noteWidth !== undefined && d.noteWidth !== null) ? d.noteWidth : 200;
    activeHeight = (d.noteHeight !== undefined && d.noteHeight !== null) ? d.noteHeight : 140;

    activeChanged();
  }
}
