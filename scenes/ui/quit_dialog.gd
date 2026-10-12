extends ConfirmationDialog
## Confirmation avant de quitter le jeu. La progression est sauvegardee avant
## la sortie (GameManager.quit_game). Les textes viennent de fr.json.


func _ready() -> void:
    title = UIText.get_text("quit.confirm_title")
    dialog_text = UIText.get_text("quit.confirm_message")
    ok_button_text = UIText.get_text("quit.confirm_yes")
    cancel_button_text = UIText.get_text("quit.confirm_no")
    confirmed.connect(_on_confirmed)


func request() -> void:
    popup_centered()


func _on_confirmed() -> void:
    GameManager.quit_game()
