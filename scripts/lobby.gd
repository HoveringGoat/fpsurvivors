extends Node3D

@export var worlds : Array[PackedScene]

# Called when the node enters the scene tree for the first time.
func _ready():
	# if is host

	gameManager.level = %Level
	gameManager.players = %Players
	multiplayerManager.become_host()
	gameManager.loadWorld(worlds[0])
	gameManager.isGameInProgress = true
	#gameManager.isGameInProgress = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
