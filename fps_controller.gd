extends CharacterBody3D

# Sensitivity and movement speed
var mouse_sensitivity = 0.2
var move_speed = 10.0
var jump_speed = 12.0
var gravity = -24.8
var max_fall_speed = -50.0

# Internal velocity and rotation variables
var velocity = Vector3.ZERO
var y_velocity = 0.0

# Head node for looking up and down
@export var head: NodePath

# Mouse look
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		if head != null:
			get_node(head).rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
			get_node(head).rotation_degrees.x = clamp(get_node(head).rotation_degrees.x, -90, 90)

# Process movement
func _physics_process(delta):
	var direction = Vector3.ZERO

	# Capture input for movement
	if Input.is_action_pressed("ui_up"): 
		direction.z -= 1
	if Input.is_action_pressed("ui_down"):
		direction.z += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1

	direction = direction.normalized()

	# Apply movement speed
	var forward_dir = -transform.basis.z * direction.z
	var right_dir = transform.basis.x * direction.x
	velocity = (forward_dir + right_dir) * move_speed

	# Handle jumping and gravity
	if is_on_floor():
		if Input.is_action_just_pressed("ui_accept"): # "ui_accept" is the default for the spacebar
			y_velocity = jump_speed
	else:
		y_velocity += gravity * delta

	y_velocity = clamp(y_velocity, max_fall_speed, jump_speed)
	velocity.y = y_velocity

	# Move the player
	velocity = move_and_slide(velocity, Vector3.UP)
