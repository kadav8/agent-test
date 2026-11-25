extends Node

const RATE := 16000
var sounds := {}
var ambience := AudioStreamPlayer.new()
var effects: Array[AudioStreamPlayer] = []
var ember := AudioStreamPlayer2D.new()
var surface := "stone"
var next_effect := 0
var bell_wait := 14.0

func _ready() -> void:
	add_child(ambience)
	add_child(ember)
	ember.max_distance = 340
	ember.attenuation = 2
	ember.volume_db = -21
	ambience.volume_db = -24
	for i in 5:
		var channel := AudioStreamPlayer.new()
		channel.volume_db = -19
		add_child(channel)
		effects.append(channel)
	var cues := {"wind":[4.0,38.0,0.8],"crypt":[4.0,54.0,0.53],"fire":[0.64,97.0,0.93],
		"bell":[1.9,203.0,0.02],"stone":[0.44,67.0,0.82],"gate":[0.68,117.0,0.52],
		"loot":[0.47,494.0,0.03],"secret":[0.85,149.0,0.33],"step":[0.10,89.0,0.8],
		"soil":[0.095,57.0,0.93],"embers":[2.43,101.0,0.96]}
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	for cue in cues:
		var settings: Array = cues[cue]
		sounds[cue] = build_wave(settings[0],settings[1],settings[2],cue in ["wind","crypt","embers"])

func build_wave(length: float, note: float, grit: float, repeating: bool) -> AudioStreamWAV:
	var samples := int(RATE*length)
	var pcm := PackedByteArray()
	pcm.resize(samples*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(note*5)
	var filtered := 0.0
	for i in samples:
		var t := float(i)/RATE
		filtered = lerpf(filtered,rng.randf_range(-1,1),0.12)
		var tone := sin(t*TAU*note)*0.22+sin(t*TAU*note*2.67)*0.07
		var envelope := minf(t*60,1) * pow(1-t/length,1.6)
		if repeating:
			envelope = pow(sin(PI*t/length),2)*0.28
		var sample := lerpf(tone,filtered,grit)*envelope
		pcm.encode_s16(i*2,int(sample*32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = pcm
	if repeating:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples
	return stream

func set_theme(theme: String) -> void:
	surface = "soil" if theme in ["gates","court"] else "stone"
	if sounds.is_empty():
		return
	var cue := "wind" if theme in ["gates","court","watch","bell","shrine"] else "crypt"
	if ambience.stream != sounds[cue]:
		ambience.stream = sounds[cue]
		ambience.play()

func set_bonfire(point: Vector2, available: bool) -> void:
	ember.stop()
	if available and sounds.has("embers"):
		ember.position = point
		ember.stream = sounds["embers"]
		ember.play()

func _process(delta: float) -> void:
	bell_wait -= delta
	if bell_wait <= 0:
		bell_wait = 29.0
		if ambience.stream == sounds.get("wind"):
			play_cue("bell")

func play_cue(cue: String) -> void:
	if not sounds.has(cue):
		return
	var voice := effects[next_effect]
	next_effect = (next_effect+1)%effects.size()
	voice.volume_db = -26 if cue == "step" or cue == "bell" else -16
	voice.stream = sounds["soil" if cue == "step" and surface == "soil" else cue]
	voice.play()
