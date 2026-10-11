extends Node
## Point d'entree du jeu : redirige immediatement vers la selection de profil.


func _ready() -> void:
    GameManager.goto(GameManager.SCENE_PROFILE_SELECT)
