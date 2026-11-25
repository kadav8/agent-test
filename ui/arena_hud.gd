extends CanvasLayer

const GOLD := Color("#d8b585")
const PAPER := Color("#e1d8c9")
const MUTED := Color("#aaa39e")
const PANEL := Color("#14141be8")
var arena: Node2D
var surface := Control.new()
var menu := ""
var notice := ""
var tint := GOLD
var timer := 0.0
var weapons: VBoxContainer
var menu_title: Label
var menu_panel: PanelContainer

func setup(world: Node2D) -> void:
	arena = world
	process_mode = Node.PROCESS_MODE_ALWAYS
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surface)
	surface.draw.connect(draw_hud)
	menu_panel = PanelContainer.new()
	menu_panel.position = Vector2(371,143)
	menu_panel.custom_minimum_size.x = 410
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = GOLD.darkened(0.4)
	style.set_border_width_all(1)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	menu_panel.add_theme_stylebox_override("panel",style)
	add_child(menu_panel)
	weapons = VBoxContainer.new()
	weapons.add_theme_constant_override("separation",10)
	menu_panel.add_child(weapons)
	menu_panel.hide()

func show_feedback(message: String, color: Color) -> void:
	notice = message
	tint = color
	timer = 2.65

func add_button(caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 43
	button.pressed.connect(callback)
	weapons.add_child(button)
	if weapons.get_child_count() == 2:
		button.grab_focus()

func open_menu(next: String) -> void:
	menu = next
	get_tree().paused = menu != ""
	menu_panel.visible = menu != ""
	for child in weapons.get_children():
		weapons.remove_child(child)
		child.queue_free()
	if menu == "":
		return
	menu_title = Label.new()
	menu_title.text = "Equipment" if menu == "equipment" else "Paused"
	menu_title.add_theme_color_override("font_color", GOLD)
	menu_title.add_theme_font_size_override("font_size", 29)
	weapons.add_child(menu_title)
	if menu == "equipment":
		for i in weapon_indices():
			var data: Array = arena.player.WEAPONS[i]
			var equipped := "  •  Equipped" if i == arena.player.weapon else ""
			add_button("%s  ·  %s%s" % [data[0], data[1], equipped], equip.bind(i))
	else:
		add_button("Resume", open_menu.bind(""))
		add_button("Equipment", open_menu.bind("equipment"))
	if menu == "equipment":
		add_button("Return to arena", open_menu.bind(""))

func weapon_indices() -> Array:
	return range(arena.player.WEAPONS.size())

func equip(index: int) -> void:
	arena.player.weapon = index
	open_menu("")
	show_feedback("Equipped " + arena.player.WEAPONS[index][0], GOLD)

func _input(event: InputEvent) -> void:
	if not is_instance_valid(arena) or arena.player.vitals.health <= 0:
		return
	if event.is_action_pressed("pause"):
		open_menu("pause" if menu == "" else "")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		open_menu("" if menu == "equipment" else "equipment")
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	timer = maxf(0, timer-delta)
	surface.queue_redraw()

func line_text(position: Vector2, value: String, size: int, color: Color = PAPER) -> void:
	surface.draw_string(ThemeDB.fallback_font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func bar(rect: Rect2, value: float, color: Color) -> void:
	surface.draw_rect(rect.grow(1), Color("#7a6556"))
	surface.draw_rect(rect, Color("#25242b"))
	surface.draw_rect(Rect2(rect.position, Vector2(rect.size.x*clampf(value,0,1),rect.size.y)),color)

func draw_hud() -> void:
	var player: CharacterBody2D = arena.player
	var foe: CharacterBody2D = arena.enemy
	surface.draw_rect(Rect2(0,0,1152,75), Color("#101117be"))
	surface.draw_line(Vector2(33,74),Vector2(1119,74),Color("#88725c7c"),1)
	line_text(Vector2(35,28), "A S H E N   C R O W N", 16, GOLD)
	bar(Rect2(35,38,205,10), player.vitals.health/player.vitals.max_health, Color("#a34f55"))
	bar(Rect2(35,55,165,6), player.vitals.stamina/player.vitals.max_stamina, Color("#809778"))
	line_text(Vector2(264,44), "Flasks  %d / %d" % [player.flasks,player.MAX_FLASKS], 16)
	line_text(Vector2(476,44), "THE SHRINE YARD", 16, GOLD)
	line_text(Vector2(863,44), player.WEAPONS[player.weapon][0], 16, MUTED)
	line_text(Vector2(1022,44), "Embers  %d" % arena.embers, 16, GOLD)
	if foe.vitals.health > 0 and absf(foe.position.x-player.position.x) < 410:
		bar(Rect2(foe.position + Vector2(-24,-63) - arena.camera.offset,Vector2(48,4)),foe.vitals.health/foe.vitals.max_health,Color("#a35f53"))
	surface.draw_rect(Rect2(0,552,1152,96), PANEL)
	var prompt := "Defeat the Hollow Soldier"
	if arena.won:
		prompt = "Yard cleared  ·  Rest at the shrine to fight again"
	if absf(player.position.x - arena.SPAWN.x) < 70:
		prompt = "E  Rest at the Ash Shrine"
	if arena.drop > 0 and player.position.distance_to(arena.drop_location) < 57:
		prompt = "E  Recover Embers"
	line_text(Vector2(35,582), prompt, 19, GOLD)
	line_text(Vector2(35,612), "A / D Move    Space Jump    Ctrl Sprint    Shift Roll    J / K Attack    Q Guard / Parry    R Heal    F Lock    Tab Equipment    Esc Pause", 16, MUTED)
	if timer > 0:
		var width := ThemeDB.fallback_font.get_string_size(notice, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		surface.draw_rect(Rect2((1152-width)/2-17,93,width+34,39),PANEL)
		line_text(Vector2((1152-width)/2,120),notice,22,tint)
	if menu != "":
		surface.draw_rect(Rect2(0,0,1152,648), Color(0,0,0,0.48))
