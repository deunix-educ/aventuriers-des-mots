# Sources des assets provisoires

Tous les graphismes et sons actuels sont provisoires, crees pour ce projet, sans asset tiers.

| Fichier | Origine | Licence |
|---|---|---|
| `icon.svg` | Forme geometrique simple, creee pour ce projet | AGPL-3.0 (code et assets du depot) |
| `audio/dictations/ce1_accord_adjectif_dictee_01.ogg` | Voix de synthese generee hors ligne avec eSpeak NG 1.52 (voix `fr-fr`), via `tools/generate_dictation_audio.py` | GPL-3.0 (eSpeak NG) ; fichier genere verse en AGPL-3.0 avec le reste du depot |

Chaque nouvelle dictee ajoutee a `data/dictations/` doit avoir son audio genere avec `make generate-dictation-audio`, puis une ligne ajoutee ici. Toutes les voix actuelles sont provisoires (`audio_provisional: true` dans la donnee, badge « voix provisoire » affiche a l'enfant) : a remplacer par une vraie voix humaine avant diffusion.
