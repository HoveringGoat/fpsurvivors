extends Area3D

class_name HitSource

@export var controller: CharacterBody3D
@export var knockbackForce = 0.0
@export var damage = 10

func hit(hitTarget: HitTarget) -> void:
	if is_instance_valid(hitTarget):
		hitTarget.hit.emit(self)

# Returns the closest overlapping Interactable or null if there isn't one.

func performHit():
	var list: Array[Area3D] = get_overlapping_areas()
	print("hitting")
	for hit in list:
		hit(hit as HitTarget)
		
