extends CharacterBody3D

signal health_changed(health_value)
signal name_changed(chosen_name)

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D

var deaths = 0
var kills = 0
var auto = false
var health = 3
var display_name = ''
var bhop = false
var SPEED = 10.0
const JUMP_VELOCITY = 10.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20.0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * .005)
			camera.rotate_x(-event.relative.y * .005)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		if !auto:
			if Input.is_action_just_pressed("shoot") \
					and anim_player.current_animation != "shoot":
				play_shoot_effects.rpc()
				if raycast.is_colliding():
					var hit_player = raycast.get_collider()
					hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())
		else:
			if Input.is_action_pressed("shoot"):
				play_shoot_effects.rpc()
				if raycast.is_colliding():
					var hit_player = raycast.get_collider()
					hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if bhop:
		if Input.is_action_pressed("ui_accept"):
			if SPEED >= 50:
				SPEED =50
			else:
				SPEED += 0.1
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
		else:
			if !SPEED <= 10.0:
				SPEED -= 10
			else:
				SPEED = 10.0
	else:
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			SPEED = 10.0
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED * delta * 50
		velocity.z = direction.z * SPEED * delta * 50
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 50)
		velocity.z = move_toward(velocity.z, 0, SPEED * delta * 50)

	if anim_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		anim_player.play("move")
	else:
		anim_player.play("idle")

	move_and_slide()

@rpc("call_local")
func play_shoot_effects():
	anim_player.stop()
	anim_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true

@rpc("any_peer")
func receive_damage():
	health -= 1
	if health <= 0:
		deaths += 1
		health = 3
		position = Vector3.ZERO
	health_changed.emit(health)

@rpc("any_peer")
func name_change():
	print(display_name)
	display_name = $NameEntry.text
	name_changed.emit(display_name)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")


func _on_button_pressed():
	print('Name Change Pressed')
	$Button.focus_mode = 0
	rpc("name_change")
