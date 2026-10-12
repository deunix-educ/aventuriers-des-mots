#!/usr/bin/env python3
"""Sert la version web du jeu en local et ouvre le navigateur.

Usage : serve_web.py [dossier]   (par defaut : le dossier « web » a cote du script)
Aucune connexion Internet : le serveur n'ecoute que sur 127.0.0.1.
"""

import functools
import http.server
import sys
import webbrowser
from pathlib import Path

PORTS = range(8080, 8100)


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent / "web"
    if not (root / "index.html").is_file():
        print(f"index.html introuvable dans {root}", file=sys.stderr)
        return 1
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(root))
    for port in PORTS:
        try:
            server = http.server.ThreadingHTTPServer(("127.0.0.1", port), handler)
        except OSError:
            continue
        url = f"http://localhost:{port}/index.html"
        print(f"Les Aventuriers des mots : {url}")
        print("Cliquer une fois dans la page pour activer le son. Ctrl+C pour arreter.")
        webbrowser.open(url)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass
        return 0
    print("Aucun port libre entre 8080 et 8099.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
