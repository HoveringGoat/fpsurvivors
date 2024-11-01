extends MultiplayerSynchronizer

var player_id = 1
@onready var camera3D: Camera3D = %Camera3D

@export
var motion = Vector2():
	set(value):
		# This will be sent by players, make sure values are within limits.
		if value.length() > 1:
			value = value.normalized()
		motion = value
@export var jump : bool = false
@export var sprint : bool = false
@export var attack : bool = false
@export var strongAttack : bool = false
@export var interact : bool = false
enum Scroll {none, up, down}
@export var scroll : Scroll
@export
var zoom = 0.0
var mouseMotion : Vector2
var lookDirection = Vector2():
	set(value):
		lookDirection = value.normalized()
var mouseLocked : bool = true

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	mouseLocked = true

func _input(event):
	if multiplayer.get_unique_id() != player_id:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pass
			#print("Left button was clicked at ", event.position)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			scroll = Scroll.up
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			scroll = Scroll.down

		
func _physics_process(delta):
	if multiplayer.get_unique_id() != player_id:
		return
	zoom = 0
	motion = Vector2()
	if Input.is_action_pressed("move_left"):
		motion += Vector2(-1, 0)
	if Input.is_action_pressed("move_right"):
		motion += Vector2(1, 0)
	if Input.is_action_pressed("move_forward"):
		motion += Vector2(0, -1)
	if Input.is_action_pressed("move_back"):
		motion += Vector2(0, 1)
		
	jump = Input.is_action_pressed("jump")
	sprint = Input.is_action_pressed("sprint")
	
	attack = Input.is_action_pressed("attack")
	#strongAttack = Input.is_action_pressed("strongAttack")
	#interact = Input.is_action_pressed("interact")
	#if interact:
		#print("interacting")
		
	mouseMotion = Vector2.ZERO
	var center = Vector2i(get_viewport().size.x *.5, get_viewport().size.y * .5)
	if mouseLocked:
		mouseMotion = get_viewport().get_mouse_position() - (center as Vector2)
		Input.warp_mouse(center)
		#if mouseMotion != Vector2.ZERO:
			#print("center: %s" % center)
			#print("mouse motion: %s" % mouseMotion)
		
	if Input.is_action_just_pressed("esc"):
		if mouseLocked:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouseLocked = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			Input.warp_mouse(center)
			mouseLocked = true
	

	
	
