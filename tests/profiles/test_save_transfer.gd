extends GutTest
## Tests de SaveTransfer : export, liste, restauration non destructive et
## rejet des fichiers invalides. Le dossier d'export est un dossier de test
## sous user:// ; jamais le dossier Documents de l'utilisateur.

const EXPORT_DIR := "user://test_save_transfer_exports"
const SOURCE_ID := "test_transfer_source"
const RESTORED_ID := "test_transfer_restored"

var schema: Dictionary = {}


func before_each() -> void:
    schema = DataLoader.load_schema("save")
    _clean()


func after_all() -> void:
    _clean()


func _clean() -> void:
    SaveIO.delete(SOURCE_ID)
    SaveIO.delete(RESTORED_ID)
    var dir := DirAccess.open(EXPORT_DIR)
    if dir != null:
        for file_name in dir.get_files():
            dir.remove(file_name)
        DirAccess.remove_absolute(EXPORT_DIR)


func _make_source() -> void:
    var save := SaveFactory.new_save(SOURCE_ID, "Léa", "CE2")
    save["rewards"] = {"stars": 4, "items": ["item_graine_magique"]}
    save["mission_results"] = {"m": {"best_stars": 3, "last_stars": 3, "completions": 2}}
    SaveIO.write(SOURCE_ID, save)


func test_export_writes_a_readable_file_named_after_the_profile() -> void:
    _make_source()
    var path := SaveTransfer.export_profile(SOURCE_ID, schema, EXPORT_DIR)
    assert_ne(path, "")
    assert_true(path.get_file().begins_with("Léa_CE2"))
    var read_back: Variant = SaveTransfer.read_export(path, schema)
    assert_not_null(read_back)
    assert_eq(read_back["display_name"], "Léa")


func test_second_export_does_not_overwrite_the_first() -> void:
    _make_source()
    var first := SaveTransfer.export_profile(SOURCE_ID, schema, EXPORT_DIR)
    var second := SaveTransfer.export_profile(SOURCE_ID, schema, EXPORT_DIR)
    assert_ne(first, second)
    assert_eq(SaveTransfer.list_exports(EXPORT_DIR, schema).size(), 2)


func test_export_of_missing_profile_fails_cleanly() -> void:
    assert_eq(SaveTransfer.export_profile("test_transfer_nobody", schema, EXPORT_DIR), "")


func test_restore_creates_a_new_profile_and_keeps_the_original() -> void:
    _make_source()
    var path := SaveTransfer.export_profile(SOURCE_ID, schema, EXPORT_DIR)
    assert_true(SaveTransfer.import_as_new_profile(path, schema, RESTORED_ID))

    var restored: Variant = SaveIO.read(RESTORED_ID, schema)
    assert_not_null(restored)
    assert_eq(restored["profile_id"], RESTORED_ID)
    assert_eq(restored["rewards"]["stars"], 4)
    assert_eq(restored["mission_results"]["m"]["completions"], 2)

    var original: Variant = SaveIO.read(SOURCE_ID, schema)
    assert_eq(original["profile_id"], SOURCE_ID)


func test_invalid_files_are_listed_as_invalid_and_cannot_be_restored() -> void:
    DirAccess.make_dir_recursive_absolute(EXPORT_DIR)
    var file := FileAccess.open(EXPORT_DIR + "/abime.json", FileAccess.WRITE)
    file.store_string("{ pas du json")
    file.close()
    var entries := SaveTransfer.list_exports(EXPORT_DIR, schema)
    assert_eq(entries.size(), 1)
    assert_false(entries[0]["valid"])
    assert_false(
        SaveTransfer.import_as_new_profile(EXPORT_DIR + "/abime.json", schema, RESTORED_ID)
    )
    assert_null(SaveIO.read(RESTORED_ID, schema))


func test_list_of_missing_directory_is_empty() -> void:
    assert_eq(SaveTransfer.list_exports("user://test_transfer_absent_dir", schema).size(), 0)
