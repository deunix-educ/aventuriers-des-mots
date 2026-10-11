extends Control
## Panneau de regle : affiche l'enonce et l'exemple issus de data/rules/
## (cycle d'apprentissage §2, etape "Decouvrir la regle"). Instancie par
## exercise_host, qui ecoute le signal `continued` pour lancer le premier
## exercice.

signal continued

@onready var _title_label: Label = %TitleLabel
@onready var _statement_label: Label = %StatementLabel
@onready var _example_label: Label = %ExampleLabel
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
    _title_label.text = UIText.get_text("rule_panel.title")
    _continue_button.text = UIText.get_text("rule_panel.continue_button")
    _continue_button.pressed.connect(_on_continue_pressed)


func show_rule(rule: Dictionary) -> void:
    _statement_label.text = rule.get("statement", "")
    _example_label.text = "%s %s" % [
        UIText.get_text("rule_panel.example_label"), rule.get("example", "")
    ]


func _on_continue_pressed() -> void:
    continued.emit()
