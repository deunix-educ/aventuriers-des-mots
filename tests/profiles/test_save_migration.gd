extends GutTest
## Tests de SaveMigration : garde-fous sur la version de schema.


func test_current_version_is_returned_unchanged() -> void:
    var data := {"schema_version": 1, "profile_id": "profile_test"}
    var migrated := SaveMigration.migrate(data)
    assert_eq(migrated["schema_version"], 1)
    assert_eq(migrated["profile_id"], "profile_test")


func test_missing_version_is_rejected() -> void:
    var data := {"profile_id": "profile_test"}
    assert_eq(SaveMigration.migrate(data), {})


func test_future_unknown_version_is_rejected_rather_than_guessed() -> void:
    var data := {"schema_version": 99, "profile_id": "profile_test"}
    assert_eq(SaveMigration.migrate(data), {})


func test_zero_or_negative_version_is_rejected() -> void:
    var data := {"schema_version": 0, "profile_id": "profile_test"}
    assert_eq(SaveMigration.migrate(data), {})


func test_non_numeric_version_is_rejected() -> void:
    var data := {"schema_version": "one", "profile_id": "profile_test"}
    assert_eq(SaveMigration.migrate(data), {})


func test_migration_does_not_mutate_the_input_in_place() -> void:
    var data := {"schema_version": 1, "profile_id": "profile_test"}
    var migrated := SaveMigration.migrate(data)
    migrated["profile_id"] = "changed"
    assert_eq(data["profile_id"], "profile_test")
