extends CharacterBody3D

# TODO: Add descriptions for each value

@export_category("Character")
@export var base_speed : float = 3.0
@export var sprint_speed : float = 6.0
@export var crouch_speed : float = 1.0

@export var acceleration : float = 10.0
@export var jump_velocity : float = 4.5
@export var mouse_sensitivity : float = 0.1

@export_group("Nodes")
@export var HEAD : Node3D
@export var CAMERA : Camera3D
@export var CAMERA_ANIMATION : AnimationPlayer
@export var COLLISION_MESH : CollisionShape3D

@export_group("Controls")
# We are using UI controls because they are built into Godot Engine so they can be used right away
@export var JUMP : String = "ui_accept"
@export var LEFT : String = "ui_left"
@export var RIGHT : String = "ui_right"
@export var FORWARD : String = "ui_up"
@export var BACKWARD : String = "ui_down"
@export var PAUSE : String = "ui_cancel"
@export var CROUCH : String
@export var SPRINT : String

# Uncomment if you want full controller support
#@export var LOOK_LEFT : String
#@export var LOOK_RIGHT : String
#@export var LOOK_UP : String
#@export var LOOK_DOWN : String

@export_group("Feature Settings")
@export var immobile : bool = false
@export var jumping_enabled : bool = true
@export var in_air_momentum : bool = true
@export var motion_smoothing : bool = true
@export var sprint_enabled : bool = true
@export var crouch_enabled : bool = true
@export_enum("Hold to Crouch", "Toggle Crouch") var crouch_mode : int = 0
@export_enum("Hold to Sprint", "Toggle Sprint") var sprint_mode : int = 0
@export var dynamic_fov : bool = true
@export var continuous_jumping : bool = true
@export var view_bobbing : bool = true


# Member variables
var speed : float = base_speed
# States: normal, crouching, sprinting
var state : String = "normal"
var low_ceiling : bool = false # This is for when the cieling is too low and the player needs to crouch.

var player_id
var direction = Vector3(0,0,0)

var crouch = false
var sprint = false
var jump = false

var just_crouch = false
var just_sprint = false
var just_jump = false

@onready var inventory = $Inventory
@onready var backpack_slot_inv = $BackpackSlotInv

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") # Don't set this as a const, see the gravity section in _physics_process

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	
	# Add some debug data
	$UserInterface/DebugPanel.add_property("Movement Speed", speed, 1)
	$UserInterface/DebugPanel.add_property("Velocity", get_real_velocity(), 2)
	
	# Gravity
	#gravity = ProjectSettings.get_setting("physics/3d/default_gravity") # If the gravity changes during your game, uncomment this code
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	handle_jumping()
	
	var input_dir = Vector2.ZERO
	if !immobile:
		input_dir = direction
	handle_movement(delta, input_dir)
	
	low_ceiling = $CrouchCeilingDetection.is_colliding()
	
	handle_state(input_dir)
	update_camera_fov()
	update_collision_scale()
	
	if view_bobbing:
		headbob_animation(input_dir)

	if just_crouch:
		just_crouch = false
	if just_sprint:
		just_sprint = false
	if just_jump:
		just_jump = false
		
func handle_jumping():
	if jumping_enabled:
		if continuous_jumping:
			if jump and is_on_floor():
				velocity.y += jump_velocity
		else:
			if just_jump and is_on_floor():
				velocity.y += jump_velocity


func handle_movement(delta, input_dir):
	#var direction = input_dir.rotated(-HEAD.rotation.y)
	#direction = Vector3(direction.x, 0, direction.y)
	if immobile:
		direction = Vector3(0,0,0)
	move_and_slide()
	
	if in_air_momentum:
		if is_on_floor():
			if motion_smoothing:
				velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
				velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
			else:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
	else:
		if motion_smoothing:
			velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
			velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
		else:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed


func handle_state(moving):
	if sprint_enabled:
		if sprint_mode == 0:
			if sprint and !crouch:
				if moving:
					if state != "sprinting":
						enter_sprint_state()
				else:
					if state == "sprinting":
						enter_normal_state()
			elif state == "sprinting":
				enter_normal_state()
		elif sprint_mode == 1:
			if moving:
				if just_sprint:
					match state:
						"normal":
							enter_sprint_state()
						"sprinting":
							enter_normal_state()
			elif state == "sprinting":
				enter_normal_state()
	
	if crouch_enabled:
		if crouch_mode == 0:
			if crouch and !sprint:
				if state != "crouching":
					enter_crouch_state()
			elif state == "crouching" and !$CrouchCeilingDetection.is_colliding():
				enter_normal_state()
		elif crouch_mode == 1:
			if just_crouch:
				match state:
					"normal":
						enter_crouch_state()
					"crouching":
						if !$CrouchCeilingDetection.is_colliding():
							enter_normal_state()


func enter_normal_state():
	#print("entering normal state")
	var prev_state = state
	state = "normal"
	speed = base_speed

func enter_crouch_state():
	#print("entering crouch state")
	var prev_state = state
	state = "crouching"
	speed = crouch_speed


func enter_sprint_state():
	#print("entering sprint state")
	var prev_state = state
	state = "sprinting"
	speed = sprint_speed


func update_camera_fov():
	#CLIENTSIDE-FUNCTIONS
	#if state == "sprinting":
		#CAMERA.fov = lerp(CAMERA.fov, 85.0, 0.3)
	#else:
		#CAMERA.fov = lerp(CAMERA.fov, 75.0, 0.3)
	return

func update_collision_scale():
	if state == "crouching": # Add your own crouch animation code
		COLLISION_MESH.scale.y = lerp(COLLISION_MESH.scale.y, 0.75, 0.2)
	else:
		COLLISION_MESH.scale.y = lerp(COLLISION_MESH.scale.y, 1.0, 0.2)


func headbob_animation(moving):
	if moving and is_on_floor():
		CAMERA_ANIMATION.play("headbob")
		CAMERA_ANIMATION.speed_scale = speed / base_speed
	else:
		CAMERA_ANIMATION.play("RESET")


func _process(delta):
	$UserInterface/DebugPanel.add_property("FPS", 1.0/delta, 0)
	$UserInterface/DebugPanel.add_property("State", state, 0)
	
	if Input.is_action_just_pressed(PAUSE):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	HEAD.rotation.x = clamp(HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	# Uncomment if you want full controller support
	#var controller_view_rotation = Input.get_vector(LOOK_LEFT, LOOK_RIGHT, LOOK_UP, LOOK_DOWN)
	#HEAD.rotation_degrees.y -= controller_view_rotation.x * 1.5
	#HEAD.rotation_degrees.x -= controller_view_rotation.y * 1.5


func _unhandled_input(event):
	#CLIENT-SIDE FUNCTIONS
	#if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		#HEAD.rotation_degrees.y -= event.relative.x * mouse_sensitivity
		#HEAD.rotation_degrees.x -= event.relative.y * mouse_sensitivity
	return

@rpc("authority", "call_local", "reliable")
func create_backpack_slot_inv(id):
	$BackpackSlotInv.create_sizeless_inventory.rpc(id)
	$BackpackSlot.inventory = $BackpackSlotInv.inventory_grid
	
#@rpc("authority", "reliable")
#func update_player_position():
	#
	#return

@rpc("any_peer", "call_remote")
func set_head_rot(rot):
	if multiplayer.get_remote_sender_id() == player_id:
		$Head.rotation = rot
		#print("head rot")
		pass
	return

@rpc("any_peer", "call_remote")
func set_crouch(b):
	if multiplayer.get_remote_sender_id() == player_id:
		crouch = b
		just_crouch = b

@rpc("any_peer", "call_remote")
func set_jump(b):
	if multiplayer.get_remote_sender_id() == player_id:
		jump = b
		just_jump = b
	
@rpc("any_peer", "call_remote")
func set_sprint(b):
	if multiplayer.get_remote_sender_id() == player_id:
		sprint = b
		just_sprint = b

@rpc("any_peer", "call_remote")
func set_direction(dir):
	if multiplayer.get_remote_sender_id() == player_id:
		direction = dir

@rpc("authority", "call_local", "reliable")
func set_player_id(id):
	player_id = id

@rpc("authority", "call_remote", "reliable")
func set_camera_enable(b):
	return
