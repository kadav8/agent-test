extends Node2D

var id: String
var kind: String
var label: String
var link := ""
var entry := ""
var flag := ""
var from_unlock_side := false
var quantity := 0
var open := false
var time := 0.0

func _init(spec: Array) -> void:
	id = spec[0]
	kind = spec[1]
	position = Vector2(spec[2], spec[3])
	label = spec[4]
	if kind == "loot":
		quantity = spec[5]
	elif spec.size() >= 7:
		link = spec[5]
		entry = spec[6]
		if spec.size() >= 8:
			flag = spec[7]
		if spec.size() >= 9:
			from_unlock_side = spec[8]

func refresh(progress: Dictionary) -> void:
	visible = kind != "loot" or not progress.loot.has(id)
	open = bool(progress.doors.get(flag if flag != "" else id, false))

func prompt() -> String:
	match kind:
		"loot":
			var item: Array = preload("res://world/region/layout.gd").ITEMS[label]
			return "Take %s ×%d" % [item[0], quantity] if quantity > 1 else "Take " + item[0]
		"fire": return "Rest at bonfire"
		"npc": return "Speak with " + label
		"reserved": return "Inspect " + label
		"fog": return "Approach the Bell Warden's fog gate"
		"secret": return "Inspect the fractured stone" if not open else "Enter the burial chamber"
		"key": return "Try the treasury lock" if not open else "Enter the treasury"
		"shortcut":
			if open:
				return "Ride to " + label.trim_suffix(" lift")
			return "Release the lift counterweight" if from_unlock_side else "Inspect the lift gate"
	return "Open door · " + label

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	match kind:
		"fire":
			for radius in [72, 55, 39, 24]:
				draw_circle(Vector2(0,-18), radius + sin(time*4) * 2, Color("#ed985513"))
			draw_line(Vector2(-19,-3), Vector2(18,-10), Color("#82634a"), 5)
			draw_line(Vector2(-18,-10), Vector2(18,-3), Color("#82634a"), 5)
			for i in 6:
				var base := Vector2(sin(time*7+i)*8,-10)
				draw_colored_polygon(PackedVector2Array([base+Vector2(-7,4),base+Vector2(6,4),base+Vector2(sin(time*8+i)*8,-16-i*3)]), Color(1,0.63+i*0.04,0.26,0.44))
			for i in 9:
				var height := fposmod(time*28+i*11,75)
				draw_circle(Vector2(sin(time*2+i)*height*0.32,-height-17),1.3,Color("#e5ad62"))
		"loot":
			var bob := sin(time*3)*4
			draw_circle(Vector2(0,-14+bob),17,Color("#c8b08625"))
			draw_colored_polygon(PackedVector2Array([Vector2(0,-25+bob),Vector2(6,-14+bob),Vector2(0,-6+bob),Vector2(-6,-14+bob)]), Color("#e4c893"))
			draw_line(Vector2(-9,-1),Vector2(9,-1),Color("#78694c"),3)
		"npc":
			var coat := Color("#786657") if id == "ashkeeper" else Color("#495660")
			draw_colored_polygon(PackedVector2Array([Vector2(-17,-1),Vector2(-10,-45),Vector2(9,-43),Vector2(18,-1)]), coat)
			draw_circle(Vector2(0,-49),10,coat.lightened(0.15))
			draw_line(Vector2(-4,-48),Vector2(5,-48),Color("#d0af87"),1)
			draw_line(Vector2(17,-53),Vector2(17,0),Color("#9e8469"),2)
		"secret":
			if not open:
				draw_rect(Rect2(-35,-98,70,98),Color("#33313a"))
				for row in 4:
					draw_line(Vector2(-35,-25*row),Vector2(35,-25*row),Color("#49444a"),2)
				draw_polyline(PackedVector2Array([Vector2(-19,-89),Vector2(6,-65),Vector2(-3,-43),Vector2(14,-24),Vector2(5,-4)]),Color("#b398815c"),2,true)
			else:
				draw_arch(100,37)
		_:
			var tall := 172 if kind == "fog" else 102
			var wide := 64 if kind == "fog" else 34
			draw_arch(tall,wide)
			if kind in ["key","shortcut","reserved"] and not open:
				for x in range(-wide+8,wide,10):
					draw_line(Vector2(x,-tall+34),Vector2(x,-1),Color("#756350"),3)
			if kind == "fog":
				for i in 19:
					var rise := fposmod(time*(19+i%4)+i*13,124)
					var x := sin(i*2+time*0.7)*53
					draw_circle(Vector2(x,-rise-1),16+i%3*5,Color("#dcc8af26"))
			elif kind != "reserved":
				var font := ThemeDB.fallback_font
				var width := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
				draw_string(font,Vector2(-width/2,-tall-13),label,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#c8ae84"))

func draw_arch(height: float, width: float) -> void:
	var outline := PackedVector2Array([Vector2(-width,0),Vector2(-width,-height+38),
		Vector2(-width*0.71,-height+18),Vector2(0,-height),Vector2(width*0.71,-height+18),
		Vector2(width,-height+38),Vector2(width,0)])
	draw_colored_polygon(outline, Color("#14141c"))
	draw_polyline(outline, Color("#766c66"),7,true)
	draw_line(Vector2(-width-9,-1),Vector2(width+9,-1),Color("#918276"),2)
