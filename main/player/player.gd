class_name Player extends CharacterBody2D

@export var plant_radius: float = 32.0
@export var sprite: Sprite2D
@export var plant_ray_cast: RayCast2D
@export var walk_anim: AnimationPlayer
@export var step_particles: CPUParticles2D
@export var step_player: AudioStreamPlayer
@export var fruit_scene: PackedScene

@export var speed: float = 64.0

var last_dir: Vector2 = Vector2(0, 1)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("plant", false):
		if Data.seeds <= 0:
			return
		plant()

func _physics_process(delta: float) -> void:
	var input: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input.length() > 0:
		last_dir = input
	
	velocity = input * speed
	
	move_and_slide()
	
	animate(input)

func step() -> void:
	step_particles.direction = -velocity.normalized()
	step_particles.restart()
	step_particles.emitting = true
	step_player.play()

func animate(input: Vector2) -> void:
	if input.x < 0 and input.y < 0:
		sprite.frame = 0
	elif input.x > 0 and input.y < 0:
		sprite.frame = 2
	elif input.x > 0 and input.y > 0:
		sprite.frame = 4
	elif input.x < 0 and input.y > 0:
		sprite.frame = 6
	
	elif input.y < 0:
		sprite.frame = 1
	elif input.x > 0:
		sprite.frame = 3
	elif input.y > 0:
		sprite.frame = 5
	elif input.x < 0:
		sprite.frame = 7
	
	if is_zero_approx(input.length()):
		walk_anim.play("idle")
	else:
		walk_anim.play("walk") 

func plant() -> void:
	var plant_position = last_dir * plant_radius
	plant_ray_cast.target_position = plant_position
	plant_ray_cast.force_raycast_update()
	
	if plant_ray_cast.is_colliding():
		return
	
	Data.seeds -= 1
	
	var new_fruit: Fruit = fruit_scene.instantiate()
	get_parent().add_child(new_fruit)
	new_fruit.global_position = global_position + plant_position
	
