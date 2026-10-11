extends Control
## Espace adulte (cahier des charges §9 et §10) : tableau de progres par
## profil, notions a retravailler, export et restauration des sauvegardes.
## Derriere une petite barriere (AdultGate). Aucune action ici n'est
## destructive : la restauration cree un nouveau profil, l'export ecrit un
## nouveau fichier.

var _challenge: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _selected_profile_id := ""
var _schema: Dictionary = {}

@onready var _title_label: Label = %TitleLabel
@onready var _gate_box: VBoxContainer = %GateBox
@onready var _gate_question_label: Label = %GateQuestionLabel
@onready var _gate_input: LineEdit = %GateInput
@onready var _gate_error_label: Label = %GateErrorLabel
@onready var _gate_ok_button: Button = %GateOkButton
@onready var _content_box: VBoxContainer = %ContentBox
@onready var _profile_option: OptionButton = %ProfileOption
@onready var _summary_label: Label = %SummaryLabel
@onready var _skills_box: VBoxContainer = %SkillsBox
@onready var _export_button: Button = %ExportButton
@onready var _transfer_status_label: Label = %TransferStatusLabel
@onready var _restore_title_label: Label = %RestoreTitleLabel
@onready var _restore_list: VBoxContainer = %RestoreList
@onready var _folder_label: Label = %FolderLabel
@onready var _back_button: Button = %BackButton


func _ready() -> void:
    _schema = DataLoader.load_schema("save")
    _title_label.text = UIText.get_text("adult.title")
    _set_gate_texts()
    _export_button.text = UIText.get_text("adult.export_button")
    _restore_title_label.text = UIText.get_text("adult.restore_title")
    _folder_label.text = UIText.get_text("adult.folder_label") % SaveTransfer.default_export_dir()
    _back_button.text = UIText.get_text("adult.back_button")
    _gate_ok_button.pressed.connect(_on_gate_submitted)
    _gate_input.text_submitted.connect(_on_gate_text_submitted)
    _export_button.pressed.connect(_on_export_pressed)
    _profile_option.item_selected.connect(_on_profile_option_selected)
    _back_button.pressed.connect(_on_back_pressed)

    _rng.randomize()
    _challenge = AdultGate.make_challenge(_rng)
    _gate_question_label.text = (
        UIText.get_text("adult.gate_question") % [_challenge["a"], _challenge["b"]]
    )
    _gate_box.visible = true
    _content_box.visible = false


func _set_gate_texts() -> void:
    _gate_ok_button.text = UIText.get_text("adult.gate_button")
    _gate_error_label.text = UIText.get_text("adult.gate_error")
    _gate_error_label.visible = false


func _on_gate_text_submitted(_text: String) -> void:
    _on_gate_submitted()


func _on_gate_submitted() -> void:
    if not AdultGate.is_correct(_challenge, _gate_input.text):
        _gate_error_label.visible = true
        _gate_input.clear()
        return
    _gate_box.visible = false
    _content_box.visible = true
    _refresh_profiles()
    _refresh_restore_list()


func _refresh_profiles() -> void:
    _profile_option.clear()
    var summaries := ProfileManager.list_profile_summaries()
    for summary: Dictionary in summaries:
        _profile_option.add_item("%s (%s)" % [summary["display_name"], summary["school_level"]])
        _profile_option.set_item_metadata(_profile_option.item_count - 1, summary["profile_id"])
    var has_profiles := not summaries.is_empty()
    _export_button.disabled = not has_profiles
    if has_profiles:
        _profile_option.select(0)
        _show_profile(_profile_option.get_item_metadata(0))
    else:
        _selected_profile_id = ""
        _summary_label.text = UIText.get_text("adult.no_profile")
        _clear_skills()


func _on_profile_option_selected(index: int) -> void:
    _show_profile(_profile_option.get_item_metadata(index))


func _show_profile(profile_id: String) -> void:
    _selected_profile_id = profile_id
    var save: Variant = SaveManager.load(profile_id)
    _clear_skills()
    if save == null:
        _summary_label.text = UIText.get_text("adult.profile_unreadable")
        return
    var level: String = save["school_level"]
    var report := ProgressReport.build(
        save, ExerciseEngine.get_missions_for_level(level).size(), ExerciseEngine.get_reward_items().size()
    )
    _summary_label.text = UIText.get_text("adult.summary") % [
        report["stars"],
        report["missions_done"],
        report["missions_total"],
        report["items_owned"],
        report["items_total"],
        report["session_count"],
    ]
    var skills: Array = report["skills"]
    if skills.is_empty():
        _skills_box.add_child(_skill_label(UIText.get_text("adult.no_skills_yet"), false))
        return
    for row: Dictionary in skills:
        _skills_box.add_child(_skill_label(_skill_text(row), row["needs_work"]))


func _skill_text(row: Dictionary) -> String:
    var line := (
        UIText.get_text("adult.skill_line")
        % [
            UIText.get_text("skill.%s" % row["skill_id"]),
            UIText.get_text("world_map.status_%s" % row["status"]),
            row["successes"],
            row["attempts"],
            row["hints_used"],
        ]
    )
    if row["needs_work"]:
        line += "\n" + UIText.get_text("adult.needs_work")
    return line


func _skill_label(text: String, highlight: bool) -> Control:
    var card := PanelContainer.new()
    card.theme_type_variation = &"SoftCard"
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    if highlight:
        label.theme_type_variation = &"Emphasis"
    card.add_child(label)
    return card


func _clear_skills() -> void:
    for child in _skills_box.get_children():
        _skills_box.remove_child(child)
        child.queue_free()


func _on_export_pressed() -> void:
    if _selected_profile_id.is_empty():
        return
    var path := SaveTransfer.export_profile(
        _selected_profile_id, _schema, SaveTransfer.default_export_dir()
    )
    if path.is_empty():
        _transfer_status_label.text = UIText.get_text("adult.export_failed")
    else:
        _transfer_status_label.text = UIText.get_text("adult.export_done") % path
    _refresh_restore_list()


func _refresh_restore_list() -> void:
    for child in _restore_list.get_children():
        _restore_list.remove_child(child)
        child.queue_free()
    var exports := SaveTransfer.list_exports(SaveTransfer.default_export_dir(), _schema)
    if exports.is_empty():
        var empty := Label.new()
        empty.text = UIText.get_text("adult.restore_empty")
        empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _restore_list.add_child(empty)
        return
    for entry: Dictionary in exports:
        var button := Button.new()
        button.theme_type_variation = &"SecondaryButton"
        button.custom_minimum_size = Vector2(0, 48)
        if entry["valid"]:
            button.text = (
                UIText.get_text("adult.restore_entry")
                % [entry["display_name"], entry["school_level"], entry["path"].get_file()]
            )
            button.pressed.connect(_on_restore_pressed.bind(entry["path"]))
        else:
            button.text = UIText.get_text("adult.restore_invalid") % entry["path"].get_file()
            button.disabled = true
        _restore_list.add_child(button)


func _on_restore_pressed(path: String) -> void:
    var new_id := ProfileManager.new_profile_id()
    if SaveTransfer.import_as_new_profile(path, _schema, new_id):
        _transfer_status_label.text = UIText.get_text("adult.restore_done")
        _refresh_profiles()
    else:
        _transfer_status_label.text = UIText.get_text("adult.restore_failed")


func _on_back_pressed() -> void:
    GameManager.goto(GameManager.SCENE_SETTINGS)
