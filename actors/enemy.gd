extends CharacterBody2D

signal slain
signal impacted(strength: float)
signal feedback(message: String, color: Color)

const Strike = preload("res://combat/strike.gd")
const Vitals = preload("res://combat/vitals.gd")
enum State { IDLE, PATROL, DETECT, CHASE, ATTACK, RECOVER, BLOCK, STAGGER, RETREAT, DEAD }
var vitals := Vitals.new(160, 100)
var state := State.IDLE
var target: CharacterBody2D
var elapsed := 0.0
var facing := -1
var home := Vector2.ZERO
var attack: Strike
var hit := false
var flash := 0.0
var poise := 0.0
var stagger_duration := 0.0
var vulnerable := false
var swings := 0
var anim := 0.0
var territory := Vector2(-INF, INF)
var attack_permission: Callable
var elite := false

func enter(next: State) -> void:
	state = next
	elapsed = 0

func reset_at(point: Vector2) -> void:
	position = point
	home = point
	velocity = Vector2.ZERO
	vitals.restore()
	poise = 0
	swings = 0
	facing = -1
	flash = 0
	vulnerable = false
	enter(State.IDLE)

func sees_player() -> bool:
	if target.position.x < territory.x or target.position.x > territory.y:
		return false
	if target.vitals.health <= 0 or global_position.distance_to(target.global_position) > 400:
		return false
	var ray := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func _physics_process(delta: float) -> void:
	elapsed += delta
	anim += delta
	flash = maxf(0, flash - delta)
	poise = maxf(0, poise - delta * 12)
	if not is_on_floor():
		velocity.y += 980 * delta
	var offset: Vector2 = target.position - position
	var distance := absf(offset.x)
	var direction := 1 if offset.x >= 0 else -1
	match state:
		State.IDLE:
			velocity.x = 0
			if sees_player():
				enter(State.DETECT)
			elif elapsed > 0.65:
				enter(State.PATROL)
		State.PATROL:
			velocity.x = facing * 39
			if absf(position.x - home.x) > 70 and signf(position.x-home.x) == facing:
				facing *= -1
			if sees_player():
				enter(State.DETECT)
		State.DETECT:
			facing = direction
			velocity.x = 0
			if elapsed > 0.32:
				enter(State.CHASE)
		State.CHASE:
			facing = direction
			velocity.x = facing * 113
			if distance < 87 and absf(offset.y) < 43 and sees_player():
				velocity.x = 0
				if not attack_permission.is_valid() or attack_permission.call(self):
					start_attack()
			elif not sees_player() and elapsed > 1.2:
				enter(State.RETREAT)
		State.ATTACK:
			velocity.x = facing * (120 if elapsed >= attack.startup and elapsed < attack.startup + attack.active else 0)
			if not hit and elapsed >= attack.startup and elapsed < attack.startup + attack.active:
				if attack.connects(self, target, facing):
					hit = true
					target.receive(attack.damage, facing, self)
			if state == State.ATTACK and elapsed >= attack.startup + attack.active:
				enter(State.RECOVER)
		State.RECOVER:
			velocity.x = 0
			if elapsed >= attack.recovery:
				enter(State.BLOCK if swings % 2 == 0 and distance < 125 else State.CHASE)
		State.BLOCK:
			facing = direction
			velocity.x = -facing * 22
			if elapsed > 0.48:
				enter(State.CHASE)
		State.STAGGER:
			velocity.x = move_toward(velocity.x, 0, 680 * delta)
			if elapsed >= stagger_duration:
				vulnerable = false
				enter(State.CHASE)
		State.RETREAT:
			facing = 1 if home.x > position.x else -1
			velocity.x = facing * 85
			if absf(home.x - position.x) < 10:
				enter(State.IDLE)
			elif sees_player():
				enter(State.DETECT)
		State.DEAD:
			velocity.x = 0
	if (position.x <= territory.x and velocity.x < 0) or (position.x >= territory.y and velocity.x > 0):
		velocity.x = 0
	move_and_slide()
	queue_redraw()

func start_attack() -> void:
	swings += 1
	attack = Strike.new(0.72, 0.14, 0.85, 32, 0, 111, 0) if swings % 3 == 0 else Strike.new(0.48, 0.12, 0.62, 21, 0, 95, 0)
	hit = false
	enter(State.ATTACK)

func parried() -> void:
	vulnerable = true
	stagger_duration = 1.45
	flash = 0.32
	enter(State.STAGGER)

func receive(damage: float, impact: float, direction: int) -> void:
	if state == State.DEAD:
		return
	if vulnerable:
		damage *= 1.9
		vulnerable = false
		feedback.emit("Critical strike", Color.PALE_GOLDENROD)
	elif state == State.BLOCK and direction == -facing:
		damage *= 0.24
	vitals.hurt(damage)
	poise += impact
	flash = 0.13
	impacted.emit(3 if impact < 40 else 6)
	if vitals.health == 0:
		enter(State.DEAD)
		slain.emit()
	elif poise >= 43:
		poise = 0
		stagger_duration = maxf(0.47, stagger_duration - elapsed) if state == State.STAGGER else 0.54
		velocity.x = direction * 135
		enter(State.STAGGER)

func _draw() -> void:
	draw_set_transform(Vector2(0,21), 0, Vector2(1,0.24))
	draw_circle(Vector2.ZERO, 22, Color(0,0,0,0.40))
	draw_set_transform(Vector2.ZERO, 0, Vector2(facing,1))
	if state == State.DEAD:
		draw_set_transform(Vector2(0,8), -PI/2, Vector2.ONE)
	var plate := Color("#73776c") if flash == 0 else Color("#ffeabf")
	if elite and flash == 0:
		plate = Color("#a28b63")
	var step := sin(anim * 12) * minf(absf(velocity.x)/15.0, 8)
	draw_line(Vector2(-7,1), Vector2(-7+step,21), plate.darkened(0.24), 8)
	draw_line(Vector2(6,1), Vector2(6-step,21), plate.darkened(0.37), 7)
	draw_colored_polygon(PackedVector2Array([Vector2(-15,-25),Vector2(12,-26),Vector2(16,-12),Vector2(9,8),Vector2(-11,8)]), plate)
	draw_colored_polygon(PackedVector2Array([Vector2(-9,-27),Vector2(-10,-39),Vector2(-5,-44),Vector2(9,-41),Vector2(11,-28)]), plate.darkened(0.19))
	draw_line(Vector2(1,-34), Vector2(9,-34), Color("#d48d62"), 2)
	var angle := -0.38
	if state == State.ATTACK:
		if elapsed < attack.startup:
			angle = -2.15
			draw_arc(Vector2(4,-11), 39, -2.8, -2.8 + TAU * elapsed / attack.startup, 36, Color("#e58c59"), 2, true)
		else:
			angle = lerpf(-2.15, 1.12, clampf((elapsed - attack.startup)/attack.active, 0, 1))
			draw_arc(Vector2(9,-12), 65, -2.15, angle + 0.08, 25, Color("#da7758b8"), 5, true)
	elif state == State.RECOVER:
		angle = lerpf(1.12, -0.38, elapsed / attack.recovery)
	elif state == State.STAGGER:
		angle = 1.06
	var hand := Vector2(10,-13)
	draw_line(hand, hand + Vector2.from_angle(angle)*34, Color("#a6a995"), 5, true)
	if state == State.BLOCK:
		draw_rect(Rect2(11,-24,9,25), Color("#b29968"))
	if state == State.STAGGER and vulnerable:
		draw_arc(Vector2(0,-28),25,0,TAU,32,Color("#ffe8a4"),2,true)
