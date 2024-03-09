extends Node

var inventory_grid = null

var inv_dict = {}
var inventory_id

var connected_item_id = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

@rpc("authority", "call_local", "reliable")
func create_sizeless_inventory(id):
	print("creating sizeless inventory")
	inventory_grid = Inventory.new()
	inventory_grid.item_protoset = ResourceLoader.load("res://ItemProtoset.tres")
	inventory_id = id
	Server.create_control_inventory(inventory_grid)

@rpc("authority", "call_local", "reliable")
func create_inventory(width,height, id):
	print("creating inventory: (", width, ", ", height, ")")
	inventory_grid = InventoryGrid.new()
	inventory_grid.item_protoset = ResourceLoader.load("res://ItemProtoset.tres")
	inventory_grid.size.x = width
	inventory_grid.size.y = height
	inventory_id = id
	Server.create_control_inventory(inventory_grid)

func create_item(item_name):
	var item = null
	item = inventory_grid.create_and_add_item(item_name)
	if item:
		inv_dict[item.get_instance_id()] = item
		replicate_item.rpc(item.get_instance_id(), item_name)
	return item

@rpc("authority", "call_local", "reliable")
func connect_item(item_id, inv_id):
	inv_dict[item_id].set_property("connected_inv", inv_id)
	return

@rpc("authority", "call_remote", "reliable")
func replicate_item(item_id, item_name):
	return

@rpc("any_peer", "call_remote", "reliable")
func request_move_item_same_inv(item_id, item_pos):
	
	print(inv_dict)
	
	if !inv_dict.has(item_id):
		print("something went wrong...")
		return 
	
	var item = inv_dict[item_id]
	var success = inventory_grid.move_item_to(item, item_pos)
	send_move_item_same_inv.rpc(item_id, inventory_grid.get_item_position(item))
	if success:
		print("moved item")
	else:
		print("failed to move item")
	return

@rpc("authority", "call_remote", "reliable")
func send_move_item_same_inv(item_id, item_pos):
	return
	
@rpc("authority", "call_remote", "reliable")
func remove_item(item_id):
	return
	
@rpc("authority", "call_remote", "reliable")
func add_item(item_name, item_id, item_pos):
	return
