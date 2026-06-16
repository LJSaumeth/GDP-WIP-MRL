class_name MoveData
extends Resource

enum Category { PHYSICAL, SPECIAL, STATUS }
enum Rarity { BASIC, COMMON, UNCOMMON, RARE }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var energy_cost: int = 1
@export var elemental_type: String = "Normal"
@export var category: Category = Category.PHYSICAL
@export var rarity: Rarity = Rarity.BASIC
@export var base_damage: int = 0
@export var self_defense_gain: int = 0          # >0 = defensive move
@export var status_effect: String = ""           # "paralysis", "burn", "" = none
@export var status_chance: float = 0.0           # 0.0 - 1.0
@export var buff_target: String = ""             # "self" or "enemy"
@export var buff_stat: String = ""               # "atk", "def", "spd"
@export var buff_amount: float = 0.0             # 0.0 - 2.0
@export var is_exclusive: bool = false           # true = only for one creature
