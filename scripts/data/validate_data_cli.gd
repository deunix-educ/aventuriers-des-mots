extends SceneTree
## Outil headless invoque par `make validate-data`.
## A ce stade, verifie seulement que les fichiers data/**/*.json sont du JSON bien forme.
## La validation contre les schemas (rule, exercise, dictation, curriculum, save) sera
## ajoutee a l'etape "Donnees" (voir Ordre de construction, docs/specs/decisions.md point 2).


func _init() -> void:
    var json_paths: Array[String] = _find_json_files("res://data")
    var failures: Array[String] = []
    for path in json_paths:
        var file := FileAccess.open(path, FileAccess.READ)
        if file == null:
            failures.append("%s : lecture impossible" % path)
            continue
        var text := file.get_as_text()
        if text.strip_edges().is_empty():
            continue
        if JSON.parse_string(text) == null:
            failures.append("%s : JSON invalide" % path)

    if failures.is_empty():
        print("validate-data : %d fichier(s) JSON valide(s)" % json_paths.size())
        quit(0)
    else:
        for failure in failures:
            printerr(failure)
        quit(1)


func _find_json_files(root_path: String) -> Array[String]:
    var result: Array[String] = []
    var dir := DirAccess.open(root_path)
    if dir == null:
        return result
    dir.list_dir_begin()
    var entry := dir.get_next()
    while entry != "":
        if entry != "." and entry != "..":
            var full_path := root_path.path_join(entry)
            if dir.current_is_dir():
                result.append_array(_find_json_files(full_path))
            elif entry.ends_with(".json"):
                result.append(full_path)
        entry = dir.get_next()
    return result
