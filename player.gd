extends CharacterBody3D

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Assault_Rifle/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D
@onready var player_list = $PlayerList

var auto_touches = 0
var playerlistnames = ''
var deaths = 0
var kills = 0
var auto = true
var health = 3
var display_name = ''
var speed = 10.0
const JUMP_VELOCITY = 5
var upsidedown = false
var testbool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
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
	if get_parent().auto:
		auto = true
	else:
		auto = false
	if Input.is_action_just_pressed("["):
		position = Vector3(1000,-1000,1000)
	# Handle jump
	if Input.is_action_just_pressed("ui_accept"):
		speed = 10.0
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.]
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
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


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
