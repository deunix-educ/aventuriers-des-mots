extends Control
## Exercice a choix multiple. Scene autonome : emet la reponse par signal,
## ne touche ni a la sauvegarde ni a la progression (invariant d'architecture,
## CLAUDE.md).

signal answer_submitted(selected_index: int)

@onready var _instruction_label: Label = %InstructionLabel
@onready var _question_label: Label = %QuestionLabel
@onready var _answers_box: VBoxContainer = %AnswersBox


func load_exercise(exercise: Dictionary) -> void:
    _instruction_label.text = exercise["instruction"]
    _question_label.text = exercise["question"]

    for child in _answers_box.get_children():
        child.queue_free()

    var answers: Array = exercise["answers"]
    for i in answers.size():
        var button := Button.new()
        button.text = answers[i]
        button.custom_minimum_size = Vector2(0, 64)
        button.add_theme_font_size_override("font_size", SettingsManager.scaled_font_size(28))
        button.pressed.connect(_on_answer_pressed.bind(i))
        _answers_box.add_child(button)


func _on_answer_pressed(index: int) -> void:
    answer_submitted.emit(index)
