extends Node2D

const Landmark = preload("res://world/region/landmark.gd")
const Soldier = preload("res://actors/enemy.tscn")
const Visuals = preload("res://world/region/scenery.gd")
var spec: Dictionary
var ground: Array[Rect2] = []
var ledges: Array[Rect2] = []
var objects: Array[Landmark] = []
var enemies: Array[CharacterBody2D] = []
var bounds: Vector2
var world: Node2D

func build(data: Dictionary, owner_world: Node2D, previous: Array) -> void:
	spec = data
	world = owner_world
	bounds = Vector2(spec.width, maxf(648, spec.floor + 116))
	for row in spec.get("foundations", [[0,spec.floor,spec.width]]):
		var rect := Rect2(row[0],row[1],row[2],bounds.y-row[1]+260)
		ground.append(rect)
		collider(rect)
	for row in spec.get("ledges", []):
		var rect := Rect2(row[0],row[1],row[2],14)
		ledges.append(rect)
		collider(rect,true)
	collider(Rect2(-44,-220,64,bounds.y+520))
	collider(Rect2(bounds.x-20,-220,64,bounds.y+520))
	var scenery := Visuals.new()
	scenery.room = self
	add_child(scenery)
	for row in spec.objects:
		var point := Landmark.new(row)
		objects.append(point)
		add_child(point)
		if point.kind == "fog":
			collider(Rect2(point.position.x+47,point.position.y-210,26,210))
	for index in range(spec.get("foes", []).size()):
		var row: Array = spec.foes[index]
		var foe := Soldier.instantiate() as CharacterBody2D
		foe.target = world.player
		foe.territory = Vector2(row[2], row[3])
		foe.attack_permission = world.can_enemy_attack
		foe.elite = row.size() > 4
		if foe.elite:
			foe.vitals.max_health = 210
		foe.reset_at(Vector2(row[0],row[1]-22))
		if index < previous.size():
			foe.position = previous[index][0]
			foe.vitals.health = previous[index][1]
			if foe.vitals.health <= 0:
				foe.enter(foe.State.DEAD)
		foe.slain.connect(world.on_enemy_slain)
		foe.feedback.connect(world.hud.show_feedback)
		foe.impacted.connect(world.impact)
		foe.z_index = 3
		enemies.append(foe)
		add_child(foe)
	refresh()

func refresh() -> void:
	for point in objects:
		point.refresh(world.state.data)

func snapshot() -> Array:
	var result := []
	for foe in enemies:
		result.append([foe.position, foe.vitals.health])
	return result

func collider(rect: Rect2, one_way := false) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.one_way_collision = one_way
	body.add_child(collision)
	add_child(body)

func safe_ground(point: Vector2) -> bool:
	for rect in ground + ledges:
		if absf(point.y + 22 - rect.position.y) < 4 and point.x >= rect.position.x+17 and point.x <= rect.end.x-17:
			return true
	return false
