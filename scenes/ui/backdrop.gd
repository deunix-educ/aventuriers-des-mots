extends Control
## Decor plein ecran derriere un ecran (illustration vectorielle provisoire,
## voir assets/CREDITS.md). Le decor est celui du « tableau » (BackdropKinds) ;
## un identifiant inconnu retombe sur la foret.

@export var kind: String = "forest":
    set(value):
        kind = value
        _apply()

@onready var _picture: TextureRect = $Picture


func _ready() -> void:
    _apply()


func _apply() -> void:
    if _picture != null:
        var path: String = BackdropKinds.TEXTURES.get(kind, BackdropKinds.TEXTURES["forest"])
        _picture.texture = load(path)
