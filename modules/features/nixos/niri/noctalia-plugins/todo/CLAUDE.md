# CLAUDE.md — Noctalia Todo Plugin

## What this is

A [Noctalia Shell](https://github.com/noctalia-dev/noctalia-plugins) plugin for managing a todo list. Built with QML/Quickshell. Entry points:

| File | Role |
|------|------|
| `Main.qml` | Business logic, persistence, IPC handlers |
| `Panel.qml` | Primary UI panel (full todo management) |
| `Settings.qml` | Plugin settings UI |
| `BarWidget.qml` | Taskbar icon showing active todo count |
| `DesktopWidget.qml` | Desktop overlay widget |
| `ControlCenterWidget.qml` | Control center button |
| `manifest.json` | Plugin metadata and default settings |

## What we did in this session

**Goal:** Migrate todo/page storage from Quickshell's `pluginSettings` blob (machine-local) to a user-configured JSON file, so todos can be synced across machines via Syncthing.

### Changes made

**`manifest.json`**

- Added `todoFilePath: "~/Sync/sync/noctalia/todo.json"` to `defaultSettings`

**`Main.qml`** — storage layer rewrite

- Added 4 new state properties: `readBuffer`, `isWritingFile`, `pendingWrite`, `fileErrorShown`
- Added `fileReadProcess`: reads the JSON file via `cat` using `SplitParser` stdout capture
- Added `fileWriteProcess`: writes atomically via `printf | base64 -d > file.tmp && mv file.tmp file`
- Added `filePollingTimer`: 30-second timer that re-reads the file to pick up external changes (e.g. Syncthing delivery)
- Rewrote `Component.onCompleted`: removed todos/pages init from pluginSettings, added `todoFilePath` init, replaced synchronous load with `readTodosFile()` + timer start
- Updated `saveTodos()` and `savePages()`: both now call `writeTodosFile()` in addition to mirroring to `pluginSettings`
- Added new functions: `resolveFilePath`, `readTodosFile`, `writeTodosFile`, `createTodosFile`, `applyFileData`, `showFileError`, `reloadTodosFile`

**`Settings.qml`**

- Added `valueTodoFilePath` property
- Added "Sync File Path" `NTextInputButton` + `NFilePicker` at the top of the settings form
- Changing the path calls `mainInstance.reloadTodosFile()` immediately

### Architecture decision: mirroring to pluginSettings

Todos and pages are written to the JSON file (authoritative source) AND mirrored back into `pluginApi.pluginSettings.todos` / `.pages` on every load/save. This is intentional: `Panel.qml` and `DesktopWidget.qml` have reactive bindings on `pluginSettings.todos` that trigger UI reloads. Without the mirror, those components would not react to file-based changes without modification. The mirror avoids touching Panel.qml/DesktopWidget.qml entirely.

`pluginSettings.count` and `pluginSettings.completedCount` are also kept updated — `BarWidget.qml` and `ControlCenterWidget.qml` read these.

### JSON file format

```json
{
  "version": 1,
  "todos": [
    { "id": 1234567890, "text": "...", "completed": false, "createdAt": "2026-04-22T...", "pageId": 0, "priority": "medium", "details": "" }
  ],
  "pages": [
    { "id": 0, "name": "General" }
  ]
}
```

### What stays in pluginSettings (machine-specific, not synced)

- `todoFilePath` — path to the sync file (each machine configures its own)
- `showCompleted`, `showBackground`, `isExpanded` — UI state
- `useCustomColors`, `priorityColors` — appearance
- `exportPath`, `exportFormat`, `exportEmptySections` — export config
- `current_page_id` — currently selected page
- `count`, `completedCount` — derived counts (kept for BarWidget/ControlCenterWidget)

### What lives in the JSON file (synced via Syncthing)

- `todos` array
- `pages` array

## Key implementation details

### File read flow

`readTodosFile()` → `fileReadProcess` runs `[ -f "path" ] && cat "path" || exit 2` → on exit:

- code 0: parse JSON → `applyFileData()`
- code 2: file not found → `createTodosFile()` (writes defaults)
- other: `showFileError()` (once, suppressed on repeat polls)

### File write flow

`writeTodosFile()` → checks `isWritingFile` flag (sets `pendingWrite = true` if already writing) → base64-encodes JSON → `fileWriteProcess` runs atomic `printf | base64 -d > tmp && mv tmp target` → on exit: clears flag, triggers `pendingWrite` if set

### Polling

`filePollingTimer` fires every 30 seconds. If `isWritingFile` is true, the tick is skipped. On fire: calls `readTodosFile()`. If the file changed (external edit by Syncthing), `applyFileData()` updates `rawTodos`/`rawPages` and mirrors to `pluginSettings`, which triggers Panel/DesktopWidget reactive bindings.

### Error suppression

`fileErrorShown` flag ensures toast errors appear only once per error condition. It is reset to `false` on a successful read or when `reloadTodosFile()` is called.

### Path change in settings

Calls `mainInstance.reloadTodosFile()` → stops timer, clears `fileErrorShown`, calls `readTodosFile()`, restarts timer.

## Quickshell/QML notes

- `Quickshell.Io` is already imported in `Main.qml` — `Process` and `SplitParser` come from there
- `Process.running = true` triggers the process; it must be set to `false` in the definition and re-set to `true` to re-run
- `pluginApi.mainInstance` gives Settings.qml direct access to Main.qml's Item instance
- `pluginApi.saveSettings()` persists the entire `pluginSettings` blob to Quickshell's config directory (machine-local)
- `IpcHandler { target: "plugin:todo" }` exposes functions for CLI/external callers; `mainInstance` is for direct QML-to-QML calls

## Verification checklist

1. Start plugin on a fresh machine → `todo.json` created with `{"version":1,"todos":[],"pages":[{"id":0,"name":"General"}]}`
2. Create a todo → file updated atomically (no partial writes visible)
3. Create a page → file updated
4. Manually edit the JSON file → UI reflects changes within 30 seconds
5. Set an invalid/nonexistent path in settings → one error toast, no repeated spam on polls
6. Delete the file while plugin is running → next poll triggers `createTodosFile()` (re-creates it)
7. Change `todoFilePath` in settings → loads from new path immediately
8. Rapid creates/deletes → `pendingWrite` mechanism ensures no writes are lost

## Potential follow-up work

- Add a "Test connection" button in settings that reads the file and shows a success/failure toast
- Consider adding `current_page_id` to the sync file if users want the same page selected across machines
- If the Syncthing folder structure changes, the default path in `manifest.json` may need updating
