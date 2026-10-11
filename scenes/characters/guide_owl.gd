extends Control
## Plume, le hibou guide : affiche une remarque ou un indice sous forme de
## texte. Portrait provisoire (forme simple, voir assets/CREDITS.md), a
## remplacer fichier par fichier sans toucher ce script.

@onready var _dialogue_label: Label = %DialogueLabel


func say(text: String) -> void:
    _dialogue_label.text = text
    _dialogue_label.visible = true


func clear() -> void:
    _dialogue_label.visible = false
