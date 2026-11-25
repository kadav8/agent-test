extends SceneTree

const Expedition = preload("res://world/region/expedition.tscn")
const Layout = preload("res://world/region/layout.gd")
var game: Node2D
var player: CharacterBody2D
var failures := 0
var save_path := "user://expedition-smoke.save"

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		print("PASS ",label)
	else:
		failures += 1
		push_error("FAIL "+label)

func clean_save() -> void:
	for suffix in ["",".old",".tmp"]:
		var path := ProjectSettings.globalize_path(save_path+suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func start() -> void:
	game = Expedition.instantiate()
	game.state.path = save_path
	root.add_child(game)
	player = game.player

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(2)

func walk(x: float) -> void:
	var action := "right" if player.position.x < x else "left"
	var direction := 1 if action == "right" else -1
	Input.action_press(action)
	for i in 800:
		if (x-player.position.x)*direction < 4:
			break
		await physics_frame
	Input.action_release(action)
	await frames(2)

func jump_to(x: float, ground_y: float, label: String) -> void:
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	await walk(x)
	await frames(56)
	check(player.is_on_floor() and absf(player.position.y+22-ground_y) < 4,label)

func use(id: String) -> void:
	var point: Node2D
	for landmark in game.room.objects:
		if landmark.id == id:
			point = landmark
			break
	check(point != null,"landmark exists · "+id)
	if point == null:
		return
	await walk(point.position.x)
	await frames(3)
	check(game.nearby == point,"reached · "+id)
	await tap("interact")

func quiet() -> void:
	# Exercise movement and collision independently of combat RNG and death.
	for foe in game.room.enemies:
		foe.set_physics_process(false)

func fight_gate_soldier() -> void:
	var foe: CharacterBody2D = game.room.enemies[0]
	await walk(690)
	for exchange in 4:
		for frame in 240:
			if foe.state == foe.State.ATTACK and foe.elapsed >= foe.attack.startup-0.095:
				break
			await physics_frame
		if foe.state != foe.State.ATTACK:
			break
		Input.action_press("guard")
		await frames(9)
		Input.action_release("guard")
		await frames(3)
		if foe.vulnerable:
			await tap("light" if foe.vitals.health <= 23 else "heavy")
			await frames(58)
		if foe.vitals.health <= 0:
			break
	check(foe.vitals.health == 0 and player.vitals.health == 79,"live enemy AI engages and can be defeated by timed guard and heavy inputs")

func run() -> void:
	clean_save()
	start()
	await frames(8)
	check(game.room_id == "ashen_shrine" and game.room.enemies.is_empty(),"safe fresh spawn")
	await use("shrine_lift")
	check(game.room_id == "ashen_shrine" and not game.state.data.doors.has("bell_lift"),"shrine side cannot unlock shortcut")
	await use("ashkeeper")
	check(paused and game.hud.speaker == "The Ashkeeper","NPC opens a single dialogue panel")
	game.advance_dialogue()
	game.advance_dialogue()
	check(not paused and game.state.data.dialogue.has("ashkeeper"),"dialogue advances and records completion")
	player.vitals.health = 79
	player.flasks = 2
	await use("shrine_exit")
	check(game.room_id == "cemetery_gates" and player.vitals.health == 79 and player.flasks == 2,"main entrance preserves resources")
	await fight_gate_soldier()
	check(game.state.data.souls == 75,"actual regional fight awards souls")
	if failures > 0:
		game.queue_free()
		await frames(4)
		clean_save()
		quit(failures)
		return
	await walk(1199)
	await jump_to(1263,463,"cemetery first ledge")
	await walk(1248)
	await jump_to(1235,401,"cemetery second ledge")
	await walk(1110)
	await jump_to(1105,338,"cemetery reward ledge")
	await use("gate_fragment")
	check(game.state.data.souls == 100,"first Soul Fragment collected")
	await use("gates_court")
	quiet()
	check(game.encounters["cemetery_gates"][0][1] == 0,"departing a room preserves temporary encounter state")
	await use("court_fire")
	check(game.encounters.is_empty(),"rest clears previous encounters across the region")
	quiet()
	check(game.state.data.checkpoint == "court_fire" and player.flasks == 3 and player.vitals.health == 100,"courtyard bonfire saves and restores")
	await walk(1044)
	await jump_to(1100,459,"courtyard first ledge")
	await walk(1180)
	await jump_to(1184,388,"courtyard tower entrance ledge")
	await use("court_tower")
	quiet()
	await walk(416)
	await jump_to(478,781,"watchtower step 1")
	await walk(602)
	await jump_to(605,714,"watchtower step 2")
	await walk(746)
	await jump_to(749,646,"watchtower step 3")
	await jump_to(745,581,"watchtower step 4")
	await walk(650)
	await jump_to(645,513,"watchtower step 5")
	await walk(488)
	await jump_to(486,446,"watchtower step 6")
	await walk(404)
	await jump_to(401,380,"watchtower reward ledge")
	await use("watch_reward")
	await use("watch_basket")
	check(1 in game.available_weapons(),"watchtower reward unlocks daggers")
	await walk(140)
	await frames(90)
	await use("watch_court")
	quiet()
	await use("court_crypt")
	quiet()
	await use("crypt_secret")
	check(game.state.data.doors.has("royal_wall"),"revealed permanent burial passage")
	await use("crypt_secret")
	check(game.room_id == "secret_burial_chamber","entered hidden burial chamber")
	await use("widows_offering")
	await use("burial_fragment")
	await use("burial_crypt")
	quiet()
	await use("crypt_lower")
	quiet()
	await use("exile")
	check(paused and game.hud.speaker == "The Exiled Knight","Exiled Knight dialogue")
	game.hud.close_dialogue()
	await walk(990)
	await jump_to(1161,522,"collapsed floor can be crossed with walking jump")
	await use("lower_hall")
	quiet()
	await use("treasury_lock")
	check(not game.state.data.doors.has("treasury_door"),"treasury rejects entry before key")
	await use("hall_lower")
	quiet()
	await walk(1140)
	await jump_to(968,522,"collapsed floor can be crossed in reverse")
	await walk(990)
	await jump_to(1161,522,"collapsed floor outbound remains reachable")
	await use("lower_key")
	await walk(1523)
	# Climb from the bottom, then follow the elevated branch to the optional pickup.
	await walk(1241)
	await jump_to(1280,458,"catacomb ledge 1")
	await walk(1407)
	await jump_to(1409,391,"catacomb ledge 2")
	await walk(1582)
	await jump_to(1584,324,"catacomb ledge 3")
	await use("lower_fragment")
	await use("lower_hall")
	quiet()
	await use("treasury_lock")
	await use("treasury_lock")
	await use("warden_cleaver")
	await use("treasury_fragment")
	check(2 in game.available_weapons(),"Rusty Key opens treasury and cleaver is equipable")
	await use("treasury_hall")
	quiet()
	await use("hall_bell")
	quiet()
	await walk(405)
	await jump_to(471,746,"bell tower step 1")
	await walk(609)
	await jump_to(613,678,"bell tower step 2")
	await walk(768)
	await jump_to(771,610,"bell tower step 3")
	await walk(942)
	await jump_to(946,536,"bell tower step 4")
	await walk(1090)
	await jump_to(1095,462,"bell tower landing")
	await use("bell_lift_lever")
	await use("bell_lift_lever")
	check(game.room_id == "ashen_shrine","Bell Tower lift leads directly to shrine")
	await use("shrine_lift")
	quiet()
	check(game.room_id == "bell_tower","lift works in both directions")
	await use("bell_warden")
	await use("warden_fire")
	await use("warden_fog")
	check(game.state.data.checkpoint == "warden_fire" and game.room_id == "wardens_approach" and "unavailable" in game.hud.notice,"warden fire and reserved fog gate")
	check(root.get_node("GraveOfKings").get_children().filter(func(n): return n is CharacterBody2D).size() == 1,"one player instance")
	check(game.get_children().filter(func(n): return n is CanvasLayer).size() == 1,"one HUD instance")
	var carried: float = game.state.data.souls
	for room_id in ["cemetery_gates","broken_courtyard","watchtower","royal_crypts","lower_catacombs","guardians_hall","bell_tower","wardens_approach"]:
		if failures > 0:
			break
		var port: String = Layout.ROOMS[room_id].entries.keys()[0]
		game.enter_room(room_id,port)
		await frames(5)
		player.receive(1000,-1,null)
		check(game.state.data.marker.get("room") == room_id,"death marker in "+room_id)
		await frames(87)
		check(game.room_id == "wardens_approach" and player.vitals.health == 100,"checkpoint respawn from "+room_id)
		game.enter_room(room_id,port)
		await frames(4)
		await tap("interact")
		check(game.state.data.marker.is_empty() and game.state.data.souls == carried,"recover souls across rooms from "+room_id)
	game.enter_room("lower_catacombs","crypt")
	quiet()
	await walk(1059)
	await frames(80)
	check(game.state.data.marker.get("room") == "lower_catacombs","lethal fall creates marker")
	check(game.marker_position().x < 1020,"pit marker remains on reachable bank")
	await frames(85)
	game.persist()
	game.queue_free()
	await frames(6)
	start()
	await frames(8)
	check(game.state.data.checkpoint == "warden_fire" and game.room_id == "wardens_approach","reload restores checkpoint")
	check(game.state.data.doors.has("bell_lift") and game.state.data.doors.has("royal_wall") and game.state.data.doors.has("treasury_door"),"reload restores shortcut, secret, treasury")
	check(game.state.data.loot.size() == 9 and 2 in game.available_weapons(),"reload retains unique loot and inventory")
	check(game.state.data.marker.get("room") == "lower_catacombs","reload restores marker")
	await use("warden_bell")
	quiet()
	await use("bell_lift_lever")
	check(game.room_id == "ashen_shrine","shortcut remains usable after death and reload")
	game.enter_room("locked_treasury","hall")
	var loot_left: Array = game.room.objects.filter(func(p): return p.kind == "loot" and p.visible)
	check(loot_left.is_empty(),"collected treasure stays absent on reload")
	game.enter_room("lower_catacombs","crypt")
	quiet()
	await frames(6)
	player.receive(1000,-1,null)
	check(game.state.data.marker.is_empty(),"second death with no souls discards previous marker")
	var backup_state: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_path+".old"))
	var damaged := FileAccess.open(save_path,FileAccess.WRITE)
	damaged.store_string("{broken")
	damaged.close()
	var reopened = game.state.get_script().new()
	reopened.path = save_path
	reopened.load_file()
	check(reopened.data.marker == backup_state.marker,"a truncated primary save falls back to the previous snapshot")
	game.queue_free()
	await frames(4)
	clean_save()
	quit(failures)
