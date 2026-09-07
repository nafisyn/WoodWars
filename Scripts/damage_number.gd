extends Label


var distance := 50.0
var duration := 2.0
var end_scale = Vector2(0.3, 0.3)
var pop_duration = 0.25

func setup(damage: int):
	
	text = "-%d" % damage
	
	var start_rotation = deg_to_rad(randf_range(-30, 30))
	var end_rotation = start_rotation +  deg_to_rad(randf_range(-30, 30))
	
	var tween = create_tween()
	
	# Pops in
	tween.tween_property(
			self,
			"scale",
			end_scale,
			pop_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.set_parallel(true)
	
	## Move up
	tween.tween_property(
		self,
		"position:y",
		position.y - distance,
		duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	## Fade
	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(
		self,
		"rotation",
		end_rotation,
		duration
	)
	
	## Remove after animation
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
