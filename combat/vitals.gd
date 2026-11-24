extends RefCounted

var health: float
var stamina: float
var max_health: float
var max_stamina: float
var regen_delay := 0.0

func _init(hp: float, energy: float) -> void:
	max_health = hp
	max_stamina = energy
	restore()

func restore() -> void:
	health = max_health
	stamina = max_stamina
	regen_delay = 0.0

func spend(cost: float) -> bool:
	if stamina < cost:
		return false
	stamina -= cost
	regen_delay = 0.55
	return true

func tick(delta: float, regen_rate: float) -> void:
	regen_delay = maxf(0, regen_delay - delta)
	if regen_delay == 0:
		stamina = minf(max_stamina, stamina + regen_rate * delta)

func hurt(amount: float) -> void:
	health = maxf(0, health - amount)
