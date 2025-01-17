class_name Player extends CharacterBody2D

@export var plant_radius: float = 32.0
@export var interact_radius: float = 10.0
@export var speed: float = 64.0

@export var fruit_scene: PackedScene

@export var interact_area: Area2D
@export var sprite: Sprite2D
@export var plant_ray_cast: RayCast2D
@export var walk_anim: AnimationPlayer
@export var step_particles: CPUParticles2D
@export var step_player: AudioStreamPlayer

var interact_target: Interactable
var interactables: Array[Interactable]
var last_dir: Vector2 

var can_interact: bool = true
var frozen: bool = false

func _ready() -> void:
	interact_area.area_entered.connect(_on_area_entered)
	interact_area.area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	area.interact_changed.connect(_on_interact_changed)
	if not area in interactables:
		interactables.append(area as Interactable)
	update_target()

func _on_area_exited(area: Area2D) -> void:
	area.interact_changed.disconnect(_on_interact_changed)
	if area in interactables:
		interactables.remove_at(interactables.find(area as Interactable))
	update_target()

func _on_interact_changed() -> void:
	update_target()

func _input(event: InputEvent) -> void:
	if not can_interact:
		return
	
	if event.is_action_pressed("interact", false) and not is_instance_valid(interact_target):
		if Data.seeds <= 0:
			return
		plant()
	
	if event.is_action_pressed("interact", false) and is_instance_valid(interact_target):
		can_interact = false # target must reset this!
		interact_target.interact(self)

func _physics_process(_delta: float) -> void:
	if frozen:
		walk_anim.play("idle")
		return
	
	var input: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if last_dir.length() <= 0: # initialization 
		input = Vector2(0, 1)
	
	if input.length() > 0:
		last_dir = input
		interact_area.position = last_dir * interact_radius
	
	velocity = input * speed
	
	move_and_slide()
	
	animate(input)

func update_target() -> void:
	interact_target = null
	for area in interactables:
		if not area.can_interact:
			continue
		if not is_instance_valid(interact_target) or area.global_position.distance_to(self.global_position) < interact_target.global_position.distance_to(self.global_position):
			interact_target = area
	if is_instance_valid(interact_target):
		Ref.interact_label.prompt(interact_target.interact_string())
	else:
		Ref.interact_label.prompt("")

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
	
