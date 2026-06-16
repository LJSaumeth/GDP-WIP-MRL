class_name TypeEnum
extends RefCounted

enum Type {
	NORMAL,
	FIRE,
	WATER,
	ELECTRIC,
	GRASS,
	ICE,
	FIGHTING,
	POISON,
	GROUND,
	FLYING,
	PSYCHIC,
	BUG,
	ROCK,
	GHOST,
	DRAGON,
	DARK,
	STEEL,
	FAIRY
}

static func type_name(t: Type) -> String:
	return Type.keys()[t]

static func from_type_name(s: String) -> Type:
	return Type[s]
