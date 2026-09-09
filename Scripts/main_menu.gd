extends Node2D


func _on_play_button_pressed() -> void:
	
	get_tree().change_scene_to_file("res://Scenes/MainWorld.tscn")


func _on_visual_ranges_check_toggled(toggled_on: bool) -> void:
	
	GameData.visible_ranges = toggled_on
