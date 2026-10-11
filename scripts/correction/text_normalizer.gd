class_name TextNormalizer
extends RefCounted
## Normalisation de texte avant comparaison dans les dictees : espaces (dont
## insecables), apostrophes typographiques, et sequences Unicode decomposees
## des caracteres francais ramenees a leur forme composee. GDScript n'expose
## pas de normalisation NFC/NFD native : table explicite ici, comme prevu par
## les "Points durs" du prompt de lancement.

const NBSP := " "
const NARROW_NBSP := " "
const TYPOGRAPHIC_APOSTROPHE := "’"

## Sequences decomposees (lettre de base + marque combinante) -> caractere
## compose. Couvre les caracteres francais courants : accents, cedille, trema.
const DECOMPOSED_TO_COMPOSED := {
    "é": "é",
    "è": "è",
    "ê": "ê",
    "ë": "ë",
    "É": "É",
    "È": "È",
    "Ê": "Ê",
    "Ë": "Ë",
    "à": "à",
    "â": "â",
    "À": "À",
    "Â": "Â",
    "ù": "ù",
    "û": "û",
    "ü": "ü",
    "Ù": "Ù",
    "Û": "Û",
    "Ü": "Ü",
    "î": "î",
    "ï": "ï",
    "Î": "Î",
    "Ï": "Ï",
    "ô": "ô",
    "ö": "ö",
    "Ô": "Ô",
    "Ö": "Ö",
    "ç": "ç",
    "Ç": "Ç",
}


static func normalize(text: String) -> String:
    var result := text
    result = result.replace(NBSP, " ")
    result = result.replace(NARROW_NBSP, " ")
    result = result.replace(TYPOGRAPHIC_APOSTROPHE, "'")
    for decomposed: String in DECOMPOSED_TO_COMPOSED:
        result = result.replace(decomposed, DECOMPOSED_TO_COMPOSED[decomposed])
    while result.find("  ") != -1:
        result = result.replace("  ", " ")
    return result.strip_edges()


static func split_words(text: String) -> Array[String]:
    var normalized := normalize(text)
    var words: Array[String] = []
    if normalized.is_empty():
        return words
    var parts: PackedStringArray = normalized.split(" ", false)
    for part in parts:
        words.append(part)
    return words
