extends GutTest
## Test d'integration de exercise_host : regle -> exercice -> validation ->
## enregistrement de la tentative. S'arrete avant la fin de la mission : aller
## jusqu'au bout declencherait un vrai changement de scene (GameManager.goto),
## ce qui casserait le processus de test lui-meme.

var _profile_id: String = ""


func before_each() -> void:
    _profile_id = ProfileManager.create_profile("Test", "CE1")
    ProfileManager.select_profile(_profile_id)
    GameManager.pending_mission_id = "mission_01_pre_des_mots"


func after_each() -> void:
    ProfileManager.delete_profile(_profile_id)
    GameManager.pending_mission_id = ""


func _start_host() -> Control:
    var host: Control = load("res://scenes/exercises/exercise_host.tscn").instantiate()
    add_child_autofree(host)
    await wait_process_frames(1)
    return host


func test_rule_panel_is_shown_before_any_exercise() -> void:
    var host := await _start_host()
    var overlay: Control = host.get_node("%OverlayContainer")
    assert_eq(overlay.get_child_count(), 1)
    assert_eq(host.get_node("%ExerciseContainer").get_child_count(), 0)


func test_dismissing_rule_panel_loads_the_first_exercise() -> void:
    var host := await _start_host()
    var overlay: Control = host.get_node("%OverlayContainer")
    overlay.get_child(0).continued.emit()
    await wait_process_frames(1)

    assert_eq(overlay.get_child_count(), 0)
    assert_eq(host.get_node("%ExerciseContainer").get_child_count(), 1)
    assert_eq(host.get_current_exercise()["rule_id"], "regle_accord_adjectif")


func test_correct_answer_records_a_successful_attempt() -> void:
    var host := await _start_host()
    var overlay: Control = host.get_node("%OverlayContainer")
    overlay.get_child(0).continued.emit()
    await wait_process_frames(1)

    var exercise_scene: Control = host.get_node("%ExerciseContainer").get_child(0)
    var correct_index: int = host.get_current_exercise()["correct_answer"]
    exercise_scene.answer_submitted.emit(correct_index)
    await wait_process_frames(1)

    assert_eq(overlay.get_child_count(), 1, "le panneau de retour doit s'afficher")
    var skill_state := ProgressManager.get_skill_state("accord_groupe_nominal")
    assert_eq(skill_state["recent_results"], [true])
    assert_eq(skill_state["recent_hint_used"], [false])


func test_wrong_answer_escalates_hint_then_explanation_then_reveal() -> void:
    var host := await _start_host()
    var overlay: Control = host.get_node("%OverlayContainer")
    overlay.get_child(0).continued.emit()
    await wait_process_frames(1)

    var exercise: Dictionary = host.get_current_exercise()
    var wrong_index := 0 if exercise["correct_answer"] != 0 else 1

    for _i in 3:
        var exercise_scene: Control = host.get_node("%ExerciseContainer").get_child(0)
        exercise_scene.answer_submitted.emit(wrong_index)
        await wait_process_frames(1)
        var feedback: Control = overlay.get_child(overlay.get_child_count() - 1)
        feedback.continue_pressed.emit()
        await wait_process_frames(1)

    # Apres 3 echecs, l'exercice est termine (reponse montree) et un nouveau
    # commence : le compteur de tentative revient a 1, et une mission n'est
    # pas encore terminee (longueur 3, un seul exercice traite ici).
    assert_eq(host.get_attempt_number(), 1)
    assert_eq(host.get_completed_count(), 1)

    var skill_state := ProgressManager.get_skill_state("accord_groupe_nominal")
    assert_eq(skill_state["recent_results"], [false, false, false])
    assert_eq(skill_state["recent_hint_used"], [false, true, true])


func test_a_mission_never_shows_the_same_exercise_twice() -> void:
    # Regression : le tirage n'excluait que le dernier exercice, donc le meme
    # enonce pouvait revenir dans une meme mission (A, B, A). On s'arrete au
    # troisieme exercice charge, sans le terminer (pas de changement de scene).
    for _run in range(10):
        var host := await _start_host()
        host.get_node("%OverlayContainer").get_child(0).continued.emit()
        await wait_process_frames(1)
        var shown: Array[String] = []
        for step in range(3):
            shown.append(host.get_current_exercise()["id"])
            if step == 2:
                break
            var scene: Control = host.get_node("%ExerciseContainer").get_child(0)
            scene.answer_submitted.emit(host.get_current_exercise()["correct_answer"])
            await wait_process_frames(1)
            var overlay: Control = host.get_node("%OverlayContainer")
            var feedback: Control = overlay.get_child(overlay.get_child_count() - 1)
            feedback.get_node("%ContinueButton").pressed.emit()
            await wait_process_frames(1)
        var unique := {}
        for exercise_id in shown:
            unique[exercise_id] = true
        assert_eq(unique.size(), 3, "exercices vus : %s" % [shown])
        host.queue_free()
        await wait_process_frames(1)
