class_name Motion
extends RefCounted
## Petites animations d'interface (apparition, rebond). Toutes respectent le
## reglage d'animations (cahier des charges §11 : possibilite de les
## desactiver) : elles ne font alors rien et l'element est affiche tel quel.


## Fait grossir `node` depuis rien avec un leger rebond.
static func pop_in(node: Control, delay: float = 0.0) -> void:
    if not SettingsManager.animations_enabled:
        return
    node.scale = Vector2.ZERO
    await node.get_tree().process_frame
    node.pivot_offset = node.size / 2.0
    var tween := node.create_tween()
    tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(node, "scale", Vector2.ONE, 0.4).set_delay(delay)


## Fait apparaitre `node` en fondu.
static func fade_in(node: CanvasItem, duration: float = 0.25) -> void:
    if not SettingsManager.animations_enabled:
        return
    node.modulate.a = 0.0
    var tween := node.create_tween()
    tween.tween_property(node, "modulate:a", 1.0, duration)
