extends GutTest
## exercise_host note, pour chaque exercice termine, comment il a ete resolu
## (du premier coup, avec aide, reponse montree) : c'est ce qui alimente le
## score de la mission (MissionScoring). Le changement de scene final n'est
## jamais atteint ici.

var _profile_id: String = ""


func before_each() -> void:
    _profile_id = ProfileManager.create_profile("Test", "CE1")
    ProfileManager.select_profile(_profile_id)
    GameManager.pending_mission_id = "mission_01_pre_des_mots"


func after_each() -> void:
    ProfileManager.delete_profile(_profile_id)
    GameManager.pending_mission_id = ""


func _open_host() -> Control:
    var host: Control = load("res://scenes/exercises/exercise_host.tscn").instantiate()
    add_child_autofree(host)
    await wait_process_frames(1)
    host.get_node("%OverlayContainer").get_child(0).continued.emit()
    await wait_process_frames(1)
    return host


func _answer(host: Control, correctly: bool) -> void:
    var exercise: Dictionary = host.get_current_exercise()
    var correct: int = exercise["correct_answer"]
    var choice := correct if correctly else (correct + 1) % (exercise["answers"] as Array).size()
    host.get_node("%ExerciseContainer").get_child(0).answer_submitted.emit(choice)
    await wait_process_frames(1)
    var overlay: Control = host.get_node("%OverlayContainer")
    overlay.get_child(overlay.get_child_count() - 1).get_node("%ContinueButton").pressed.emit()
    await wait_process_frames(1)


func test_correct_first_try_then_found_with_help_then_revealed() -> void:
    var host: Control = await _open_host()

    await _answer(host, true)
    await _answer(host, false)
    await _answer(host, true)
    await _answer(host, false)
    await _answer(host, false)
    await _answer(host, false)

    assert_eq(
        host.get_outcomes(),
        [
            MissionScoring.OUTCOME_FIRST_TRY,
            MissionScoring.OUTCOME_WITH_HELP,
            MissionScoring.OUTCOME_REVEALED,
        ]
    )
