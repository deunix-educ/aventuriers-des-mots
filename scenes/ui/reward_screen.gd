extends Control
## Ecran de recompense : une mission terminee rapporte toujours la meme
## recompense, que l'enfant ait eu besoin d'aide ou non (cahier des charges
## §2, principe 6 : pas de recompense liee a la vitesse ou a la performance).
## Sauvegarde groupee ici, en fin de mission (docs/specs/decisions.md point 7).

const STARS_PER_MISSION := 1

@onready var _title_label: Label = %TitleLabel
@onready var _stars_label: Label = %StarsLabel
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
    ProgressManager.add_stars(STARS_PER_MISSION)
    ProgressManager.save_now()

    _title_label.text = UIText.get_text("reward_screen.title")
    _stars_label.text = "%s %d" % [
        UIText.get_text("reward_screen.stars_label"), ProgressManager.stars()
    ]
    _continue_button.text = UIText.get_text("reward_screen.continue_button")
    _continue_button.pressed.connect(_on_continue_pressed)


func _on_continue_pressed() -> void:
    GameManager.pending_mission_id = ""
    GameManager.goto(GameManager.SCENE_WORLD_MAP)
