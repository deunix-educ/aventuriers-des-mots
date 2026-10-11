extends Control
## Ecran de fin de mission : etoiles gagnees (1 a 3, selon la reussite et
## l'aide utilisee, jamais selon la vitesse : cahier des charges §2), total,
## nouveaux objets de la collection. Une mission terminee rapporte toujours
## au moins une etoile. Sauvegarde groupee ici, en fin de mission
## (docs/specs/decisions.md point 7).

@onready var _title_label: Label = %TitleLabel
@onready var _stars_label: Label = %StarsLabel
@onready var _message_label: Label = %MessageLabel
@onready var _record_label: Label = %RecordLabel
@onready var _total_label: Label = %TotalLabel
@onready var _new_items_label: Label = %NewItemsLabel
@onready var _collection_button: Button = %CollectionButton
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
    var summary := ProgressManager.complete_mission(
        GameManager.pending_mission_id, GameManager.last_outcomes
    )
    ProgressManager.save_now()

    _title_label.text = UIText.get_text("reward_screen.title")
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

    var new_items: Array = summary["new_items"]
    _new_items_label.visible = not new_items.is_empty()
    if not new_items.is_empty():
        var titles: Array[String] = []
        for item in ExerciseEngine.get_reward_items():
            if new_items.has(item["item_id"]):
                titles.append(item["title"])
        _new_items_label.text = (
            "%s\n%s" % [UIText.get_text("reward_screen.new_items_label"), "\n".join(titles)]
        )

    _collection_button.text = UIText.get_text("reward_screen.collection_button")
    _collection_button.pressed.connect(_on_collection_pressed)
    _continue_button.text = UIText.get_text("reward_screen.continue_button")
    _continue_button.pressed.connect(_on_continue_pressed)


func _on_collection_pressed() -> void:
    GameManager.pending_mission_id = ""
    GameManager.goto(GameManager.SCENE_COLLECTION)


func _on_continue_pressed() -> void:
    GameManager.pending_mission_id = ""
    GameManager.goto(GameManager.SCENE_WORLD_MAP)
