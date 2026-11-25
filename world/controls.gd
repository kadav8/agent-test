extends RefCounted

static func bind() -> void:
	if InputMap.has_action("interact"):
		return
	var mappings := {
		"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE],
		"roll": [KEY_SHIFT], "sprint": [KEY_CTRL], "light": [KEY_J], "heavy": [KEY_K],
		"guard": [KEY_Q], "heal": [KEY_R], "lock": [KEY_F], "interact": [KEY_E],
		"inventory": [KEY_TAB], "pause": [KEY_ESCAPE],
	}
	var pad := {"left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT,
		"jump": JOY_BUTTON_A, "roll": JOY_BUTTON_B, "light": JOY_BUTTON_X, "heal": JOY_BUTTON_Y,
		"guard": JOY_BUTTON_LEFT_SHOULDER, "heavy": JOY_BUTTON_RIGHT_SHOULDER,
		"pause": JOY_BUTTON_START, "inventory": JOY_BUTTON_BACK, "interact": JOY_BUTTON_DPAD_UP,
		"lock": JOY_BUTTON_RIGHT_STICK, "sprint": JOY_BUTTON_LEFT_STICK}
	for action in mappings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in mappings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
		var button := InputEventJoypadButton.new()
		button.button_index = pad[action]
		InputMap.action_add_event(action, button)
	for action in ["left", "right"]:
		var axis := InputEventJoypadMotion.new()
		axis.axis = JOY_AXIS_LEFT_X
		axis.axis_value = -1 if action == "left" else 1
		InputMap.action_add_event(action, axis)
	for action in ["light", "heavy"]:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT if action == "light" else MOUSE_BUTTON_RIGHT
		InputMap.action_add_event(action, mouse)
