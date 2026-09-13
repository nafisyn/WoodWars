extends Node2D


@onready var color_picker := $ColorPickerBackground


func _on_play_button_pressed() -> void:
	
	get_tree().change_scene_to_file("res://Scenes/MainWorld.tscn")


func _on_visual_ranges_check_toggled(toggled_on: bool) -> void:
	
	GameData.visible_ranges = toggled_on


## Player color picker
func _on_color_picker_color_changed(color: Color) -> void:
	
	GameData.player_modulate = color


func _on_player_color_button_pressed() -> void:
	
	if color_picker.visible:
		
		color_picker.visible = false
	
	else:
		
		color_picker.visible = true

## God mode
func _on_god_mode_toggle_toggled(toggled_on: bool) -> void:
	
	GameData.god_mode = toggled_on
