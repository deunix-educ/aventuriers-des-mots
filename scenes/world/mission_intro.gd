extends Control
## Introduction de la mission choisie sur la carte : contexte narratif issu
## des donnees (data/missions/), pas un questionnaire habille d'un decor
## (voir "Points durs" du prompt de lancement, Sens de l'aventure).

@onready var _title_label: Label = %TitleLabel
@onready var _narrative_label: Label = %NarrativeLabel
@onready var _guide: Control = %Guide
@onready var _start_button: Button = %StartButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
    var mission := ExerciseEngine.get_mission(GameManager.pending_mission_id)
    _title_label.text = mission.get("title", "")
    _narrative_label.text = mission.get("narrative_context", "")
    _guide.say(mission.get("narrative_context", ""))

    _start_button.text = UIText.get_text("mission_intro.start_button")
    _back_button.text = UIText.get_text("mission_intro.back_button")

    _start_button.pressed.connect(_on_start_pressed)
    _back_button.pressed.connect(_on_back_pressed)


func _on_start_pressed() -> void:
    GameManager.goto(GameManager.SCENE_EXERCISE_HOST)


func _on_back_pressed() -> void:
    GameManager.pending_mission_id = ""
    GameManager.goto(GameManager.SCENE_WORLD_MAP)
