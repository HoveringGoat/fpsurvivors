extends Area3D

class_name Hitter

@export var controller: CharacterBody3D
@export var knockbackForce = 0.0
@export var damage = 10

# todo can have different damage types
signal killed(hittable: Hittable)

func hit(hittable: Hittable) -> void:
	if is_instance_valid(hittable):
		hittable.hit.emit(self)

# Returns the closest overlapping Interactable or null if there isn't one.

func performHit():
	var list: Array[Area3D] = get_overlapping_areas()
	for hittable in list:
		hit(hittable as Hittable)
		
