"use strict";
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/current-track.ts
var current_track_exports = {};
__export(current_track_exports, {
  default: () => Command
});
module.exports = __toCommonJS(current_track_exports);
var import_api2 = require("@vicinae/api");

// src/supersonic.ts
var import_api = require("@vicinae/api");
var import_child_process = require("child_process");
var import_util = require("util");
var import_os = require("os");
var execFileAsync = (0, import_util.promisify)(import_child_process.execFile);
function resolvePath(p) {
  return p.replace(/\$\{USER\}|\$USER\b/g, (0, import_os.userInfo)().username).replace(/^~(?=\/|$)/, (0, import_os.homedir)());
}
function binaryPath() {
  const { supersonicPath } = (0, import_api.getPreferenceValues)();
  return resolvePath(supersonicPath || "supersonic");
}
function isNoIpcError(err) {
  const e = err;
  const haystack = `${e.stderr ?? ""} ${e.message ?? ""}`;
  return /no IPC connection/i.test(haystack);
}
async function notRunningToast() {
  await (0, import_api.showToast)({
    style: import_api.Toast.Style.Failure,
    title: "Supersonic is not running",
    message: "Launch Supersonic and try again"
  });
}
var ENV_VARS_TO_LOG = [
  "XDG_RUNTIME_DIR",
  "WAYLAND_DISPLAY",
  "DISPLAY",
  "DBUS_SESSION_BUS_ADDRESS",
  "HOME",
  "USER"
];
function logEnv() {
  const env = Object.fromEntries(
    ENV_VARS_TO_LOG.map((k) => [k, process.env[k] ?? "(unset)"])
  );
  console.debug("[supersonic:env]", JSON.stringify(env));
}
async function captureStdout(args) {
  const bin = binaryPath();
  console.debug("[supersonic]", bin, ...args);
  logEnv();
  try {
    const { stdout, stderr } = await execFileAsync(bin, args, {
      maxBuffer: 16 * 1024 * 1024
    });
    if (stderr) console.debug("[supersonic:stderr]", stderr.trim());
    return stdout;
  } catch (err) {
    const e = err;
    console.debug("[supersonic:error]", JSON.stringify({ code: e.code, stderr: e.stderr, message: e.message }));
    throw err;
  }
}
function artistLabel(names) {
  return (names ?? []).join(", ");
}
function durationSeconds(nanoseconds) {
  if (!nanoseconds) return 0;
  return Math.round(nanoseconds / 1e9);
}
function formatDuration(seconds) {
  if (!seconds) return "";
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, "0")}`;
}
function trackArtistLabel(track) {
  return artistLabel(track.ArtistNames);
}
async function currentTrack() {
  try {
    const raw = await captureStdout(["--current-track"]);
    const trimmed = raw.trim();
    if (!trimmed || trimmed === "null") return null;
    return JSON.parse(trimmed);
  } catch (err) {
    if (isNoIpcError(err)) {
      await notRunningToast();
      return null;
    }
    throw err;
  }
}

// src/current-track.ts
async function Command() {
  const track = await currentTrack();
  if (!track) {
    await (0, import_api2.showToast)({
      style: import_api2.Toast.Style.Success,
      title: "Nothing playing"
    });
    return;
  }
  const artist = trackArtistLabel(track);
  const parts = [artist, track.Album].filter(Boolean);
  const secs = durationSeconds(track.Duration);
  if (secs) parts.push(formatDuration(secs));
  await (0, import_api2.showToast)({
    style: import_api2.Toast.Style.Success,
    title: track.Title,
    message: parts.join(" \xB7 ") || void 0
  });
}
