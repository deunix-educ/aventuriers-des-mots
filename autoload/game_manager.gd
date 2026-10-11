extends Node
## Cycle de vie de l'application, navigation entre scenes et etat general du
## jeu. Porte le contexte transitoire necessaire entre deux changements de
## scene (ex. la mission choisie sur la carte), puisque Godot libere les
## noeuds de la scene precedente a chaque changement.

const SCENE_BOOT := "res://scenes/boot/boot.tscn"
const SCENE_PROFILE_SELECT := "res://scenes/profiles/profile_select.tscn"
const SCENE_PROFILE_CREATE := "res://scenes/profiles/profile_create.tscn"
const SCENE_WORLD_MAP := "res://scenes/world/world_map.tscn"
const SCENE_MISSION_INTRO := "res://scenes/world/mission_intro.tscn"
const SCENE_EXERCISE_HOST := "res://scenes/exercises/exercise_host.tscn"
const SCENE_REWARD := "res://scenes/ui/reward_screen.tscn"
const SCENE_COLLECTION := "res://scenes/ui/collection.tscn"

## Mission choisie sur la carte, lue par mission_intro puis exercise_host et
## reward_screen. Remise a vide par reward_screen au retour sur la carte.
var pending_mission_id: String = ""

## Resultat de chaque exercice de la mission qui vient de se terminer
## (MissionScoring.OUTCOME_*), transmis par exercise_host a reward_screen.
var last_outcomes: Array[String] = []


func goto(scene_path: String) -> void:
    # Differe le changement de scene : l'appeler depuis le _ready() de la
    # scene en cours d'ajout a l'arbre echoue sinon ("Parent node is busy").
    get_tree().change_scene_to_file.call_deferred(scene_path)
