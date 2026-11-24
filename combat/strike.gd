extends RefCounted

var startup: float
var active: float
var recovery: float
var damage: float
var cost: float
var reach: float
var poise: float

func _init(windup: float, contact: float, endlag: float, power: float, stamina: float, distance: float, impact: float) -> void:
	startup = windup
	active = contact
	recovery = endlag
	damage = power
	cost = stamina
	reach = distance
	poise = impact

func duration() -> float:
	return startup + active + recovery

func connects(attacker: Node2D, target: Node2D, facing: int) -> bool:
	var offset := target.global_position - attacker.global_position
	if offset.x * facing < -8 or absf(offset.x) > reach or absf(offset.y) >= 44:
		return false
	var ray := PhysicsRayQueryParameters2D.create(attacker.global_position, target.global_position, 1)
	return attacker.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
