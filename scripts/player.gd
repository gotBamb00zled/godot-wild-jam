extends CharacterBody3D

#player nodes

@onready var neck = $neck
@onready var head = $neck/head
@onready var standing_collision_shape = $standing_collision_shape
@onready var crouching_collision_shape = $crouching_collision_shape
@onready var ray_cast_3d = $RayCast3D
@onready var camera_3d = $neck/head/Camera3D

var direction = Vector3.ZERO

#speed variables

var current_speed = 9.0
const walking_speed = 9.0
const sprinting_speed = 27.0
const crouching_speed = 3.0

# states for state machine

var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

#sliding vars

var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 13.0



"""
#head bobbing variables

const head_bobbing_sprinting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed = 10.0

const head_bobbing_sprinting_intensity = 0.2
const head_bobbing_walking_intensity = 0.1
const head_bobbing_crouching_intensity = 0.05

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0

"""

#movement variables

var lerp_speed = 10.0
const jump_velocity = 3.75
var crouching_depth = -0.5
#toDo get rid of freelook or rework
var free_look_tilt_amount = 8

#input variables

const mouse_sens = 0.3

"""
END OF VARIABLES
"""

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#capture mouse cursor when running game
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	#quit game preview window if Esc is pressed	
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()

	#rotate camera based on mouse movement
	if event is InputEventMouseMotion:
		if free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y,deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
			head.rotation.x = clamp(head.rotation.x,deg_to_rad(-89), deg_to_rad(89))
	
func _physics_process(delta):
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerp_speed)
	
	#if you're pressing sprint, then give player sprinting speed. else, speed = walking speed
	
	if Input.is_action_pressed("crouch") || sliding:
		
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y, crouching_depth, delta*lerp_speed)
		
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		#for when slide begins
		
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			free_looking = true
			print("Slide begin")
		
		walking = false
		sprinting = false
		crouching = true

	elif !ray_cast_3d.is_colliding():
		
		#standing state
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		head.position.y = lerp(head.position.y, 0.0, delta*lerp_speed)
		
		
		#check if sprinting
		if Input.is_action_pressed("sprint"):
			current_speed = sprinting_speed
			
			walking = false
			sprinting = true
			crouching = false
		else:
			#if you're not sprinting, then you're walking
			current_speed = walking_speed
			
			walking = false
			sprinting = false
			crouching = true
			
	#add freelook option while sliding
	if Input.is_action_pressed("free_look"):
		free_looking = true
		camera_3d.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt_amount)
		
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta*lerp_speed)
		camera_3d.rotation.z = lerp(camera_3d.rotation.y, 0.0, delta*lerp_speed)
	
	#sliding
	
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			print("Slide end")

	"""
	# head bobbing
	
	if sprinting:
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed*delta
	elif walking:
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed*delta
	elif crouching:
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed*delta
	"""
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if Input.is_action_pressed("sprint"):
		current_speed = sprinting_speed
		
		walking = false
		sprinting = true
		crouching = false
	# badcode - he's making our velocity be upward jump velocify if we hit spacebar when we're on floor. also sets slide to false no matter what.
	"""
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		sliding = false
	"""
		
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
		
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if sliding:
			velocity.x = direction.x * (slide_timer + 0.1) * slide_speed
			velocity.z = direction.z * (slide_timer + 0.1) * slide_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
