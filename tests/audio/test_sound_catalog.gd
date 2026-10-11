extends GutTest
## Chaque identifiant sonore pointe vers un fichier present ; un identifiant
## inconnu ne produit jamais de chemin libre.


func test_every_sfx_file_exists() -> void:
    for sfx_id in SoundCatalog.SFX_IDS:
        assert_true(ResourceLoader.exists(SoundCatalog.sfx_path(sfx_id)), sfx_id)


func test_every_music_file_exists() -> void:
    for music_id in SoundCatalog.MUSIC_IDS:
        assert_true(ResourceLoader.exists(SoundCatalog.music_path(music_id)), music_id)


func test_unknown_ids_give_no_path() -> void:
    assert_eq(SoundCatalog.sfx_path("../../etc/passwd"), "")
    assert_eq(SoundCatalog.music_path("inconnue"), "")


func test_music_follows_the_level() -> void:
    assert_eq(SoundCatalog.music_for_level("CE1"), "forest")
    assert_eq(SoundCatalog.music_for_level("CE2"), "marsh")


func test_audio_manager_plays_without_crashing_and_remembers_music() -> void:
    AudioManager.play_sfx("success")
    AudioManager.play_music("marsh")
    assert_eq(AudioManager.current_music_id(), "marsh")
    AudioManager.play_music("marsh")
    AudioManager.stop_music()
    assert_eq(AudioManager.current_music_id(), "")


func test_buses_exist_and_are_idempotent() -> void:
    AudioBuses.ensure()
    AudioBuses.ensure()
    assert_ne(AudioServer.get_bus_index(AudioBuses.MUSIC), -1)
    assert_ne(AudioServer.get_bus_index(AudioBuses.EFFECTS), -1)
    var count := 0
    for i in AudioServer.bus_count:
        if AudioServer.get_bus_name(i) == AudioBuses.MUSIC:
            count += 1
    assert_eq(count, 1)
