extends GutTest
## Tests de MissionScoring : le score valorise la reussite sans aide, jamais
## la vitesse, et une mission terminee rapporte toujours au moins 1 etoile.

const FIRST := MissionScoring.OUTCOME_FIRST_TRY
const HELP := MissionScoring.OUTCOME_WITH_HELP
const REVEALED := MissionScoring.OUTCOME_REVEALED


func test_all_first_try_gives_three_stars() -> void:
    assert_eq(MissionScoring.stars_for([FIRST, FIRST, FIRST]), 3)


func test_some_help_but_everything_found_gives_two_stars() -> void:
    assert_eq(MissionScoring.stars_for([FIRST, HELP, FIRST]), 2)
    assert_eq(MissionScoring.stars_for([HELP, HELP, HELP]), 2)


func test_a_revealed_answer_gives_one_star() -> void:
    assert_eq(MissionScoring.stars_for([FIRST, FIRST, REVEALED]), 1)
    assert_eq(MissionScoring.stars_for([REVEALED, REVEALED, REVEALED]), 1)


func test_a_finished_mission_never_gives_zero_stars() -> void:
    assert_eq(MissionScoring.stars_for([]), 1)
