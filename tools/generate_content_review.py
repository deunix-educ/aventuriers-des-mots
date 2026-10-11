#!/usr/bin/env python3
"""Genere docs/review/content-review.md a partir des donnees de data/.

Le JSON se relit mal ; ce document rassemble, pour chaque regle, son enonce
puis chaque exercice qui l'illustre, avec sa reponse attendue, son indice et
son explication. C'est ce document que l'adulte valide (voir CLAUDE.md,
section Contenu pedagogique).
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data"
OUTPUT_PATH = REPO_ROOT / "docs" / "review" / "content-review.md"


def load_json_files(directory: Path) -> list[dict[str, Any]]:
    if not directory.exists():
        return []
    return [
        json.loads(path.read_text(encoding="utf-8")) for path in sorted(directory.rglob("*.json"))
    ]


def format_multiple_choice(exercise: dict[str, Any]) -> str:
    answers: list[str] = exercise["answers"]
    correct = answers[exercise["correct_answer"]]
    return "\n".join(
        [
            f"- **{exercise['id']}** (difficulte {exercise['difficulty']}) : {exercise['question']}",
            f"  - Reponses : {', '.join(answers)}",
            f"  - Reponse attendue : {correct}",
            f"  - Indice : {exercise['hint']}",
            f"  - Explication : {exercise['explanation']}",
            f"  - Statut : {exercise['review_status']}",
        ]
    )


def format_sentence_correction(exercise: dict[str, Any]) -> str:
    rendered: list[str] = []
    for token in exercise["tokens"]:
        if token.get("correct", True):
            rendered.append(token["text"])
        else:
            rendered.append(f"[{token['text']} -> {token['expected']}]")
    sentence = " ".join(rendered)
    return "\n".join(
        [
            f"- **{exercise['id']}** (difficulte {exercise['difficulty']}) : {sentence}",
            f"  - Indice : {exercise['hint']}",
            f"  - Explication : {exercise['explanation']}",
            f"  - Statut : {exercise['review_status']}",
        ]
    )


def format_dictation(dictation: dict[str, Any]) -> str:
    variants: list[str] = dictation["accepted_variants"]
    audio_state = "provisoire" if dictation["audio_provisional"] else "finalise"
    return "\n".join(
        [
            f"- **{dictation['id']}** : {dictation['target_text']}",
            f"  - Variantes acceptees : {', '.join(variants) if variants else 'aucune'}",
            f"  - Audio : {audio_state}",
            f"  - Statut : {dictation['review_status']}",
        ]
    )


def render(
    rules: list[dict[str, Any]],
    exercises: list[dict[str, Any]],
    dictations: list[dict[str, Any]],
) -> str:
    multiple_choice = [e for e in exercises if e["type"] == "multiple_choice"]
    sentence_correction = [e for e in exercises if e["type"] == "sentence_correction"]

    lines: list[str] = [
        "# Revue du contenu pedagogique",
        "",
        "Genere automatiquement depuis `data/` par `tools/generate_content_review.py`. "
        "Ne pas editer ce fichier a la main.",
        "",
    ]

    for rule in sorted(rules, key=lambda r: str(r["rule_id"])):
        rule_id = rule["rule_id"]
        lines += [
            f"## {rule_id} ({rule['level']}, {rule['domain']})",
            "",
            f"**Enonce** : {rule['statement']}",
            "",
            f"**Exemple** : {rule['example']}",
            "",
            f"**Statut** : {rule['review_status']}",
            "",
        ]

        rule_mc = [e for e in multiple_choice if e["rule_id"] == rule_id]
        if rule_mc:
            lines.append("### Choix multiples")
            lines.append("")
            for exercise in sorted(rule_mc, key=lambda e: str(e["id"])):
                lines.append(format_multiple_choice(exercise))
            lines.append("")

        rule_sc = [e for e in sentence_correction if e["rule_id"] == rule_id]
        if rule_sc:
            lines.append("### Corrections de phrase")
            lines.append("")
            for exercise in sorted(rule_sc, key=lambda e: str(e["id"])):
                lines.append(format_sentence_correction(exercise))
            lines.append("")

        rule_dictations = [d for d in dictations if rule_id in d["rule_ids"]]
        if rule_dictations:
            lines.append("### Dictees")
            lines.append("")
            for dictation in sorted(rule_dictations, key=lambda d: str(d["id"])):
                lines.append(format_dictation(dictation))
            lines.append("")

    return "\n".join(lines) + "\n"


def main() -> None:
    rules = load_json_files(DATA_DIR / "rules")
    exercises = load_json_files(DATA_DIR / "exercises")
    dictations = load_json_files(DATA_DIR / "dictations")

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(render(rules, exercises, dictations), encoding="utf-8")
    print(
        f"content-review.md genere : {len(rules)} regle(s), "
        f"{len(exercises)} exercice(s), {len(dictations)} dictee(s)."
    )


if __name__ == "__main__":
    main()
