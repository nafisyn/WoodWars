extends Area2D


@export var ring_color := Color(0.1, 0.5, 1.0, 0.2)

@onready var collision = $CollisionShape2D
@onready var polygon = $VisibleRange
@onready var shader_material : ShaderMaterial


var alpha := 0.0
var fade_tween : Tween


func _ready():
	
	polygon.material = polygon.material.duplicate()
	shader_material = polygon.material
	queue_redraw()
	
	## Draws circle
	var radius = collision.shape.radius
	var points = PackedVector2Array()
	
	for i in 64:
		var angle = TAU * i / 64.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	polygon.polygon = points
	polygon.visible = get_parent().range_visible
	
	shader_material.set_shader_parameter("radius", radius)
	shader_material.set_shader_parameter("ring_color", ring_color)
	shader_material.set_shader_parameter("fade_alpha", 0.0)
	
	## Fades in
	set_dead(false)


func set_dead(dead: bool):
	
	if GameData.visible_ranges:
		if fade_tween:
			
			fade_tween.kill()
		
		fade_tween = create_tween()
		
		var target_alpha := 0.0 if dead else 1.0
		
		fade_tween.tween_method(
			func(value):
				alpha = value
				shader_material.set_shader_parameter("fade_alpha", alpha)
				queue_redraw(),
			alpha,
			target_alpha,
			0.7
		)
		
		fade_tween.set_trans(Tween.TRANS_QUAD)
		fade_tween.set_ease(Tween.EASE_IN_OUT)


func _draw():
	
	if GameData.visible_ranges:
		if collision.shape is CircleShape2D and get_parent().range_visible:
			
			draw_arc(
				collision.position,
				collision.shape.radius,
				0,
				TAU,
				64,
				Color(ring_color.r, ring_color.g, ring_color.b, ring_color.a * alpha),
				0.5
			)


func _on_died() -> void:
	
	set_dead(true)
