extends CharacterBody2D
# Angry Tree Enemy


#region Variables, Constants, and Signals
## @export variables
@export var range_visible := true

## @onready variables
@onready var sprite := $AnimatedSprite2D
@onready var navigation_agent := $NavigationAgent2D
@onready var attack_range := $AttackRange
@onready var hive_range := $HiveRange
@onready var wander_timer := $Timers/WanderTimer
@onready var stop_timer = $Timers/StopTimer
@onready var hive_alert_timer := $Timers/HiveAlertTimer
@onready var attack_timer := $Timers/AttackTimer
@onready var hitstop_timer := $Timers/HitstopTimer
@onready var death_animation_timer := $Timers/DeathAnimationTimer
@onready var spawn_animation_timer := $Timers/SpawnAnimationTimer
@onready var leaf_particles := $Particles/LeafParticles
@onready var wood_particles := $Particles/WoodParticles
@onready var health_bar := $HealthBar
@onready var health_label := $HealthBar/HealthBarLabel
@onready var world := $"../.."


## Constants
const NORMAL_SPEED := 30.0
const CHASE_SPEED := 55.0
const ATTACK_DAMAGE := 10
const KNOCKBACK_POWER := 150
const HITSTOP := 0.1

## Variables
var last_direction: String = "down"
var direction = Vector2.ZERO
var chasing := false
var wandering := true
var animal = null
var health := 30
var attacking := false
var losing_health := false
var dead := true
var hitstopped := false
var damage_number_scene := preload("res://Scenes/DamageNumber.tscn")
#endregion


#region Main
func _ready() -> void:
	
	# Sets random timer offset for variation
	wander_timer.wait_time += randf_range(-1, 1)
	wander_timer.start()
	wander_timer.wait_time = 4.0


func _physics_process(_delta):
	
	if hitstopped:
		return
	
	if not dead:
		
		## Chase
		if chasing:
			
			velocity = direction * CHASE_SPEED
		
		else:
			
			velocity = direction * NORMAL_SPEED
		
		if chasing or wandering:
			
			var next_position = navigation_agent.get_next_path_position()
			direction = global_position.direction_to(next_position)
		
		move_and_slide()
		
		if chasing and animal == null and navigation_agent.is_navigation_finished():
			chasing = false
			wandering = true
			direction = Vector2.ZERO
		
		
		## Animation
		update_animation(direction)
		
		## Attacking
		if attacking and attack_timer.is_stopped():
			
			attack()
		
		## Health bar animation
		if losing_health:
			
			health_bar.value -= 2.5
			
			if health_bar.value <= health:
				
				losing_health = false


## Animation
@warning_ignore("shadowed_variable")
func update_animation(direction: Vector2):
	
	## Direction
	if abs(direction.y) > abs(direction.x):
		
		if direction.y > 0:
			
			last_direction = "down"
		
		else:
			
			last_direction = "up"
	
	else:
		
		if direction.x > 0:
			
			last_direction = "right"
		
		else:
			
			last_direction = "left"
	
	## Animation
	if attacking:
		
		sprite.play("attack_%s_animation" % last_direction)
	
	elif direction != Vector2.ZERO:
		
		sprite.play("walk_%s_animation" % last_direction)
	
	else:
		
		sprite.play("idle_animation")
#endregion


#region Chasing and Wandering
## Every 0.5 seconds changes chase direction
func _on_chase_timer_timeout():
	
	if not chasing:
		return
	
	if animal != null:
		
		## Finds animal
		navigation_agent.target_position = animal.global_position
	
	## Finds next positon
	var next_position = navigation_agent.get_next_path_position()
	
	## Sets direction to found position
	direction = global_position.direction_to(next_position)


## Animal enters sight range
func _on_sight_range_body_entered(body):
	
	if body.is_in_group("animal"):
		
		animal = body
		chasing = true
		wandering = false
		
		send_hive_alert(animal.global_position)
		hive_alert_timer.start()


## animal exits sight range
func _on_sight_range_body_exited(body):
	
	if body == animal:
		
		animal = null
		chasing = false
		direction = Vector2.ZERO
		
		hive_alert_timer.stop()


## Wander direction change
func _on_wander_timer_timeout():
	
	if chasing:
		return
	
	wandering = true
	
	var random_direction = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()
	
	var random_distance = randf_range(50.0, 150.0)
	var target = global_position + random_direction * random_distance
	
	navigation_agent.target_position = target
	
	stop_timer.start()


## Stop wandering timer
func _on_stop_timer_timeout() -> void:
	wandering = false
	direction = Vector2.ZERO
#endregion


#region Hivemind
func send_hive_alert(player_position: Vector2):
	
	# ORANGE = sent hive signal
	sprite.modulate = Color.ORANGE
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	for body in hive_range.get_overlapping_areas():
		
		if body.get_parent().is_in_group("tree") and body != attack_range:
			
			body.get_parent().receive_hive_alert(player_position)


func receive_hive_alert(player_last_seen: Vector2):
	
	if dead or animal != null:
		return
	
	# BLUE = received hive signal
	sprite.modulate = Color.BLUE
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	chasing = true
	wandering = false
	navigation_agent.target_position = player_last_seen


func _on_hive_alert_timer_timeout() -> void:
	
	if animal != null:
		
		send_hive_alert(animal.global_position)
		hive_alert_timer.start()
#endregion



#region Fighting

## Attack
func attack():
	
	if attack_timer.is_stopped() and attacking:
		
		attack_timer.start()


func _on_attack_timer_timeout():
	
	if animal != null and attacking:
		
		## Damage
		animal.take_damage(ATTACK_DAMAGE, direction, KNOCKBACK_POWER, HITSTOP)


## Attack range
func _on_attack_range_body_entered(body):
	
	if body.is_in_group("animal"):
		
		animal = body
		attacking = true


func _on_attack_range_body_exited(body: Node2D) -> void:
	
	if body == animal:
		
		attacking = false


## Taking damage
func take_damage(damage, hitstop):
	
	## Damage
	health -= damage
	
	losing_health = true
	health_label.text = str(health)
	
	## Damage particles
	leaf_particles.emitting = true
	wood_particles.emitting = true
	
	var damage_number = damage_number_scene.instantiate()
	world.add_child(damage_number)
	damage_number.setup(damage)
	damage_number.position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	
	## Hitstop
	hitstopped = true
	hitstop_timer.wait_time = hitstop
	sprite.modulate = Color(1.0, 0.631, 0.608)
	hitstop_timer.start()
	

	
	if health <= 0:
		
		die()


func _on_hitstop_timer_timeout():
	
	hitstopped = false
	sprite.modulate = Color(1, 1, 1)


## Death
func die():
	
	dead = true
	
	## Death particles
	
	## Leaves
	leaf_particles.amount = 500
	leaf_particles.speed_scale = 0.3
	leaf_particles.emitting = true
	
	## Wood
	wood_particles.amount = 500
	wood_particles.speed_scale = 0.3
	wood_particles.emitting = true
	
	## Animation
	sprite.play("death_animation")
	death_animation_timer.start()


func _on_death_animation_timer_timeout() -> void:
	
	queue_free()


func _on_spawn_animation_timer_timeout() -> void:
	
	dead = false

#endregion
