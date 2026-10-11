extends Control
## Ecran de fin de mission : etoiles gagnees (1 a 3, selon la reussite et
## l'aide utilisee, jamais selon la vitesse : cahier des charges §2), total,
## nouveaux objets de la collection. Une mission terminee rapporte toujours
## au moins une etoile. Sauvegarde groupee ici, en fin de mission
## (docs/specs/decisions.md point 7).

const STAR_FULL := preload("res://assets/interface/star_full.svg")
const STAR_EMPTY := preload("res://assets/interface/star_empty.svg")
const STAR_SIZE := 88.0
const ITEM_SIZE := 72.0

@onready var _backdrop: Control = %Backdrop
@onready var _title_label: Label = %TitleLabel
@onready var _stars_row: HBoxContainer = %StarsRow
@onready var _stars_label: Label = %StarsLabel
@onready var _message_label: Label = %MessageLabel
@onready var _record_label: Label = %RecordLabel
@onready var _total_label: Label = %TotalLabel
@onready var _new_items_box: VBoxContainer = %NewItemsBox
@onready var _new_items_label: Label = %NewItemsLabel
@onready var _new_items_row: HBoxContainer = %NewItemsRow
@onready var _collection_button: Button = %CollectionButton
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
    var mission := ExerciseEngine.get_mission(GameManager.pending_mission_id)
    var rule := ExerciseEngine.get_rule(mission.get("rule_id", ""))
    _backdrop.kind = "marsh" if rule.get("level", "CE1") == "CE2" else "forest"

    var summary := ProgressManager.complete_mission(
        GameManager.pending_mission_id, GameManager.last_outcomes
    )
    ProgressManager.save_now()

    _title_label.text = UIText.get_text("reward_screen.title")
    _show_stars(summary["stars"])
    _stars_label.text = (
        "%s %d/%d"
        % [UIText.get_text("reward_screen.stars_label"), summary["stars"], MissionScoring.MAX_STARS]
    )
    _message_label.text = UIText.get_text("reward_screen.message_%d" % summary["stars"])
    _record_label.text = UIText.get_text("reward_screen.record_label")
    _record_label.visible = summary["is_record"]
    _total_label.text = (
        "%s %d" % [UIText.get_text("reward_screen.total_label"), summary["total_stars"]]
    )
    _show_new_items(summary["new_items"])

    _collection_button.text = UIText.get_text("reward_screen.collection_button")
    _collection_button.pressed.connect(_on_collection_pressed)
    _continue_button.text = UIText.get_text("reward_screen.continue_button")
    _continue_button.pressed.connect(_on_continue_pressed)


func _show_stars(earned: int) -> void:
    for i in MissionScoring.MAX_STARS:
        var star := TextureRect.new()
        star.texture = STAR_FULL if i < earned else STAR_EMPTY
        star.custom_minimum_size = Vector2(STAR_SIZE, STAR_SIZE)
        star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        _stars_row.add_child(star)
        if i < earned:
            Motion.pop_in(star, 0.25 + 0.2 * i)


func _show_new_items(new_items: Array) -> void:
    _new_items_box.visible = not new_items.is_empty()
    if new_items.is_empty():
        return
    _new_items_label.text = UIText.get_text("reward_screen.new_items_label")
    var index := 0
    for item in ExerciseEngine.get_reward_items():
        if not new_items.has(item["item_id"]):
            continue
        var holder := VBoxContainer.new()
        var icon := TextureRect.new()
        icon.texture = ItemIcons.texture_for(item["item_id"])
        icon.custom_minimum_size = Vector2(ITEM_SIZE, ITEM_SIZE)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        holder.add_child(icon)
        var name_label := Label.new()
        name_label.text = item["title"]
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_label.theme_type_variation = &"Small"
        holder.add_child(name_label)
        _new_items_row.add_child(holder)
        Motion.pop_in(holder, 0.8 + 0.15 * index)
        index += 1


func _on_collection_pressed() -> void:
    GameManager.pending_mission_id = ""
    GameManager.goto(GameManager.SCENE_COLLECTION)


func _on_continue_pressed() -> void:
    GameManager.pending_mission_id = ""
    GameManager.goto(GameManager.SCENE_WORLD_MAP)
