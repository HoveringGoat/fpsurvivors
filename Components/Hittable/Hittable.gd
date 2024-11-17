extends Area3D

class_name Hittable

signal hit(hitter: Hitter)

func killed(hitter: Hitter) -> void:
	if is_instance_valid(hitter):
		hitter.killed.emit(self)
