extends GutTest
## Tests de ExercisePicker.

var rng := RandomNumberGenerator.new()


func before_each() -> void:
    rng.seed = 42


func test_empty_candidates_returns_null() -> void:
    var candidates: Array[Dictionary] = []
    assert_null(ExercisePicker.pick(candidates, "", rng))


func test_picks_among_candidates() -> void:
    var candidates: Array[Dictionary] = [{"id": "a"}, {"id": "b"}, {"id": "c"}]
    var picked: Dictionary = ExercisePicker.pick(candidates, "", rng)
    var ids: Array = candidates.map(func(c: Dictionary) -> String: return c["id"])
    assert_true(ids.has(picked["id"]))


func test_never_returns_the_excluded_id_when_alternatives_exist() -> void:
    var candidates: Array[Dictionary] = [{"id": "a"}, {"id": "b"}]
    for _i in 20:
        var picked: Dictionary = ExercisePicker.pick(candidates, "a", rng)
        assert_eq(picked["id"], "b")


func test_returns_the_only_candidate_even_if_excluded() -> void:
    var candidates: Array[Dictionary] = [{"id": "a"}]
    var picked: Dictionary = ExercisePicker.pick(candidates, "a", rng)
    assert_eq(picked["id"], "a")


func test_pick_unseen_never_repeats_while_others_remain() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 3
    var candidates: Array[Dictionary] = [{"id": "a"}, {"id": "b"}, {"id": "c"}]
    var seen: Array[String] = []
    for _i in range(3):
        var picked: Dictionary = ExercisePicker.pick_unseen(candidates, candidates, seen, rng)
        assert_false(seen.has(picked["id"]), "un exercice deja vu a ete redonne")
        seen.append(picked["id"])
    assert_eq(seen.size(), 3)


func test_pick_unseen_falls_back_to_other_difficulty_then_to_repeat() -> void:
    var rng := RandomNumberGenerator.new()
    var preferred: Array[Dictionary] = [{"id": "a"}]
    var all: Array[Dictionary] = [{"id": "a"}, {"id": "b"}]
    var picked: Dictionary = ExercisePicker.pick_unseen(preferred, all, ["a"], rng)
    assert_eq(picked["id"], "b")
    var again: Dictionary = ExercisePicker.pick_unseen(preferred, all, ["a", "b"], rng)
    assert_true(["a", "b"].has(again["id"]))
