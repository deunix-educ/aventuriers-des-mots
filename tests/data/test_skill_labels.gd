extends GutTest
## Chaque notion (skill) presente dans les donnees doit avoir un intitule
## affichable dans l'espace adulte.


func test_every_skill_has_a_label() -> void:
    var file := FileAccess.open(UIText.LOCALIZATION_PATH, FileAccess.READ)
    var labels: Dictionary = JSON.parse_string(file.get_as_text())
    var seen := {}
    for rule: Dictionary in ExerciseEngine._rules.values():
        seen[rule["skill"]] = true
    assert_gt(seen.size(), 0)
    for skill_id: String in seen:
        assert_true(labels.has("skill.%s" % skill_id), "Intitule manquant : skill.%s" % skill_id)
