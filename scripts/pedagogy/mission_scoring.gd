class_name MissionScoring
extends RefCounted
## Score d'une mission en etoiles (1 a 3), calcule a partir de ce qui s'est
## passe sur chaque exercice. Code pur. Le score valorise la reussite sans
## aide, jamais la vitesse ni la duree (cahier des charges §2) ; ce n'est
## pas une note scolaire (§9). Une mission terminee rapporte toujours au
## moins une etoile : l'erreur n'est jamais punie.

const OUTCOME_FIRST_TRY := "first_try"
const OUTCOME_WITH_HELP := "with_help"
const OUTCOME_REVEALED := "revealed"

const MIN_STARS := 1
const MAX_STARS := 3


## 3 etoiles : tous les exercices reussis du premier coup.
## 2 etoiles : tous reussis, au moins un apres un indice ou une explication.
## 1 etoile : au moins une reponse a ete montree (mission terminee quand meme).
static func stars_for(outcomes: Array[String]) -> int:
    if outcomes.is_empty():
        return MIN_STARS
    var all_first_try := true
    for outcome in outcomes:
        if outcome == OUTCOME_REVEALED:
            return 1
        if outcome != OUTCOME_FIRST_TRY:
            all_first_try = false
    return MAX_STARS if all_first_try else 2
