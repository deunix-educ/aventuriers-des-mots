extends Control
## Exercice de dictee : ecoute puis ecrit. Scene autonome : emet la reponse
## par signal, ne touche ni a la sauvegarde ni a la progression. L'audio est
## provisoire (voir docs/specs/decisions.md, point 8) ; le badge l'indique a
## l'enfant tant qu'aucune voix definitive n'a remplace le fichier.
##
## Majuscule initiale et point final sont exiges a la correction (point 22)
## sans etre entendus dans l'audio : le rappel ci-dessous est la facon dont
## l'enfant en est informe, pas une tolerance ajoutee au validateur.

signal answer_submitted(submitted_text: String)

var _dictation: Dictionary = {}

@onready var _instruction_label: Label = %InstructionLabel
@onready var _replay_button: Button = %ReplayButton
@onready var _provisional_badge: Label = %ProvisionalBadge
@onready var _convention_hint_label: Label = %ConventionHintLabel
@onready var _text_edit: LineEdit = %TextEdit
@onready var _validate_button: Button = %ValidateButton


func _ready() -> void:
    _instruction_label.text = UIText.get_text("dictation.instruction_label")
    _replay_button.text = UIText.get_text("dictation.replay_button")
    _text_edit.placeholder_text = UIText.get_text("dictation.input_placeholder")
    _provisional_badge.text = UIText.get_text("dictation.provisional_audio_badge")
    _convention_hint_label.text = UIText.get_text("dictation.convention_hint")
    _validate_button.text = UIText.get_text("exercise_host.validate_button")

    _replay_button.pressed.connect(_on_replay_pressed)
    _validate_button.pressed.connect(_on_validate_pressed)


func load_exercise(dictation: Dictionary) -> void:
    _dictation = dictation
    _text_edit.text = ""
    _provisional_badge.visible = dictation.get("audio_provisional", false)
    _on_replay_pressed()


func _on_replay_pressed() -> void:
    AudioManager.play_dictation(_dictation.get("audio_id", ""))


func _on_validate_pressed() -> void:
    answer_submitted.emit(_text_edit.text)
