extends Control
## Carte des missions du niveau scolaire du profil. Le prototype initial
## (cahier des charges §15) se limitait a trois lieux ; le perimetre a ete
## etendu (docs/specs/decisions.md, points 25 et 27). La position de chaque
## mission vient de data/missions/*.json (fractions 0..1 de la zone de
## carte), jamais d'une position fixe en dur dans le script. Un profil CE2
## peut basculer sur la carte CE1 pour revoir les notions precedentes.

const MARKER_HALF_WIDTH := 80.0
const MARKER_HALF_HEIGHT := 48.0

var _viewed_level := "CE1"

@onready var _title_label: Label = %TitleLabel
@onready var _map_area: Control = %MapArea
@onready var _level_toggle_button: Button = %LevelToggleButton
@onready var _total_stars_label: Label = %TotalStarsLabel
@onready var _collection_button: Button = %CollectionButton


func _ready() -> void:
    _viewed_level = ProgressManager.school_level()
    _level_toggle_button.visible = _viewed_level == "CE2"
    _level_toggle_button.pressed.connect(_on_level_toggle_pressed)
    _collection_button.text = UIText.get_text("world_map.collection_button")
    _collection_button.pressed.connect(_on_collection_pressed)
    _refresh()


func _refresh() -> void:
    var title_key := "world_map.title_ce2" if _viewed_level == "CE2" else "world_map.title"
    _title_label.text = UIText.get_text(title_key)
    var toggle_key := (
        "world_map.review_ce1_button" if _viewed_level == "CE2" else "world_map.back_to_ce2_button"
    )
    _level_toggle_button.text = UIText.get_text(toggle_key)
    _total_stars_label.text = (
        "%s %d" % [UIText.get_text("world_map.total_stars_label"), ProgressManager.stars()]
    )
    _populate_missions()


func _populate_missions() -> void:
    for child in _map_area.get_children():
        _map_area.remove_child(child)
        child.queue_free()

    for mission: Dictionary in ExerciseEngine.get_missions_for_level(_viewed_level):
        _map_area.add_child(_build_marker(mission))


func _on_collection_pressed() -> void:
    GameManager.goto(GameManager.SCENE_COLLECTION)


func _on_level_toggle_pressed() -> void:
    _viewed_level = "CE1" if _viewed_level == "CE2" else "CE2"
    _refresh()


func _build_marker(mission: Dictionary) -> Control:
    var button := Button.new()
    button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    button.text = (
        "%s\n%s\n%s %d/%d"
        % [
            mission["title"],
            _status_label_for(mission),
            UIText.get_text("world_map.mission_stars_label"),
            ProgressManager.mission_best_stars(mission["mission_id"]),
            MissionScoring.MAX_STARS,
        ]
    )

    var map_position: Dictionary = mission["map_position"]
    var x: float = map_position["x"]
    var y: float = map_position["y"]
    button.anchor_left = x
    button.anchor_right = x
    button.anchor_top = y
    button.anchor_bottom = y
    button.offset_left = -MARKER_HALF_WIDTH
    button.offset_right = MARKER_HALF_WIDTH
    button.offset_top = -MARKER_HALF_HEIGHT
    button.offset_bottom = MARKER_HALF_HEIGHT

    button.pressed.connect(_on_mission_pressed.bind(mission["mission_id"]))
    return button


func _status_label_for(mission: Dictionary) -> String:
    var rule: Dictionary = ExerciseEngine.get_rule(mission["rule_id"])
    var skill_id: String = rule.get("skill", "")
    var skill_state := ProgressManager.get_skill_state(skill_id)
    var status: String = skill_state["status"]
    return UIText.get_text("world_map.status_%s" % status)


func _on_mission_pressed(mission_id: String) -> void:
    GameManager.pending_mission_id = mission_id
    GameManager.goto(GameManager.SCENE_MISSION_INTRO)
