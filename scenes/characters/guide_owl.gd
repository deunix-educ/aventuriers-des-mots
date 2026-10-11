extends Control
## Plume, le hibou guide : affiche une remarque ou un indice dans une bulle.
## Illustration vectorielle provisoire (voir assets/CREDITS.md), a remplacer
## fichier par fichier sans toucher ce script.

@onready var _bubble: Control = $HBox/Bubble
@onready var _dialogue_label: Label = %DialogueLabel


func _ready() -> void:
    _bubble.visible = _dialogue_label.visible


func say(text: String) -> void:
    _dialogue_label.text = text
    _dialogue_label.visible = true
    _bubble.visible = true
    Motion.fade_in(_bubble)


func clear() -> void:
    _dialogue_label.visible = false
    _bubble.visible = false
