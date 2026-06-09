import QtQuick

// Lightweight per-plugin store. Because there is a single shared Panel editor
// but N note instances, the note that was clicked records its identity here so
// the Panel knows which widgetData to write back to (AD-002).
Item {
  id: root
  property var pluginApi: null

  // Context of the note currently being edited.
  property string activeScreenName: ""
  property int activeWidgetIndex: -1

  function setActive(screenName, widgetIndex) {
    activeScreenName = screenName;
    activeWidgetIndex = widgetIndex;
  }
}
