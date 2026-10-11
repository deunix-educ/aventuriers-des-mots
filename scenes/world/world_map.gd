extends Control
## Carte des missions. Le prototype initial (cahier des charges §15) se
## limitait a trois lieux ; le perimetre a ete etendu au-dela (voir
## docs/specs/decisions.md, point 25) pour couvrir plus d'une regle par
## chapitre. La position de chaque mission vient de data/missions/*.json
## (fractions 0..1 de la zone de carte), jamais d'une position fixe en dur
## dans le script.

const MARKER_HALF_WIDTH := 80.0
const MARKER_HALF_HEIGHT := 36.0

@onready var _title_label: Label = %TitleLabel
@onready var _map_area: Control = %MapArea


func _ready() -> void:
    _title_label.text = UIText.get_text("world_map.title")
    _populate_missions()


func _populate_missions() -> void:
    for child in _map_area.get_children():
        child.queue_free()

    for mission: Dictionary in ExerciseEngine.get_missions():
        _map_area.add_child(_build_marker(mission))


func _build_marker(mission: Dictionary) -> Control:
    var button := Button.new()
    button.text = "%s\n%s" % [mission["title"], _status_label_for(mission)]

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
