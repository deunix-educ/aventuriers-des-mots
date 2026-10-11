extends GutTest
## Tests d'AppSettings : valeurs par defaut, nettoyage des fichiers abimes,
## conversions volume/echelle de texte.


func test_defaults_are_usable() -> void:
    var settings := AppSettings.defaults()
    assert_true(settings["animations_enabled"])
    assert_eq(AppSettings.text_scale(settings), 1.0)


func test_sanitize_of_non_dictionary_gives_defaults() -> void:
    assert_eq(AppSettings.sanitize("n'importe quoi"), AppSettings.defaults())
    assert_eq(AppSettings.sanitize(null), AppSettings.defaults())


func test_sanitize_clamps_out_of_range_values() -> void:
    var clean := AppSettings.sanitize(
        {"volume": 7.0, "text_scale_index": 99, "animations_enabled": false}
    )
    assert_eq(clean["volume"], 1.0)
    assert_eq(clean["text_scale_index"], AppSettings.TEXT_SCALES.size() - 1)
    assert_false(clean["animations_enabled"])
    assert_eq(AppSettings.sanitize({"volume": -2})["volume"], 0.0)


func test_sanitize_ignores_wrong_types() -> void:
    var clean := AppSettings.sanitize(
        {"volume": "fort", "text_scale_index": "grand", "animations_enabled": "oui"}
    )
    assert_eq(clean, AppSettings.defaults())


func test_zero_volume_is_real_silence() -> void:
    assert_eq(AppSettings.volume_db(0.0), -80.0)
    assert_eq(AppSettings.volume_db(1.0), 0.0)
    assert_lt(AppSettings.volume_db(0.5), 0.0)


func test_music_and_effects_volumes_are_bounded() -> void:
    var clean := AppSettings.sanitize({"music_volume": 3, "effects_volume": -1})
    assert_eq(clean["music_volume"], 1.0)
    assert_eq(clean["effects_volume"], 0.0)
    assert_eq(AppSettings.sanitize({})["music_volume"], AppSettings.defaults()["music_volume"])
