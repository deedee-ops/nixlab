# Notes Scratchpad — Noctalia Plugin

## Project Overview

This is a Noctalia shell plugin (`notes-scratchpad`) that provides a quick scratchpad panel accessible from the status bar or control center. Written in QML using the Quickshell/Noctalia framework.

**Plugin ID:** `notes-scratchpad`
**Version:** 1.1.6
**Min Noctalia Version:** 3.7.1

## Entry Points

| File | Role |
|---|---|
| `Main.qml` | Initializes settings on first run; IPC handler for `togglePanel` |
| `Panel.qml` | Main scratchpad panel UI (text area, header, stats footer) |
| `Settings.qml` | Plugin settings UI shown in Noctalia settings |
| `BarWidget.qml` | Icon button in the status bar |
| `ControlCenterWidget.qml` | Button in the control center |
| `manifest.json` | Plugin metadata and default settings |

## Key Settings (stored via `pluginApi.pluginSettings`)

| Key | Type | Default | Notes |
|---|---|---|---|
| `scratchpadContent` | string | `""` | Text content (if not using file storage) |
| `panelWidth` | real | `0.4` | > 1 = pixels, ≤ 1 = fraction of screen width |
| `panelHeight` | real | `0.3` | > 1 = pixels, ≤ 1 = fraction of screen height |
| `fontSize` | int | `14` | Font size in pixels |
| `cursorPosition` | int | `0` | Saved cursor position |
| `scrollPositionX` | real | `0` | Saved horizontal scroll position |
| `scrollPositionY` | real | `0` | Saved vertical scroll position |
| `filePath` | string | `""` | Optional external file path for content storage |
| `useMonospace` | bool | `false` | Use fixed-width font |

## Relative Dimension Feature (implemented)

`panelWidth` and `panelHeight` support both absolute and relative values:
- **> 1** → treated as pixels (e.g. `600` = 600px), scaled by `Style.uiScaleRatio`
- **≤ 1** → treated as a fraction of the screen (e.g. `0.5` = 50% of screen width/height)

**Panel.qml resolution logic (lines 16–31):**
```qml
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
```

**Key implementation notes (learned from debugging on a 4K/1.5× setup):**
- The Noctalia framework reads `contentPreferredWidth`/`contentPreferredHeight` **before** it sets the `screen` property on the Panel component — so `screen` is always `null` at evaluation time.
- `Qt.application.screens[0]?.width` is the correct fallback: it is available immediately at component creation and returns **logical pixel** dimensions (e.g. 2560 on a 3840px/1.5× monitor).
- `Style.uiScaleRatio` is **not** applied to relative values — the framework already works in logical pixels (`uiScaleRatio = 1` on a properly scaled Wayland session). Applying it would double-scale.
- `screen?.virtualGeometry` is still tried first so the binding stays reactive if Noctalia ever sets `screen` in time (multi-monitor future-proofing).

**Settings.qml** uses plain `TextField` inputs (no sliders) for width/height. The label above each field shows the value as `"40%"` or `"600px"` dynamically. A hint line below explains the rule.

## File Storage Feature (implemented)

When `filePath` is set, content is read from and written to an external file instead of `scratchpadContent` in plugin settings.

**Path handling** (`Panel.qml`): Qt does **not** expand `~` automatically. The `filePath` property explicitly expands `~/` to `Quickshell.env("HOME")`. Without this, `FileView` and the write `Process` both receive a literal `~` and fail silently.

**Loading** (`Panel.qml`): `FileView` reads the file via `externalFile.reload()` → `onLoaded` sets `root.textContent`. This triggers on `Component.onCompleted` and on `onFilePathChanged`.

**Saving** (`Panel.qml`): A `Process` object runs a shell write command. `saveContent()` is called by the 500ms debounce `saveTimer` (on text/scroll/cursor changes) and synchronously from `Component.onDestruction` on panel close.

**Write command used:**
```qml
fileWriteProcess.environment = { "SCRATCHPAD_CONTENT": content, "SCRATCHPAD_FILE": root.filePath };
fileWriteProcess.exec(["sh", "-c", "printf '%s' \"$SCRATCHPAD_CONTENT\" > \"$SCRATCHPAD_FILE\""]);
```
Content and path passed via env vars to avoid shell-escaping issues. `printf '%s'` does not interpret backslashes (unlike `%b`). Null bytes are not supported, but those won't appear in a text scratchpad. The forked OS process outlives the QML component, so writes initiated in `Component.onDestruction` complete even as the panel tears down.

**Critical Panel.qml pitfall fixed:**
`onPluginApiChanged` must guard with `!root.useFileStorage` — without it, the handler fires when the framework injects `pluginApi` and overwrites file-loaded content with the empty `scratchpadContent` from settings.

## Noctalia/Quickshell Framework Notes

- `Style.uiScaleRatio` — additional UI scaling factor on top of OS DPI scaling; `1` on a properly scaled Wayland session (OS handles HiDPI). Apply to absolute pixel values only — do **not** apply to values already derived from logical screen dimensions.
- `Style.fontSizeS/M/L`, `Style.marginS/M/L`, `Style.radiusM/L` — standard sizing tokens
- `Color.mSurface`, `Color.mOnSurface`, `Color.mPrimary`, etc. — Material You color tokens
- `pluginApi.saveSettings()` — persists `pluginApi.pluginSettings` to disk
- `pluginApi.openPanel(screen, widget)` / `pluginApi.closePanel(screen)` / `pluginApi.togglePanel(screen)` — panel lifecycle
- `pluginApi.tr("key")` — i18n translation lookup
- `ShellScreen` — represents a monitor; exposes `virtualGeometry` (a rect with `.width`/`.height`)
- Custom widgets available from `qs.Widgets`: `NText`, `NIcon`, `NIconButton`, `NLabel`, `NSlider`, `NToggle`, `NTextInputButton`, `NScrollView`, `NFilePicker`
- **`FileView` is read-only.** It has no `setText()` method. Calls to it throw a `TypeError` silently if wrapped in `try/catch`. Use `Process.exec()` to write files.
- **`Process.exec(command)`** — runs a one-shot command (array of args). Supports `environment` property (JS object). Used in `Settings.qml` for writability checks and in `Panel.qml` for file writes.

## i18n

Translation files live in `i18n/` (14 languages). Each defines keys under namespaces:
- `bar_widget.*`
- `panel.*`
- `settings.*`

New key added (not yet in translation files): `settings.panel_dimensions.hint` — falls back to `"Values > 1 are pixels; values ≤ 1 are screen percentage (0.5 = 50%)"`.

## IPC Toggle Command

```bash
qs -c noctalia-shell ipc call plugin:notes-scratchpad togglePanel
```
