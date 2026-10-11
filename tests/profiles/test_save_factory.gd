extends GutTest
## Tests de SaveFactory : une nouvelle sauvegarde doit etre conforme a
## data/schemas/save.schema.json.

var save_schema: Dictionary = {}


func before_all() -> void:
    save_schema = DataLoader.load_schema("save")


func test_new_save_is_valid_against_the_save_schema() -> void:
    var data := SaveFactory.new_save("profile_abc123", "Explorateur", "CE1")
    var errors := SchemaValidator.validate(data, save_schema)
    assert_eq(errors, [])


func test_new_save_starts_at_session_zero_with_no_skills() -> void:
    var data := SaveFactory.new_save("profile_abc123", "Explorateur", "CE1")
    assert_eq(data["session_count"], 0)
    assert_eq(data["skills"], {})
    assert_eq(data["unlocked_regions"], [])
    assert_eq(data["rewards"], {"stars": 0, "items": []})
