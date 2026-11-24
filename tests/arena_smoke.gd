extends SceneTree

const Arena = preload("res://world/arena.tscn")
const Player = preload("res://actors/player.gd")
const Enemy = preload("res://actors/enemy.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func tap(action: String, count := 2) -> void:
	Input.action_press(action)
	await frames(count)
	Input.action_release(action)

func run() -> void:
	var arena := Arena.instantiate()
	root.add_child(arena)
	var player: Player = arena.player
	var enemy: Enemy = arena.enemy
	await frames(8)
	check(player.is_on_floor(), "player lands on arena floor")
	var start := player.position.x
	await tap("right", 23)
	check(player.position.x > start + 50, "movement via input")
	await tap("jump", 9)
	check(player.position.y < arena.SPAWN.y - 25, "jump via input")
	await frames(55)
	await tap("roll", 8)
	check(player.state == Player.State.ROLL and player.vitals.stamina < 100, "roll costs stamina")
	var hp := player.vitals.health
	player.receive(25, -1, enemy)
	check(player.vitals.health == hp, "roll invulnerability window")
	await frames(24)
	player.receive(30, -1, enemy)
	check(player.vitals.health == hp-30, "roll recovery is vulnerable")
	await frames(25)
	await tap("heal", 48)
	check(player.flasks == 2 and player.vitals.health == 100, "flask restores health and spends charge")
	player.vitals.stamina = 0
	player.vitals.regen_delay = 1
	await tap("heavy")
	check(player.state == Player.State.FREE, "exhaustion prevents attack")
	arena.reset_round()
	player.position.x = 650
	await frames(100)
	check(player.vitals.health < 100, "enemy detects, approaches and lands a timed attack")
	arena.reset_round()
	player.position.x = 746
	enemy.enter(Enemy.State.DETECT)
	await tap("light", 9)
	await tap("roll", 8)
	check(player.state == Player.State.ATTACK, "roll cannot cancel attack startup or contact")
	await frames(12)
	check(is_equal_approx(enemy.vitals.health, 137), "one light swing deals damage exactly once")
	arena.reset_round()
	player.position.x = 746
	enemy.enter(Enemy.State.DETECT)
	await tap("heavy", 25)
	check(enemy.state == Enemy.State.STAGGER, "heavy attack staggers the soldier")
	arena.reset_round()
	player.position.x = 746
	enemy.enter(Enemy.State.DETECT)
	await tap("guard", 2)
	Input.action_press("guard")
	player.receive(21, -1, enemy)
	check(enemy.vulnerable and enemy.state == Enemy.State.STAGGER and player.vitals.health == 100, "parry opens critical window")
	var enemy_hp := enemy.vitals.health
	enemy.receive(20, 18, 1)
	check(is_equal_approx(enemy.vitals.health, enemy_hp - 38), "critical consumes parry opening")
	await frames(13)
	player.receive(21, -1, enemy)
	check(player.vitals.health > 90 and player.vitals.health < 100 and player.state == Player.State.GUARD, "held guard reduces damage")
	player.vitals.stamina = 2
	player.receive(21, -1, enemy)
	check(player.state == Player.State.STAGGER and player.vitals.stamina == 0, "guard break drains stamina and staggers")
	Input.action_release("guard")
	enemy.receive(500, 48, 1)
	check(arena.won and arena.embers == 75, "enemy death grants arena victory and Embers")
	player.receive(500, -1, enemy)
	check(arena.drop == 75 and arena.embers == 0 and player.state == Player.State.DEAD, "death drops currency")
	await frames(106)
	check(player.vitals.health == 100 and enemy.vitals.health == 160 and not arena.won, "death respawns the player and soldier")
	player.position = arena.drop_location
	await tap("interact")
	check(arena.drop == 0 and arena.embers == 75, "Embers can be reclaimed")
	arena.hud.open_menu("equipment")
	check(paused and arena.hud.menu_panel.visible, "equipment menu pauses gameplay")
	arena.hud.equip(2)
	check(not paused and player.weapon == 2, "equipment selection resumes and equips weapon")
	player.position = arena.SPAWN
	player.vitals.health = 40
	await tap("interact")
	check(player.vitals.health == 100 and player.flasks == 3, "shrine restores resources")
	arena.reset_round()
	player.weapon = 2
	player.position.x = 758
	enemy.vitals.health = 50
	await tap("heavy", 45)
	check(enemy.state == Enemy.State.DEAD and arena.won, "equipped weapon can land a finishing blow through attack input")
	quit(failures)
