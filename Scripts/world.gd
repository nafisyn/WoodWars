extends Node2D

## Variables
@onready var y_sort := $YSort
@onready var tree_counter := $YSort/Player/GUI/Control/TreeCounter

func _ready() -> void:
	print(tree_counter)
#region Ledges

func _on_player_going_down() -> void:
	
	for border in $Ledges.get_children():
		
		border.get_node("CollisionShape2D").disabled = true


func _on_player_not_going_down():
	
	for border in $Ledges.get_children():
		
		border.get_node("CollisionShape2D").disabled = false
#endregion


#region Debugging

## Restart
func _on_player_died() -> void:
	
	get_tree().reload_current_scene() # Placeholder
	Engine.time_scale = 1


func _on_spawn_tree():
	
	var scene = preload("res://Scenes/Trees/AngryTreeEnemy.tscn").instantiate()
	
	y_sort.add_child(scene)
	
	tree_counter.text = "Trees: %d" % len(get_tree().get_nodes_in_group("tree"))
#endregion
