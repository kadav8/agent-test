extends Node2D

signal boss_gate_requested(room_id: String)

const Layout = preload("res://world/region/layout.gd")
const WorldState = preload("res://world/region/world_state.gd")
const Room = preload("res://world/region/room.gd")
const Landmark = preload("res://world/region/landmark.gd")
const Player = preload("res://actors/player.gd")

@onready var player: Player = $Knight
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var audio: Node = $Audio
var state := WorldState.new()
var room: Room
var room_id := ""
var arrival := ""
var safe_position := Vector2.ZERO
var encounters := {}
var nearby: Landmark
var marker_near := false
var shake := 0.0
var camera_aim := Vector2.ZERO
var clock := 0.0
var death_delay := 0.0
var dialogue_id := ""
var dialogue_index := 0
var dialogue_speaker := ""
var step_distance := 0.0
var previous_step_x := 0.0

func _ready() -> void:
	preload("res://world/controls.gd").bind()
	hud.setup(self)
	state.load_file()
	player.died.connect(on_death)
	player.feedback.connect(hud.show_feedback)
	player.impacted.connect(impact)
	var location: Dictionary = Layout.ROOMS.get(state.data.room, {})
	if not location.get("entries", {}).has(state.data.entry):
		state.data.room = Layout.SHRINE
		state.data.entry = "fire"
	player.vitals.health = clampf(state.data.health, 1, player.vitals.max_health)
	player.vitals.stamina = clampf(state.data.stamina, 0, player.vitals.max_stamina)
	player.flasks = clampi(int(state.data.flasks),0,player.MAX_FLASKS)
	var saved_weapon := int(state.data.weapon)
	player.weapon = saved_weapon if saved_weapon in available_weapons() else 0
	enter_room(state.data.room, state.data.entry)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(room):
		persist()

func enter_room(id: String, port: String) -> void:
	var spec: Dictionary = Layout.ROOMS[id]
	var entry: Array = spec.entries[port]
	if is_instance_valid(room):
		encounters[room_id] = room.snapshot()
		remove_child(room)
		room.queue_free()
	room_id = id
	arrival = port
	safe_position = Vector2(entry[0],entry[1]-22)
	player.relocate(safe_position)
	room = Room.new()
	add_child(room)
	room.build(spec,self,encounters.get(id,[]))
	player.opponents.assign(room.enemies)
	nearby = null
	marker_near = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(room.bounds.x)
	camera.limit_bottom = int(room.bounds.y)
	camera_aim = camera_center()
	camera.position = camera_aim
	camera.reset_smoothing()
	camera.force_update_scroll()
	previous_step_x = player.position.x
	step_distance = 0
	audio.set_theme(spec.theme)
	audio.set_bonfire(Vector2.ZERO,false)
	for point in room.objects:
		if point.kind == "fire":
			audio.set_bonfire(point.position,true)
			break
	hud.room_changed(spec.title)

func camera_center() -> Vector2:
	var look := clampf(player.velocity.x*0.53,-125,125)
	var half := Vector2(576,324)
	return (player.position+Vector2(look,-112)).clamp(half,room.bounds-half)

func _physics_process(delta: float) -> void:
	clock += delta
	shake = move_toward(shake,0,delta*33)
	camera_aim = camera_aim.lerp(camera_center(),1.0-exp(-6.5*delta))
	camera.position = (camera_aim+Vector2(sin(clock*97),cos(clock*87))*shake).clamp(Vector2(576,324), room.bounds-Vector2(576,324))
	update_proximity()
	if death_delay > 0:
		death_delay -= delta
		if death_delay <= 0:
			respawn()
		return
	if player.position.y > float(room.spec.floor) + 130.0:
		player.vitals.hurt(player.vitals.health)
		player.enter(Player.State.DEAD)
		return
	if player.is_on_floor() and room.safe_ground(player.position):
		safe_position = player.position
		step_distance += absf(player.position.x - previous_step_x)
		if step_distance >= 57:
			step_distance = 0
			audio.play_cue("step")
	previous_step_x = player.position.x
	choose_target()
	if Input.is_action_just_pressed("interact") and player.state == Player.State.FREE:
		interact()

func choose_target() -> void:
	if player.lock_on and is_instance_valid(player.target) and player.target.vitals.health > 0 and player.position.distance_to(player.target.position) < 510:
		return
	player.lock_on = false
	var nearest := 400.0
	player.target = null
	for foe in room.enemies:
		var distance := player.position.distance_to(foe.position)
		if foe.vitals.health > 0 and distance < nearest:
			player.target = foe
			nearest = distance

func update_proximity() -> void:
	nearby = null
	var best := 72.0
	for point in room.objects:
		var distance := player.position.distance_to(point.position - Vector2(0,22))
		if point.visible and distance < best:
			nearby = point
			best = distance
	var marker: Dictionary = state.data.marker
	marker_near = marker.get("room") == room_id and marker_position().distance_to(player.position) < 60

func marker_position() -> Vector2:
	var marker: Dictionary = state.data.marker
	return Vector2(float(marker.get("x",0)),float(marker.get("y",0)))

func prompt() -> String:
	if death_delay > 0:
		return "Fallen"
	if marker_near:
		return "E  Recover %d souls" % int(state.data.marker.amount)
	return "E  " + nearby.prompt() if is_instance_valid(nearby) else ""

func interact() -> void:
	if marker_near:
		state.data.souls += int(state.data.marker.amount)
		state.data.marker = {}
		marker_near = false
		hud.show_feedback("Souls recovered",Color.WHEAT)
		audio.play_cue("loot")
		persist()
	elif is_instance_valid(nearby):
		activate(nearby)

func activate(point: Landmark) -> void:
	match point.kind:
		"fire":
			state.data.checkpoint = point.id
			state.data.fires[point.id] = true
			respawn()
			audio.play_cue("fire")
			hud.show_feedback("Rested at " + point.label,Color.WHEAT)
		"loot":
			collect(point)
		"npc":
			dialogue_id = point.id
			dialogue_index = 0
			dialogue_speaker = point.label
			hud.show_dialogue(dialogue_speaker,Layout.DIALOGUE[point.id][0])
		"reserved":
			hud.show_feedback("Locked · The apse is sealed",Color.WHEAT)
		"fog":
			boss_gate_requested.emit(room_id)
			hud.show_feedback("The Bell Warden encounter is unavailable in this build.",Color.WHEAT)
			audio.play_cue("bell")
		"shortcut":
			if not point.open:
				if point.from_unlock_side:
					unlock(point,"Lift released · Ashen Shrine shortcut opened","gate")
				else:
					hud.show_feedback("Opens from the other side",Color.WHEAT)
			else:
				travel(point,"gate")
		"secret":
			if point.open:
				travel(point,"stone")
			else:
				unlock(point,"A burial passage opens behind the stone","secret")
		"key":
			if point.open:
				travel(point,"gate")
			elif int(state.data.items.get("rusty_key",0)) > 0:
				unlock(point,"Door unlocked · Rusty Key","gate")
			else:
				hud.show_feedback("Locked · Rusty Key required",Color.WHEAT)
		"door":
			state.data.doors[point.id] = true
			travel(point,"stone")

func unlock(point: Landmark, message: String, cue: String) -> void:
	state.data.doors[point.flag] = true
	room.refresh()
	persist()
	audio.play_cue(cue)
	hud.show_feedback(message,Color.WHEAT)

func travel(point: Landmark, cue: String) -> void:
	audio.play_cue(cue)
	enter_room(point.link,point.entry)
	persist()

func collect(point: Landmark) -> void:
	if state.data.loot.has(point.id):
		return
	state.data.loot[point.id] = true
	var item: Array = Layout.ITEMS[point.label]
	if point.label == "fragment":
		state.data.souls += point.quantity
	else:
		state.data.items[point.label] = int(state.data.items.get(point.label,0))+point.quantity
	room.refresh()
	update_proximity()
	audio.play_cue("loot")
	hud.show_feedback(item[0] + ("  +%d" % point.quantity if point.quantity > 1 else ""),Color.WHEAT)
	persist()

func available_weapons() -> Array[int]:
	var result: Array[int] = [0]
	for id in ["daggers","cleaver"]:
		if state.data.items.has(id):
			result.append(Layout.ITEMS[id][2])
	return result

func item_details() -> Array[String]:
	var result: Array[String] = []
	for id in state.data.items:
		if Layout.ITEMS.has(id):
			var item: Array = Layout.ITEMS[id]
			result.append("%s ×%d\n%s" % [item[0],state.data.items[id],item[1]])
	return result

func advance_dialogue() -> void:
	var lines: Array = Layout.DIALOGUE[dialogue_id]
	dialogue_index += 1
	if dialogue_index >= lines.size():
		state.data.dialogue[dialogue_id] = true
		persist()
		hud.close_dialogue()
	else:
		hud.show_dialogue(dialogue_speaker,lines[dialogue_index])

func can_enemy_attack(candidate: CharacterBody2D) -> bool:
	for foe in room.enemies:
		if foe != candidate and foe.state == foe.State.ATTACK:
			return false
	return true

func on_enemy_slain() -> void:
	state.data.souls += 75
	hud.show_feedback("+75 souls",Color.WHEAT)

func impact(strength: float) -> void:
	shake = maxf(shake,minf(strength,5.0))

func on_death() -> void:
	state.data.marker = {}
	if state.data.souls > 0:
		state.data.marker = {
			"room": room_id, "x": safe_position.x, "y": safe_position.y, "amount": state.data.souls,
		}
	state.data.souls = 0
	death_delay = 1.3
	persist()

func checkpoint() -> Array[String]:
	match state.data.checkpoint:
		"court_fire": return ["broken_courtyard","fire"]
		"warden_fire": return ["wardens_approach","fire"]
	return [Layout.SHRINE,"fire"]

func respawn() -> void:
	var destination := checkpoint()
	# Drop the current snapshot before rebuilding the checkpoint room.
	var old := room
	room = null
	remove_child(old)
	old.queue_free()
	encounters.clear()
	death_delay = 0
	enter_room(destination[0],destination[1])
	player.reset_at(safe_position)
	persist()

func persist() -> void:
	var destination: Array = checkpoint() if death_delay > 0 else [room_id,arrival]
	state.data.room = destination[0]
	state.data.entry = destination[1]
	state.data.health = player.vitals.max_health if death_delay > 0 else player.vitals.health
	state.data.stamina = player.vitals.max_stamina if death_delay > 0 else player.vitals.stamina
	state.data.flasks = player.MAX_FLASKS if death_delay > 0 else player.flasks
	state.data.weapon = player.weapon
	if not state.save_file():
		hud.show_feedback("Unable to save world progress",Color.SALMON)
