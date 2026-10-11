extends GutTest
## Tests du validateur de schema generique (scripts/data/schema_validator.gd),
## independants de tout contenu reel de data/.

var schema: Dictionary = {
    "type": "object",
    "required": ["id", "level"],
    "additionalProperties": false,
    "properties":
    {
        "id": {"type": "string", "pattern": "^[a-z][a-z0-9_]*$"},
        "level": {"type": "string", "enum": ["CE1", "CE2"]},
        "difficulty": {"type": "integer", "minimum": 1, "maximum": 3},
        "tags": {"type": "array", "minItems": 1, "items": {"type": "string"}},
    },
}


func test_valid_object_has_no_errors() -> void:
    var data := {"id": "ex_01", "level": "CE1", "difficulty": 2, "tags": ["pluriel"]}
    assert_eq(SchemaValidator.validate(data, schema), [])


func test_missing_required_property_is_reported() -> void:
    var data := {"level": "CE1"}
    var errors := SchemaValidator.validate(data, schema)
    assert_eq(errors.size(), 1)
    assert_string_contains(errors[0], "id")


func test_wrong_type_is_reported() -> void:
    var data := {"id": "ex_01", "level": "CE1", "difficulty": "deux"}
    var errors := SchemaValidator.validate(data, schema)
    assert_eq(errors.size(), 1)
    assert_string_contains(errors[0], "difficulty")


func test_enum_violation_is_reported() -> void:
    var data := {"id": "ex_01", "level": "CM1"}
    var errors := SchemaValidator.validate(data, schema)
    assert_eq(errors.size(), 1)
    assert_string_contains(errors[0], "level")


func test_pattern_violation_is_reported() -> void:
    var data := {"id": "Ex-01", "level": "CE1"}
    var errors := SchemaValidator.validate(data, schema)
    assert_eq(errors.size(), 1)
    assert_string_contains(errors[0], "id")


func test_unexpected_property_is_reported_when_additional_forbidden() -> void:
    var data := {"id": "ex_01", "level": "CE1", "extra": true}
    var errors := SchemaValidator.validate(data, schema)
    assert_eq(errors.size(), 1)
    assert_string_contains(errors[0], "extra")


func test_min_items_violation_is_reported() -> void:
    var data := {"id": "ex_01", "level": "CE1", "tags": []}
    var errors := SchemaValidator.validate(data, schema)
    assert_eq(errors.size(), 1)
    assert_string_contains(errors[0], "tags")


func test_numeric_bounds_are_checked() -> void:
    var data := {"id": "ex_01", "level": "CE1", "difficulty": 9}
    var errors := SchemaValidator.validate(data, schema)
    assert_eq(errors.size(), 1)
    assert_string_contains(errors[0], "difficulty")
