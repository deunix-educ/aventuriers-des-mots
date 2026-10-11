extends SceneTree
## Outil de developpement : charge une scene, attend quelques images puis
## enregistre le rendu en PNG. Usage (fenetre reelle, pas --headless) :
##   godot --path . --resolution 1152x648 -s res://tools/screenshot.gd -- \
##       res://scenes/world/world_map.tscn out.png [CE1|CE2] [mission_id]
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

    var scene: Node = load(scene_path).instantiate()
    root.add_child(scene)
    for i in 5:
        await process_frame
    # Actions optionnelles sur exercise_host, a partir du 5e argument :
    #   continue_rule | answer:<index> | toggle:<index> | type:<texte> | validate
    #   | continue_feedback
    for action in args.slice(4):
        if action.begins_with("outcomes:"):
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
    var overlay: Node = scene.get_node("%OverlayContainer")
    var exercise: Node = scene.get_node("%ExerciseContainer").get_child(0) if scene.get_node("%ExerciseContainer").get_child_count() > 0 else null
    var parts := action.split(":", true, 1)
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
