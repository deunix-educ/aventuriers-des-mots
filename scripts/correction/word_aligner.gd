class_name WordAligner
extends RefCounted
## Alignement mot a mot entre le texte cible et la production de l'enfant
## (distance d'edition, algorithme de Wagner-Fischer), avant toute comparaison
## caractere par caractere : sans cela, un mot omis ou ajoute decale tous les
## mots suivants et les transforme en erreurs (voir "Points durs" du prompt de
## lancement).


## Chaque operation : {"op": "match" | "substitute" | "delete" | "insert",
## "target_index": int (-1 si insert), "submitted_index": int (-1 si delete)}.
## "delete" = mot du texte cible absent de la production ; "insert" = mot
## ajoute par l'enfant, absent du texte cible.
static func align(target_words: Array[String], submitted_words: Array[String]) -> Array[Dictionary]:
    var n := target_words.size()
    var m := submitted_words.size()

    var cost: Array = []
    for i in n + 1:
        var row: Array[int] = []
        for _j in m + 1:
            row.append(0)
        cost.append(row)
    for i in n + 1:
        cost[i][0] = i
    for j in m + 1:
        cost[0][j] = j

    for i in range(1, n + 1):
        for j in range(1, m + 1):
            if target_words[i - 1] == submitted_words[j - 1]:
                cost[i][j] = cost[i - 1][j - 1]
            else:
                cost[i][j] = 1 + mini(mini(cost[i - 1][j], cost[i][j - 1]), cost[i - 1][j - 1])

    var ops: Array[Dictionary] = []
    var i := n
    var j := m
    while i > 0 or j > 0:
        if i > 0 and j > 0 and target_words[i - 1] == submitted_words[j - 1]:
            ops.append({"op": "match", "target_index": i - 1, "submitted_index": j - 1})
            i -= 1
            j -= 1
        elif i > 0 and j > 0 and cost[i][j] == cost[i - 1][j - 1] + 1:
            ops.append({"op": "substitute", "target_index": i - 1, "submitted_index": j - 1})
            i -= 1
            j -= 1
        elif i > 0 and cost[i][j] == cost[i - 1][j] + 1:
            ops.append({"op": "delete", "target_index": i - 1, "submitted_index": -1})
            i -= 1
        else:
            ops.append({"op": "insert", "target_index": -1, "submitted_index": j - 1})
            j -= 1
    ops.reverse()
    return ops
