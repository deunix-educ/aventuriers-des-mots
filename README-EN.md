# Les Aventuriers des mots (The Word Adventurers)

An educational French-language game for 7-9 year olds (French grades CE1-CE2): an offline 2D adventure with an explorable map, a guide character, and grammar, spelling, and dictation exercises.

Open source project, in development. Current status: version 0.4.0, playable offline on Linux and Windows — profiles, saves (with export and restore in the adult area), stars and an item collection, settings (volume, text size, animations), a progress dashboard for adults, three exercise types (multiple choice, sentence correction, dictation), a CE1 chapter on noun-group agreement (3 rules) and a CE2 chapter on grammatical homophones (a/à, et/est, son/sont, on/ont), 21 missions. All pedagogical content is still `draft` (awaiting validation) and dictation voices are placeholders (see `assets/CREDITS.md`; see `docs/specs/decisions.md` for scoping decisions and `docs/specs/cahier-des-charges.md` for the full specification, both in French — this is a French-curriculum product).

## Tech stack

- Godot 4.6 (typed GDScript)
- Exercises and pedagogical content as JSON data, validated on load
- Headless tests (GUT), GDScript lint/format (gdtoolkit)

## Getting started

```sh
make setup   # installs Godot (pinned), GUT and gdtoolkit locally, nothing is committed
make run     # runs the game
```

## Commands

| Command | Effect |
|---|---|
| `make setup` | installs tooling (lint, tests, export templates) |
| `make run` | runs the game |
| `make lint` / `make format` | GDScript static analysis and formatting |
| `make validate-data` | validates the JSON files in `data/` |
| `make test` | headless tests |
| `make check` | lint + validate-data + test, must pass before every commit |
| `make content-review` | regenerates `docs/review/content-review.md` (content validation document) |
| `make generate-dictation-audio` | generates the placeholder dictation audio |
| `make export-linux` / `make export-windows` | exports into `build/` |
| `make package` | builds the distributable archives in `dist/` (single executable + license + credits) |

## Structure

- `autoload/`: global modules (game lifecycle, profiles, progress, exercises, saves, audio, settings)
- `scenes/`: self-contained Godot scenes communicating via signals
- `scripts/`: pure logic (correction, pedagogy) and data loading
- `data/`: pedagogical content as JSON, validated against schemas
- `assets/`: graphics and audio (placeholder at this stage, see `assets/CREDITS.md`)
- `tests/`: headless tests (GUT)
- `docs/specs/`: specification and scoping decisions (French)

## License

Code and content under the [GNU Affero General Public License v3](LICENSE).
