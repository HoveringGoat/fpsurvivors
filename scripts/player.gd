extends CharacterBody3D

@export var jumpForce : float
@export var gravity : float

@export var sprintSpeed : float
@export var speed : float
@export var lookPanSpeed : float
@export var lookTiltSpeed : float
@export var isOnFloor = true
@export var isJumping = false
@export var isRunning = false
@export var isCrouching = false
@export var maxHealth : float = 100.0
@export var health : float = maxHealth:
	set(value):
			
		if value <= 0:
			print("u ded")
			isDead = true
			
		health = value

var motion = Vector2.ZERO
var lookDirection = Vector2.DOWN
var jumpTime = 0.06
var curJumpTime = 0

var attackCoolDownTime = 0.7
var lastAttackTime = 0

var zoomLevel := 0.8:
	set(value):
		zoomLevel = clamp(value, 0.5, 1)
var cameraZoomMaxDistance = 6.5
var cameraZoomSpeed = 2.5
var cameraTargetPos = Vector3()
var knockBacked = 0
var knockBackTime = .2
var isDead = false

var isInvulnerable = false
var invulnerableEndTime = 0
var invulnerableTime = 5
@export var timeForAvgStep : int = 500
@export var timeModifierForCrouching : float = 0.5 # takes twice as long while crouching
@export var timeModifierForSprinting : float = 1.4 # takes 40% less time while sprinting
var nextStepProgress : float = 100 # each frame add adjusted time in ms progress to next step

@onready var footStepGenerator = $FootStepGenerator
@onready var camera3D: Camera3D = %Camera3D
@onready var headPivot: Node3D = %HeadPivot
@onready var direction: Node3D = %Direction
@onready var playerModel: Node3D = %PlayerModel
@onready var multiplayerSynchronizer: MultiplayerSynchronizer = %MultiplayerSynchronizer
@onready var inputs: MultiplayerSynchronizer = %InputSynchronizer
@onready var floorRayCast: RayCast3D = %FloorRayCast
@export
var syncedPosition := Vector3()

@export
var stunned = false

@export var player_id := 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(player_id)
		%InputSynchronizer.player_id = player_id

func _ready():
	health = maxHealth
	# player char added is the current client
	# make childed camera the main camera
	if multiplayer.get_unique_id() == player_id:
		camera3D.make_current()
		updateTargetCameraPosition(0)
		camera3D.position = cameraTargetPos
	# player char added is someone else
		
	if multiplayer.get_unique_id() != player_id and not multiplayer.is_server():
		# playerInteractor runs on the server
		pass

# the actual main process loop
# most of the main methods here are called from this
func _physics_process(delta):
	# update position from server
	# we want to do this before updating positions from input
	if not multiplayer.is_server() || multiplayerManager.host_mode_enabled:
		# update position to synced position weight current client position
		# to smooth out any artifacts from late packets or abrubt position changes
		position = (syncedPosition+position*2)/3
		
	if position.y <= 0:
		isOnFloor = true
		position.y = 0
	else:
		if floorRayCast.get_collider() != null:
			isOnFloor = true
		
	# perform position update with latest input still perform motion on client
	# for other clients we will apply their last frame input as motion.
	# it'll be corrected later from information from the server.
	#Shouldn't really be noticable unless ping is very high
	_apply_movement_from_input(delta)
	calculateStepProgress(delta)
	
	# stuff to do if we're A client 
	# apply animations if we're not the server (unless we're the host)
	if not multiplayer.is_server() || multiplayerManager.host_mode_enabled:
		updateAnimations()
		
	# stuff to do if we're server
	if multiplayer.is_server():
		# there will probably be more to sync eventually rather than just position
		if isInvulnerable and Time.get_ticks_msec() > invulnerableEndTime: 
			isInvulnerable = false
		syncedPosition = position
	
	#  stuff to do if this is this players client
	if multiplayer.get_unique_id() == player_id:
		updateCamera(delta)
		if cameraTargetPos != camera3D.position:
			var diff = cameraTargetPos - camera3D.position 
			if diff.length() < 0.01:
				camera3D.position = cameraTargetPos
			else:
				camera3D.position += diff * 0.15

# Method controlling which animations are playing  - Not used
func updateAnimations():
	if isDead:
		pass
		#layerModel.currentAnimation = playerModel.Animations.Death
	elif motion.length() > 0:
		pass
		#playerModel.currentAnimation = playerModel.Animations.Run
	else:
		pass
		#playerModel.currentAnimation = playerModel.Animations.Idle

# method to apply movement based on input from client
# runs on BOTH client and server. Client will adjust to server if there are any differences
# running on client should keep them nearly in parity
func _apply_movement_from_input(delta):
	if isDead:
		return
	var velY = velocity.y
	
	# Add the gravity.
	if not isOnFloor:
		velY += gravity * delta
		if isJumping and not inputs.jump:
			isJumping = false
	else:
		velY = 0

	# Handle jump.
	# player can continue to jump for a very short period of time after initiating the jump.
	if inputs.jump and (isOnFloor or isJumping):
		# the initial jump
		if isOnFloor:
			isOnFloor = false
			isJumping = true
			curJumpTime = 0
			forceStep(Enums.movementState.running)
		curJumpTime += delta
		
		# jump runs out
		if curJumpTime > jumpTime:
			isJumping = false
		
		# apply jump force for frame
		velY += jumpForce * delta

	# the input motion is given as a vector 2d. It tells us the left right, forward back motion but we need to map that locally to the player
	# this rotates the vector according to the players rotation so we can apply it to their velocity
	var inputMotion = inputs.motion.rotated((direction.rotation.y+headPivot.rotation.y) * -1)
	
	if isOnFloor:
		motion = inputMotion * delta
		if inputs.sprint:
			isRunning = true
			motion *= sprintSpeed
		else:
			isRunning = false
			motion *= speed
	else:
		# input motion is handled differently in the air. We get limited movement in the direction the player wasnt already moving
		motion = Vector2(velocity.x, velocity.z) * .995
		# cap speed at max of either current motion in direction or half normal speed
		# this allows limited movement in air but max speed will be to maintain motion
		var maxX = max(abs(motion.x), delta * speed * 0.5)
		var maxY = max(abs(motion.y), delta * speed * 0.5)
		motion += inputMotion * delta * speed * 0.05
		motion.x = clamp(motion.x, maxX * -1,  maxX)
		motion.y = clamp(motion.y, maxY * -1,  maxY)
		
	# handle knockback - Not used
	if knockBacked > 0:
		var xzVel = Vector2(velocity.x, velocity.z)
		motion = motion.lerp(xzVel, knockBacked)
		knockBacked -= delta/knockBackTime
		if knockBacked < 0:
			knockBacked = 0
	
	# Apply movement
	velocity = Vector3(motion.x, velY, motion.y)
	
	# control camera movement
	# mouse motion is captured and given in a vector 2d as well
	# we apply this as rotation and tilt to the player "head" which holds the camera
	# if the rotation angle is too great the body will rotate to follow the head at a maxiumum angle
	var cameraMotion = inputs.mouseMotion * -1 * delta 
	if cameraMotion != Vector2.ZERO:
		# move head first then body after it reaches maximum turn angle
		var minHeadRotation = -50.0 / 360.0 * 6.14
		var maxHeadRotation = 50.0 / 360.0 * 6.14
		var addedRotation = cameraMotion.x * lookPanSpeed * 0.01
		var headPivotRotation = clamp(headPivot.rotation.y + addedRotation, minHeadRotation, maxHeadRotation) - headPivot.rotation.y
		headPivot.rotation.y += headPivotRotation
		direction.rotation.y += addedRotation - headPivotRotation
		
		# tilt head up and down
		var tilt = headPivot.rotation.x + cameraMotion.y * lookTiltSpeed * 0.01
		var minHeadTilt = -73.0 / 360.0 * 6.14
		var maxHeadTilt = 77.0 / 360.0 * 6.14
		tilt = clamp(tilt, -1.3, 1.4)
		headPivot.rotation.x = tilt
	
	
	# attack - Not used
	if inputs.attack:
		if lastAttackTime + attackCoolDownTime * 1000 < Time.get_ticks_msec():
			lastAttackTime = Time.get_ticks_msec()
			# do attack calcs
			#playerModel.currentAnimation = playerModel.Animations.Attack
			#swordAttack.performHit()
			
			
	move_and_slide()
	
# method to calculate when a player should take a step.
# potentially we would hook this into internal kinimatics later or have it based on animations
# there is a "time per step" value and when that amount of time has been spent moving we "take a step"
# running makes this time accumulate faster and crouching slower
func calculateStepProgress(delta):
	if motion.length() == 0 or !isOnFloor:
		return
	var stepDelta = delta * 1000
	var state = Enums.movementState.walking
	if isRunning:
		state = Enums.movementState.running
		stepDelta *= timeModifierForSprinting
	elif isCrouching:
		state = Enums.movementState.crouching
		stepDelta *= timeModifierForCrouching
	
	nextStepProgress += stepDelta
	if nextStepProgress >= timeForAvgStep:
		forceStep(state)
		
# this is called when a step needs to be taken
# it refers to the state of the char motion when the step happened.
# right now there is walking running and crouching
func forceStep(state: int):
	nextStepProgress -= timeForAvgStep
	footStepGenerator.step(state)
	
# method to adjust the camera to target camera postion - not used
func updateCamera(delta):
	if inputs.zoom != 0:
		updateTargetCameraPosition(delta)
	
	
# method to adjust the cameras target postion - also not used
func updateTargetCameraPosition(delta):
	zoomLevel += inputs.zoom * delta * cameraZoomSpeed
	var offset = cameraZoomMaxDistance*zoomLevel*zoomLevel
	var yOffset = abs(zoomLevel - 1) * 0.7 + .8
	
	cameraTargetPos = Vector3(0,offset+yOffset,offset)


# hittable stuff. might replace/rewrite - not used
func _on_hittable_hit(hitter):
	# we are hit
	print("hit by %s" % hitter.controller.name)
	if isInvulnerable:
		print("invulnerable!")
		return
	# knockback
	var diff = hitter.controller.position - position
	velocity.x = 0 
	velocity.z = 0 
	velocity -= diff.normalized() * hitter.knockbackForce
	knockBacked = 1
	takeDamage(hitter)

# takes damage - not used
func takeDamage(damage:int):
	health -= damage
	# damage screen effects
