extends GutTest
## Tests de RewardRules : deblocage des objets selon le total d'etoiles ou le
## meilleur score d'une mission.

var _catalog: Array[Dictionary] = [
    {"item_id": "item_total_3", "unlock": {"type": "total_stars", "count": 3}},
    {"item_id": "item_total_6", "unlock": {"type": "total_stars", "count": 6}},
    {
        "item_id": "item_trophy",
        "unlock": {"type": "mission_stars", "count": 3, "mission_id": "mission_a"}
    },
]


func test_nothing_unlocks_with_no_stars() -> void:
    assert_eq(RewardRules.newly_unlocked(_catalog, 0, {}, []), [])


func test_total_stars_threshold_unlocks_items_reached() -> void:
    assert_eq(RewardRules.newly_unlocked(_catalog, 3, {}, []), ["item_total_3"])
    assert_eq(RewardRules.newly_unlocked(_catalog, 7, {}, []), ["item_total_3", "item_total_6"])


func test_owned_items_are_not_unlocked_again() -> void:
    assert_eq(RewardRules.newly_unlocked(_catalog, 7, {}, ["item_total_3"]), ["item_total_6"])


func test_mission_trophy_needs_the_best_score_on_that_mission() -> void:
    var two_stars := {"mission_a": {"best_stars": 2}}
    var three_stars := {"mission_a": {"best_stars": 3}}
    assert_eq(RewardRules.newly_unlocked(_catalog, 0, two_stars, []), [])
    assert_eq(RewardRules.newly_unlocked(_catalog, 0, three_stars, []), ["item_trophy"])
    var other_mission := {"mission_b": {"best_stars": 3}}
    assert_eq(RewardRules.newly_unlocked(_catalog, 0, other_mission, []), [])
