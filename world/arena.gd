extends Node2D

const Player = preload("res://actors/player.gd")
const Enemy = preload("res://actors/enemy.gd")
const SPAWN := Vector2(225, 476)
const SOLDIER_SPAWN := Vector2(810, 476)
const PLATFORMS := [Rect2(0,498,1152,150), Rect2(120,420,128,14), Rect2(286,350,115,14), Rect2(914,399,130,15)]
@onready var player: Player = $Knight
@onready var enemy: Enemy = $HollowSoldier
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
var shake := 0.0
var time := 0.0
var death_delay := 0.0
var won := false
var embers := 0
var drop := 0
var drop_location := Vector2.ZERO

func _ready() -> void:
	get_tree().paused = false
	bind_inputs()
	for rect in PLATFORMS:
		add_terrain(rect)
	add_terrain(Rect2(-24,0,50,498))
	add_terrain(Rect2(1126,0,50,498))
	player.target = enemy
	enemy.target = player
	player.died.connect(on_death)
	player.feedback.connect(hud.show_feedback)
	enemy.feedback.connect(hud.show_feedback)
	player.impacted.connect(impact)
	enemy.impacted.connect(impact)
	enemy.slain.connect(on_victory)
	reset_round()
	hud.setup(self)

func bind_inputs() -> void:
	var mappings := {
		"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE],
		"roll": [KEY_SHIFT], "sprint": [KEY_CTRL], "light": [KEY_J], "heavy": [KEY_K],
		"guard": [KEY_Q], "heal": [KEY_R], "lock": [KEY_F], "interact": [KEY_E],
		"inventory": [KEY_TAB], "pause": [KEY_ESCAPE],
	}
	var pad := {"left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT,
		"jump": JOY_BUTTON_A, "roll": JOY_BUTTON_B, "light": JOY_BUTTON_X, "heal": JOY_BUTTON_Y,
		"guard": JOY_BUTTON_LEFT_SHOULDER, "heavy": JOY_BUTTON_RIGHT_SHOULDER,
		"pause": JOY_BUTTON_START, "inventory": JOY_BUTTON_BACK, "interact": JOY_BUTTON_DPAD_UP,
		"lock": JOY_BUTTON_RIGHT_STICK, "sprint": JOY_BUTTON_LEFT_STICK}
	for action in mappings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in mappings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
		var button := InputEventJoypadButton.new()
		button.button_index = pad[action]
		InputMap.action_add_event(action, button)
	for action in ["left", "right"]:
		var axis := InputEventJoypadMotion.new()
		axis.axis = JOY_AXIS_LEFT_X
		axis.axis_value = -1 if action == "left" else 1
		InputMap.action_add_event(action, axis)
	for action in ["light", "heavy"]:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT if action == "light" else MOUSE_BUTTON_RIGHT
		InputMap.action_add_event(action, mouse)

func add_terrain(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func reset_round() -> void:
	player.reset_at(SPAWN)
	enemy.reset_at(SOLDIER_SPAWN)
	won = false
	death_delay = 0

func on_death() -> void:
	drop = embers
	embers = 0
	drop_location = player.position
	death_delay = 1.65
	hud.show_feedback("Fallen", Color.SALMON)

func on_victory() -> void:
	won = true
	embers += 75
	hud.show_feedback("Hollow Soldier defeated  ·  +75 Embers", Color.WHEAT)

func impact(strength: float) -> void:
	shake = maxf(shake, strength)

func _physics_process(delta: float) -> void:
	time += delta
	shake = move_toward(shake, 0, delta * 33)
	camera.offset = Vector2(sin(time*97), cos(time*87)) * shake
	if death_delay > 0:
		death_delay -= delta
		if death_delay <= 0:
			reset_round()
	if player.state != Player.State.DEAD and Input.is_action_just_pressed("interact"):
		if drop > 0 and player.position.distance_to(drop_location) < 57:
			embers += drop
			drop = 0
			hud.show_feedback("Embers recovered", Color.WHEAT)
		elif absf(player.position.x - SPAWN.x) < 70:
			reset_round()
			hud.show_feedback("Rested at the Ash Shrine", Color.WHEAT)
	queue_redraw()

func _draw() -> void:
	for row in range(32):
		draw_rect(Rect2(0,row*21,1152,22), Color("#141722").lerp(Color("#45404a"), row/32.0))
	draw_circle(Vector2(855,180), 105, Color("#a18c80"))
	draw_circle(Vector2(855,180), 120, Color("#c4a38a23"))
	for layer in range(2):
		for i in range(16):
			var x := float(i*83 + layer*31)
			var height := 85 + (i*53 + layer*83) % 185
			var base := 461 + layer*25
			var shade := Color("#292a37") if layer == 0 else Color("#1c202a")
			draw_rect(Rect2(x,base-height,53,height),shade)
			draw_colored_polygon(PackedVector2Array([Vector2(x-8,base-height),Vector2(x+24,base-height-61),Vector2(x+61,base-height)]),shade)
			draw_rect(Rect2(x+20,base-height+29,8,38),Color("#50434b"))
	for i in range(10):
		var x := float(36 + i*125)
		draw_rect(Rect2(x,338+(i%3)*28,14,161-(i%3)*28),Color("#26252d"))
		draw_line(Vector2(x-9,405), Vector2(x+32,405), Color("#25242c"), 8)
	for i in range(9):
		var fog_x := fposmod(time*(9+i%3) + i*171, 1500) - 190
		draw_set_transform(Vector2(fog_x,401+i%4*19), 0, Vector2(1,0.08))
		draw_circle(Vector2.ZERO, 151, Color("#a4999d13"))
	draw_set_transform(Vector2.ZERO)
	for rect in PLATFORMS:
		draw_rect(rect,Color("#212027"))
		draw_line(rect.position,Vector2(rect.end.x,rect.position.y),Color("#706157"),3)
		for x in range(int(rect.position.x)+18,int(rect.end.x),31):
			draw_line(Vector2(x,rect.position.y+2),Vector2(x-3,rect.position.y+10),Color("#463a38"),1)
	for i in range(21):
		draw_rect(Rect2(i*59,519+(i%4)*18,41,16),Color("#28252c"))
	for i in range(4):
		draw_circle(Vector2(225,474), 43 - i*9, Color("#f8a45e15"))
	draw_colored_polygon(PackedVector2Array([Vector2(204,498),Vector2(214,478),Vector2(237,478),Vector2(246,498)]),Color("#716457"))
	draw_line(Vector2(225,483),Vector2(225,446),Color("#e2b67d"),3)
	for i in range(11):
		var mote := fposmod(time*(17+i%5)+i*9,52)
		draw_circle(Vector2(225+sin(time*2+i*2.4)*mote*0.42,479-mote),1.3,Color("#efad71"))
	if drop > 0:
		draw_arc(drop_location, 10 + sin(time*3)*3, 0, TAU, 32, Color("#efd08a"), 2, true)
	if player.lock_on and enemy.vitals.health > 0:
		draw_arc(enemy.position+Vector2(0,-53), 5, 0, TAU, 16, Color.WHEAT, 2, true)
