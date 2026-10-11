class_name SchemaValidator
extends RefCounted
## Validateur de donnees contre un sous-ensemble de JSON Schema : type, required,
## properties, additionalProperties, items, enum, const, minimum, maximum,
## minItems, maxItems, minLength, maxLength, pattern.
## Les schemas ne decrivent jamais de code a executer : seulement une structure
## de donnees a verifier (voir l'invariant d'architecture dans CLAUDE.md).


static func validate(value: Variant, schema: Dictionary, path: String = "$") -> Array[String]:
    var errors: Array[String] = []
    _validate_node(value, schema, path, errors)
    return errors


static func _validate_node(
    value: Variant, schema: Dictionary, path: String, errors: Array[String]
) -> void:
    if schema.has("const"):
        if value != schema["const"]:
            errors.append("%s : doit valoir exactement %s" % [path, schema["const"]])
            return

    if schema.has("enum"):
        var allowed: Array = schema["enum"]
        if not allowed.has(value):
            errors.append("%s : valeur '%s' absente de l'enum %s" % [path, value, allowed])
            return

    if schema.has("type"):
        if not _check_type(value, schema["type"]):
            errors.append(
                "%s : type attendu '%s', trouve '%s'" % [path, schema["type"], typeof(value)]
            )
            return

    match typeof(value):
        TYPE_DICTIONARY:
            _validate_object(value, schema, path, errors)
        TYPE_ARRAY:
            _validate_array(value, schema, path, errors)
        TYPE_STRING:
            _validate_string(value, schema, path, errors)
        TYPE_INT, TYPE_FLOAT:
            _validate_number(value, schema, path, errors)


static func _check_type(value: Variant, expected: String) -> bool:
    match expected:
        "object":
            return typeof(value) == TYPE_DICTIONARY
        "array":
            return typeof(value) == TYPE_ARRAY
        "string":
            return typeof(value) == TYPE_STRING
        "boolean":
            return typeof(value) == TYPE_BOOL
        "integer":
            if typeof(value) == TYPE_INT:
                return true
            if typeof(value) == TYPE_FLOAT:
                var number: float = value
                return number == floor(number)
            return false
        "number":
            return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
        _:
            return true


static func _validate_object(
    value: Dictionary, schema: Dictionary, path: String, errors: Array[String]
) -> void:
    if schema.has("required"):
        for key: String in schema["required"]:
            if not value.has(key):
                errors.append("%s : propriete requise manquante '%s'" % [path, key])

    var properties: Dictionary = schema.get("properties", {})
    var additional_allowed: Variant = schema.get("additionalProperties", true)
    for key: String in value.keys():
        if properties.has(key):
            _validate_node(value[key], properties[key], "%s.%s" % [path, key], errors)
        elif typeof(additional_allowed) == TYPE_BOOL and additional_allowed == false:
            errors.append("%s : propriete inattendue '%s'" % [path, key])
        elif typeof(additional_allowed) == TYPE_DICTIONARY:
            # additionalProperties est lui-meme un schema : toute cle non
            # listee dans "properties" doit s'y conformer (cles dynamiques,
            # ex. une competence par skill_id dans une sauvegarde).
            _validate_node(value[key], additional_allowed, "%s.%s" % [path, key], errors)


static func _validate_array(
    value: Array, schema: Dictionary, path: String, errors: Array[String]
) -> void:
    if schema.has("minItems") and value.size() < int(schema["minItems"]):
        errors.append("%s : au moins %d element(s) attendu(s)" % [path, schema["minItems"]])
    if schema.has("maxItems") and value.size() > int(schema["maxItems"]):
        errors.append("%s : au plus %d element(s) attendu(s)" % [path, schema["maxItems"]])
    if schema.has("items"):
        var item_schema: Dictionary = schema["items"]
        for i in value.size():
            _validate_node(value[i], item_schema, "%s[%d]" % [path, i], errors)


static func _validate_string(
    value: String, schema: Dictionary, path: String, errors: Array[String]
) -> void:
    if schema.has("minLength") and value.length() < int(schema["minLength"]):
        errors.append("%s : longueur minimale %d non atteinte" % [path, schema["minLength"]])
    if schema.has("maxLength") and value.length() > int(schema["maxLength"]):
        errors.append("%s : longueur maximale %d depassee" % [path, schema["maxLength"]])
    if schema.has("pattern"):
        var regex := RegEx.new()
        regex.compile(schema["pattern"])
        if regex.search(value) == null:
            errors.append("%s : ne correspond pas au motif '%s'" % [path, schema["pattern"]])


static func _validate_number(
    value: Variant, schema: Dictionary, path: String, errors: Array[String]
) -> void:
    var number: float = value
    if schema.has("minimum") and number < float(schema["minimum"]):
        errors.append("%s : doit etre >= %s" % [path, schema["minimum"]])
    if schema.has("maximum") and number > float(schema["maximum"]):
        errors.append("%s : doit etre <= %s" % [path, schema["maximum"]])
