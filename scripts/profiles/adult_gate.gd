class_name AdultGate
extends RefCounted
## Petite barriere devant l'espace adulte : un calcul qu'un enfant du primaire
## ne fait pas facilement de tete (produit d'un nombre a deux chiffres par un
## chiffre). Ce n'est pas une protection de securite, seulement un frein
## contre un clic par curiosite. Le hasard est injecte, jamais lu ici.

const MIN_FACTOR_A := 12
const MAX_FACTOR_A := 19
const MIN_FACTOR_B := 3
const MAX_FACTOR_B := 9


static func make_challenge(rng: RandomNumberGenerator) -> Dictionary:
    var a := rng.randi_range(MIN_FACTOR_A, MAX_FACTOR_A)
    var b := rng.randi_range(MIN_FACTOR_B, MAX_FACTOR_B)
    return {"a": a, "b": b, "answer": a * b}


static func is_correct(challenge: Dictionary, typed: String) -> bool:
    var cleaned := typed.strip_edges()
    if not cleaned.is_valid_int():
        return false
    return int(cleaned) == int(challenge["answer"])
