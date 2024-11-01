extends Node

var pointsPerMin = 20

var nextSpawnAvailable : float = 0.0
var maxSpawnPerTick = 10

enum Enemies {Skelly}
var skelly : PackedScene #preload("res://monsters/Skelly.tscn")

func _ready():
	nextSpawnAvailable = Time.get_ticks_msec()

func _physics_process(delta):
	if not gameManager.isGameInProgress:
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
	var distance = 10
	var angle = randf()*2*3.14
	var offset = Vector3(distance * cos(angle), 0, distance * sin(angle))
	offset += gameManager.players.get_child(0).position
	newEnemy.position = offset
	newEnemy.syncedPosition = offset
	newEnemy.spawnManager = self
	%Spawns.add_child(newEnemy, true)
