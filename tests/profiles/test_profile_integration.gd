extends GutTest
## Tests d'integration des autoloads ProfileManager / SaveManager /
## ProgressManager : la "colle" fine entre la logique pure (deja testee
## isolement) et la persistance reelle sur disque.

var created_profile_ids: Array[String] = []


func after_each() -> void:
    for profile_id in created_profile_ids:
        ProfileManager.delete_profile(profile_id)
    created_profile_ids.clear()


func test_create_and_select_profile_round_trips_through_disk() -> void:
    var profile_id := ProfileManager.create_profile("Explorateur", "CE1")
    created_profile_ids.append(profile_id)

    assert_true(ProfileManager.select_profile(profile_id))
    assert_eq(ProfileManager.current_profile_id, profile_id)

    ProgressManager.record_attempt("accord_groupe_nominal", true, false, "multiple_choice")
    assert_true(ProgressManager.save_now())

    var reloaded: Variant = SaveManager.load(profile_id)
    assert_not_null(reloaded)
    assert_true(reloaded["skills"].has("accord_groupe_nominal"))


func test_selecting_unknown_profile_fails_without_side_effects() -> void:
    assert_false(ProfileManager.select_profile("profile_does_not_exist"))


func test_two_profiles_are_isolated_through_the_autoload_layer() -> void:
    var profile_a := ProfileManager.create_profile("Alice", "CE1")
    var profile_b := ProfileManager.create_profile("Bob", "CE2")
    created_profile_ids.append(profile_a)
    created_profile_ids.append(profile_b)

    ProfileManager.select_profile(profile_a)
    ProgressManager.record_attempt("accord_groupe_nominal", true, false, "multiple_choice")
    ProgressManager.save_now()

    ProfileManager.select_profile(profile_b)
    ProgressManager.record_attempt("homophones", false, true, "sentence_correction")
    ProgressManager.save_now()

    var save_a: Variant = SaveManager.load(profile_a)
    var save_b: Variant = SaveManager.load(profile_b)
    assert_true(save_a["skills"].has("accord_groupe_nominal"))
    assert_false(save_a["skills"].has("homophones"))
    assert_true(save_b["skills"].has("homophones"))
    assert_false(save_b["skills"].has("accord_groupe_nominal"))


func test_delete_profile_removes_it_from_disk_and_listing() -> void:
    var profile_id := ProfileManager.create_profile("Explorateur", "CE1")

    assert_true(ProfileManager.list_profiles().has(profile_id))

    ProfileManager.delete_profile(profile_id)

    assert_false(ProfileManager.list_profiles().has(profile_id))
    assert_null(SaveManager.load(profile_id))
