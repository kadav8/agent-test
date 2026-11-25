extends RefCounted

# Coordinates describe ground level. Arrival ports are always on solid stone.
const SHRINE := "ashen_shrine"
const ROOMS := {
	"ashen_shrine": {
		"title": "Ashen Shrine", "width": 1510, "floor": 514, "theme": "shrine",
		"entries": {"fire": [370,514], "gates": [1270,514], "lift": [255,514]},
		"objects": [
			["shrine_lift", "shortcut", 138,514, "Bell Tower lift", "bell_tower", "shrine", "bell_lift", false],
			["shrine_fire", "fire", 370,514, "Ashen Shrine"],
			["ashkeeper", "npc", 573,514, "The Ashkeeper"],
			["sealed_apse", "reserved", 934,514, "Sealed apse"],
			["shrine_exit", "door", 1375,514, "Cemetery Gates", "cemetery_gates", "shrine"],
		],
	},
	"cemetery_gates": {
		"title": "Cemetery Gates", "width": 1850, "floor": 524, "theme": "gates",
		"entries": {"shrine": [248,524], "court": [1580,524]},
		"ledges": [[1240,463,112],[1090,401,194],[918,338,235]],
		"foes": [[851,524,560,1050]],
		"objects": [
			["gates_back","door",110,524,"Ashen Shrine","ashen_shrine","gates"],
			["gate_fragment","loot",1010,338,"fragment",25],
			["gates_court","door",1720,524,"Broken Courtyard","broken_courtyard","gates"],
		],
	},
	"broken_courtyard": {
		"title": "Broken Courtyard", "width": 2230, "floor": 524, "theme": "court",
		"entries": {"gates":[238,524], "fire":[414,524], "tower":[1380,388], "crypt":[1968,524]},
		"ledges": [[1060,459,135],[1170,388,320],[1380,321,140]],
		"foes": [[823,524,630,1030],[1455,524,1260,1630],[1770,524,1670,1880]],
		"objects": [
			["court_gates","door",108,524,"Cemetery Gates","cemetery_gates","court"],
			["court_fire","fire",414,524,"Broken Courtyard"],
			["court_tower","door",1460,388,"Watchtower","watchtower","court"],
			["court_crypt","door",2100,524,"Royal Crypts","royal_crypts","court"],
		],
	},
	"watchtower": {
		"title": "Watchtower", "width": 1250, "floor": 849, "theme": "watch",
		"entries": {"court":[260,849]},
		"ledges": [[438,781,190],[560,714,220],[718,646,230],[622,581,189],[470,513,208],[307,446,200],[167,380,261]],
		"foes": [[813,646,761,897]],
		"objects": [
			["watch_court","door",125,849,"Broken Courtyard","broken_courtyard","tower"],
			["watch_reward","loot",247,380,"daggers",1],
			["watch_basket","loot",322,380,"fragment",50],
		],
	},
	"royal_crypts": {
		"title": "Royal Crypts", "width": 2050, "floor": 535, "theme": "crypt",
		"entries": {"court":[236,535],"burial":[1310,535],"lower":[1787,535]},
		"ledges": [[790,463,140],[1515,463,177]],
		"foes": [[694,535,500,810],[995,535,895,1140],[1504,535,1440,1644]],
		"objects": [
			["crypt_court","door",108,535,"Broken Courtyard","broken_courtyard","crypt"],
			["crypt_secret","secret",1240,535,"Fractured stonework","secret_burial_chamber","crypt","royal_wall"],
			["crypt_lower","door",1910,535,"Lower Catacombs","lower_catacombs","crypt"],
		],
	},
	"secret_burial_chamber": {
		"title": "Secret Burial Chamber", "width": 1152, "floor": 515, "theme": "burial",
		"entries": {"crypt":[248,515]},
		"objects": [
			["burial_crypt","door",110,515,"Royal Crypts","royal_crypts","burial"],
			["widows_offering","loot",757,515,"seal",1],
			["burial_fragment","loot",825,515,"fragment",100],
		],
	},
	"lower_catacombs": {
		"title": "Lower Catacombs", "width": 2300, "floor": 522, "theme": "lower",
		"entries": {"crypt":[245,522],"hall":[2035,522]},
		"foundations": [[0,522,1020],[1112,522,1188]], "pits": [[1020,92]],
		"ledges": [[1240,458,192],[1390,391,224],[1555,324,223]],
		"foes": [[663,522,470,862],[1250,522,1160,1450],[1691,324,1590,1729]],
		"objects": [
			["lower_crypt","door",108,522,"Royal Crypts","royal_crypts","lower"],
			["exile","npc",345,522,"The Exiled Knight"],
			["lower_key","loot",1830,522,"rusty_key",1],
			["lower_fragment","loot",1740,324,"fragment",65],
			["lower_hall","door",2170,522,"Guardian's Hall","guardians_hall","lower"],
		],
	},
	"guardians_hall": {
		"title": "Guardian's Hall", "width": 2030, "floor": 523, "theme": "hall",
		"entries": {"lower":[235,523],"treasury":[1040,523],"bell":[1740,523]},
		"ledges": [[1290,450,205]],
		"foes": [[1290,523,1160,1510,true],[710,523,520,855]],
		"objects": [
			["hall_lower","door",108,523,"Lower Catacombs","lower_catacombs","hall"],
			["treasury_lock","key",978,523,"Locked Treasury","locked_treasury","hall","treasury_door"],
			["hall_bell","door",1890,523,"Bell Tower","bell_tower","hall"],
		],
	},
	"locked_treasury": {
		"title": "Locked Treasury", "width": 1152, "floor": 517, "theme": "treasury",
		"entries": {"hall":[240,517]},
		"objects": [
			["treasury_hall","door",108,517,"Guardian's Hall","guardians_hall","treasury"],
			["warden_cleaver","loot",780,517,"cleaver",1],
			["treasury_fragment","loot",847,517,"fragment",120],
		],
	},
	"bell_tower": {
		"title": "Bell Tower", "width": 1560, "floor": 815, "theme": "bell",
		"entries": {"hall":[245,815],"shrine":[1191,462],"approach":[1390,462]},
		"ledges": [[420,746,220],[577,678,213],[741,610,225],[916,536,220],[1066,462,494]],
		"foes": [[714,678,618,752],[962,536,950,1049]],
		"objects": [
			["bell_hall","door",110,815,"Guardian's Hall","guardians_hall","bell"],
			["bell_lift_lever","shortcut",1120,462,"Ashen Shrine lift","ashen_shrine","lift","bell_lift",true],
			["bell_warden","door",1470,462,"Warden's Approach","wardens_approach","bell"],
		],
	},
	"wardens_approach": {
		"title": "Warden's Approach", "width": 1810, "floor": 525, "theme": "warden",
		"entries": {"bell":[233,525],"fire":[975,525]},
		"objects": [
			["warden_bell","door",107,525,"Bell Tower","bell_tower","approach"],
			["warden_fire","fire",975,525,"Warden's Approach"],
			["warden_fog","fog",1650,525,"Bell Warden's fog gate"],
		],
	},
}
const ITEMS := {
	"fragment": ["Soul Fragment", "A trace of the dead. Its souls pass to you on collection.", -1],
	"rusty_key": ["Rusty Key", "A rusted key stamped with the royal treasury seal.", -1],
	"daggers": ["Ash Daggers", "A pair of short watch blades. Equip them in the equipment menu.", 1],
	"cleaver": ["Grave Cleaver", "A burial guard's heavy weapon. Equip it in the equipment menu.", 2],
	"seal": ["Widow's Seal", "The queen's seal, hidden where the royal line was laid to rest.", -1],
}
const DIALOGUE := {
	"ashkeeper": [
		"The bells have fallen silent. Yet beneath the earth, something still answers.",
		"Follow the graves, Ashbound. The dead remember what the living have forgotten.",
	],
	"exile": [
		"I once guarded these halls. Now I dare not enter them.",
		"The Warden still rings his bell. Even death could not free him from his duty.",
	],
}
