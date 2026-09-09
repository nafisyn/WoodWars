extends Area2D


@export var ring_color := Color(0.1, 0.5, 1.0, 0.2)

@onready var collision = $CollisionShape2D




func _ready():
	
	queue_redraw()


func _draw():
	
	if collision.shape is CircleShape2D and get_parent().range_visible:
		
		var circle_color = Color(ring_color.r, ring_color.g, ring_color.b, ring_color.a / 2)
		
		draw_circle(
			collision.position,
			collision.shape.radius,
			circle_color
		)
		
		draw_arc(
			collision.position,
			collision.shape.radius,
			0,
			TAU,
			64,
			ring_color,
			0.5
		)
