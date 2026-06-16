class_name TypeChartData
extends Resource

@export var chart: Dictionary = {}
# Forma: { "FIRE": { "GRASS": 2.0, "WATER": 0.5, ... }, "WATER": { ... }, ... }
func get_multiplier(attacker: TypeEnum.Type, defender: TypeEnum.Type) -> float:
	var atk_str := TypeEnum.type_name(attacker)
	var def_str := TypeEnum.type_name(defender)
	return chart.get(atk_str, {}).get(def_str, 1.0)
