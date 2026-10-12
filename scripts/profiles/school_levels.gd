class_name SchoolLevels
extends RefCounted
## Niveaux scolaires du jeu, dans l'ordre de progression. Code pur. La liste
## est fermee : elle est aussi celle des schemas (data/schemas/*.json), et
## un test verifie que les deux concordent.

const ALL: Array[String] = ["CE1", "CE2", "CM1", "CM2"]


static func is_valid(level: String) -> bool:
    return ALL.has(level)


## Niveau juste avant `level` (celui que l'on peut « revoir »), ou "" pour
## le premier niveau ou une valeur inconnue.
static func previous(level: String) -> String:
    var index := ALL.find(level)
    return ALL[index - 1] if index > 0 else ""


## Rang du niveau (0 pour CE1), grand pour un niveau inconnu : sert au tri.
static func rank(level: String) -> int:
    var index := ALL.find(level)
    return index if index >= 0 else ALL.size()
