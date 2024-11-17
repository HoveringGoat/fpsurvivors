extends Node

var pointsPerMin = 20

var nextSpawnAvailable : float = 0.0
var maxSpawnPerTick = 10

enum Enemies {Skelly}
var skelly : PackedScene = preload("res://chars/enemy/Skelly.tscn")
@onready var spawns : Node = %Spawns
var max_spawn_count : int = 5

func _ready():
	nextSpawnAvailable = Time.get_ticks_msec() + 500

func _physics_process(delta):
	
	if not gameManager.isGameInProgress:
		return
		
	if spawns.get_child_count() >= max_spawn_count:
		return
	
	var count = 0
	while Time.get_ticks_msec() > nextSpawnAvailable and count < maxSpawnPerTick:
		var pointCost = getEnemyToSpawn()
		
		# convert point cost to adjust time in ms for this spawn
		var timeCost = pointCost/float(pointsPerMin) * 60 * 1000
		# print ("spawn cost %s ms" % timeCost)
		nextSpawnAvailable += timeCost
		count += 1
	
func getEnemyToSpawn() -> int:
	var enemy = Enemies.Skelly
	# roll which enemy to spawn
	# spawn enemy
	# return point cost of spawning enemy
	spawn(enemy)
	return 1
	
func spawn(enemy):
	var newEnemy = null
	match enemy:
		Enemies.Skelly:
			newEnemy = skelly.instantiate()
		_:
			print("no enemy found")
			return
	# this can spawn around other ppl
	var distance = randf_range(10, 20)
	var angle = randf()*2*3.14
	var offset = Vector3(distance * cos(angle), 0, distance * sin(angle))
	offset += gameManager.players.get_child(0).position
	offset.y = 0
	newEnemy.position = offset
	newEnemy.syncedPosition = offset
	newEnemy.spawnManager = self
	spawns.add_child(newEnemy, true)
