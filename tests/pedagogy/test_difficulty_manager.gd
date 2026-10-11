extends GutTest
## Tests de DifficultyManager.


func test_three_consecutive_successes_raise_difficulty() -> void:
    var recent: Array[bool] = [true, true, true]
    assert_eq(DifficultyManager.next_difficulty(1, recent), 2)


func test_three_consecutive_failures_lower_difficulty() -> void:
    var recent: Array[bool] = [false, false, false]
    assert_eq(DifficultyManager.next_difficulty(2, recent), 1)


func test_mixed_results_keep_difficulty_stable() -> void:
    var recent: Array[bool] = [true, false, true]
    assert_eq(DifficultyManager.next_difficulty(2, recent), 2)


func test_difficulty_never_exceeds_maximum() -> void:
    var recent: Array[bool] = [true, true, true]
    assert_eq(DifficultyManager.next_difficulty(3, recent), 3)


func test_difficulty_never_goes_below_minimum() -> void:
    var recent: Array[bool] = [false, false, false]
    assert_eq(DifficultyManager.next_difficulty(1, recent), 1)


func test_not_enough_history_keeps_difficulty_unchanged() -> void:
    var recent: Array[bool] = [true, true]
    assert_eq(DifficultyManager.next_difficulty(2, recent), 2)
