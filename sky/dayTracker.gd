extends WorldEnvironment

@export var sky = preload("res://sky/sky.tres")
# Called when the node enters the scene tree for the first time.
@export var directional_light_3d : DirectionalLight3D

@export var time_of_day : float
var lengthOfDay : int = 3*60

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_of_day += delta / lengthOfDay
	
	if time_of_day > 1 or time_of_day < 0:
		time_of_day =fmod(time_of_day, 1) + 1
		
	# time of day .5 = midday
	# directional light.x = 270 is straight down
	directional_light_3d.rotation.x = time_of_day * 2* PI + PI/2
	 
	#print("time: %.3f" % time_of_day)
	#print("rotation: %s" % directional_light_3d.rotation.x)
	sky.set_shader_parameter("time_of_day", time_of_day)
