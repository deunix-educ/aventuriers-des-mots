extends SceneTree
## Outil de developpement : charge une scene, attend quelques images puis
## enregistre le rendu en PNG. Usage (fenetre reelle, pas --headless) :
##   godot --path . --resolution 1152x648 -s res://tools/screenshot.gd -- \
##       res://scenes/world/world_map.tscn out.png [CE1|CE2|CM1|CM2] [mission_id]
## Cree un profil temporaire pour que les scenes qui lisent la progression
## fonctionnent, puis le supprime.


func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    var scene_path: String = args[0]
    var out_path: String = args[1]
    var level: String = args[2] if args.size() > 2 else "CE1"

    var profiles: Node = root.get_node("ProfileManager")
    var game: Node = root.get_node("GameManager")
    var profile_id: String = profiles.call("create_profile", "Capture", level)
    profiles.call("select_profile", profile_id)
    if args.size() > 3:
        game.set("pending_mission_id", args[3])

    for arg in args:
        if arg.begins_with("outcomes:"):
            var typed: Array[String] = []
            for part in arg.trim_prefix("outcomes:").split(","):
                typed.append(part)
            game.set("last_outcomes", typed)

    # Les autoloads terminent leur _ready apres _initialize : on attend une
    # image, sinon SettingsManager relirait ses reglages par-dessus les notres.
    await process_frame
    for arg in args:
        if arg.begins_with("text_scale:"):
            # Applique sans ecrire user://settings.json (reglages reels).
            var settings: Node = root.get_node("SettingsManager")
            settings.set("text_scale_index", int(arg.trim_prefix("text_scale:")))
            settings.call("apply")

    var scene: Node = load(scene_path).instantiate()
    root.add_child(scene)
    for i in 5:
        await process_frame
    # Actions optionnelles sur exercise_host, a partir du 5e argument :
    #   continue_rule | answer:<index> | toggle:<index> | type:<texte> | validate
    #   | continue_feedback | solve_gate (espace adulte) | call:<methode>
    for action in args.slice(4):
        if action.begins_with("outcomes:") or action.begins_with("text_scale:"):
            continue
        await _run_action(scene, action)
        for i in 5:
            await process_frame
    for i in 90:
        await process_frame
    var image := root.get_texture().get_image()
    image.save_png(out_path)
    profiles.call("delete_profile", profile_id)
    quit(0)


func _run_action(scene: Node, action: String) -> void:
    var parts := action.split(":", true, 1)
    if parts[0] == "call":
        # Appelle une methode de la scene (ex. call:_on_region_pressed).
        scene.call(parts[1])
        return
    if parts[0] == "solve_gate":
        # Espace adulte : saisit la bonne reponse a la barriere.
        var input: LineEdit = scene.find_child("GateInput", true, false)
        input.text = str(scene.get("_challenge")["answer"])
        scene.call("_on_gate_submitted")
        return
    var overlay: Node = scene.get_node_or_null("%OverlayContainer")
    var exercise_container: Node = scene.get_node_or_null("%ExerciseContainer")
    var exercise: Node = null
    if exercise_container != null and exercise_container.get_child_count() > 0:
        exercise = exercise_container.get_child(0)
    match parts[0]:
        "continue_rule":
            overlay.get_child(0).emit_signal("continued")
        "answer":
            exercise.emit_signal("answer_submitted", int(parts[1]))
        "toggle":
            exercise.get_node("%TokensBox").get_child(int(parts[1])).emit_signal("toggled", true)
        "type":
            var field: LineEdit = (
                exercise.get_node("%TextEdit")
                if exercise.has_node("%TextEdit")
                else exercise.get_node("%CorrectionsBox").get_child(0)
            )
            field.text = parts[1]
        "validate":
            exercise.get_node("%ValidateButton").emit_signal("pressed")
        "continue_feedback":
            overlay.get_child(overlay.get_child_count() - 1).get_node("%ContinueButton").emit_signal("pressed")
