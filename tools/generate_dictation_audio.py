#!/usr/bin/env python3
"""Genere l'audio provisoire des dictees a partir de `data/dictations/*.json`.

Synthese vocale hors ligne (eSpeak NG) + encodage en Ogg Vorbis (ffmpeg), tel
que decide dans docs/specs/decisions.md, point 8. Ne tourne jamais a
l'execution du jeu : c'est un outil de redaction de contenu, lance a la main.
Ne regenere pas un fichier deja present, sauf avec --force.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
DICTATIONS_DIR = REPO_ROOT / "data" / "dictations"
AUDIO_DIR = REPO_ROOT / "assets" / "audio" / "dictations"

ESPEAK_VOICE = "fr-fr"
ESPEAK_SPEED_WPM = "135"


def _require_tool(name: str, install_hint: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise SystemExit(f"'{name}' introuvable dans le PATH. {install_hint}")
    return path


def load_dictations() -> list[dict[str, Any]]:
    return [
        json.loads(path.read_text(encoding="utf-8"))
        for path in sorted(DICTATIONS_DIR.glob("*.json"))
    ]


def generate_one(espeak_bin: str, ffmpeg_bin: str, dictation: dict[str, Any]) -> Path:
    audio_id: str = dictation["audio_id"]
    target_text: str = dictation["target_text"]
    output_path = AUDIO_DIR / f"{audio_id}.ogg"

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_wav = Path(tmp_dir) / f"{audio_id}.wav"
        subprocess.run(
            [
                espeak_bin,
                "-v",
                ESPEAK_VOICE,
                "-s",
                ESPEAK_SPEED_WPM,
                "-w",
                str(tmp_wav),
                target_text,
            ],
            check=True,
        )
        subprocess.run(
            [
                ffmpeg_bin,
                "-y",
                "-loglevel",
                "error",
                "-i",
                str(tmp_wav),
                "-c:a",
                "libvorbis",
                "-qscale:a",
                "4",
                str(output_path),
            ],
            check=True,
        )
    return output_path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenere meme les fichiers deja presents.",
    )
    args = parser.parse_args()

    espeak_bin = _require_tool(
        "espeak-ng",
        "A installer via le gestionnaire de paquets du systeme (ex. "
        "`sudo apt install espeak-ng` sous Debian/Ubuntu, `brew install espeak-ng` sous macOS).",
    )
    ffmpeg_bin = _require_tool("ffmpeg", "A installer via le gestionnaire de paquets du systeme.")

    AUDIO_DIR.mkdir(parents=True, exist_ok=True)

    generated: list[str] = []
    skipped: list[str] = []
    for dictation in load_dictations():
        if not dictation.get("audio_provisional", False):
            continue
        audio_id: str = dictation["audio_id"]
        output_path = AUDIO_DIR / f"{audio_id}.ogg"
        if output_path.exists() and not args.force:
            skipped.append(audio_id)
            continue
        generate_one(espeak_bin, ffmpeg_bin, dictation)
        generated.append(audio_id)

    print(f"Audio genere : {len(generated)} fichier(s) ({', '.join(generated) or 'aucun'}).")
    if skipped:
        print(f"Deja present, ignore (--force pour regenerer) : {', '.join(skipped)}.")


if __name__ == "__main__":
    main()
