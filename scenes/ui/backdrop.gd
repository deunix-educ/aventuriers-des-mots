extends Control
## Decor plein ecran derriere un ecran (illustration vectorielle provisoire,
## voir assets/CREDITS.md). "forest" pour le CE1, "marsh" pour le CE2.

const TEXTURES := {
    "forest": "res://assets/environments/forest_backdrop.svg",
    "marsh": "res://assets/environments/marsh_backdrop.svg",
}

@export_enum("forest", "marsh") var kind: String = "forest":
    set(value):
        kind = value
        _apply()

@onready var _picture: TextureRect = $Picture


func _ready() -> void:
    _apply()


func _apply() -> void:
    if _picture != null:
        _picture.texture = load(TEXTURES.get(kind, TEXTURES["forest"]))
