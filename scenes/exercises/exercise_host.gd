extends Control
## Hote d'exercice : charge la regle, enchaine les exercices d'une mission,
## valide chaque reponse via les validateurs purs (AnswerValidator /
## DictationAnalyzer), applique l'aide graduee (AttemptFlow) et enregistre
## chaque tentative dans ProgressManager (docs/specs/decisions.md, point 7).
## Ne charge et ne sauvegarde rien lui-meme sur disque : ProgressManager et
## SaveManager restent seuls responsables de la persistance.

const MISSION_LENGTH := 3

const TYPE_SCENES := {
    "multiple_choice": "res://scenes/exercises/multiple_choice.tscn",
    "sentence_correction": "res://scenes/exercises/sentence_correction.tscn",
    "dictation": "res://scenes/exercises/dictation.tscn",
}

var _mission: Dictionary = {}
var _rule: Dictionary = {}
var _skill_id: String = ""
var _current_exercise: Dictionary = {}
var _current_exercise_scene: Control = null
var _current_difficulty := 1
var _attempt_number := 1
var _completed_count := 0
var _last_exercise_id := ""
var _outcomes: Array[String] = []
var _pending_outcome := ""

@onready var _exercise_container: Control = %ExerciseContainer
@onready var _overlay_container: Control = %OverlayContainer
@onready var _progress_label: Label = %ProgressLabel
@onready var _abandon_button: Button = %AbandonButton
@onready var _abandon_confirm_dialog: ConfirmationDialog = %AbandonConfirmDialog


## Accesseurs reserves aux tests d'integration (scenes/exercises/
## exercise_host.tscn n'expose pas de script "ami" en GDScript).
func get_current_exercise() -> Dictionary:
    return _current_exercise


func get_attempt_number() -> int:
    return _attempt_number


func get_completed_count() -> int:
    return _completed_count


func get_outcomes() -> Array[String]:
    return _outcomes


func _ready() -> void:
    _abandon_button.text = UIText.get_text("exercise_host.abandon_button")
    _abandon_button.pressed.connect(_on_abandon_pressed)
    _abandon_confirm_dialog.title = UIText.get_text("exercise_host.abandon_confirm_title")
    _abandon_confirm_dialog.dialog_text = UIText.get_text("exercise_host.abandon_confirm_message")
    _abandon_confirm_dialog.ok_button_text = UIText.get_text("exercise_host.abandon_confirm_yes")
    _abandon_confirm_dialog.cancel_button_text = UIText.get_text("exercise_host.abandon_confirm_no")
    _abandon_confirm_dialog.confirmed.connect(_on_abandon_confirmed)

    _mission = ExerciseEngine.get_mission(GameManager.pending_mission_id)
    _rule = ExerciseEngine.get_rule(_mission["rule_id"])
    _skill_id = _rule.get("skill", "")
    _current_difficulty = ProgressManager.next_difficulty_for_skill(_skill_id, 1)
    _show_rule_panel()


func _on_abandon_pressed() -> void:
    _abandon_confirm_dialog.popup_centered()


## Quitter une mission ne rapporte ni etoile ni objet et n'est jamais compte
## comme un echec. Les tentatives deja faites restent enregistrees (ce sont de
## vraies observations d'apprentissage) et sont sauvegardees avant de partir.
func _on_abandon_confirmed() -> void:
    ProgressManager.save_now()
    GameManager.pending_mission_id = ""
    GameManager.last_outcomes = []
    GameManager.goto(GameManager.SCENE_WORLD_MAP)


func _show_rule_panel() -> void:
    var rule_panel: Control = preload("res://scenes/ui/rule_panel.tscn").instantiate()
    _overlay_container.add_child(rule_panel)
    rule_panel.show_rule(_rule)
    rule_panel.continued.connect(_on_rule_panel_continued.bind(rule_panel))


func _on_rule_panel_continued(rule_panel: Control) -> void:
    rule_panel.queue_free()
    _load_next_exercise()


func _load_next_exercise() -> void:
    _current_exercise = ExerciseEngine.pick_exercise_for_mission(
        _mission, _last_exercise_id, _current_difficulty
    )
    _attempt_number = 1
    _update_progress_label()

    if _current_exercise_scene != null:
        _current_exercise_scene.queue_free()

    var scene_path: String = TYPE_SCENES[_mission["exercise_type"]]
    _current_exercise_scene = load(scene_path).instantiate()
    _exercise_container.add_child(_current_exercise_scene)
    _current_exercise_scene.load_exercise(_current_exercise)
    _connect_answer_signal()


## Un contenu encore peu nombreux (voir docs/specs/decisions.md, point 14)
## peut faire redonner le meme exercice d'une mission a l'autre tentative :
## sans ce repere, ca ressemble a un blocage plutot qu'a une progression.
func _update_progress_label() -> void:
    _progress_label.text = "%s %d/%d" % [
        UIText.get_text("exercise_host.progress_label"), _completed_count + 1, MISSION_LENGTH
    ]


func _connect_answer_signal() -> void:
    match _mission["exercise_type"]:
        "multiple_choice":
            _current_exercise_scene.answer_submitted.connect(_on_multiple_choice_submitted)
        "sentence_correction":
            _current_exercise_scene.answer_submitted.connect(_on_sentence_correction_submitted)
        "dictation":
            _current_exercise_scene.answer_submitted.connect(_on_dictation_submitted)


func _on_multiple_choice_submitted(selected_index: int) -> void:
    _handle_result(AnswerValidator.validate_multiple_choice(_current_exercise, selected_index))


func _on_sentence_correction_submitted(selected_indices: Array, corrections: Dictionary) -> void:
    var typed_indices: Array[int] = []
    for index: int in selected_indices:
        typed_indices.append(index)
    _handle_result(
        AnswerValidator.validate_sentence_correction(
            _current_exercise, typed_indices, corrections
        )
    )


func _on_dictation_submitted(submitted_text: String) -> void:
    _handle_result(DictationAnalyzer.analyze(_current_exercise, submitted_text))


func _handle_result(result: CorrectionResult) -> void:
    var support_level := AttemptFlow.SupportLevel.EXPLANATION
    var is_terminal := result.is_correct

    if not result.is_correct:
        support_level = AttemptFlow.support_level_for_attempt(_attempt_number)
        is_terminal = AttemptFlow.should_end_exercise(_attempt_number)

    if result.is_correct:
        _pending_outcome = (
            MissionScoring.OUTCOME_FIRST_TRY
            if _attempt_number == 1
            else MissionScoring.OUTCOME_WITH_HELP
        )
    elif is_terminal:
        _pending_outcome = MissionScoring.OUTCOME_REVEALED

    ProgressManager.record_attempt(
        _skill_id, result.is_correct, _attempt_number > 1, _mission["exercise_type"]
    )

    _show_feedback(result, support_level, is_terminal)


func _show_feedback(
    result: CorrectionResult, support_level: AttemptFlow.SupportLevel, is_terminal: bool
) -> void:
    var feedback: Control = preload("res://scenes/ui/feedback_panel.tscn").instantiate()
    _overlay_container.add_child(feedback)
    feedback.show_result(result, support_level)
    feedback.continue_pressed.connect(_on_feedback_continued.bind(feedback, is_terminal))


func _on_feedback_continued(feedback: Control, is_terminal: bool) -> void:
    feedback.queue_free()

    if not is_terminal:
        _attempt_number += 1
        return

    _current_difficulty = ProgressManager.next_difficulty_for_skill(
        _skill_id, _current_difficulty
    )
    _last_exercise_id = _current_exercise.get("id", "")
    _completed_count += 1
    _outcomes.append(_pending_outcome)

    if _completed_count >= MISSION_LENGTH:
        GameManager.last_outcomes = _outcomes.duplicate()
        GameManager.goto(GameManager.SCENE_REWARD)
    else:
        _load_next_exercise()
