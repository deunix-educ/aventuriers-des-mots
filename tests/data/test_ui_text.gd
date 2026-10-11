extends GutTest
## Tests de UIText : les textes destines a l'enfant viennent de
## data/localization/fr.json, jamais d'une chaine en dur.


func test_known_key_resolves_to_real_text() -> void:
    assert_eq(UIText.get_text("profile_select.title"), "Choisis ton profil")


func test_unknown_key_falls_back_to_the_key_itself() -> void:
    assert_eq(UIText.get_text("cle_qui_n_existe_pas"), "cle_qui_n_existe_pas")
    assert_push_error("Cle de traduction manquante")
