extends GutTest
## Tests d'AdultGate : le calcul est dans les bornes et la reponse est exacte.


func test_challenge_is_within_bounds_and_answer_matches() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 42
    for _i in range(50):
        var challenge := AdultGate.make_challenge(rng)
        assert_between(challenge["a"], AdultGate.MIN_FACTOR_A, AdultGate.MAX_FACTOR_A)
        assert_between(challenge["b"], AdultGate.MIN_FACTOR_B, AdultGate.MAX_FACTOR_B)
        assert_eq(challenge["answer"], challenge["a"] * challenge["b"])


func test_same_seed_gives_same_challenge() -> void:
    var first := RandomNumberGenerator.new()
    first.seed = 7
    var second := RandomNumberGenerator.new()
    second.seed = 7
    assert_eq(AdultGate.make_challenge(first), AdultGate.make_challenge(second))


func test_is_correct_accepts_exact_answer_with_spaces() -> void:
    var challenge := {"a": 13, "b": 7, "answer": 91}
    assert_true(AdultGate.is_correct(challenge, "91"))
    assert_true(AdultGate.is_correct(challenge, " 91 "))


func test_is_correct_rejects_wrong_or_non_numeric() -> void:
    var challenge := {"a": 13, "b": 7, "answer": 91}
    assert_false(AdultGate.is_correct(challenge, "90"))
    assert_false(AdultGate.is_correct(challenge, ""))
    assert_false(AdultGate.is_correct(challenge, "quatre-vingt-onze"))
