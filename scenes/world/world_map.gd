extends Control
## Carte des missions du niveau scolaire du profil. Le prototype initial
## (cahier des charges §15) se limitait a trois lieux ; le perimetre a ete
## etendu (docs/specs/decisions.md, points 25 et 27). La position de chaque
## mission vient de data/missions/*.json (fractions 0..1 de la zone de
## carte), jamais d'une position fixe en dur dans le script : chaque lieu est
## replace quand la zone change de taille. Chaque niveau a un a trois
## « tableaux » (data/curriculum/) entre lesquels on circule ; un profil peut
## basculer sur le niveau precedent pour revoir les notions deja vues.

const MARKER_SCENE := preload("res://scenes/world/mission_marker.tscn")

var _viewed_level := "CE1"
var _viewed_region_id := ""

@onready var _backdrop: Control = %Backdrop
@onready var _title_label: Label = %TitleLabel
@onready var _map_area: Control = %MapArea
@onready var _level_toggle_button: Button = %LevelToggleButton
@onready var _region_button: Button = %RegionButton
@onready var _total_stars_label: Label = %TotalStarsLabel
@onready var _collection_button: Button = %CollectionButton
@onready var _profile_button: Button = %ProfileButton
@onready var _guide: Control = %Guide
@onready var _settings_button: Button = %SettingsButton


func _ready() -> void:
    _viewed_level = ProgressManager.school_level()
    _viewed_region_id = _initial_region_id()
    _level_toggle_button.pressed.connect(_on_level_toggle_pressed)
    _region_button.pressed.connect(_on_region_pressed)
    _collection_button.text = UIText.get_text("world_map.collection_button")
    _collection_button.pressed.connect(_on_collection_pressed)
    _profile_button.text = UIText.get_text("world_map.change_profile_button")
    _profile_button.pressed.connect(_on_change_profile_pressed)
    _settings_button.text = UIText.get_text("world_map.settings_button")
    _settings_button.pressed.connect(_on_settings_pressed)
    _map_area.resized.connect(_layout_markers)
    _guide.say(UIText.get_text("world_map.guide_hint"))
    _refresh()


func _refresh() -> void:
    var own_level := ProgressManager.school_level()
    var previous_level := SchoolLevels.previous(own_level)
    var regions := ExerciseEngine.get_regions_for_level(_viewed_level)
    var region := ExerciseEngine.get_region(_viewed_region_id)

    var kind: String = region.get("backdrop", BackdropKinds.FALLBACK)
    _backdrop.kind = kind if BackdropKinds.is_valid(kind) else BackdropKinds.FALLBACK
    AudioManager.play_region_music(_backdrop.kind)
    _title_label.text = region.get("region_title", region.get("title", ""))

    # Niveau precedent : « Revoir le CE1 » / « Retour au CE2 ».
    _level_toggle_button.visible = previous_level != ""
    var target_level := own_level if _viewed_level != own_level else previous_level
    _level_toggle_button.text = UIText.get_text(
        "world_map.review_level_button"
        if _viewed_level == own_level
        else "world_map.back_to_level_button"
    ) % target_level

    # Autres tableaux du niveau affiche : un bouton qui passe au suivant.
    _region_button.visible = regions.size() > 1
    if regions.size() > 1:
        var next_region := regions[(_region_index(regions) + 1) % regions.size()]
        _region_button.text = (
            UIText.get_text("world_map.other_region_button")
            % next_region.get("region_title", next_region["title"])
        )
    _total_stars_label.text = str(ProgressManager.stars())
    if region.is_empty():
        _title_label.text = UIText.get_text("world_map.coming_soon")
    _populate_missions()


## Tableau a afficher a l'ouverture : celui d'ou l'on vient s'il appartient
## au niveau du profil, sinon le premier du niveau.
func _initial_region_id() -> String:
    var regions := ExerciseEngine.get_regions_for_level(_viewed_level)
    for region in regions:
        if region["region_id"] == GameManager.map_region_id:
            return region["region_id"]
    return regions[0]["region_id"] if not regions.is_empty() else ""


func _region_index(regions: Array[Dictionary]) -> int:
    for i in regions.size():
        if regions[i]["region_id"] == _viewed_region_id:
            return i
    return 0


func _populate_missions() -> void:
    for child in _map_area.get_children():
        _map_area.remove_child(child)
        child.queue_free()

    var index := 0
    for mission: Dictionary in ExerciseEngine.get_missions_for_region(_viewed_region_id):
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
    var own_level := ProgressManager.school_level()
    _viewed_level = (
        SchoolLevels.previous(own_level) if _viewed_level == own_level else own_level
    )
    _viewed_region_id = _initial_region_id()
    _refresh()


func _on_region_pressed() -> void:
    var regions := ExerciseEngine.get_regions_for_level(_viewed_level)
    if regions.size() < 2:
        return
    _viewed_region_id = regions[(_region_index(regions) + 1) % regions.size()]["region_id"]
    GameManager.map_region_id = _viewed_region_id
    _refresh()


func _on_mission_pressed(mission_id: String) -> void:
    GameManager.pending_mission_id = mission_id
    GameManager.map_region_id = _viewed_region_id
    GameManager.goto(GameManager.SCENE_MISSION_INTRO)


func _on_settings_pressed() -> void:
    GameManager.settings_return_scene = GameManager.SCENE_WORLD_MAP
    GameManager.goto(GameManager.SCENE_SETTINGS)
