extends Control
## Panneau de retour : affiche le resultat d'une tentative (CorrectionResult).
## Reussite et erreur se distinguent par le texte du titre, jamais par la
## seule couleur (cahier des charges §11). Instancie par exercise_host.

signal continue_pressed

const ICON_CORRECT := preload("res://assets/interface/icon_correct.svg")
const ICON_TRY_AGAIN := preload("res://assets/interface/icon_try_again.svg")

@onready var _icon: TextureRect = %Icon
@onready var _title_label: Label = %TitleLabel
@onready var _hint_box: VBoxContainer = %HintBox
@onready var _hint_label: Label = %HintLabel
@onready var _explanation_box: VBoxContainer = %ExplanationBox
@onready var _explanation_label: Label = %ExplanationLabel
@onready var _correction_box: VBoxContainer = %CorrectionBox
@onready var _correction_label: Label = %CorrectionLabel
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
    _continue_button.text = UIText.get_text("exercise_host.continue_button")
    _continue_button.pressed.connect(_on_continue_pressed)


func show_result(result: CorrectionResult, support_level: AttemptFlow.SupportLevel) -> void:
    _icon.texture = ICON_CORRECT if result.is_correct else ICON_TRY_AGAIN
    Motion.pop_in(_icon)
    _title_label.text = (
        UIText.get_text("feedback_panel.correct_title")
        if result.is_correct
        else UIText.get_text("feedback_panel.incorrect_title")
    )

    var show_hint := not result.is_correct and support_level == AttemptFlow.SupportLevel.HINT
    var show_explanation := (
        result.is_correct or support_level != AttemptFlow.SupportLevel.HINT
    )
    var show_correction := (
        not result.is_correct and support_level == AttemptFlow.SupportLevel.REVEAL
    )

    _hint_box.visible = show_hint
    _hint_label.text = "%s %s" % [UIText.get_text("feedback_panel.hint_label"), result.hint]

    _explanation_box.visible = show_explanation
    _explanation_label.text = "%s %s" % [
        UIText.get_text("feedback_panel.explanation_label"), result.explanation
    ]

    _correction_box.visible = show_correction
    _correction_label.text = "%s %s" % [
        UIText.get_text("feedback_panel.correction_label"), ", ".join(result.remediation)
    ]


func _on_continue_pressed() -> void:
    continue_pressed.emit()
