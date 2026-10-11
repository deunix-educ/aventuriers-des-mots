class_name CorrectionResult
extends RefCounted
## Structure de correction retournee par answer_validator et dictation_analyzer
## (cahier des charges §6, docs/specs/decisions.md point 4). Chaque entree de
## `errors` : {"position": int, "error_type": String ("lexical" | "grammatical" |
## "unclassified" | "capitalization"), "rule_id": String, "found": String,
## "expected": String}.

var is_correct: bool
var errors: Array[Dictionary]
var explanation: String
var hint: String
var remediation: Array[String]


static func correct(explanation: String) -> CorrectionResult:
    var result := CorrectionResult.new()
    result.is_correct = true
    result.errors = []
    result.explanation = explanation
    result.hint = ""
    result.remediation = []
    return result


static func incorrect(
    errors: Array[Dictionary], explanation: String, hint: String, remediation: Array[String]
) -> CorrectionResult:
    var result := CorrectionResult.new()
    result.is_correct = false
    result.errors = errors
    result.explanation = explanation
    result.hint = hint
    result.remediation = remediation
    return result
