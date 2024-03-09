extends Control

var player_list = []
var player_lobby_list = {}
var game

# Called when the node enters the scene tree for the first time.
func _ready():
	
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	
	var peer = ENetMultiplayerPeer.new()
	#peer.set_bind_ip("192.168.56.1")
	print(peer.create_server(1420, 10))
	multiplayer.multiplayer_peer = peer
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func create_control_inventory(inventory_grid):
	game.create_control_inventory(inventory_grid)
	
func peer_connected(id):
	player_list.append(id)
	print(player_list)
	return

func peer_disconnected(id):
	
	if player_lobby_list.has(id):
		
		remove_player.rpc(id)
		player_lobby_list.erase(id)
		
		
	if player_list.has(id):
		player_list.erase(id)
	return

@rpc("any_peer")
func send_ready(isready):
	var player_id = multiplayer.get_remote_sender_id()
	player_lobby_list[player_id].isready = isready
	send_client_ready.rpc(player_id, isready)
	
	var all_ready = true
	for player in player_lobby_list.values():
		if player.isready == false:
			all_ready = false
	if all_ready:
		send_client_start_game.rpc()
		game.start_game()
	return

@rpc("any_peer")
func send_server_player_info(player_name):
	var player_id = multiplayer.get_remote_sender_id()

	for player in player_lobby_list.values():
		create_player.rpc_id(player_id, player.id, player.pname, player.isready)
	
	if !add_player_to_server_lobby_list(player_id, player_name):
		return
		
	create_player.rpc(player_id, player_name,false)

func add_player_to_server_lobby_list(id, player_name):
	if player_lobby_list.keys().has(id):
		return false
		
	var newPlayerInLobby = PlayerInLobby.new()
	newPlayerInLobby.pname = player_name
	newPlayerInLobby.id = id
	newPlayerInLobby.isready = false
	player_lobby_list[id] = newPlayerInLobby
	return true

@rpc("any_peer", "reliable")
func request_transfer_item(item_id, inv1_id, inv2_id, new_pos):
	print("recieved transfer request")
	print(item_id, ", ", inv1_id, ", ", inv2_id, ", ", new_pos)
	var old_inv = instance_from_id(inv1_id)
	var new_inv = instance_from_id(inv2_id)
	var item = instance_from_id(item_id)
	

	
	if old_inv.inventory_grid is InventoryGrid and new_inv.inventory_grid is InventoryGrid:
		print("item to transfer: ", item_id, " to pos ", new_pos)
		print("item at ", new_pos, " is ", new_inv.inventory_grid.get_item_at(new_pos))
		
		var success = old_inv.inventory_grid.transfer_to(item, new_inv.inventory_grid, new_pos)
		print("transfer:",success, " item is now at ", new_inv.inventory_grid.get_item_position(item))
		print("item in new inv:", new_inv.inventory_grid.has_item(item)," item in old inv:", old_inv.inventory_grid.has_item(item))
		if success:
			print("transfered item to ", new_pos)
			old_inv.inv_dict.erase(item_id)
			new_inv.inv_dict[item_id] = item
			old_inv.remove_item.rpc(item_id)
			new_inv.add_item.rpc(item.prototype_id, item_id, new_pos)
		return
	elif old_inv.inventory_grid is InventoryGrid and new_inv.inventory_grid is Inventory:
		print("HELLO")
		#old_inv.inventory_grid.remove_item(item)
		#var success = new_inv.inventory_grid.create_and_add_item(item)
		var success = old_inv.inventory_grid.transfer(item, new_inv.inventory_grid)
		if success:
			print("transfered item")
			old_inv.inv_dict.erase(item_id)
			new_inv.inv_dict[item_id] = item
			old_inv.remove_item.rpc(item_id)
			new_inv.add_item.rpc(item.prototype_id, item_id, null)
			
	elif old_inv.inventory_grid is Inventory and new_inv.inventory_grid is InventoryGrid:
		
		var success = old_inv.inventory_grid.transfer(item, new_inv.inventory_grid)
		
		if success:
			new_inv.inventory_grid.move_item_to(item, new_pos)
			print("transfered item")
			old_inv.inv_dict.erase(item_id)
			new_inv.inv_dict[item_id] = item
			old_inv.remove_item.rpc(item_id)
			new_inv.add_item.rpc(item.prototype_id, item_id, null)
			
		#TODO handle non-grid to grid 
		return
			
@rpc("authority")
func create_player(id, player_name):
	return
	
@rpc("authority")
func remove_player(id):
	return

@rpc("authority")
func send_client_ready(id, isready):
	return
	
@rpc("authority")
func send_client_start_game():
	return
