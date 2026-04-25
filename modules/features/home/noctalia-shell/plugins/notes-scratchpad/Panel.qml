import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: {
    var w = pluginApi?.pluginSettings?.panelWidth ?? 0.4;
    if (w > 1.0) return w * Style.uiScaleRatio;
    var sw = screen?.virtualGeometry?.width
             ?? Qt.application.screens[0]?.width
             ?? 1920;
    return w * sw;
  }
  property real contentPreferredHeight: {
    var h = pluginApi?.pluginSettings?.panelHeight ?? 0.3;
    if (h > 1.0) return h * Style.uiScaleRatio;
    var sh = screen?.virtualGeometry?.height
             ?? Qt.application.screens[0]?.height
             ?? 1080;
    return h * sh;
  }
  readonly property bool allowAttach: true
  anchors.fill: parent

  // ~/ is expanded to $HOME because Qt does not expand tilde automatically
  property string filePath: {
    var p = pluginApi?.pluginSettings?.filePath ?? "";
    if (p.startsWith("~/")) return Quickshell.env("HOME") + p.slice(1);
    return p;
  }
  property bool useFileStorage: filePath !== ""

  // Local state for the text content
  property string textContent: ""
  property int fontSize: pluginApi?.pluginSettings?.fontSize ?? 14
  property bool useMonospace: pluginApi?.pluginSettings?.useMonospace ?? false
  property int savedCursorPosition: pluginApi?.pluginSettings?.cursorPosition ?? 0
  property real savedScrollX: pluginApi?.pluginSettings?.scrollPositionX ?? 0
  property real savedScrollY: pluginApi?.pluginSettings?.scrollPositionY ?? 0
  property bool restoringState: false

  // FileView for reading external file storage
  FileView {
    id: externalFile
    path: root.filePath
    watchChanges: false

    onLoaded: {
      if (root.useFileStorage) {
        root.textContent = text() || "";
      }
    }

    onLoadFailed: function(error) {
      if (error !== 2) {
        Logger.w("NotesScratchpad", "Failed to load file:", root.filePath, "error:", error);
      }
    }
  }

  // Process for writing external file storage (FileView is read-only)
  Process {
    id: fileWriteProcess
    onExited: function(code, status) {
      if (code !== 0) {
        Logger.e("NotesScratchpad", "Failed to write file:", root.filePath, "exit code:", code);
      }
    }
  }

  // Auto-save timer
  Timer {
    id: saveTimer
    interval: 500
    repeat: false
    onTriggered: {
      if (pluginApi && !restoringState) {
        saveContent();
      }
    }
  }

  function saveContent() {
    if (!pluginApi) return;

    if (root.useFileStorage) {
      var content = root.textContent;
      if (!content.endsWith("\n")) content += "\n";
      fileWriteProcess.environment = { "SCRATCHPAD_CONTENT": content, "SCRATCHPAD_FILE": root.filePath };
      fileWriteProcess.exec(["sh", "-c", "printf '%s' \"$SCRATCHPAD_CONTENT\" > \"$SCRATCHPAD_FILE\""]);
    } else {
      pluginApi.pluginSettings.scratchpadContent = root.textContent;
    }

    // Always save cursor and scroll positions to settings
    pluginApi.pluginSettings.cursorPosition = textArea.cursorPosition;
    pluginApi.pluginSettings.scrollPositionX = scrollView.ScrollBar.horizontal.position;
    pluginApi.pluginSettings.scrollPositionY = scrollView.ScrollBar.vertical.position;
    pluginApi.saveSettings();
  }

  onTextContentChanged: {
    if (!restoringState) {
      saveTimer.restart();
    }
  }

  onFilePathChanged: {
    if (useFileStorage) {
      externalFile.reload();
    }
  }

  Component.onCompleted: {
    restoringState = true;

    if (pluginApi) {
      if (root.useFileStorage) {
        externalFile.reload();
      } else {
        textContent = pluginApi.pluginSettings.scratchpadContent || "";
      }

      savedCursorPosition = pluginApi.pluginSettings.cursorPosition ?? 0;
      savedScrollX = pluginApi.pluginSettings.scrollPositionX ?? 0;
      savedScrollY = pluginApi.pluginSettings.scrollPositionY ?? 0;
    }

    Qt.callLater(() => {
      textArea.forceActiveFocus();
      textArea.cursorPosition = savedCursorPosition;
      scrollView.ScrollBar.horizontal.position = savedScrollX;
      scrollView.ScrollBar.vertical.position = savedScrollY;
      restoringState = false;
    });
  }

  Component.onDestruction: {
    if (pluginApi) {
      saveContent();
    }
  }

  onPluginApiChanged: {
    if (pluginApi && !root.useFileStorage) {
      textContent = pluginApi.pluginSettings.scratchpadContent || "";
    }
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"
    radius: Style.radiusL

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NIcon {
          icon: "file-text"
          pointSize: Style.fontSizeL
        }

        NText {
          text: {
            if (root.useFileStorage && root.filePath) {
              var parts = root.filePath.split("/");
              return parts[parts.length - 1];
            }
            return pluginApi?.tr("panel.header.title") || "Scratchpad";
          }
          pointSize: Style.fontSizeL
          font.weight: Font.Bold
          Layout.fillWidth: true
        }

        NIconButton {
          icon: "x"
          onClicked: {
            if (pluginApi) {
              pluginApi.closePanel(pluginApi.panelOpenScreen)
            }
          }
        }
      }

      // Main text area
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurfaceVariant
        radius: Style.radiusM
        border.color: Color.mOutline
        border.width: 1

        NScrollView {
          id: scrollView
          anchors.fill: parent
          anchors.margins: Style.marginM
          handleWidth: 5

          ScrollBar.horizontal.onPositionChanged: {
            if (!restoringState) saveTimer.restart();
          }
          ScrollBar.vertical.onPositionChanged: {
            if (!restoringState) saveTimer.restart();
          }

          TextArea {
            id: textArea
            text: root.textContent
            placeholderText: pluginApi?.tr("panel.placeholder") || "Start typing your notes here..."
            wrapMode: TextArea.Wrap
            selectByMouse: true
            color: Color.mOnSurface
            font.pixelSize: root.fontSize
            font.family: root.useMonospace ? Settings.data.ui.fontFixed : Settings.data.ui.fontDefault
            background: Item {}
            focus: true

            onTextChanged: {
              if (text !== root.textContent) {
                root.textContent = text;
              }
            }

            onCursorPositionChanged: {
              if (!restoringState) saveTimer.restart();
            }
          }
        }
      }

      // Character count
      NText {
        text: {
          var chars = textArea.text.length;
          var words = textArea.text.trim().split(/\s+/).filter(w => w.length > 0).length;
          var charText = pluginApi?.tr("panel.stats.characters") || "characters";
          var wordText = pluginApi?.tr("panel.stats.words") || "words";
          return chars + " " + charText + " · " + words + " " + wordText;
        }
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        Layout.alignment: Qt.AlignRight
      }
    }
  }
}
