class_name BackdropKinds
extends RefCounted
## Decors disponibles (un par « tableau » de la carte) et musique associee.
## Liste fermee, resolue par identifiant vers un repertoire fixe ; un test
## verifie qu'elle concorde avec l'enum `backdrop` de
## data/schemas/curriculum.schema.json.

const TEXTURES := {
    "forest": "res://assets/environments/forest_backdrop.svg",
    "marsh": "res://assets/environments/marsh_backdrop.svg",
    "beach": "res://assets/environments/beach_backdrop.svg",
    "mountain": "res://assets/environments/mountain_backdrop.svg",
    "desert": "res://assets/environments/desert_backdrop.svg",
    "island": "res://assets/environments/island_backdrop.svg",
}

## Morceau joue par defaut avec chaque decor (reglage « automatique »).
const MUSIC := {
    "forest": "forest",
    "marsh": "marsh",
    "beach": "river",
    "mountain": "meadow",
    "desert": "night",
    "island": "river",
}

const FALLBACK := "forest"


static func kinds() -> Array[String]:
    var result: Array[String] = []
    for kind: String in TEXTURES:
        result.append(kind)
    return result


static func is_valid(kind: String) -> bool:
    return TEXTURES.has(kind)


static func music_for(kind: String) -> String:
    return MUSIC.get(kind, MUSIC[FALLBACK])
