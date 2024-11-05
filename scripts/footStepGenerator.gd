extends Node3D

@export var footstepAudios : Array[AudioStream]
@onready var footStepAudioPlayer = $FootStepAudioPlayer

func step(state : int):
	print("step")
	# char takes a step. Play sound according to current speed
	var randIndex = randi_range(0,len(footstepAudios)-1)
	footStepAudioPlayer.stream = footstepAudios[randIndex]
	# walking default audio volume
	footStepAudioPlayer.volume_db = -12
	# running 
	if state == 1:
		footStepAudioPlayer.volume_db += 2
		pass
	# crouching
	elif state == 2:
		footStepAudioPlayer.volume_db -= 2
		pass
	footStepAudioPlayer.play()
	

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
