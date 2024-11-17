extends CharacterBody3D

@export var syncedPosition := Vector3()
@export var syncedTargetPlayerId = 1

var activeCharacter = 0
@onready var animationTree: AnimationTree = %AnimationTree
@onready var direction : Node3D = %Direction
@onready var hitter : Hitter = %Hitter
@onready var healthBar: Node3D = %Healthbar
@onready var collider: CollisionShape3D = %CollisionShape3D
@onready var floorRayCast: RayCast3D = %FloorRayCast
@onready var footStepGenerator = $FootStepGenerator

@export var timeForAvgStep : int = 500
var nextStepProgress : float = 100 # each frame add adjusted time in ms progress to next step

var gravity : float = -20
var isOnFloor = true
var spawnManager = null
enum Animations {Idle=0, Run=1, Death = 2, Attack = 3}
var animationBlendValues = [0,0,0] # idle doesnt get updated but its easier to jsut have it exist too
var blendTime = 0.1
var currentTarget : CharacterBody3D = null
var speed : float = 5000
# acttack sutff
var attackRange = 1.5
var isAttacking = false
var attackPerformed = false
var lastAttackTime = 0
var attackHitTime = .5
var attackCooldown = 1.0
var targetSwitchDistance = 1.0
var minRange = 1.0
var isDead = false
var isSinking = false
var knockBacked : float = 0
var knockBackTime : float = .2
var deathTime : float = 5.0
var deathSinkTime : float = 1.0
var deathSinkRate : float = 0.25


@export var maxHealth = 20.0
@export var health = maxHealth:
	set(value):
		if healthBar != null:
			healthBar.percentage = value/maxHealth
			
		if value <= 0:
			if not isDead:
				print("%s ded" % name)
				isDead = true
				deathTimer()
			
		health = value
var currentAnimation := Animations.Idle:
	set(value):
		if value >= len(Animations):
			print("invalid animation")
		elif currentAnimation != value:
			# check if its a one-shot animation
			match value:
				Animations.Attack:
					requestOneShotAnimation(value, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				_:
					currentAnimation = value


func requestOneShotAnimation(animation, request):
	var animName = ""
	match animation:
		Animations.Attack:
			animName = "Attack"
		_:
			print("cannot find one-shot animation")
	var animationParamPath = "parameters/%s/request" % animName
	animationTree[animationParamPath] = request
	
func interruptAllOneShotAnimations():
	animationTree["parameters/Attack/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
	
func _ready():
	if not multiplayer.is_server():
		position = syncedPosition
		
func _process(delta):
	# apply animations if we're not the server (unless we're the host)
	if not multiplayer.is_server() || multiplayerManager.host_mode_enabled:
		handleAnims(delta)
		updateAnimationTree()
	if not multiplayer.is_server():
		var diff = syncedPosition - position
		position += diff * .2
		
	isOnFloor = false
	if position.y <= 0:
		isOnFloor = true
		position.y = 0
	else:
		if floorRayCast.get_collider() != null:
			isOnFloor = true
	
	# Add the gravity.
	if not isOnFloor:
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		
	# probably broken
	if knockBacked > 0:
		knockBacked -= delta/knockBackTime
		if knockBacked < 0:
			knockBacked = 0
			
	# knockback???
	#if velocity.length() > 0:
		#velocity *= 0.96
		#if velocity.length() < 0.01:
			#velocity = Vector3.ZERO
			
	if not isDead:
		livingUpdate(delta)
	elif isSinking:
		position.y -= deathSinkRate * delta
		
	if multiplayer.is_server():
		syncedPosition = position
	move_and_slide()
	
func livingUpdate(delta):
	if isAttacking:
		if not attackPerformed and lastAttackTime + attackHitTime * 1000 < Time.get_ticks_msec():
			# current attack hits
			hitter.performHit()
			attackPerformed = true
			
			
		if lastAttackTime + attackCooldown * 1000 < Time.get_ticks_msec():
			# attack is over
			isAttacking = false
	
	# server handles the targeting clients get the servers target
	if multiplayer.is_server():
		updateTarget()
	else:
		updateTargetFromPlayerId()
	
	if currentTarget == null:
		currentAnimation = Animations.Idle
		return
		
	# face target
	var target = currentTarget.position
	target.y = 0
	direction.look_at(target)
	currentAnimation = Animations.Run
	var diff = currentTarget.position - position
	
	diff.y = 0 # Zero y vector
	
	if diff.length() < attackRange and not isAttacking:
		currentAnimation = Animations.Attack
		isAttacking = true
		attackPerformed = false
		lastAttackTime = Time.get_ticks_msec()
		
	# move towards target
	if diff.length() > minRange:
		var adjustedSpeed = lerpf(speed, 0, knockBacked) # idk if i broke this by changing away from positional movement
		var motion = (Vector2.UP).rotated(direction.rotation.y*-1) * delta * adjustedSpeed
		velocity.x = motion.x
		velocity.z = motion.y
		
	calculateStepProgress(delta)
	
func updateTarget():
	var minDistance = null
	var newTarget = null
	
	# remove target if they ded
	if currentTarget != null and currentTarget.isDead:
		currentTarget = null
		syncedTargetPlayerId = 0
		
	for player in gameManager.players.get_children():
		if player.isDead:
			continue
		var distance = (player.position - position).length()
		if minDistance == null or distance < minDistance:
			minDistance = distance
			newTarget = player
	
		
	if currentTarget == null and newTarget != null:
		currentTarget = newTarget
		syncedTargetPlayerId = newTarget.player_id
		return
	
	if currentTarget == null:
		return
		
	var currentDistance = (currentTarget.position - position).length()
	
	if minDistance + targetSwitchDistance < currentDistance:
		currentTarget = newTarget
		syncedTargetPlayerId = newTarget.player_id
	
	
func updateTargetFromPlayerId():
	currentTarget = null
	for player in gameManager.players.get_children():
		if player.player_id == syncedTargetPlayerId:
			currentTarget = player
			
func handleAnims(delta):
	for i in range(1, len(animationBlendValues)):
		# check if this is the currently animating blend value
		if int(currentAnimation) == i:
			if animationBlendValues[i] < 1:
				animationBlendValues[i] = lerpf(animationBlendValues[i], 1, delta/blendTime)
		else:
			if animationBlendValues[i] > 0:
				animationBlendValues[i] = lerpf(animationBlendValues[i], 0, delta/blendTime)
			
func updateAnimationTree():
	animationTree["parameters/Run/blend_amount"] = animationBlendValues[Animations.Run]
	animationTree["parameters/Death/blend_amount"] = animationBlendValues[Animations.Death]
	
func deathTimer():
	# perform a queue free in a little bit after death anim plays
	# remove colliders
	currentAnimation = Animations.Death
	hitter.queue_free()
	healthBar.queue_free()
	
	#spawnConsumables()
	# set velocity so model sinks into the ground
	await get_tree().create_timer(deathSinkTime).timeout
	isSinking = true
	collider.queue_free()
	
	if not multiplayer.is_server():
		return
	# create timer to remove enemy 
	await get_tree().create_timer(deathTime - deathSinkTime).timeout
	queue_free()
	
func spawnConsumables():
	if randf() > 0.5:
		spawnManager.spawnPotion()
	
	
# method to calculate when a player should take a step.
# potentially we would hook this into internal kinimatics later or have it based on animations
# there is a "time per step" value and when that amount of time has been spent moving we "take a step"
# running makes this time accumulate faster and crouching slower
func calculateStepProgress(delta):
	if velocity.length() == 0 or !isOnFloor:
		return
	var stepDelta = delta * 1000
	var state = Enums.movementState.walking
	
	nextStepProgress += stepDelta
	if nextStepProgress >= timeForAvgStep:
		forceStep(state)
		
# this is called when a step needs to be taken
# it refers to the state of the char motion when the step happened.
# right now there is walking running and crouching
func forceStep(state: int):
	nextStepProgress -= timeForAvgStep
	footStepGenerator.step(state)


func _on_hittable_hit(hitter):
	# we are hit
	#print("hit by %s" % hitter.controller.name)
	# knockback
	var diff = hitter.controller.position - position
	velocity.x = 0 
	velocity.z = 0 
	velocity -= diff.normalized() * hitter.knockbackForce
	knockBacked = 1
	takeDamage(hitter)
	
func takeDamage(hitter:Hitter):
	health -= hitter.damage
	# damage screen effects
