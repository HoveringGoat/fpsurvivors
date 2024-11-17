extends Node3D

@export var footstepAudios : Array[AudioStream]
@onready var footStepAudioPlayer = $FootStepAudioPlayer
@export var baseSoundLevel : float = -20
func step(state : int):
	# char takes a step. Play sound according to current speed
	var randIndex = randi_range(0,len(footstepAudios)-1)
	footStepAudioPlayer.stream = footstepAudios[randIndex]
	# walking default audio volume
	footStepAudioPlayer.volume_db = baseSoundLevel
	# running 
	if state == Enums.movementState.running:
		footStepAudioPlayer.volume_db += 3
		pass
	# crouching
	elif state == Enums.movementState.crouching:
		footStepAudioPlayer.volume_db -= 3
		pass
	footStepAudioPlayer.play()
	

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
