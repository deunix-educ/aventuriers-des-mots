extends GutTest
## Tests de SaveIO : ecriture atomique, copie de secours, isolation entre
## profils. Utilise de vrais chemins user:// (headless Godot les fournit),
## avec des profile_id de test nettoyes avant et apres la suite.

const PROFILE_IDS: Array[String] = [
    "test_save_io_roundtrip",
    "test_save_io_profile_a",
    "test_save_io_profile_b",
    "test_save_io_truncated_tmp",
    "test_save_io_corrupted_main",
    "test_save_io_invalid_content",
    "test_save_io_missing",
    "test_save_io_delete",
]

var save_schema: Dictionary = {}


func before_all() -> void:
    save_schema = DataLoader.load_schema("save")
    for profile_id in PROFILE_IDS:
        SaveIO.delete(profile_id)


func after_all() -> void:
    for profile_id in PROFILE_IDS:
        SaveIO.delete(profile_id)


func test_write_then_read_roundtrip() -> void:
    var data := SaveFactory.new_save("test_save_io_roundtrip", "Explorateur", "CE1")
    data["session_count"] = 3
    assert_true(SaveIO.write("test_save_io_roundtrip", data))
    var read_back: Variant = SaveIO.read("test_save_io_roundtrip", save_schema)
    assert_eq(int(read_back["session_count"]), 3)
    assert_eq(read_back["profile_id"], "test_save_io_roundtrip")


func test_two_profiles_do_not_mix() -> void:
    var data_a := SaveFactory.new_save("test_save_io_profile_a", "Alice", "CE1")
    data_a["session_count"] = 1
    var data_b := SaveFactory.new_save("test_save_io_profile_b", "Bob", "CE2")
    data_b["session_count"] = 7

    SaveIO.write("test_save_io_profile_a", data_a)
    SaveIO.write("test_save_io_profile_b", data_b)

    var read_a: Variant = SaveIO.read("test_save_io_profile_a", save_schema)
    var read_b: Variant = SaveIO.read("test_save_io_profile_b", save_schema)
    assert_eq(read_a["display_name"], "Alice")
    assert_eq(int(read_a["session_count"]), 1)
    assert_eq(read_b["display_name"], "Bob")
    assert_eq(int(read_b["session_count"]), 7)


func test_missing_profile_returns_null() -> void:
    assert_null(SaveIO.read("test_save_io_missing", save_schema))


func test_truncated_tmp_file_does_not_corrupt_the_readable_save() -> void:
    # Simule un plantage pendant l'ecriture : le fichier temporaire existe,
    # tronque et invalide, mais n'a jamais ete renomme sur le fichier
    # principal. La derniere sauvegarde valide doit rester lisible.
    var profile_id := "test_save_io_truncated_tmp"
    var data := SaveFactory.new_save(profile_id, "Explorateur", "CE1")
    SaveIO.write(profile_id, data)

    var tmp_path := "%s/%s.json.tmp" % [SaveIO.SAVE_DIR, profile_id]
    var tmp_file := FileAccess.open(tmp_path, FileAccess.WRITE)
    tmp_file.store_string('{"schema_version": 1, "profile_id": ')
    tmp_file.close()

    var read_back: Variant = SaveIO.read(profile_id, save_schema)
    assert_not_null(read_back)
    assert_eq(read_back["profile_id"], profile_id)


func test_corrupted_main_file_falls_back_to_backup() -> void:
    var profile_id := "test_save_io_corrupted_main"
    var first_save := SaveFactory.new_save(profile_id, "Explorateur", "CE1")
    first_save["session_count"] = 1
    SaveIO.write(profile_id, first_save)

    # Deuxieme ecriture : copie la version precedente (valide) en secours
    # avant de l'ecraser.
    var second_save := first_save.duplicate(true)
    second_save["session_count"] = 2
    SaveIO.write(profile_id, second_save)

    var main_path := "%s/%s.json" % [SaveIO.SAVE_DIR, profile_id]
    var main_file := FileAccess.open(main_path, FileAccess.WRITE)
    main_file.store_string("ceci n'est pas du json valide {{{")
    main_file.close()

    var read_back: Variant = SaveIO.read(profile_id, save_schema)
    assert_engine_error("Parse JSON failed")
    assert_not_null(read_back)
    assert_eq(int(read_back["session_count"]), 1)


func test_schema_invalid_content_without_backup_returns_null() -> void:
    var profile_id := "test_save_io_invalid_content"
    var main_path := "%s/%s.json" % [SaveIO.SAVE_DIR, profile_id]
    DirAccess.make_dir_recursive_absolute(SaveIO.SAVE_DIR)
    var main_file := FileAccess.open(main_path, FileAccess.WRITE)
    main_file.store_string(JSON.stringify({"schema_version": 1, "profile_id": profile_id}))
    main_file.close()

    assert_null(SaveIO.read(profile_id, save_schema))


func test_delete_removes_main_backup_and_tmp_files() -> void:
    var profile_id := "test_save_io_delete"
    var data := SaveFactory.new_save(profile_id, "Explorateur", "CE1")
    SaveIO.write(profile_id, data)
    SaveIO.write(profile_id, data)

    SaveIO.delete(profile_id)

    assert_null(SaveIO.read(profile_id, save_schema))
    assert_false(SaveIO.list_profile_ids().has(profile_id))
