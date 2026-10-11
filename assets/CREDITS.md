# Sources des assets provisoires

Tous les graphismes et sons actuels sont provisoires et crees pour ce projet ; seules la police et les voix de synthese reposent sur des composants tiers libres, listes ci-dessous.

| Fichier | Origine | Licence |
|---|---|---|
| `icon.svg` | Forme geometrique simple, creee pour ce projet | AGPL-3.0 (code et assets du depot) |
| `fonts/AtkinsonHyperlegible-*.ttf` | Atkinson Hyperlegible, police conçue pour la lisibilité (Braille Institute) | SIL Open Font License 1.1 (`fonts/OFL.txt`) |
| `environments/*.svg`, `characters/*.svg`, `interface/*.svg`, `interface/items/*.svg` | Illustrations vectorielles originales créées pour ce projet (décors, hibou Plume, étoiles, pictogrammes, objets de collection) ; provisoires | AGPL-3.0 (code et assets du dépôt) |
| `audio/dictations/*.ogg` (toutes les dictees) | Voix de synthese neuronale generee hors ligne avec Piper (modele `fr_FR-siwis-medium`, entraine sur le corpus SIWIS de l'EPFL), via `tools/generate_dictation_audio.py` | MIT (Piper) ; dataset SIWIS en CC-BY 4.0 (attribution requise) ; fichiers generes verses en AGPL-3.0 avec le reste du depot |

Chaque nouvelle dictee ajoutee a `data/dictations/` doit avoir son audio genere avec `make generate-dictation-audio`, puis une ligne ajoutee ici. Toutes les voix actuelles sont provisoires (`audio_provisional: true` dans la donnee, badge « voix provisoire » affiche a l'enfant) : a remplacer par une vraie voix humaine avant diffusion.

Attribution requise par la licence CC-BY 4.0 du corpus SIWIS : Honnet, P.-E., Lazaridis, A., Garner, P. N., & Yamagishi, J. (2017). *The SIWIS French Speech Synthesis Database*. Idiap Research Institute / EPFL.
