class_name ReviewScheduler
extends RefCounted
## Transitions de maitrise (cahier des charges §9) et planification des
## revisions. Code pur : l'horloge n'intervient jamais ; le numero de seance
## est injecte par l'appelant (ProgressManager), jamais lu directement (voir
## l'invariant d'architecture dans CLAUDE.md). Seuils et paliers detailles dans
## docs/specs/decisions.md, point 5.

const RECENT_WINDOW_SMALL := 5
const RECENT_WINDOW_LARGE := 8
const MIN_SUCCESS_RATE_CONSOLIDATION := 0.6
const MIN_SUCCESS_RATE_ACQUISE := 0.85
const MIN_SUCCESSES_WITHOUT_HINT_CONSOLIDATION := 2
const MIN_HINTLESS_RECENT_SUCCESSES_ACQUISE := 4
const MIN_DISTINCT_SESSIONS_ACQUISE := 3
const MIN_DISTINCT_FORMATS_ACQUISE := 2
const REVIEW_INTERVALS_SESSIONS: Array[int] = [1, 3, 6, 12]

const STATUS_DECOUVERTE := "decouverte"
const STATUS_EN_ACQUISITION := "en_acquisition"
const STATUS_EN_CONSOLIDATION := "en_consolidation"
const STATUS_ACQUISE := "acquise"
const STATUS_A_REVISER := "a_reviser"


static func initial_state() -> Dictionary:
    return {
        "status": STATUS_DECOUVERTE,
        "recent_results": [] as Array[bool],
        "recent_hint_used": [] as Array[bool],
        "sessions_succeeded": [] as Array[int],
        "formats_succeeded": [] as Array[String],
        "last_session_practiced": -1,
        "review_interval_index": -1,
        "next_review_session": -1,
    }


## attempt : {"success": bool, "hint_used": bool, "exercise_type": String}.
## Retourne un nouvel etat ; ne modifie jamais `state` en place.
static func record_attempt(
    state: Dictionary, attempt: Dictionary, current_session: int
) -> Dictionary:
    var previous_status: String = state["status"]
    var new_state: Dictionary = state.duplicate(true)
    var success: bool = attempt["success"]
    var hint_used: bool = attempt["hint_used"]
    var exercise_type: String = attempt["exercise_type"]

    _push_bounded(new_state["recent_results"], success, RECENT_WINDOW_LARGE)
    _push_bounded(new_state["recent_hint_used"], hint_used, RECENT_WINDOW_LARGE)
    new_state["last_session_practiced"] = current_session

    if success:
        if not new_state["sessions_succeeded"].has(current_session):
            new_state["sessions_succeeded"].append(current_session)
        if not new_state["formats_succeeded"].has(exercise_type):
            new_state["formats_succeeded"].append(exercise_type)

    var was_due: bool = is_due_for_review(state, current_session)
    new_state["status"] = _next_status(new_state, success)
    _update_review_schedule(new_state, previous_status, success, was_due, current_session)

    return new_state


static func is_due_for_review(state: Dictionary, current_session: int) -> bool:
    var next_review: int = state.get("next_review_session", -1)
    return next_review != -1 and current_session >= next_review


## A appeler au debut d'une seance pour chaque competence "acquise" avant toute
## nouvelle tentative : un delai de revision atteint sans pratique bascule la
## competence en "a_reviser" (cahier des charges §9, delai de revision).
static func mark_overdue_as_review(state: Dictionary, current_session: int) -> Dictionary:
    if state["status"] == STATUS_ACQUISE and is_due_for_review(state, current_session):
        var new_state: Dictionary = state.duplicate(true)
        new_state["status"] = STATUS_A_REVISER
        new_state["review_interval_index"] = -1
        new_state["next_review_session"] = -1
        return new_state
    return state


static func _update_review_schedule(
    new_state: Dictionary,
    previous_status: String,
    success: bool,
    was_due: bool,
    current_session: int,
) -> void:
    var status: String = new_state["status"]

    if status == STATUS_A_REVISER:
        new_state["review_interval_index"] = -1
        new_state["next_review_session"] = -1
        return

    if status != STATUS_ACQUISE:
        return

    if previous_status != STATUS_ACQUISE:
        # Premiere arrivee en "acquise" (depuis en_consolidation ou a_reviser).
        new_state["review_interval_index"] = 0
        new_state["next_review_session"] = current_session + REVIEW_INTERVALS_SESSIONS[0]
        return

    if success and was_due:
        var next_index: int = mini(
            int(new_state["review_interval_index"]) + 1, REVIEW_INTERVALS_SESSIONS.size() - 1
        )
        new_state["review_interval_index"] = next_index
        new_state["next_review_session"] = current_session + REVIEW_INTERVALS_SESSIONS[next_index]


static func _next_status(state: Dictionary, last_success: bool) -> String:
    var current_status: String = state["status"]

    if current_status == STATUS_ACQUISE or current_status == STATUS_A_REVISER:
        return STATUS_ACQUISE if last_success else STATUS_A_REVISER

    if not last_success:
        return current_status

    if current_status == STATUS_DECOUVERTE:
        return STATUS_EN_ACQUISITION

    if current_status == STATUS_EN_ACQUISITION:
        return STATUS_EN_CONSOLIDATION if _is_ready_for_consolidation(state) else current_status

    if current_status == STATUS_EN_CONSOLIDATION:
        return STATUS_ACQUISE if _is_ready_for_acquise(state) else current_status

    return current_status


static func _is_ready_for_consolidation(state: Dictionary) -> bool:
    var recent: Array = _last_n(state["recent_results"], RECENT_WINDOW_SMALL)
    var hints: Array = _last_n(state["recent_hint_used"], RECENT_WINDOW_SMALL)
    if recent.is_empty():
        return false

    var successes_without_hint := 0
    var success_count := 0
    for i in recent.size():
        if recent[i]:
            success_count += 1
            if not hints[i]:
                successes_without_hint += 1

    var success_rate := float(success_count) / float(recent.size())
    return (
        successes_without_hint >= MIN_SUCCESSES_WITHOUT_HINT_CONSOLIDATION
        and success_rate >= MIN_SUCCESS_RATE_CONSOLIDATION
    )


static func _is_ready_for_acquise(state: Dictionary) -> bool:
    var recent: Array = _last_n(state["recent_results"], RECENT_WINDOW_LARGE)
    var hints: Array = _last_n(state["recent_hint_used"], RECENT_WINDOW_LARGE)
    if recent.size() < RECENT_WINDOW_LARGE:
        return false

    var success_count := 0
    for result in recent:
        if result:
            success_count += 1
    var success_rate := float(success_count) / float(recent.size())
    if success_rate < MIN_SUCCESS_RATE_ACQUISE:
        return false

    var hintless_recent_successes := 0
    var i := recent.size() - 1
    while i >= 0 and hintless_recent_successes < MIN_HINTLESS_RECENT_SUCCESSES_ACQUISE:
        if recent[i]:
            if hints[i]:
                return false
            hintless_recent_successes += 1
        i -= 1
    if hintless_recent_successes < MIN_HINTLESS_RECENT_SUCCESSES_ACQUISE:
        return false

    if state["sessions_succeeded"].size() < MIN_DISTINCT_SESSIONS_ACQUISE:
        return false
    if state["formats_succeeded"].size() < MIN_DISTINCT_FORMATS_ACQUISE:
        return false

    return true


static func _push_bounded(array: Array, value: Variant, max_size: int) -> void:
    array.append(value)
    while array.size() > max_size:
        array.remove_at(0)


static func _last_n(array: Array, n: int) -> Array:
    if array.size() <= n:
        return array.duplicate()
    return array.slice(array.size() - n)
