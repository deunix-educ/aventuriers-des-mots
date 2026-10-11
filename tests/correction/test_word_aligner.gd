extends GutTest
## Tests de WordAligner : l'alignement doit absorber les mots omis ou ajoutes
## sans decaler les comparaisons suivantes.

var target: Array[String] = ["Les", "petits", "chats", "dorment."]


func test_identical_sequences_are_all_matches() -> void:
    var ops := WordAligner.align(target, target.duplicate())
    for op in ops:
        assert_eq(op["op"], "match")
    assert_eq(ops.size(), 4)


func test_single_substitution_is_detected_at_the_right_position() -> void:
    var submitted: Array[String] = ["Les", "petit", "chats", "dorment."]
    var ops := WordAligner.align(target, submitted)
    assert_eq(ops.size(), 4)
    assert_eq(ops[1]["op"], "substitute")
    assert_eq(ops[1]["target_index"], 1)
    assert_eq(ops[0]["op"], "match")
    assert_eq(ops[2]["op"], "match")
    assert_eq(ops[3]["op"], "match")


func test_missing_word_is_a_delete_and_does_not_shift_later_matches() -> void:
    # L'enfant a oublie "petits" : sans alignement, "chats" se comparerait a
    # "petits" et "dorment." a "chats", generant deux fausses erreurs en cascade.
    var submitted: Array[String] = ["Les", "chats", "dorment."]
    var ops := WordAligner.align(target, submitted)
    assert_eq(ops.size(), 4)
    assert_eq(ops[0]["op"], "match")
    assert_eq(ops[1]["op"], "delete")
    assert_eq(ops[1]["target_index"], 1)
    assert_eq(ops[2]["op"], "match")
    assert_eq(ops[2]["target_index"], 2)
    assert_eq(ops[3]["op"], "match")
    assert_eq(ops[3]["target_index"], 3)


func test_extra_word_is_an_insert() -> void:
    var submitted: Array[String] = ["Les", "petits", "petits", "chats", "dorment."]
    var ops := WordAligner.align(target, submitted)
    var insert_ops: Array = ops.filter(func(op: Dictionary) -> bool: return op["op"] == "insert")
    assert_eq(insert_ops.size(), 1)
