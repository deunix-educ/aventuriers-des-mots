extends GutTest
## Garde-fou contre le chevauchement de marqueurs sur la carte (signale
## manuellement : "La clairiere" et "La cabane" se chevauchaient, voir
## docs/specs/decisions.md, point 26). scenes/world/world_map.gd place chaque
## marqueur a une position fractionnelle (map_position.x/y de
## data/missions/*.json) ; sans ecart suffisant entre deux missions affichees
## ensemble (meme niveau), leurs boutons se recouvrent a l'ecran. Verifie
## l'ecart plutot que le rendu reel (non testable sans ecran), a la
## resolution par defaut (1152 px de large : 0.2 = 230 px pour des
## marqueurs de 160 px ; 0.3 de hauteur pour des marqueurs de 72 px).

const MIN_GAP_X := 0.2
const MIN_GAP_Y := 0.3


func test_mission_markers_do_not_overlap_within_a_region() -> void:
    var checked_regions := 0
    for level in SchoolLevels.ALL:
        for region in ExerciseEngine.get_regions_for_level(level):
            var missions := ExerciseEngine.get_missions_for_region(region["region_id"])
            assert_false(missions.is_empty(), "aucune mission pour %s" % region["region_id"])
            checked_regions += 1
            for i in missions.size():
                for j in range(i + 1, missions.size()):
                    var a: Dictionary = missions[i]["map_position"]
                    var b: Dictionary = missions[j]["map_position"]
                    var dx: float = abs(float(a["x"]) - float(b["x"]))
                    var dy: float = abs(float(a["y"]) - float(b["y"]))
                    assert_true(
                        dx >= MIN_GAP_X or dy >= MIN_GAP_Y,
                        (
                            "%s et %s sont trop proches (dx=%s, dy=%s)"
                            % [missions[i]["mission_id"], missions[j]["mission_id"], dx, dy]
                        ),
                    )
    assert_gt(checked_regions, 1)
