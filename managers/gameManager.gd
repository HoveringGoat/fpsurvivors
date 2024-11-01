extends Node

var isGameInProgress : bool = false

enum Worlds {world1}
var level : Node3D = null
var players : Node3D = null
var difficulty : float = 1.0
var difficultyUpgradeInterval = 5000
var lastDifficultyUpgradeTime = null
var spawnManager : Node

func _ready():
	if OS.has_feature("dedicated_server"):
		print("Starting dedicated server...")
		multiplayerManager.become_host()
		
func startGame():
	isGameInProgress = true
	
func endGame():
	isGameInProgress = false
	multiplayerManager.end_game()

func _process(delta):
	if isGameInProgress:
		if lastDifficultyUpgradeTime == null:
			lastDifficultyUpgradeTime = Time.get_ticks_msec()
			return
			
		if lastDifficultyUpgradeTime + difficultyUpgradeInterval < Time.get_ticks_msec():
			difficulty += 1
			print("difficulty increased: %s" % difficulty)
			spawnManager.pointsPerMin += 5
			lastDifficultyUpgradeTime = Time.get_ticks_msec()
		
func loadWorld(world):
	isGameInProgress = true
	rpc("loadWorldRpc", world)
	
@rpc("call_local", "reliable")
func loadWorldRpc(world : PackedScene):
	assert(level != null)
	assert(players != null)
	var newWorld = world.instantiate()
	
	level.add_child(newWorld)
	
	# move all player chars to around 0,0
	moveAllPlayersAround(Vector3(0,0,0))
	
	spawnManager = newWorld.get_node("SpawnManager")
	
	
func returnToLobby():
	assert(level != null)
	assert(players != null)
	isGameInProgress = false
	
	if level.get_child_count() > 0:
		level.get_child(0).queue_free()
	
	# move all player chars to around 0,0
	moveAllPlayersAround(Vector3(0,0,0))
	
func moveAllPlayersAround(vector):
	var distance = 2
	for player in players.get_children():
		var offset = Vector3(randf_range(distance * -1, distance), 0, randf_range(distance * -1, distance))
		player.position = vector + offset
