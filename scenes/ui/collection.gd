extends Control
## Collection d'objets gagnes avec les etoiles. Un objet non debloque reste
## mysterieux mais indique comment l'obtenir (jamais de mystere frustrant).

@onready var _title_label: Label = %TitleLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _items_box: VBoxContainer = %ItemsBox
@onready var _back_button: Button = %BackButton


func _ready() -> void:
    _title_label.text = UIText.get_text("collection.title")
    _back_button.text = UIText.get_text("collection.back_button")
    _back_button.pressed.connect(_on_back_pressed)

    var owned: Array = ProgressManager.owned_items()
    var catalog := ExerciseEngine.get_reward_items()
    var found := 0
    for item in catalog:
        var is_owned := owned.has(item["item_id"])
        if is_owned:
            found += 1
        _items_box.add_child(_build_row(item, is_owned))
    _progress_label.text = (
        "%s %d/%d" % [UIText.get_text("collection.progress_label"), found, catalog.size()]
    )


func _build_row(item: Dictionary, is_owned: bool) -> Control:
    var label := Label.new()
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.custom_minimum_size = Vector2(560, 0)
    if is_owned:
        label.text = (
            "%s — %s\n%s"
            % [item["title"], UIText.get_text("collection.owned_marker"), item["description"]]
        )
    else:
        label.text = (
            "%s\n%s" % [UIText.get_text("collection.locked_title"), _unlock_hint(item["unlock"])]
        )
    return label


func _unlock_hint(unlock: Dictionary) -> String:
    var count: int = int(unlock["count"])
    if unlock["type"] == "mission_stars":
        var mission := ExerciseEngine.get_mission(unlock.get("mission_id", ""))
        return UIText.get_text("collection.unlock_mission_stars") % [count, mission.get("title", "")]
    return UIText.get_text("collection.unlock_total_stars") % count


func _on_back_pressed() -> void:
    GameManager.goto(GameManager.SCENE_WORLD_MAP)
