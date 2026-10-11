extends GutTest
## Verifie que le squelette du projet charge correctement les sept autoloads.
## Les tests de logique pedagogique (correction, progression, sauvegardes)
## arrivent avec les etapes correspondantes.


func test_autoloads_are_registered() -> void:
    assert_not_null(GameManager, "GameManager doit etre charge")
    assert_not_null(ProfileManager, "ProfileManager doit etre charge")
    assert_not_null(ProgressManager, "ProgressManager doit etre charge")
    assert_not_null(ExerciseEngine, "ExerciseEngine doit etre charge")
    assert_not_null(SaveManager, "SaveManager doit etre charge")
    assert_not_null(AudioManager, "AudioManager doit etre charge")
    assert_not_null(SettingsManager, "SettingsManager doit etre charge")
