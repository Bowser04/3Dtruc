extends CharacterBody3D

var lamp_x = 0
var SPEED = 2.5
const BASE_SPEED = 2.5
const JUMP_VELOCITY = 4.5
var mouse_sensitivity = 0.002
var lamp_base_y = 0.0
var squat = false
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	lamp_base_y = $Camera3D/SpotLight3D.position.y

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("q", "d", "z", "s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		if not squat:
			$Camera3D/SpotLight3D.position.y = lamp_base_y+sin(lamp_x)/100
			$Camera3D/SpotLight3D.rotate_x(sin(lamp_x+randf_range(-0.1,0.1))/(100))
			print(sin(lamp_x))
			lamp_x+=delta*2*SPEED
	else:
		$Camera3D/SpotLight3D.rotation.x = lerp($Camera3D/SpotLight3D.rotation.x,0.0,delta*5)
		$Camera3D/SpotLight3D.position.y = lamp_base_y+sin(lamp_x)/500
		lamp_x+=delta*2
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	if Input.is_action_pressed("squat"):
		$Collision.scale.y = lerp($Collision.scale.y,0.2,delta*5)
		$Camera3D/SpotLight3D.position.y = lamp_base_y+sin(lamp_x)/500
		SPEED=BASE_SPEED/4
		$Camera3D/SpotLight3D.rotation.x = lerp($Camera3D/SpotLight3D.rotation.x,0.0,delta*5)
		squat =true
	if not Input.is_action_pressed("squat"):
		$Collision.scale.y = lerp($Collision.scale.y,1.0,delta*5)
		SPEED= BASE_SPEED
		squat=false

		

	move_and_slide()
func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))
