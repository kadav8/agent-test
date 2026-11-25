extends "res://ui/arena_hud.gd"

var title := ""
var fade := 0.0
var speaker := ""
var sentence := ""

func room_changed(value: String) -> void:
	title = value
	fade = 0.32

func weapon_indices() -> Array:
	return arena.available_weapons()

func equip(index: int) -> void:
	super.equip(index)
	arena.persist()

func open_menu(next: String) -> void:
	super.open_menu(next)
	if next == "equipment":
		var back := weapons.get_child(weapons.get_child_count()-1)
		back.text = "Return to expedition"
		for detail in arena.item_details():
			var entry := Label.new()
			entry.text = detail
			entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			entry.custom_minimum_size.x = 345
			entry.add_theme_color_override("font_color", MUTED)
			weapons.add_child(entry)
		weapons.move_child(back,-1)
	elif next == "pause":
		var help := Label.new()
		help.text = "A / D  Move     Ctrl  Sprint     Space  Jump\nShift  Roll     J / K  Strike     Q  Guard / Parry\nR  Flask     F  Lock on     E  Interact     Tab  Equipment"
		help.add_theme_color_override("font_color", MUTED)
		weapons.add_child(help)

func show_dialogue(who: String, line: String) -> void:
	speaker = who
	sentence = line
	get_tree().paused = true

func close_dialogue() -> void:
	speaker = ""
	sentence = ""
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if speaker == "":
		super._input(event)
	elif event.is_action_pressed("interact") and not event.is_echo():
		arena.advance_dialogue()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		close_dialogue()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	super._process(delta)
	fade = maxf(0,fade-delta)

func draw_hud() -> void:
	var player: CharacterBody2D = arena.player
	surface.draw_rect(Rect2(27,25,247,56),PANEL)
	bar(Rect2(39,38,217,9),player.vitals.health/player.vitals.max_health,Color("#aa5456"))
	bar(Rect2(39,55,173,6),player.vitals.stamina/player.vitals.max_stamina,Color("#819679"))
	line_text(Vector2(39,75),"Flasks  %s" % player.flasks,12,MUTED)
	line_text(Vector2(35,101),player.WEAPONS[player.weapon][0],14,GOLD)
	surface.draw_rect(Rect2(848,25,277,56),PANEL)
	line_text(Vector2(865,48),title,18,GOLD)
	line_text(Vector2(865,69),"Souls  %d" % arena.state.data.souls,14,PAPER)
	if not is_instance_valid(arena.room):
		return
	for foe in arena.room.enemies:
		if foe.vitals.health > 0 and foe.vitals.health < foe.vitals.max_health:
			var point: Vector2 = foe.get_global_transform_with_canvas().origin + Vector2(-24,-61)
			bar(Rect2(point,Vector2(48,4)),foe.vitals.health/foe.vitals.max_health,Color("#aa5456"))
	if speaker != "":
		surface.draw_rect(Rect2(164,478,824,135),PANEL)
		surface.draw_line(Vector2(164,478),Vector2(988,478),GOLD,1)
		line_text(Vector2(190,512),speaker,19,GOLD)
		line_text(Vector2(190,550),sentence,20)
		line_text(Vector2(190,588),"E  Continue     Esc  Leave",14,MUTED)
	else:
		var prompt: String = arena.prompt()
		if prompt != "":
			center_panel(prompt,576,19,GOLD)
	if timer > 0:
		center_panel(notice,133,19,tint)
	if menu != "":
		surface.draw_rect(Rect2(0,0,1152,648),Color(0,0,0,0.48))
	if fade > 0:
		surface.draw_rect(Rect2(0,0,1152,648),Color(0.05,0.05,0.07,fade/0.32))

func center_panel(value: String, y: int, size: int, color: Color) -> void:
	var width := ThemeDB.fallback_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	surface.draw_rect(Rect2((1152-width)/2-17,y-26,width+34,38),PANEL)
	line_text(Vector2((1152-width)/2,y),value,size,color)
