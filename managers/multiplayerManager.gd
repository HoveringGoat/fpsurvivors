extends Node

const SERVER_PORT = 10567
const SERVER_IP = "127.0.0.1"

var playerChar = preload("res://chars/player.tscn")

var _players_spawn_node
var host_mode_enabled = false

func become_host():
	print("Starting host!")
	_players_spawn_node = get_tree().get_current_scene().get_node("Players")
	
	host_mode_enabled = true
	
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	
	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)
	
	
	if not OS.has_feature("dedicated_server"):
		_add_player_to_game(1)
	
func join_as_peer(serverIp):
	print("Player joining")
	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(serverIp, SERVER_PORT)
	
	multiplayer.multiplayer_peer = client_peer

func _add_player_to_game(id: int):
	print("Player %s joined the game!" % id)
	
	var player_to_add = playerChar.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	_players_spawn_node.add_child(player_to_add, true)
	
func _del_player(id: int):
	print("Player %s left the game!" % id)
	if not _players_spawn_node.has_node(str(id)):
		return
	_players_spawn_node.get_node(str(id)).queue_free()
	
	
	
	
	
	
	
	
	
	
	
