extends GutTest
## Garde-fou contre le chevauchement de marqueurs sur la carte (signale
## manuellement : "La clairiere" et "La cabane" se chevauchaient, voir
## docs/specs/decisions.md). scenes/world/world_map.gd place chaque marqueur
## a une position fractionnelle (map_position.x/y de data/missions/*.json) ;
## sans ecart suffisant entre deux missions, leurs boutons se recouvrent a
## l'ecran. Verifie l'ecart plutot que le rendu reel (non testable sans
## ecran), avec une marge volontairement un peu permissive par rapport a la
## grille 0.35 utilisee dans les donnees.

const MIN_FRACTIONAL_GAP := 0.3


func test_mission_markers_do_not_overlap() -> void:
    var missions := ExerciseEngine.get_missions()
    for i in missions.size():
        for j in range(i + 1, missions.size()):
            var a: Dictionary = missions[i]["map_position"]
            var b: Dictionary = missions[j]["map_position"]
            var dx: float = abs(float(a["x"]) - float(b["x"]))
            var dy: float = abs(float(a["y"]) - float(b["y"]))
            assert_true(
                dx >= MIN_FRACTIONAL_GAP or dy >= MIN_FRACTIONAL_GAP,
                (
                    "%s et %s sont trop proches (dx=%s, dy=%s)"
                    % [missions[i]["mission_id"], missions[j]["mission_id"], dx, dy]
                ),
            )
