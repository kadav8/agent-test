extends Node2D

var room: Node2D
var time := 0.0
const STONE := Color("#363542")
const LIGHT := Color("#8d8077")
const NIGHT := Color("#151923")
const DUST := Color("#c0aa9526")
const PALETTES := {
	"shrine": ["#171a25","#594344","#292635","#f1b375"],
	"gates": ["#172332","#51546a","#262b3a","#aab0bd"],
	"court": ["#191e2a","#56525b","#35303a","#beb0a1"],
	"watch": ["#192139","#5a5871","#262b3b","#b8a6a0"],
	"crypt": ["#13141d","#3b2e38","#2a2632","#dd9d64"],
	"burial": ["#1b1524","#544052","#30283c","#d7a779"],
	"lower": ["#101a25","#364e58","#26323b","#95adb0"],
	"hall": ["#1b1926","#514449","#322a39","#caa984"],
	"treasury": ["#201c2b","#685244","#3d303d","#d4ae7d"],
	"bell": ["#191d2e","#4e455f","#2b293a","#b19da9"],
	"warden": ["#211a2b","#59424a","#382e3d","#d6a49a"],
}

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var theme: String = room.spec.theme
	var colors: Array = PALETTES[theme]
	var bottom := float(room.spec.floor)
	var size: Vector2 = room.bounds
	var camera_x: float = room.world.camera.position.x
	var top := Color(colors[0])
	var haze := Color(colors[1])
	var stone := Color(colors[2])
	var accent := Color(colors[3])
	for row in 26:
		var height := size.y / 26
		draw_rect(Rect2(0,row*height,size.x,height+1),top.lerp(haze,row/26.0))
	var open_air := theme in ["gates","court","watch","bell"]
	if open_air:
		draw_circle(Vector2(size.x*0.69+camera_x*0.15,177),65,accent.darkened(0.19))
		draw_circle(Vector2(size.x*0.69+camera_x*0.15,177),83,Color(accent,0.08))
		for i in range(1,int(size.x/130)):
			var x := i*145 + camera_x*0.15-132
			var y := bottom*0.68 + (i*73)%95
			spire(Vector2(x,y),48+(i*17)%89,stone.lerp(haze,0.42))
		if theme in ["gates","court","watch"]:
			spire(Vector2(size.x*0.73+camera_x*0.16,bottom-105),225,stone)
	# Structural arches repeat with the space; landmarks interrupt the rhythm.
	for i in range(-1,int(size.x/275)+2):
		var x := i*275+71+camera_x*0.035
		var y := bottom + (72 if open_air else 0)
		var height := 202 + (i*61)%93
		arch(Vector2(x,y),height,215,stone,top)
		if not open_air:
			draw_line(Vector2(x-124,y-height*0.55),Vector2(x-124,y),stone.darkened(0.35),16)
			draw_line(Vector2(x-130,y-height*0.55),Vector2(x-130,y),stone.lightened(0.09),2)
	for i in range(13):
		var x := fposmod(i*221+time*(9+i%3),size.x+280)-140
		draw_set_transform(Vector2(x,bottom-89+i%5*17),0,Vector2(1,0.055))
		draw_circle(Vector2.ZERO,140,Color(accent,0.065))
	draw_set_transform(Vector2.ZERO)
	match theme:
		"shrine":
			arch(Vector2(370,bottom),344,322,stone.lightened(0.16), top)
			rose(Vector2(370,bottom-242),48,accent)
			candles(313,bottom,accent)
			candles(456,bottom,accent)
		"gates":
			arch(Vector2(320,bottom),353,306,stone.lightened(0.20),top)
			for x in [540,587,647,1082,1176,1258,1350]:
				grave(Vector2(x,bottom),stone.lightened(0.18))
			tree(Vector2(754,bottom),stone.darkened(0.22))
			tree(Vector2(1560,bottom),stone.darkened(0.24))
		"court":
			statue(Vector2(1070,bottom),142,stone.lightened(0.28),true)
			for x in [915,970,1208,1280]:
				grave(Vector2(x,bottom),stone.lightened(0.18))
			arch(Vector2(1540,bottom),210,251,stone.lightened(0.08),top)
			tree(Vector2(1940,bottom),stone.darkened(0.27))
		"watch":
			for y in [330,490,650]:
				arch(Vector2(560,y),131,185,stone.lightened(0.20),haze)
				spire(Vector2(560,y),77,stone)
		"crypt", "burial":
			for x in ([318,549,1210,1672] if theme == "crypt" else [450,670,879]):
				coffin(Vector2(x,bottom),stone.lightened(0.20))
				candles(x+67,bottom,accent)
			if theme == "crypt":
				draw_line(Vector2(1201,bottom-5),Vector2(1178,bottom-57),LIGHT,4)
				draw_line(Vector2(1181,bottom-20),Vector2(1203,bottom-33),LIGHT,2)
		"lower":
			for i in range(7):
				var x := 375+i*218
				draw_line(Vector2(x,245),Vector2(x+23,415),Color("#55727540"),3)
			for x in [995,1136]:
				draw_line(Vector2(x-8,bottom-20),Vector2(x+8,bottom-20),Color("#c28758"),5)
		"hall":
			for x in [385,995,1510]:
				statue(Vector2(x,bottom),190,stone.lightened(0.25),x==995)
			candles(906,bottom,accent)
			draw_line(Vector2(915,bottom-3),Vector2(949,bottom-16),LIGHT,5)
			draw_circle(Vector2(924,bottom-13),8,LIGHT.darkened(0.3))
		"treasury":
			for x in [555,658,911]:
				candles(x,bottom,accent)
				draw_rect(Rect2(x-11,bottom-29,64,24),STONE)
				draw_line(Vector2(x-12,bottom-27),Vector2(x+53,bottom-27),LIGHT,2)
		"bell":
			bell(Vector2(1140,283),accent)
		"warden":
			for x in [410,640,1210,1440,1740]:
				statue(Vector2(x,bottom),235,stone.lightened(0.25),x==1210)
			for x in [940,1024,1510]:
				candles(x,bottom,accent)
	for platform in room.ground + room.ledges:
		draw_rect(platform,STONE)
		draw_line(platform.position,Vector2(platform.end.x,platform.position.y),LIGHT,2)
		for x in range(int(platform.position.x+16),int(platform.end.x),36):
			draw_line(Vector2(x,platform.position.y+3),Vector2(x-5,platform.position.y+12),Color("#262631"),2)
		if platform.size.y > 100:
			for row in 5:
				var y: float = platform.position.y+18+row*23
				draw_line(Vector2(platform.position.x,y),Vector2(platform.end.x,y),Color("#282632"),1)
				for x in range(int(platform.position.x)+25+(row%2)*31,int(platform.end.x),74):
					draw_line(Vector2(x,y),Vector2(x-2,y+22),Color("#292733"),1)
	for pit in room.spec.get("pits",[]):
		draw_rect(Rect2(pit[0],bottom,pit[1],145),Color("#10111b"))
		for i in 7:
			var x: float = pit[0]+i*13
			draw_colored_polygon(PackedVector2Array([Vector2(x,bottom+89),Vector2(x+6,bottom+53-i%3*6),Vector2(x+12,bottom+89)]),Color("#99645a"))
	for i in range(24):
		var x := fposmod(i*129+time*(9+i%6),size.x)
		var y := fposmod(i*83-time*(11+i%8),bottom)
		draw_circle(Vector2(x,y),1.0+i%3*0.35,DUST)
	for x in [22.0,size.x-44.0]:
		draw_rect(Rect2(x,0,22,size.y),Color("#11121db0"))
	var mark: Dictionary = room.world.state.data.marker
	if mark.get("room") == room.world.room_id:
		var point: Vector2 = room.world.marker_position()+Vector2(0,12)
		draw_arc(point,12+sin(time*4)*3,0,TAU,32,Color("#b5d3a4"),2,true)
		draw_line(point+Vector2(0,-20),point+Vector2(0,8),Color("#b5d3a4b0"),2)
	var player: CharacterBody2D = room.world.player
	if player.lock_on and is_instance_valid(player.target):
		draw_arc(player.target.position+Vector2(0,-57),5,0,TAU,16,Color.WHEAT,2,true)

func arch(base: Vector2, height: float, width: float, stone: Color, interior: Color) -> void:
	var w := width/2
	var points := PackedVector2Array([base+Vector2(-w,0),base+Vector2(-w,-height*0.72),
		base+Vector2(-w*0.62,-height*0.91),base+Vector2(0,-height),
		base+Vector2(w*0.62,-height*0.91),base+Vector2(w,-height*0.72),base+Vector2(w,0)])
	draw_colored_polygon(points,interior)
	draw_polyline(points,stone,14,true)
	draw_polyline(points,stone.lightened(0.14),2,true)
	for side in [-1,1]:
		var pillar := base+Vector2(side*w,0)
		for rib in [-4.0,4.0]:
			draw_line(pillar+Vector2(rib,-height*0.70),pillar+Vector2(rib,-12),stone.darkened(0.25),1)
		draw_line(pillar+Vector2(-12,-height*0.71),pillar+Vector2(12,-height*0.71),stone.lightened(0.25),4)
		draw_line(pillar+Vector2(-15,-8),pillar+Vector2(15,-8),stone.lightened(0.17),5)
		var spring := base+Vector2(side*w,-height*0.72)
		var shoulder := base+Vector2(side*w*0.62,-height*0.91)
		var crown := base+Vector2(0,-height)
		for segment in [[spring,shoulder],[shoulder,crown]]:
			var tangent: Vector2 = (segment[1]-segment[0]).normalized()
			var normal := tangent.orthogonal()*7
			for step in [0.2,0.45,0.7,0.95]:
				var at: Vector2 = segment[0].lerp(segment[1],step)
				draw_line(at-normal,at+normal,stone.darkened(0.3),1)

func rose(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center,radius+7,STONE)
	draw_arc(center,radius,0,TAU,48,Color(color,0.45),2,true)
	for i in 8:
		var point := center+Vector2.from_angle(i*TAU/8)*radius*0.52
		draw_circle(point,radius*0.23,Color(color,0.20))
		draw_arc(point,radius*0.23,0,TAU,24,Color(color,0.45),1,true)

func spire(point: Vector2, height: float, color: Color) -> void:
	draw_rect(Rect2(point.x-23,point.y-height,46,height),color)
	draw_colored_polygon(PackedVector2Array([point+Vector2(-29,-height),point+Vector2(0,-height-59),point+Vector2(29,-height)]),color)
	draw_rect(Rect2(point.x-5,point.y-height+17,10,37),color.darkened(0.34))

func tree(point: Vector2, color: Color) -> void:
	var bough := point+Vector2(-15,-106)
	draw_colored_polygon(PackedVector2Array([point+Vector2(-15,0),point+Vector2(-12,-69),bough,
		bough+Vector2(8,14),point+Vector2(1,-52),point+Vector2(12,0)]),color)
	for branch in [[Vector2(-10,-69),Vector2(-47,-96),Vector2(-65,-127)],
			[Vector2(-8,-58),Vector2(22,-85),Vector2(41,-119)],
			[Vector2(-13,-91),Vector2(6,-121),Vector2(6,-152)]]:
		draw_line(point+branch[0],point+branch[1],color,5,true)
		draw_line(point+branch[1],point+branch[2],color,2,true)

func grave(point: Vector2, color: Color) -> void:
	draw_rect(Rect2(point.x-12,point.y-24,24,25),color)
	draw_circle(point+Vector2(0,-24),12,color)
	draw_line(point+Vector2(-6,-16),point+Vector2(6,-16),color.darkened(0.32),2)

func coffin(point: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([point+Vector2(-56,0),point+Vector2(-48,-34),point+Vector2(46,-34),point+Vector2(54,0)]),color)
	draw_line(point+Vector2(-46,-32),point+Vector2(45,-32),color.lightened(0.26),3)
	draw_line(point+Vector2(-62,-3),point+Vector2(58,-3),LIGHT.darkened(0.3),3)

func statue(point: Vector2, height: float, color: Color, broken: bool) -> void:
	draw_rect(Rect2(point.x-46,point.y-27,92,27),color.darkened(0.14))
	draw_colored_polygon(PackedVector2Array([point+Vector2(-29,-27),point+Vector2(-17,-height+35),point+Vector2(18,-height+33),point+Vector2(32,-27)]),color)
	draw_line(point+Vector2(12,-height+43),point+Vector2(45,-height+72),color,12,true)
	if broken:
		draw_circle(point+Vector2(66,-13),15,color)
	else:
		draw_circle(point+Vector2(0,-height+20),15,color)
		draw_line(point+Vector2(-17,-height+14),point+Vector2(17,-height+14),color.lightened(0.16),4)

func candles(x: float, y: float, accent: Color) -> void:
	for i in 4:
		var p := Vector2(x+i*11,y-8-(i*7)%16)
		draw_circle(p,20+sin(time*11+i)*3,Color(accent,0.08))
		draw_line(p,p+Vector2(0,8+i%2*4),Color("#d2b787"),3)
		draw_circle(p-Vector2(0,3),1.6+sin(time*12+i)*0.5,accent)

func bell(center: Vector2, accent: Color) -> void:
	for x in [-45,45]:
		for i in 18:
			draw_arc(center+Vector2(x,-i*12-53),5,0,TAU,12,accent.darkened(0.45),2,true)
	var shape := PackedVector2Array([center+Vector2(-96,52),center+Vector2(-69,13),
		center+Vector2(-53,-42),center+Vector2(-24,-64),center+Vector2(24,-64),
		center+Vector2(53,-42),center+Vector2(69,13),center+Vector2(96,52)])
	draw_colored_polygon(shape,Color("#554643"))
	draw_polyline(shape,accent.darkened(0.21),3,true)
	draw_line(center+Vector2(-94,51),center+Vector2(94,51),accent,6,true)
	draw_circle(center+Vector2(0,62),13,accent.darkened(0.46))
