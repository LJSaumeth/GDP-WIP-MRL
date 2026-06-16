class_name CharacterData
extends Resource


@export var id: String = ""                          # "prota_pikachu"

# -- CharacterVersion --
@export var display_name: String = ""
@export var character_id: String = ""                # "protagonist", "misty"
@export var is_protagonist: bool = false
@export var character_sprite: String = ""
@export var creature_sprite: String = ""

# -- Pokémon --
@export var types: Array[TypeEnum.Type] = []
@export var base_hp: int = 50
@export var base_atk: int = 50
@export var base_def: int = 50
@export var base_spd: int = 50

# -- Move pool --
@export var move_pool_ids: Array[String] = []        # ["thunder_shock", "quick_attack"]

# -- Evolution --
@export var evolution_options: Array[Dictionary] = [] # [{dest: "raichu", lvl: 16, mat: "thunder_stone", type: 0}]
