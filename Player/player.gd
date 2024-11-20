extends CharacterBody3D
var player_id:int = 0
var is_you:bool = false
var lamp=true
var lamp_x = 0
var lamp_energy = 2
var SPEED = 2.5
const BASE_SPEED = 2.5
const JUMP_VELOCITY = 2.8
var mouse_sensitivity = 0.002
var lamp_base_y = 0.0
var last_velo = Vector3(0,0,0)
var squat = false
var i=0
var posi = Vector3.ZERO
var rota = 0
var is_ennemy = false
var caught = false
var is_dead = false
@export var RayCastCaught:RayCast3D
@export var cammera:Camera3D
@export var ennemy_cammera:Camera3D
@export var lamp_node:SpotLight3D
@export var Ennemy_squeleton:Skeleton3D
@export var Player_squeleton:Skeleton3D
func _ready():
	print(is_ennemy)
	if is_ennemy:
		Player_squeleton.name = "Player"
		Ennemy_squeleton.name = "GeneralSkeleton"
		Ennemy_squeleton.show()
		Player_squeleton.hide()
		ennemy_cammera.current = is_you
		cammera.current = false
		lamp_node.light_energy = 0
		lamp_node.hide()
	else:
		Ennemy_squeleton.name = "Ennemy"
		Player_squeleton.name = "GeneralSkeleton"
		Ennemy_squeleton.hide()
		Player_squeleton.show()
		ennemy_cammera.current = false
		cammera.current = is_you
	if !is_you:return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	lamp_base_y = lamp_node.position.y
	lamp_node.light_energy=lamp_energy
	if is_ennemy:
		$Shader/TextureRect.hide()
func _physics_process(delta):
	set_anim("idle",false)
	set_anim("walk",false)
	set_anim("right",false)
	set_anim("left",false)
	if !is_you or is_dead:
		position = lerp(position,posi,delta*6)
		rotation.y = lerp_angle(rotation.y,rota,delta*6)
		#velocity = last_velo
		#move_and_slide()
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and false:
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("q", "d", "z", "s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var mouvement_speed = direction.length()
	ennemy_cammera.environment.set("fog_density",lerp(ennemy_cammera.environment.get("fog_density"),1-((0.1+sqrt(2)-mouvement_speed)/2),delta*4))
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		#if velocity!=last_velo:set_velo.rpc(velocity)
		if not squat:
			lamp_node.position.y = lamp_base_y+sin(lamp_x)/100
			lamp_node.rotate_x(sin(lamp_x+randf_range(-0.1,0.1))/(100))
			lamp_x+=delta*2*SPEED
	else:
		lamp_node.rotation.x = lerp(lamp_node.rotation.x,0.0,delta*5)
		lamp_node.position.y = lamp_base_y+sin(lamp_x)/500
		lamp_x+=delta*2
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	if Input.is_action_pressed("squat") and not is_ennemy:
		$Collision.scale.y = lerp($Collision.scale.y,0.2,delta*5)
		lamp_node.position.y = lamp_base_y+sin(lamp_x)/500
		SPEED=BASE_SPEED/4
		lamp_node.rotation.x = lerp(lamp_node.rotation.x,0.0,delta*5)
		squat =true
	if not Input.is_action_pressed("squat") and not is_ennemy:
		$Collision.scale.y = lerp($Collision.scale.y,1.0,delta*5)
		SPEED= BASE_SPEED
		squat=false
	if Input.is_action_just_pressed("clic") and not is_ennemy:
		if lamp:
			lamp_node.light_energy = 0
		else:
			lamp_node.light_energy = lamp_energy
		set_lamp.rpc(lamp)
		lamp = not lamp
	if RayCastCaught.is_colliding():
		var collider = RayCastCaught.get_collider()
		if collider.is_in_group("Player") and not collider == self:
			caught = collider
			print(collider)
		else:
			caught = null
	else:
		caught = null
	if Input.is_action_just_pressed("caught"):
		if not is_ennemy:return
		set_anim.rpc("caught",true)
		if caught != null:
			var player =  caught
			await get_tree().create_timer(0.7).timeout
			player.dead.rpc()
	if Input.is_action_just_released("caught"):
		set_anim.rpc("caught",false)
	
	if input_dir == Vector2.ZERO:
		set_anim.rpc("idle",true)
	else:
		if input_dir.y != 0:
			set_anim.rpc("walk",true)
		if input_dir.x > 0:
			set_anim.rpc("left",true)
		if input_dir.x < 0:
			set_anim.rpc("right",true)
	last_velo = velocity
	move_and_slide()
	i+=1
	if i >=3:
		set_rot.rpc(rotation.y,cammera.rotation)
	if i >=6:
		set_pos.rpc(position)
		set_rot.rpc(rotation.y,cammera.rotation)
		i=0
@rpc("any_peer","call_local")
func dead():
	set_anim("alive",false)
	set_anim("dead",true)
	is_dead = true
func _input(event):
	if !is_you or is_dead:return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		cammera.rotation.x = clampf(cammera.rotation.x+(-event.relative.y * mouse_sensitivity), -deg_to_rad(50), deg_to_rad(60))
		ennemy_cammera.rotation.x = clampf(cammera.rotation.x+(-event.relative.y * mouse_sensitivity), -deg_to_rad(50), deg_to_rad(60))
		
@rpc("any_peer","call_local")
func set_anim(anim,state):
	$AnimationTree.set("parameters/conditions/"+anim, state)
@rpc("any_peer")
func set_pos(pos):
	posi = pos
@rpc("any_peer")
func set_lamp(status):
	if status:
		lamp_node.light_energy = 0
	else:
		lamp_node.light_energy = lamp_energy
@rpc("any_peer")
func set_rot(roty,rot_cam):
	rota = roty
	if is_ennemy:
		ennemy_cammera.rotation = rot_cam
	else:
		cammera.rotation = rot_cam
#@rpc("any_peer")
#func set_velo(velo):
	#last_velo = velo
