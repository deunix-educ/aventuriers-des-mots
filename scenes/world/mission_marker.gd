extends Button
## Un lieu de la carte : pictogramme du type d'exercice, titre, etoiles
## gagnees (pleines/vides : la forme porte l'information, pas la couleur) et
## etat de la competence. Scene autonome : la carte la configure et ecoute
## `pressed`.

const STAR_FULL := preload("res://assets/interface/star_full.svg")
const STAR_EMPTY := preload("res://assets/interface/star_empty.svg")
const TYPE_ICONS := {
    "multiple_choice": "res://assets/interface/icon_multiple_choice.svg",
    "sentence_correction": "res://assets/interface/icon_sentence_correction.svg",
    "dictation": "res://assets/interface/icon_dictation.svg",
}
const STAR_SIZE := 24.0

@onready var _type_icon: TextureRect = %TypeIcon
@onready var _title_label: Label = %TitleLabel
@onready var _stars_row: HBoxContainer = %StarsRow
@onready var _status_label: Label = %StatusLabel


func setup(mission: Dictionary, stars: int, max_stars: int, status_text: String) -> void:
    _title_label.text = mission["title"]
    _status_label.text = status_text
    _status_label.visible = not status_text.is_empty()
    _type_icon.texture = load(TYPE_ICONS.get(mission["exercise_type"], TYPE_ICONS["multiple_choice"]))

    for child in _stars_row.get_children():
        child.queue_free()
    for i in max_stars:
        var star := TextureRect.new()
        star.texture = STAR_FULL if i < stars else STAR_EMPTY
        star.custom_minimum_size = Vector2(STAR_SIZE, STAR_SIZE)
        star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        star.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _stars_row.add_child(star)
