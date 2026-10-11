# Sources des assets provisoires

Tous les graphismes et sons actuels sont provisoires, crees pour ce projet, sans asset tiers.

| Fichier | Origine | Licence |
|---|---|---|
| `icon.svg` | Forme geometrique simple, creee pour ce projet | AGPL-3.0 (code et assets du depot) |
| `audio/dictations/ce1_accord_adjectif_dictee_01.ogg` | Voix de synthese neuronale generee hors ligne avec Piper (modele `fr_FR-siwis-medium`, entraine sur le corpus SIWIS de l'EPFL), via `tools/generate_dictation_audio.py` | MIT (Piper) ; dataset SIWIS en CC-BY 4.0 (attribution requise) ; fichier genere verse en AGPL-3.0 avec le reste du depot |
| `audio/dictations/ce1_accord_adjectif_dictee_02.ogg` | Idem (voix Piper `fr_FR-siwis-medium`) | Idem |
| `audio/dictations/ce1_accord_adjectif_dictee_03.ogg` | Idem (voix Piper `fr_FR-siwis-medium`) | Idem |

Chaque nouvelle dictee ajoutee a `data/dictations/` doit avoir son audio genere avec `make generate-dictation-audio`, puis une ligne ajoutee ici. Toutes les voix actuelles sont provisoires (`audio_provisional: true` dans la donnee, badge « voix provisoire » affiche a l'enfant) : a remplacer par une vraie voix humaine avant diffusion.

Attribution requise par la licence CC-BY 4.0 du corpus SIWIS : Honnet, P.-E., Lazaridis, A., Garner, P. N., & Yamagishi, J. (2017). *The SIWIS French Speech Synthesis Database*. Idiap Research Institute / EPFL.
