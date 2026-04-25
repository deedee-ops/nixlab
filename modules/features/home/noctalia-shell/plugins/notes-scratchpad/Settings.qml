import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null

  // Local state
  property real panelWidth: pluginApi?.pluginSettings?.panelWidth ?? 0.4
  property real panelHeight: pluginApi?.pluginSettings?.panelHeight ?? 0.3
  property int fontSize: pluginApi?.pluginSettings?.fontSize ?? 14
  property string filePath: pluginApi?.pluginSettings?.filePath ?? ""
  property bool filePathWritable: true
  property bool useMonospace: pluginApi?.pluginSettings?.useMonospace ?? false

  spacing: Style.marginM

  // Check file path writability
  Process {
    id: writeCheckProcess

    onExited: function(exitCode, exitStatus) {
      root.filePathWritable = (exitCode === 0);
    }
  }

  function checkFilePathWritability() {
    if (root.filePath === "") {
      root.filePathWritable = true;
      return;
    }

    // Check if file exists and is writable, or if parent directory is writable
    var testCmd = "if [ -e \"" + root.filePath + "\" ]; then " +
                  "[ -w \"" + root.filePath + "\" ]; " +
                  "else " +
                  "[ -w \"$(dirname \"" + root.filePath + "\")\" ]; " +
                  "fi";
    writeCheckProcess.exec(["sh", "-c", testCmd]);
  }

  function saveSettings() {
    if (pluginApi) {
      pluginApi.pluginSettings.panelWidth = root.panelWidth
      pluginApi.pluginSettings.panelHeight = root.panelHeight
      pluginApi.pluginSettings.fontSize = root.fontSize
      pluginApi.pluginSettings.filePath = root.filePath
      pluginApi.pluginSettings.useMonospace = root.useMonospace
      pluginApi.saveSettings();
    }
  }

  onFilePathChanged: {
    checkFilePathWritability();
  }

  // UI Components
  NLabel {
    label: pluginApi?.tr("settings.panel_dimensions.title") || "Panel Dimensions"
    description: pluginApi?.tr("settings.panel_dimensions.description") || "Configure the size of the scratchpad panel when it opens."
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginL

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NText {
        text: {
          var w = root.panelWidth;
          return (pluginApi?.tr("settings.panel_dimensions.width") || "Width") + ": " +
                 (w <= 1.0 ? Math.round(w * 100) + "%" : Math.round(w) + "px");
        }
        pointSize: Style.fontSizeM
      }

      TextField {
        id: widthField
        Layout.fillWidth: true
        text: root.panelWidth.toString()
        placeholderText: "e.g. 600 or 0.5"
        onEditingFinished: {
          var v = parseFloat(text);
          if (!isNaN(v) && v > 0) {
            root.panelWidth = v;
            saveSettings();
          }
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NText {
        text: {
          var h = root.panelHeight;
          return (pluginApi?.tr("settings.panel_dimensions.height") || "Height") + ": " +
                 (h <= 1.0 ? Math.round(h * 100) + "%" : Math.round(h) + "px");
        }
        pointSize: Style.fontSizeM
      }

      TextField {
        id: heightField
        Layout.fillWidth: true
        text: root.panelHeight.toString()
        placeholderText: "e.g. 400 or 0.3"
        onEditingFinished: {
          var v = parseFloat(text);
          if (!isNaN(v) && v > 0) {
            root.panelHeight = v;
            saveSettings();
          }
        }
      }
    }
  }

  NText {
    text: pluginApi?.tr("settings.panel_dimensions.hint") ||
          "Values > 1 are pixels; values ≤ 1 are screen percentage (0.5 = 50%)"
    pointSize: Style.fontSizeS
    color: Color.mOnSurfaceVariant
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS
    Layout.topMargin: Style.marginM

    NTextInputButton {
      label: pluginApi?.tr("settings.file_storage.title") || "File Storage"
      description: pluginApi?.tr("settings.file_storage.description") || "Optionally save scratchpad content to a file instead of plugin storage. Leave empty to use default storage."
      placeholderText: "/home/user/notes.txt"
      text: root.filePath
      buttonIcon: "file"
      buttonTooltip: pluginApi?.tr("settings.file_storage.select") || "Select file"
      onInputEditingFinished: root.filePath = text
      onButtonClicked: filePicker.openFilePicker()
    }

    NText {
      visible: root.filePath !== "" && !root.filePathWritable
      text: pluginApi?.tr("settings.file_storage.not_writable") || "⚠ Warning: No write permission for this location"
      pointSize: Style.fontSizeS
      color: Color.mError
      Layout.fillWidth: true
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS
    Layout.topMargin: Style.marginM

    NText {
      text: pluginApi?.tr("settings.text_appearance.title") || "Text Appearance"
      pointSize: Style.fontSizeL
      font.weight: Font.DemiBold
    }

    NText {
      text: (pluginApi?.tr("settings.text_appearance.font_size") || "Font Size") + ": " + root.fontSize + "px"
      pointSize: Style.fontSizeM
    }

    NSlider {
      id: fontSizeSlider
      Layout.fillWidth: true
      from: 10
      to: 24
      value: root.fontSize
      stepSize: 1
      onMoved: {
        root.fontSize = Math.round(value)
      }
    }

    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.text_appearance.monospace") || "Monospace Font"
      description: pluginApi?.tr("settings.text_appearance.monospace_description") || "Use a monospace font for the text area"
      checked: root.useMonospace
      onToggled: checked => root.useMonospace = checked
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS
    Layout.topMargin: Style.marginL

    NLabel {
      label: pluginApi?.tr("settings.keyboard_shortcut.title") || "Keyboard Shortcut"
      description: pluginApi?.tr("settings.keyboard_shortcut.description") || "Toggle the scratchpad panel with this command:"
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: commandText.implicitHeight + Style.marginM * 2
      color: Color.mSurfaceVariant
      radius: Style.radiusM

      TextEdit {
        id: commandText
        anchors.fill: parent
        anchors.margins: Style.marginM
        text: "qs -c noctalia-shell ipc call plugin:notes-scratchpad togglePanel"
        font.pointSize: Style.fontSizeS
        font.family: Settings.data.ui.fontFixed
        color: Color.mPrimary
        wrapMode: TextEdit.WrapAnywhere
        readOnly: true
        selectByMouse: true
        selectionColor: Color.mPrimary
        selectedTextColor: Color.mOnPrimary
      }
    }
  }

  NFilePicker {
    id: filePicker
    selectionMode: "files"
    title: pluginApi?.tr("settings.file_storage.picker_title") || "Choose file for scratchpad"
    initialPath: root.filePath || Quickshell.env("HOME")
    onAccepted: paths => {
      if (paths.length > 0) {
        root.filePath = paths[0]
      }
    }
  }
}
