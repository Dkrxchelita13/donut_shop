#!/usr/bin/env python3

from __future__ import annotations

import http.server
import socketserver
from pathlib import Path


PORT: int = 8000
PROJECT_ROOT: Path = Path(__file__).resolve().parent.parent
WEB_DIRECTORY: Path = PROJECT_ROOT / "builds" / "web"


class QARequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args: object, **kwargs: object) -> None:
        super().__init__(*args, directory=str(WEB_DIRECTORY), **kwargs)

    def end_headers(self) -> None:
        self.send_header(
            "Cache-Control",
            "no-store, no-cache, must-revalidate",
        )
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()


class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address: bool = True


def main() -> None:
    WEB_DIRECTORY.mkdir(parents=True, exist_ok=True)

    with ReusableTCPServer(("127.0.0.1", PORT), QARequestHandler) as httpd:
        print(f"Web QA: http://localhost:{PORT}")
        print(f"Sirviendo: {WEB_DIRECTORY}")
        print("Ctrl+C para detener.")

        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServidor detenido.")


if __name__ == "__main__":
    main()
