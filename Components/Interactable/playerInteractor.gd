extends Interactor

@export var player: CharacterBody3D

var cached_closest: Interactable
var player_id = null

func _ready() -> void:
	controller = player
	player_id = player.player_id

func _physics_process(_delta: float) -> void:
	var new_closest: Interactable = get_closest_interactable()
	if new_closest != cached_closest:
		if is_instance_valid(cached_closest):
			unfocus(cached_closest)
		if new_closest:
			focus(new_closest)
		cached_closest = new_closest
	if player.inputs.interact and multiplayer.is_server():
		if is_instance_valid(cached_closest):
			interact(cached_closest)

#func _on_area_exited(area: Interactable) -> void:
	#if multiplayer.is_server():
		#print("serverw")
	#if cached_closest == area:
		#unfocus(area)
