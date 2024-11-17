extends Node3D

@onready var healthbar : TextureProgressBar = %TextureProgressBar
@export var healthyColor : Color
@export var hurtColor : Color
@export var animTime : float = 0.1
# percentage from 0-1

func _ready():
	updateSize()
		
var percentage : float = 100.0:
	set(value):
		if value != percentage:
			if value < 0:
				value = 0
			percentage = value * 100
			updateSize()
			

func updateSize():
	var tween = create_tween()
	tween.tween_property(healthbar, "value", percentage, animTime)
	healthbar.tint_progress = hurtColor.lerp(healthyColor, percentage/ 100)
