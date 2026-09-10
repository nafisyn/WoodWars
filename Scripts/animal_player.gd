extends CharacterBody2D


#region Variables, Constants, and Signals
## @export variables
@export var range_visible := true

## @onreadys
@onready var sprite = $AnimatedSprite2D
@onready var camera := $Camera
@onready var last_direction: String = "down"
@onready var attack_timer = $Timers/AttackCooldown
@onready var hitstop_timer = $Timers/HitstopTimer
@onready var attack_range = $AttackRange
@onready var damage_particles = $DamageParticles
@onready var health_bar = $HealthBar
@onready var health_label = $HealthBar/HealthBarLabel
@onready var world := $"../.."
@onready var attack_cooldown_bar := $GUI/Control/AttackBar
@onready var fps_label := $GUI/Control/FPSLabel

## Constants
const SPEED := 65.0
const ACCELERATION := 400.0

## Variables
var max_health := 100
var health := max_health
var attack_damage := 10
var attacking := true
var losing_health := false
var damage_number_scene := preload("res://Scenes/DamageNumber.tscn")

signal going_down()
signal not_going_down()
signal died()
#endregion


func _ready() -> void:
	
	health_bar.max_value = max_health
	health_bar.value = health
	health_label.text = str(health)


func _physics_process(delta):
	
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	
	## Movement
	var direction = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	
	velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
	move_and_slide()
	
	## Other Inputs
	if Input.is_action_pressed("left_click"):
		
		attack()
	
	## Direction
	if direction.y > 0:
		
		last_direction = "down"

	elif direction.y < 0:
		
		last_direction = "up"

	elif direction.x > 0:
		
		last_direction = "right"

	elif direction.x < 0:
		
		last_direction = "left"
	
	update_animation(direction)
	update_camera_position(direction)
	
	## Ledges
	if last_direction == "down":
		
		going_down.emit()
	
	else:
		
		not_going_down.emit()
	
	## Bars
	
	## Health bar animation
	if losing_health:
		
		health_bar.value -= 2.5
		
		if health_bar.value <= health:
			
			losing_health = false
	
	if not attack_timer.is_stopped():
		
		attack_cooldown_bar.value = attack_timer.wait_time - attack_timer.time_left + delta
		
		if attack_cooldown_bar.value >= 1:
			
			attack_cooldown_bar.value = 1


#region Animation
func update_animation(direction: Vector2):
	
	if direction != Vector2.ZERO:
		
		sprite.play("walk_%s_animation" % last_direction)
	else:
		
		sprite.play("%s_idle_animation" % last_direction)


func update_camera_position(direction: Vector2):
	
	var target_position := direction * 12
	var tween := create_tween()
	
	tween.tween_property(
		camera,
		"position",
		target_position,
		0.2
	)
	
	
#endregion


#region Fighting

## Attack
func attack():
	
	if attacking:
		
		for body in attack_range.get_overlapping_areas():
			
			var parent = body.get_parent()
			
			if parent.is_in_group("tree"):
				
				parent.take_damage(attack_damage, 0.1)
	
	if attack_timer.is_stopped():
		
		attack_timer.start()
	
	attacking = false


func _on_attack_timer_timeout():
	
	attacking = true


## Taking damage
func take_damage(damage: int, knockback_direction: Vector2, knockback_power: int, hitstop: float, hitstop_power: float = 0.0):
	
	## Damage
	health = clamp(health - damage, 0, max_health)
	
	losing_health = true
	
	health_label.text = str(health)
	
	if len(str(health)) == 2:
		
		health_label.position.x = 6
	
	elif len(str(health)) == 1:
		health_label.position.x = 12
	
	## Hitstop
	if hitstop > 0.0:
		
		Engine.time_scale = hitstop_power
		hitstop_timer.wait_time = hitstop
		sprite.modulate = Color(1.0, 0.631, 0.608)
		hitstop_timer.start()
	
	## Damage particles
	damage_particles.emitting = true
	var damage_number = damage_number_scene.instantiate()
	world.add_child(damage_number)
	damage_number.setup(damage)
	damage_number.position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	
	## Knockback
	velocity = velocity.move_toward(knockback_direction * knockback_power, ACCELERATION)
	move_and_slide()
	
	if health <= 0:
		
		die()


func _on_hitstop_timer_timeout():
	
	Engine.time_scale = 1
	sprite.modulate = Color(1, 1, 1)


## Death
func die():
	
	## Death particles
	damage_particles.amount = 500
	damage_particles.speed_scale = 0.3
	damage_particles.emitting = true
	
	## Died
	died.emit()
#endregion
