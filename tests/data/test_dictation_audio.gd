extends GutTest
## L'absence de fichier audio pour une dictee bloque tout test manuel de ce
## type d'exercice (voir docs/specs/decisions.md, point 19) : ce test garantit
## que chaque dictee marquee `audio_provisional: true` a reellement un fichier
## `.ogg` chargeable, pas seulement une entree de donnees qui le promet.


func test_every_provisional_dictation_has_a_loadable_audio_file() -> void:
    var dictation_paths := DataLoader.find_json_files("res://data/dictations")
    assert_false(dictation_paths.is_empty(), "il doit y avoir au moins une dictee a verifier")

    for path: String in dictation_paths:
        var dictation: Dictionary = DataLoader.read_json(path)
        if not dictation.get("audio_provisional", false):
            continue

        var audio_id: String = dictation["audio_id"]
        var audio_path := "res://assets/audio/dictations/%s.ogg" % audio_id
        assert_true(
            ResourceLoader.exists(audio_path),
            "audio manquant pour %s : %s" % [audio_id, audio_path],
        )
        var stream: Variant = load(audio_path)
        assert_true(
            stream is AudioStream, "le fichier charge pour %s doit etre un AudioStream" % audio_id
        )
