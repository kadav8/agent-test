extends CharacterBody2D

signal died
signal feedback(message: String, color: Color)
signal impacted(strength: float)

const Strike = preload("res://combat/strike.gd")
const Vitals = preload("res://combat/vitals.gd")
enum State { FREE, ATTACK, ROLL, GUARD, HEAL, STAGGER, DEAD }
const WEAPONS := [
	["Vigil Sword", "Balanced", 23.0, 74.0, 13.0, 0.20],
	["Ash Daggers", "Fast · short reach", 16.0, 58.0, 9.0, 0.13],
	["Grave Cleaver", "Slow · high impact", 34.0, 91.0, 19.0, 0.31],
]
const MAX_FLASKS := 3
var vitals := Vitals.new(100, 100)
var state := State.FREE
var facing := 1
var elapsed := 0.0
var weapon := 0
var flasks := MAX_FLASKS
var target: CharacterBody2D
var opponents: Array[CharacterBody2D] = []
var lock_on := false
var attack: Strike
var hit := false
var heavy := false
var chain := false
var combo := 0
var flash := 0.0
var stagger_length := 0.37
var anim := 0.0

func enter(next: State) -> void:
	state = next
	elapsed = 0
	if next == State.DEAD:
		died.emit()

func reset_at(point: Vector2) -> void:
	global_position = point
	velocity = Vector2.ZERO
	vitals.restore()
	flasks = MAX_FLASKS
	lock_on = false
	flash = 0
	enter(State.FREE)

func start_attack(power: bool) -> void:
	var data: Array = WEAPONS[weapon]
	heavy = power
	attack = Strike.new(data[5] * (1.75 if heavy else 1.0), 0.10,
		0.45 if heavy else 0.27, data[2] * (1.65 if heavy else 1.0),
		data[4] + (12.0 if heavy else 0.0), data[3] + (15.0 if heavy else 0.0),
		48.0 if heavy else 18.0)
	if vitals.spend(attack.cost):
		hit = false
		chain = false
		enter(State.ATTACK)
	else:
		feedback.emit("Exhausted", Color.BURLYWOOD)

func _physics_process(delta: float) -> void:
	elapsed += delta
	anim += delta
	flash = maxf(0, flash - delta)
	if not is_on_floor():
		velocity.y += 980 * delta
	if state == State.FREE:
		vitals.tick(delta, 34)
	if Input.is_action_just_pressed("lock") and is_instance_valid(target) and target.vitals.health > 0:
		lock_on = not lock_on
	match state:
		State.FREE:
			free_move()
		State.ATTACK:
			velocity.x = facing * (68 if elapsed < attack.startup + attack.active else 0)
			if not heavy and elapsed >= attack.startup and Input.is_action_just_pressed("light"):
				chain = true
			if not hit and elapsed >= attack.startup and elapsed < attack.startup + attack.active:
				var victim := strike_target()
				if victim != null:
					hit = true
					victim.receive(attack.damage, attack.poise, facing)
			if elapsed >= attack.duration():
				enter(State.FREE)
				if chain and combo < 2:
					combo += 1
					start_attack(false)
				else:
					combo = 0
		State.ROLL:
			velocity.x = facing * 337.0 * maxf(0.28, 1.0 - elapsed)
			if elapsed >= 0.43:
				enter(State.FREE)
		State.GUARD:
			velocity.x = Input.get_axis("left", "right") * 58.0
			if not Input.is_action_pressed("guard"):
				enter(State.FREE)
		State.HEAL:
			velocity.x = 0
			if elapsed >= 0.75:
				flasks -= 1
				vitals.health = minf(vitals.max_health, vitals.health + 45)
				feedback.emit("Restored", Color.PALE_GREEN)
				enter(State.FREE)
		State.STAGGER:
			velocity.x = move_toward(velocity.x, 0, 760 * delta)
			if elapsed >= stagger_length:
				enter(State.FREE)
		State.DEAD:
			velocity.x = 0
	move_and_slide()
	queue_redraw()

func strike_target() -> CharacterBody2D:
	if is_instance_valid(target) and target.vitals.health > 0 and attack.connects(self, target, facing):
		return target
	for opponent in opponents:
		if opponent.vitals.health > 0 and attack.connects(self, opponent, facing):
			return opponent
	return null

func relocate(point: Vector2) -> void:
	global_position = point
	velocity = Vector2.ZERO
	lock_on = false
	target = null
	opponents.clear()
	enter(State.FREE)

func free_move() -> void:
	var axis := Input.get_axis("left", "right")
	if lock_on and is_instance_valid(target) and target.vitals.health > 0:
		facing = 1 if target.position.x >= position.x else -1
	elif axis != 0:
		facing = 1 if axis > 0 else -1
	var speed := 175.0
	if axis != 0 and Input.is_action_pressed("sprint") and vitals.spend(0.32):
		speed = 248.0
	velocity.x = axis * speed
	if Input.is_action_just_pressed("roll") and is_on_floor() and vitals.spend(24):
		if axis != 0:
			facing = 1 if axis > 0 else -1
		enter(State.ROLL)
	elif Input.is_action_just_pressed("heavy"):
		combo = 0
		start_attack(true)
	elif Input.is_action_just_pressed("light"):
		combo = 0
		start_attack(false)
	elif Input.is_action_just_pressed("heal") and flasks > 0 and vitals.health < vitals.max_health:
		enter(State.HEAL)
	elif Input.is_action_just_pressed("guard"):
		enter(State.GUARD)
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -405

func receive(damage: float, direction: int, attacker: CharacterBody2D) -> void:
	if state == State.DEAD or (state == State.ROLL and elapsed >= 0.055 and elapsed < 0.27):
		return
	if state == State.GUARD and direction == -facing:
		if elapsed <= 0.145 and vitals.spend(9):
			attacker.parried()
			impacted.emit(5)
			feedback.emit("Parry", Color.PALE_GOLDENROD)
			return
		if vitals.stamina > 1.15 * damage:
			vitals.spend(1.15 * damage)
			vitals.hurt(damage * 0.16)
			impacted.emit(2)
			if vitals.health <= 0:
				enter(State.DEAD)
			return
		vitals.spend(vitals.stamina)
		feedback.emit("Guard broken", Color.SALMON)
		stagger_length = 0.67
	else:
		stagger_length = 0.37
	vitals.hurt(damage)
	flash = 0.16
	impacted.emit(6)
	velocity.x = direction * 185
	enter(State.DEAD if vitals.health <= 0 else State.STAGGER)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(facing, 1))
	draw_ellipse_shadow()
	var body := Color("#848a91") if flash == 0 else Color.WHITE
	var cloak := Color("#622e38")
	if state == State.DEAD:
		draw_set_transform(Vector2(0, 12), PI / 2, Vector2.ONE)
	elif state == State.ROLL:
		draw_set_transform(Vector2(0, 6), elapsed * TAU * 2.3 * facing, Vector2(facing, 0.75))
	var step := sin(anim * 13) * minf(absf(velocity.x) / 21, 9)
	draw_colored_polygon(PackedVector2Array([Vector2(-8,-24), Vector2(6,-17), Vector2(3,20), Vector2(-17-step,19)]), cloak)
	draw_line(Vector2(-4,1), Vector2(-5+step,19), body.darkened(0.3), 6)
	draw_line(Vector2(5,1), Vector2(6-step,19), body, 6)
	draw_colored_polygon(PackedVector2Array([Vector2(-10,-20), Vector2(10,-20), Vector2(8,3), Vector2(-7,4)]), body)
	draw_line(Vector2(-7,-14), Vector2(8,-8), body.lightened(0.23), 2)
	draw_rect(Rect2(-8,-34,16,14), body.darkened(0.14))
	draw_line(Vector2(0,-28), Vector2(8,-28), Color("#f7c486"), 2)
	var angle := -0.75
	if state == State.ATTACK:
		if elapsed < attack.startup:
			angle = -2.7
		else:
			angle = lerpf(-2.7,1.05, minf(1, (elapsed-attack.startup)/attack.active))
			if elapsed < attack.startup + attack.active:
				draw_arc(Vector2(6,-8), attack.reach * 0.76, -2.7, angle + 0.12, 24, Color("#ecc189b8"), 4, true)
	if state == State.GUARD:
		draw_circle(Vector2(12,-9), 11, Color("#3e4751"))
		draw_arc(Vector2(12,-9), 11, 0, TAU, 24, Color.GOLDENROD if elapsed < 0.145 else body, 2, true)
	elif state == State.HEAL:
		draw_circle(Vector2(13,-17), 4 + elapsed * 6, Color("#deb36e"))
	else:
		var hand := Vector2(8,-9)
		var blade := Vector2.from_angle(angle)
		draw_line(hand, hand + blade * (attack.reach * 0.64 if state == State.ATTACK else 29), Color("#dfd9c6"), 5 if weapon == 2 else 3, true)
		draw_line(hand + blade.orthogonal()*5, hand - blade.orthogonal()*5, Color("#b48e58"), 3, true)

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0,20), 0, Vector2(1,0.24))
	draw_circle(Vector2.ZERO, 17, Color(0,0,0,0.42))
	draw_set_transform(Vector2.ZERO, 0, Vector2(facing,1))
