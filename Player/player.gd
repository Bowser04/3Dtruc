extends CharacterBody3D
var player_id:int = 0
var is_you:bool = false
var lamp=true
var lamp_x = 0
var lamp_energy = 2
var SPEED = 2.5
const BASE_SPEED = 2.5
const JUMP_VELOCITY = 4.5
var mouse_sensitivity = 0.002
var lamp_base_y = 0.0
var last_velo = Vector3(0,0,0)
var squat = false
var i=0
var posi = Vector3.ZERO
var rota = 0
func _ready():
	$Camera3D.current = is_you
	if !is_you:return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	lamp_base_y = $Camera3D/SpotLight3D.position.y
	$Camera3D/SpotLight3D.light_energy=lamp_energy

func _physics_process(delta):
	if !is_you:
		position = lerp(position,posi,delta*6)
		rotation.y = lerp_angle(rotation.y,rota,delta*6)
		#velocity = last_velo
		#move_and_slide()
		return
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
		#if velocity!=last_velo:set_velo.rpc(velocity)
		if not squat:
			$Camera3D/SpotLight3D.position.y = lamp_base_y+sin(lamp_x)/100
			$Camera3D/SpotLight3D.rotate_x(sin(lamp_x+randf_range(-0.1,0.1))/(100))
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
	if Input.is_action_just_pressed("clic"):
		if lamp:
			$Camera3D/SpotLight3D.light_energy = 0
		else:
			$Camera3D/SpotLight3D.light_energy = lamp_energy
		set_lamp.rpc(lamp)
		lamp = not lamp

	last_velo = velocity
	move_and_slide()
	i+=1
	if i >=3:
		set_rot.rpc(rotation.y,$Camera3D.rotation)
	if i >=6:
		set_pos.rpc(position)
		set_rot.rpc(rotation.y,$Camera3D.rotation)
		i=0
func _input(event):
	if !is_you:return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))

@rpc("any_peer")
func set_pos(pos):
	posi = pos
@rpc("any_peer")
func set_lamp(status):
	if status:
		$Camera3D/SpotLight3D.light_energy = 0
	else:
		$Camera3D/SpotLight3D.light_energy = lamp_energy
@rpc("any_peer")
func set_rot(roty,rot_cam):
	rota = roty
	$Camera3D.rotation = rot_cam
#@rpc("any_peer")
#func set_velo(velo):
	#last_velo = velo
