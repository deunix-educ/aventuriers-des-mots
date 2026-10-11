#!/usr/bin/env python3
"""Genere les effets sonores et les musiques d'ambiance du jeu.

Synthese entierement procedurale (numpy, aucune banque de sons, aucun
echantillon tiers) puis encodage en Ogg Vorbis par ffmpeg. Les sons sont donc
originaux et sous la meme licence que le depot. Outil de redaction de
contenu : il ne tourne jamais pendant le jeu. Ne regenere pas un fichier deja
present, sauf avec --force.

Intentions sonores : un retour « a retenter » reste doux et interrogatif
(jamais de buzzer : une erreur n'est pas punie) ; les musiques sont calmes,
sans percussions, pour ne pas distraire de la regle etudiee.
"""

from __future__ import annotations

import argparse
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np
from numpy.typing import NDArray

REPO_ROOT = Path(__file__).resolve().parent.parent
SFX_DIR = REPO_ROOT / "assets" / "audio" / "sfx"
MUSIC_DIR = REPO_ROOT / "assets" / "audio" / "music"
SAMPLE_RATE = 32000

Signal = NDArray[np.float64]


def _time(duration: float) -> Signal:
    return np.arange(int(duration * SAMPLE_RATE)) / SAMPLE_RATE


def bell(freq: float, duration: float, decay: float = 5.0, brightness: float = 0.4) -> Signal:
    """Note de cloche douce : fondamentale + deux partiels qui s'eteignent."""
    t = _time(duration)
    tone = np.sin(2 * np.pi * freq * t)
    tone += brightness * np.sin(2 * np.pi * freq * 2.0 * t) * np.exp(-decay * 1.6 * t)
    tone += brightness * 0.5 * np.sin(2 * np.pi * freq * 3.01 * t) * np.exp(-decay * 2.2 * t)
    attack = np.minimum(t / 0.004, 1.0)
    return tone * np.exp(-decay * t) * attack


def pad(freq: float, duration: float, attack: float = 1.2, release: float = 1.5) -> Signal:
    """Note tenue, douce (sinus + octave legere), a attaque et fin lentes."""
    t = _time(duration)
    tone = np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(2 * np.pi * freq * 2 * t)
    tone += 0.12 * np.sin(2 * np.pi * freq * 1.003 * t)  # leger battement
    env = np.minimum(t / attack, 1.0) * np.minimum((duration - t) / release, 1.0)
    return tone * np.clip(env, 0.0, 1.0)


def place(target: Signal, sound: Signal, start: float, gain: float = 1.0) -> None:
    begin = int(start * SAMPLE_RATE)
    end = min(begin + len(sound), len(target))
    if begin < len(target):
        target[begin:end] += sound[: end - begin] * gain


def normalise(signal: Signal, peak: float) -> Signal:
    top = float(np.max(np.abs(signal)))
    return signal * (peak / top) if top > 0 else signal


def hz(note: str) -> float:
    names = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    pitch = names[note[0]]
    if note[1] == "#":
        pitch += 1
    elif note[1] == "b":
        pitch -= 1
    octave = int(note[-1])
    midi = 12 * (octave + 1) + pitch
    return 440.0 * 2 ** ((midi - 69) / 12)


def make_sfx() -> dict[str, Signal]:
    sounds: dict[str, Signal] = {}

    click = bell(hz("A5"), 0.12, decay=38.0, brightness=0.2)
    sounds["click"] = normalise(click, 0.45)

    success = np.zeros(int(1.0 * SAMPLE_RATE))
    for index, note in enumerate(["C5", "E5", "G5"]):
        place(success, bell(hz(note), 0.8, decay=4.5), 0.1 * index)
    sounds["success"] = normalise(success, 0.6)

    # Deux notes douces qui montent legerement : une question, pas un reproche.
    again = np.zeros(int(0.8 * SAMPLE_RATE))
    place(again, bell(hz("E4"), 0.6, decay=6.0, brightness=0.25), 0.0)
    place(again, bell(hz("G4"), 0.6, decay=6.0, brightness=0.25), 0.18)
    sounds["try_again"] = normalise(again, 0.5)

    star = bell(hz("E6"), 0.9, decay=4.0, brightness=0.5)
    sounds["star"] = normalise(star, 0.55)

    fanfare = np.zeros(int(2.0 * SAMPLE_RATE))
    for index, note in enumerate(["C5", "E5", "G5", "C6"]):
        place(fanfare, bell(hz(note), 1.2, decay=3.5), 0.14 * index)
    for note in ["C5", "E5", "G5", "C6"]:
        place(fanfare, bell(hz(note), 1.4, decay=2.8), 0.6, gain=0.7)
    sounds["fanfare"] = normalise(fanfare, 0.65)
    return sounds


def make_music(
    chords: list[list[str]],
    melody_scale: list[str],
    seconds_per_chord: float,
    seed: int,
    melody_density: float,
) -> Signal:
    """Boucle : accords tenus + quelques notes de melodie pentatonique.

    La queue de la derniere note est repliee sur le debut pour que la boucle
    ne presente ni coupure ni claquement.
    """
    rng = np.random.default_rng(seed)
    body = seconds_per_chord * len(chords)
    tail = 3.0
    track = np.zeros(int((body + tail) * SAMPLE_RATE))
    for index, chord in enumerate(chords):
        start = index * seconds_per_chord
        for note in chord:
            place(track, pad(hz(note), seconds_per_chord + 1.2), start, gain=0.35)
    beat = seconds_per_chord / 4
    for step in range(len(chords) * 4):
        if rng.random() < melody_density:
            note = melody_scale[int(rng.integers(len(melody_scale)))]
            place(track, bell(hz(note), 2.0, decay=2.4, brightness=0.3), step * beat, gain=0.28)
    folded = track[: int(body * SAMPLE_RATE)].copy()
    overflow = track[int(body * SAMPLE_RATE) :]
    folded[: len(overflow)] += overflow
    return normalise(folded, 0.5)


def make_all_music() -> dict[str, Signal]:
    forest = make_music(
        chords=[["C3", "G3", "E4"], ["A2", "E3", "C4"], ["F2", "C3", "A3"], ["G2", "D3", "B3"]] * 2,
        melody_scale=["C5", "D5", "E5", "G5", "A5", "C6"],
        seconds_per_chord=4.0,
        seed=11,
        melody_density=0.45,
    )
    marsh = make_music(
        chords=[["A2", "E3", "C4"], ["F2", "C3", "A3"], ["D3", "A3", "F4"], ["E3", "B3", "G4"]] * 2,
        melody_scale=["A4", "C5", "D5", "E5", "G5"],
        seconds_per_chord=5.0,
        seed=23,
        melody_density=0.35,
    )
    meadow = make_music(  # prairie : majeur lumineux, un peu plus vif
        chords=[["G2", "D3", "B3"], ["E2", "B2", "G3"], ["C3", "G3", "E4"], ["D3", "A3", "F#4"]] * 2,
        melody_scale=["G4", "A4", "B4", "D5", "E5", "G5"],
        seconds_per_chord=3.5,
        seed=37,
        melody_density=0.55,
    )
    river = make_music(  # riviere : mode dorien, melodie qui coule
        chords=[["D3", "A3", "F4"], ["G2", "D3", "B3"], ["C3", "G3", "E4"], ["A2", "E3", "C4"]] * 2,
        melody_scale=["D5", "E5", "F5", "A5", "C6", "A4"],
        seconds_per_chord=3.0,
        seed=41,
        melody_density=0.65,
    )
    night = make_music(  # nuit : berceuse lente et rare
        chords=[["F2", "C3", "A3"], ["D3", "A3", "E4"], ["Bb2", "F3", "D4"], ["C3", "G3", "E4"]] * 2,
        melody_scale=["F5", "G5", "A5", "C6", "E5"],
        seconds_per_chord=6.0,
        seed=53,
        melody_density=0.25,
    )
    return {"forest": forest, "marsh": marsh, "meadow": meadow, "river": river, "night": night}


def write_ogg(signal: Signal, destination: Path, quality: str = "3") -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    pcm = (np.clip(signal, -1.0, 1.0) * 32767).astype(np.int16)
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = Path(tmp) / "source.wav"
        with wave.open(str(wav_path), "wb") as handle:
            handle.setnchannels(1)
            handle.setsampwidth(2)
            handle.setframerate(SAMPLE_RATE)
            handle.writeframes(pcm.tobytes())
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav_path),
             "-c:a", "libvorbis", "-q:a", quality, str(destination)],
            check=True,
        )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--force", action="store_true", help="regenere les fichiers existants")
    args = parser.parse_args()

    jobs: list[tuple[Path, Signal]] = []
    for name, signal in make_sfx().items():
        jobs.append((SFX_DIR / f"{name}.ogg", signal))
    for name, signal in make_all_music().items():
        jobs.append((MUSIC_DIR / f"{name}.ogg", signal))

    for destination, signal in jobs:
        if destination.exists() and not args.force:
            print(f"existe deja : {destination.relative_to(REPO_ROOT)}")
            continue
        write_ogg(signal, destination)
        print(f"genere : {destination.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()
