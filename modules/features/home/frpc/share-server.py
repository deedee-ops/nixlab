"""Local file server behind frpc for `share`.

Serves the symlinks in --root under /<id>/ on 127.0.0.1, with single-range
support (resumable downloads), and reports every download as it starts and
ends, with the downloader's address.
"""

import argparse
import email.utils
import http.server
import os
import shutil
import subprocess
import sys
import threading
import time
import urllib.parse

CHUNK = 1 << 20


def human(size):
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if size < 1024 or unit == "TiB":
            return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} TiB"


def duration(seconds):
    seconds = int(seconds)
    if seconds < 60:
        return f"{seconds}s"
    if seconds < 3600:
        return f"{seconds // 60}m{seconds % 60:02d}s"
    return f"{seconds // 3600}h{seconds // 60 % 60:02d}m"


def parse_range(header, size):
    """Return (start, end) for a single byte range, None to serve the whole
    file, or False when the range cannot be satisfied."""
    if not header or not header.startswith("bytes=") or "," in header:
        return None
    first, _, last = header[len("bytes=") :].strip().partition("-")
    try:
        if not first:
            length = int(last)
            if length <= 0:
                return False
            return max(size - length, 0), size - 1
        start = int(first)
        end = int(last) if last else size - 1
    except ValueError:
        return None
    if start >= size or end < start:
        return False
    return start, min(end, size - 1)


class Server(http.server.ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, args):
        super().__init__(("127.0.0.1", 0), Handler)
        self.root = args.root
        self.prefix = "/" + args.id
        self.once = args.once
        self.probe = os.environ.get("SHARE_PROBE_TOKEN", "")
        self.notify = shutil.which("notify-send")
        self.lock = threading.Lock()
        self.inflight = 0
        self.completed = False

    def event(self, message, notify=True):
        print(f"[{time.strftime('%H:%M:%S')}] {message}", flush=True)
        if notify and self.notify:
            subprocess.Popen(
                [self.notify, "--app-name=share", "share", message],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )

    def begin(self):
        with self.lock:
            self.inflight += 1

    def end(self, completed):
        with self.lock:
            self.inflight -= 1
            self.completed = self.completed or completed
            stop = self.once and self.completed and self.inflight == 0
        if stop:
            self.event("download complete, stopping", notify=False)
            threading.Thread(target=self.shutdown).start()


class Handler(http.server.SimpleHTTPRequestHandler):
    server: Server

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=args[2].root, **kwargs)

    def log_message(self, *args):
        pass

    # No Server header and no error page body, so nothing tells what runs here.
    def send_response(self, code, message=None):
        self.send_response_only(code, message)
        self.send_header("Date", self.date_time_string())

    def send_error(self, code, message=None, explain=None):
        self.send_response(code)
        self.send_header("Content-Length", "0")
        self.send_header("Connection", "close")
        self.end_headers()

    def translate_path(self, path):
        path = urllib.parse.unquote(path.split("?", 1)[0].split("#", 1)[0])
        prefix = self.server.prefix
        if path != prefix and not path.startswith(prefix + "/"):
            return ""  # never exists, so the caller answers 404
        parts = [p for p in path[len(prefix) :].split("/") if p not in ("", ".", "..")]
        return os.path.join(self.server.root, *parts)

    def client(self):
        # frps appends its peer (envoy) last; envoy appended the real client
        # (from the PROXY header) right before it. Earlier entries came from
        # the client itself and cannot be trusted.
        chain = [p.strip() for p in self.headers.get("X-Forwarded-For", "").split(",") if p.strip()]
        if len(chain) >= 2:
            return chain[-2]
        return chain[-1] if chain else self.client_address[0]

    def do_HEAD(self):
        self.send_error(405)

    def is_probe(self):
        return bool(self.server.probe) and self.headers.get("X-Share-Probe") == self.server.probe

    def list_directory(self, path):
        if not self.is_probe():
            name = os.path.relpath(path, self.server.root)
            self.server.event(f"☰ {self.client()} listed {'/' if name == '.' else name}", notify=False)
        return super().list_directory(path)

    def do_GET(self):
        path = self.translate_path(self.path)
        if not os.path.isfile(path):
            super().do_GET()  # directory listings, slash redirects and 404s
            return
        self.serve_file(path)

    def serve_file(self, path):
        try:
            f = open(path, "rb")
        except OSError:
            self.send_error(404)
            return
        with f:
            size = os.fstat(f.fileno()).st_size
            byte_range = parse_range(self.headers.get("Range"), size)
            if byte_range is False:
                self.send_response(416)
                self.send_header("Content-Range", f"bytes */{size}")
                self.send_header("Content-Length", "0")
                self.end_headers()
                return
            start, end = byte_range or (0, size - 1)
            length = end - start + 1

            name = os.path.relpath(path, self.server.root)
            self.send_response(206 if byte_range else 200)
            self.send_header("Content-Type", self.guess_type(path))
            self.send_header("Content-Length", str(length))
            self.send_header("Accept-Ranges", "bytes")
            self.send_header(
                "Content-Disposition",
                f"attachment; filename*=UTF-8''{urllib.parse.quote(os.path.basename(path))}",
            )
            self.send_header("Last-Modified", email.utils.formatdate(os.fstat(f.fileno()).st_mtime, usegmt=True))
            if byte_range:
                self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
            self.end_headers()

            quiet = self.is_probe()
            who = self.client()
            part = f" (bytes {start}-{end})" if byte_range else ""
            if not quiet:
                self.server.event(f"▶ {who} started {name}{part}, {human(length)}")
                self.server.begin()

            began, sent = time.monotonic(), 0
            f.seek(start)
            try:
                while sent < length:
                    chunk = f.read(min(CHUNK, length - sent))
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    sent += len(chunk)
            except (BrokenPipeError, ConnectionResetError):
                pass
            finally:
                if not quiet:
                    took = duration(time.monotonic() - began)
                    if sent == length:
                        self.server.event(f"✔ {who} finished {name}{part}, {human(sent)} in {took}")
                    else:
                        self.server.event(
                            f"✖ {who} aborted {name}{part} after {human(sent)} of {human(length)} ({took})"
                        )
                    self.server.end(sent == length and end == size - 1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--id", required=True)
    parser.add_argument("--port-file", required=True)
    parser.add_argument("--once", action="store_true")
    args = parser.parse_args()

    server = Server(args)
    with open(args.port_file + ".tmp", "w", encoding="utf-8") as port_file:
        port_file.write(str(server.server_address[1]))
    os.rename(args.port_file + ".tmp", args.port_file)
    server.serve_forever()
    return 0


if __name__ == "__main__":
    sys.exit(main())
