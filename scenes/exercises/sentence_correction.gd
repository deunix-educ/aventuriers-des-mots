extends Control
## Exercice de correction de phrase : toucher le mot fautif puis le corriger
## (interaction decidee dans docs/specs/decisions.md, point 3). Scene
## autonome : emet la reponse par signal, ne touche ni a la sauvegarde ni a
## la progression.

signal answer_submitted(selected_indices: Array, corrections: Dictionary)

var _correction_edits: Dictionary = {}

@onready var _instruction_label: Label = %InstructionLabel
@onready var _tokens_box: HFlowContainer = %TokensBox
@onready var _corrections_box: VBoxContainer = %CorrectionsBox
@onready var _validate_button: Button = %ValidateButton


func _ready() -> void:
    _validate_button.text = UIText.get_text("exercise_host.validate_button")
    _validate_button.pressed.connect(_on_validate_pressed)


func load_exercise(exercise: Dictionary) -> void:
    _instruction_label.text = exercise["instruction"]

    for child in _tokens_box.get_children():
        child.queue_free()
    for child in _corrections_box.get_children():
        child.queue_free()
    _correction_edits.clear()

    var tokens: Array = exercise["tokens"]
    for i in tokens.size():
        var button := Button.new()
        button.text = tokens[i]["text"]
        button.toggle_mode = true
        button.theme_type_variation = &"SecondaryButton"
        button.custom_minimum_size = Vector2(0, 60)
        button.add_theme_font_size_override("font_size", SettingsManager.scaled_font_size(30))
        button.toggled.connect(_on_token_toggled.bind(i))
        _tokens_box.add_child(button)


func _on_token_toggled(pressed: bool, index: int) -> void:
    if pressed:
        if not _correction_edits.has(index):
            var edit := LineEdit.new()
            edit.placeholder_text = UIText.get_text("sentence_correction.correction_placeholder")
            # La touche Entree valide comme le bouton.
            edit.text_submitted.connect(func(_text: String) -> void: _on_validate_pressed())
            _corrections_box.add_child(edit)
            _correction_edits[index] = edit
    elif _correction_edits.has(index):
        var edit: LineEdit = _correction_edits[index]
        edit.queue_free()
        _correction_edits.erase(index)


func _on_validate_pressed() -> void:
    var selected_indices: Array = []
    var corrections: Dictionary = {}
    for index: int in _correction_edits.keys():
        selected_indices.append(index)
        corrections[index] = (_correction_edits[index] as LineEdit).text.strip_edges()
    answer_submitted.emit(selected_indices, corrections)
