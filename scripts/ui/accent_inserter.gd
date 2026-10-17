class_name AccentInserter
extends RefCounted
## Insertion d'un caractere accentue dans un texte, a la position du curseur.
## Pur et testable sans scene : la barre d'accents (AccentBar) s'appuie dessus.
## Sert quand le clavier de l'appareil n'offre pas les accents du francais
## (clavier tactile mal regle, disposition etrangere).

const LOWER: Array[String] = [
    "é", "è", "ê", "ë", "à", "â", "î", "ï", "ô", "û", "ù", "ü", "ç", "œ"
]
const UPPER: Array[String] = [
    "É", "È", "Ê", "Ë", "À", "Â", "Î", "Ï", "Ô", "Û", "Ù", "Ü", "Ç", "Œ"
]


## Retourne {"text": nouveau texte, "caret": nouvelle position du curseur}.
## Le curseur est borne au texte ; une chaine vide ne change rien.
static func insert(text: String, caret: int, character: String) -> Dictionary:
    var position := clampi(caret, 0, text.length())
    if character.is_empty():
        return {"text": text, "caret": position}
    return {
        "text": text.substr(0, position) + character + text.substr(position),
        "caret": position + character.length(),
    }


static func characters(uppercase: bool) -> Array[String]:
    return UPPER if uppercase else LOWER
