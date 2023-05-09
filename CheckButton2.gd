extends CheckButton
var touches = 0

func _on_toggled(button_pressed):
	focus_mode = 0
	touches += 1
	if touches%2 == 0:
		$"..".bhop = false
	else:
		$"..".bhop = true
