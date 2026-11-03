#!/usr/bin/env python3
# views service · 站点阅读计数（自建，数据只落本机 sqlite）
# 2026-11-04 建。GET /views?slug=x 取数；POST /views {slug} 自增（同 IP+slug 10 分钟只算一次）。
import json, os, sqlite3, threading, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

DB = "/srv/views/views.db"
RATE_WINDOW = 600
ALLOW = {
    "https://example.com", "https://www.example.com",
    "https://ajiu.yourname.com",
    "http://127.0.0.1:5199", "http://127.0.0.1:5187",
    "http://localhost:5199", "http://localhost:5187",
}
lock = threading.Lock()
seen = {}


def conn():
    c = sqlite3.connect(DB, timeout=5)
    c.execute("CREATE TABLE IF NOT EXISTS views("
              "slug TEXT PRIMARY KEY, n INTEGER NOT NULL DEFAULT 0, "
              "updated INTEGER NOT NULL DEFAULT 0)")
    return c


class H(BaseHTTPRequestHandler):
    def _cors(self):
        o = self.headers.get("Origin", "")
        if o in ALLOW:
            self.send_header("Access-Control-Allow-Origin", o)
            self.send_header("Vary", "Origin")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _json(self, code, obj):
        b = json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self._cors()
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        u = urlparse(self.path)
        if u.path != "/views":
            return self._json(404, {"error": "not found"})
        slug = (parse_qs(u.query).get("slug") or [""])[0][:120]
        if not slug:
            return self._json(400, {"error": "slug required"})
        with lock:
            c = conn()
            row = c.execute("SELECT n FROM views WHERE slug=?", (slug,)).fetchone()
            c.close()
        return self._json(200, {"slug": slug, "n": row[0] if row else 0})

    def do_POST(self):
        u = urlparse(self.path)
        if u.path != "/views":
            return self._json(404, {"error": "not found"})
        try:
            ln = int(self.headers.get("Content-Length") or 0)
            body = json.loads(self.rfile.read(ln) or b"{}")
        except Exception:
            return self._json(400, {"error": "bad json"})
        slug = str(body.get("slug", ""))[:120]
        if not slug:
            return self._json(400, {"error": "slug required"})
        ip = self.headers.get("X-Real-IP") or self.client_address[0]
        key = (ip, slug)
        now = time.time()
        with lock:
            last = seen.get(key)
            hit = last is not None and (now - last) < RATE_WINDOW
            c = conn()
            if not hit:
                seen[key] = now
                c.execute("INSERT INTO views(slug,n,updated) VALUES(?,1,?) "
                          "ON CONFLICT(slug) DO UPDATE SET n=n+1, updated=?",
                          (slug, int(now), int(now)))
                c.commit()
            row = c.execute("SELECT n FROM views WHERE slug=?", (slug,)).fetchone()
            c.close()
        if len(seen) > 50000:
            seen.clear()
        return self._json(200, {"slug": slug, "n": row[0] if row else 0, "counted": not hit})

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    os.makedirs(os.path.dirname(DB), exist_ok=True)
    ThreadingHTTPServer(("127.0.0.1", 8092), H).serve_forever()
