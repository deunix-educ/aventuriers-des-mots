#!/usr/bin/env python3
"""Genere l'audio provisoire des dictees a partir de `data/dictations/*.json`.

Synthese vocale hors ligne (voix neuronale Piper, francaise) + encodage en
Ogg Vorbis (ffmpeg), tel que decide dans docs/specs/decisions.md, points 8 et
19. Ne tourne jamais a l'execution du jeu : c'est un outil de redaction de
contenu, lance a la main. Ne regenere pas un fichier deja present, sauf avec
--force.

Un premier essai avec eSpeak NG (synthese par formants) s'est revele
inintelligible a l'oreille lors d'un test manuel : remplace par une voix
neuronale Piper, nettement plus naturelle tout en restant generee hors ligne
sans aucun acces reseau au moment de jouer (le telechargement du modele de
voix, ci-dessous, n'a lieu qu'une fois, a la redaction du contenu).
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import tempfile
import wave
from pathlib import Path
from typing import Any
from urllib.request import urlretrieve

from piper import PiperVoice
from piper.config import SynthesisConfig

REPO_ROOT = Path(__file__).resolve().parent.parent
DICTATIONS_DIR = REPO_ROOT / "data" / "dictations"
AUDIO_DIR = REPO_ROOT / "assets" / "audio" / "dictations"

# Cache local, non versionne (voir .gitignore) : le modele de voix (~60 Mo)
# n'a pas sa place dans le depot, seul l'audio genere l'a.
VOICE_CACHE_DIR = REPO_ROOT / ".cache" / "piper-voices"
VOICE_NAME = "fr_FR-siwis-medium"
VOICE_BASE_URL = "https://huggingface.co/rhasspy/piper-voices/resolve/main/fr/fr_FR/siwis/medium"

# > 1.0 ralentit legerement le debit (duree des phonemes etiree), plus
# confortable pour un enfant de 7-11 ans qu'une diction par defaut pensee
# pour un adulte.
LENGTH_SCALE = 1.1


def _require_tool(name: str, install_hint: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise SystemExit(f"'{name}' introuvable dans le PATH. {install_hint}")
    return path


def _ensure_voice() -> Path:
    VOICE_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    model_path = VOICE_CACHE_DIR / f"{VOICE_NAME}.onnx"
    config_path = VOICE_CACHE_DIR / f"{VOICE_NAME}.onnx.json"

    if not model_path.exists():
        print(f"Telechargement de la voix {VOICE_NAME} (environ 60 Mo, une seule fois)...")
        urlretrieve(f"{VOICE_BASE_URL}/{VOICE_NAME}.onnx", model_path)
    if not config_path.exists():
        urlretrieve(f"{VOICE_BASE_URL}/{VOICE_NAME}.onnx.json", config_path)

    return model_path


def load_dictations() -> list[dict[str, Any]]:
    return [
        json.loads(path.read_text(encoding="utf-8"))
        for path in sorted(DICTATIONS_DIR.glob("*.json"))
    ]


def generate_one(voice: PiperVoice, ffmpeg_bin: str, dictation: dict[str, Any]) -> Path:
    audio_id: str = dictation["audio_id"]
    target_text: str = dictation["target_text"]
    output_path = AUDIO_DIR / f"{audio_id}.ogg"
    syn_config = SynthesisConfig(length_scale=LENGTH_SCALE)

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_wav = Path(tmp_dir) / f"{audio_id}.wav"
        with wave.open(str(tmp_wav), "wb") as wav_file:
            voice.synthesize_wav(target_text, wav_file, syn_config=syn_config)
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

    ffmpeg_bin = _require_tool("ffmpeg", "A installer via le gestionnaire de paquets du systeme.")

    AUDIO_DIR.mkdir(parents=True, exist_ok=True)

    provisional_dictations = [d for d in load_dictations() if d.get("audio_provisional", False)]
    dictations_to_generate: list[dict[str, Any]] = []
    skipped: list[str] = []
    for dictation in provisional_dictations:
        output_path = AUDIO_DIR / f"{dictation['audio_id']}.ogg"
        if output_path.exists() and not args.force:
            skipped.append(dictation["audio_id"])
        else:
            dictations_to_generate.append(dictation)

    generated: list[str] = []
    if dictations_to_generate:
        voice = PiperVoice.load(str(_ensure_voice()))
        for dictation in dictations_to_generate:
            generate_one(voice, ffmpeg_bin, dictation)
            generated.append(dictation["audio_id"])

    print(f"Audio genere : {len(generated)} fichier(s) ({', '.join(generated) or 'aucun'}).")
    if skipped:
        print(f"Deja present, ignore (--force pour regenerer) : {', '.join(skipped)}.")


if __name__ == "__main__":
    main()
