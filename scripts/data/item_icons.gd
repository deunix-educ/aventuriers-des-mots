class_name ItemIcons
extends RefCounted
## Illustration d'un objet de la collection, resolue par identifiant dans un
## repertoire fixe (CLAUDE.md : jamais de chemin libre dans les donnees). Un
## objet sans illustration retombe sur un cadenas : jamais d'erreur a l'ecran.

const ITEM_DIR := "res://assets/interface/items"
const FALLBACK := "res://assets/interface/icon_locked.svg"
const LOCKED := "res://assets/interface/icon_locked.svg"


static func texture_for(item_id: String) -> Texture2D:
    var path := "%s/%s.svg" % [ITEM_DIR, item_id]
    if ResourceLoader.exists(path):
        return load(path)
    return load(FALLBACK)


static func locked_texture() -> Texture2D:
    return load(LOCKED)
