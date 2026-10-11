extends Control
## Collection d'objets gagnes avec les etoiles. Un objet non debloque reste
## mysterieux mais indique comment l'obtenir (jamais de mystere frustrant).

const ICON_SIZE := 72.0

@onready var _title_label: Label = %TitleLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _items_box: GridContainer = %ItemsBox
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


## Une ligne = pictogramme + texte (le Label s'appelle "TextLabel").
func _build_row(item: Dictionary, is_owned: bool) -> Control:
    var card := PanelContainer.new()
    card.theme_type_variation = &"SoftCard"
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    card.add_child(row)

    var icon := TextureRect.new()
    icon.texture = (
        ItemIcons.texture_for(item["item_id"]) if is_owned else ItemIcons.locked_texture()
    )
    icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    row.add_child(icon)

    var label := Label.new()
    label.name = "TextLabel"
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    if is_owned:
        label.text = "%s\n%s" % [item["title"], item["description"]]
    else:
        label.text = (
            "%s\n%s" % [UIText.get_text("collection.locked_title"), _unlock_hint(item["unlock"])]
        )
    row.add_child(label)
    return card


func _unlock_hint(unlock: Dictionary) -> String:
    var count: int = int(unlock["count"])
    if unlock["type"] == "mission_stars":
        var mission := ExerciseEngine.get_mission(unlock.get("mission_id", ""))
        return UIText.get_text("collection.unlock_mission_stars") % [count, mission.get("title", "")]
    return UIText.get_text("collection.unlock_total_stars") % count


func _on_back_pressed() -> void:
    GameManager.goto(GameManager.SCENE_WORLD_MAP)
