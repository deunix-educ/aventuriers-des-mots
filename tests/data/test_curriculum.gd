extends GutTest
## Coherence des « tableaux » (data/curriculum/) avec le reste des donnees.


func test_school_levels_match_the_schemas() -> void:
    for schema_name in ["save", "rule", "curriculum", "dictation", "exercise_multiple_choice"]:
        var schema := DataLoader.load_schema(schema_name)
        var enum_values: Array = []
        if schema_name == "save":
            enum_values = schema["properties"]["school_level"]["enum"]
        else:
            enum_values = schema["properties"]["level"]["enum"]
        assert_eq(enum_values, SchoolLevels.ALL as Array, "schema %s" % schema_name)


func test_backdrop_enum_matches_available_art() -> void:
    var schema := DataLoader.load_schema("curriculum")
    var enum_values: Array = schema["properties"]["backdrop"]["enum"]
    var kinds: Array = BackdropKinds.kinds()
    enum_values.sort()
    kinds.sort()
    assert_eq(enum_values, kinds)
    for kind in BackdropKinds.kinds():
        assert_true(
            ResourceLoader.exists(BackdropKinds.TEXTURES[kind]), "decor manquant : %s" % kind
        )
        assert_true(SoundCatalog.MUSIC_IDS.has(BackdropKinds.music_for(kind)))


func test_every_rule_belongs_to_exactly_one_region_of_its_level() -> void:
    var owners := {}
    for level in SchoolLevels.ALL:
        for region in ExerciseEngine.get_regions_for_level(level):
            assert_between(
                ExerciseEngine.get_regions_for_level(level).size(), 1, 3, "3 tableaux maximum"
            )
            for rule_id: String in region["rule_ids"]:
                assert_false(owners.has(rule_id), "regle dans deux tableaux : %s" % rule_id)
                owners[rule_id] = region["region_id"]
                var rule := ExerciseEngine.get_rule(rule_id)
                assert_false(rule.is_empty(), "regle inconnue : %s" % rule_id)
                assert_eq(rule.get("level", ""), level, "niveau de %s" % rule_id)
    for mission in ExerciseEngine.get_missions():
        assert_true(
            owners.has(mission["rule_id"]), "mission hors tableau : %s" % mission["mission_id"]
        )


func test_regions_have_a_child_facing_title_and_unique_order() -> void:
    for level in SchoolLevels.ALL:
        var orders := {}
        for region in ExerciseEngine.get_regions_for_level(level):
            assert_true(region.has("region_title"), "titre manquant : %s" % region["region_id"])
            var order := int(region.get("order", 1))
            assert_false(orders.has(order), "numero de tableau en double dans %s" % level)
            orders[order] = true


func test_school_levels_helpers() -> void:
    assert_eq(SchoolLevels.previous("CE1"), "")
    assert_eq(SchoolLevels.previous("CM1"), "CE2")
    assert_eq(SchoolLevels.previous("n_importe_quoi"), "")
    assert_true(SchoolLevels.rank("CM2") > SchoolLevels.rank("CE2"))


func test_correct_answer_position_is_not_always_the_same() -> void:
    # Une regle dont la bonne reponse est toujours au meme rang se devine sans
    # lire : les QCM d'une regle doivent varier la position de la bonne reponse.
    var positions: Dictionary = {}
    for rule_id: String in ExerciseEngine._rules:
        for exercise: Dictionary in ExerciseEngine._candidates_for(rule_id, "multiple_choice"):
            if not positions.has(rule_id):
                positions[rule_id] = {}
            positions[rule_id][int(exercise["correct_answer"])] = true
    assert_gt(positions.size(), 5)
    for rule_id: String in positions:
        assert_gt(
            (positions[rule_id] as Dictionary).size(),
            1,
            "bonne reponse toujours au meme rang : %s" % rule_id
        )
