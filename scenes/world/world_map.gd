extends Control
## Carte des missions du niveau scolaire du profil. Le prototype initial
## (cahier des charges §15) se limitait a trois lieux ; le perimetre a ete
## etendu (docs/specs/decisions.md, points 25 et 27). La position de chaque
## mission vient de data/missions/*.json (fractions 0..1 de la zone de
## carte), jamais d'une position fixe en dur dans le script : chaque lieu est
## replace quand la zone change de taille. Un profil CE2 peut basculer sur la
## carte CE1 pour revoir les notions precedentes.

const MARKER_SCENE := preload("res://scenes/world/mission_marker.tscn")

var _viewed_level := "CE1"

@onready var _backdrop: Control = %Backdrop
@onready var _title_label: Label = %TitleLabel
@onready var _map_area: Control = %MapArea
@onready var _level_toggle_button: Button = %LevelToggleButton
@onready var _total_stars_label: Label = %TotalStarsLabel
@onready var _collection_button: Button = %CollectionButton
@onready var _profile_button: Button = %ProfileButton
@onready var _guide: Control = %Guide


func _ready() -> void:
    _viewed_level = ProgressManager.school_level()
    _level_toggle_button.visible = _viewed_level == "CE2"
    _level_toggle_button.pressed.connect(_on_level_toggle_pressed)
    _collection_button.text = UIText.get_text("world_map.collection_button")
    _collection_button.pressed.connect(_on_collection_pressed)
    _profile_button.text = UIText.get_text("world_map.change_profile_button")
    _profile_button.pressed.connect(_on_change_profile_pressed)
    _map_area.resized.connect(_layout_markers)
    _guide.say(UIText.get_text("world_map.guide_hint"))
    _refresh()


func _refresh() -> void:
    var is_ce2 := _viewed_level == "CE2"
    _backdrop.kind = "marsh" if is_ce2 else "forest"
    _title_label.text = UIText.get_text("world_map.title_ce2" if is_ce2 else "world_map.title")
    _level_toggle_button.text = UIText.get_text(
        "world_map.review_ce1_button" if is_ce2 else "world_map.back_to_ce2_button"
    )
    _total_stars_label.text = str(ProgressManager.stars())
    _populate_missions()


func _populate_missions() -> void:
    for child in _map_area.get_children():
        _map_area.remove_child(child)
        child.queue_free()

    var index := 0
    for mission: Dictionary in ExerciseEngine.get_missions_for_level(_viewed_level):
        var marker: Button = MARKER_SCENE.instantiate()
        _map_area.add_child(marker)
        marker.set_meta("map_position", mission["map_position"])
        marker.setup(
            mission,
            ProgressManager.mission_best_stars(mission["mission_id"]),
            MissionScoring.MAX_STARS,
            _status_label_for(mission)
        )
        marker.pressed.connect(_on_mission_pressed.bind(mission["mission_id"]))
        Motion.pop_in(marker, 0.04 * index)
        index += 1
    _layout_markers()


## Replace chaque lieu selon sa position fractionnelle. Les positions du
## niveau affiche sont etalees sur toute la zone (la plus petite colle au
## bord, la plus grande au bord oppose) : les lieux restent entierement
## visibles et ne se chevauchent pas, quelle que soit la taille de la fenetre.
func _layout_markers() -> void:
    var markers: Array[Control] = []
    var low := Vector2(INF, INF)
    var high := Vector2(-INF, -INF)
    for child in _map_area.get_children():
        var control := child as Control
        if control == null or not control.has_meta("map_position"):
            continue
        var fraction: Dictionary = control.get_meta("map_position")
        var point := Vector2(float(fraction["x"]), float(fraction["y"]))
        low = Vector2(minf(low.x, point.x), minf(low.y, point.y))
        high = Vector2(maxf(high.x, point.x), maxf(high.y, point.y))
        markers.append(control)

    for control in markers:
        var fraction: Dictionary = control.get_meta("map_position")
        var free_space := _map_area.size - control.size
        control.position = Vector2(
            _spread(float(fraction["x"]), low.x, high.x) * maxf(free_space.x, 0.0),
            _spread(float(fraction["y"]), low.y, high.y) * maxf(free_space.y, 0.0)
        )


func _spread(value: float, low: float, high: float) -> float:
    if high - low < 0.0001:
        return 0.5
    return (value - low) / (high - low)


func _status_label_for(mission: Dictionary) -> String:
    var rule: Dictionary = ExerciseEngine.get_rule(mission["rule_id"])
    var skill_id: String = rule.get("skill", "")
    var skill_state := ProgressManager.get_skill_state(skill_id)
    var status: String = skill_state["status"]
    if status == "decouverte":
        return ""
    return UIText.get_text("world_map.status_%s" % status)


## Revient au choix du profil sans rien perdre : la progression est ecrite
## avant de quitter la carte (le profil se rechargera a la prochaine selection).
func _on_change_profile_pressed() -> void:
    ProgressManager.save_now()
    GameManager.goto(GameManager.SCENE_PROFILE_SELECT)


func _on_collection_pressed() -> void:
    GameManager.goto(GameManager.SCENE_COLLECTION)


func _on_level_toggle_pressed() -> void:
    _viewed_level = "CE1" if _viewed_level == "CE2" else "CE2"
    _refresh()


func _on_mission_pressed(mission_id: String) -> void:
    GameManager.pending_mission_id = mission_id
    GameManager.goto(GameManager.SCENE_MISSION_INTRO)
