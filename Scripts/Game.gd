extends Node3D

const CONTAINER = preload("res://Scenes/Container.tscn")
const CHARACTER = preload("res://addons/fpc/character.tscn")
const INVENTORY = preload("res://Scenes/inventory.tscn")

var container
# Called when the node enters the scene tree for the first time.
func _ready():
	#multiplayer.object_configuration_add()
	Server.game = self
	#multiplayer_spawner.add_spawnable_scene("res://addons/fpc/character.tscn")
	pass # Replace with function body.

func start_game():
	print("hello")
	var x = 0
	for player in Server.player_list:
		x += 5
		var new_char = CHARACTER.instantiate()
		new_char.name = "Char" + str(player)
		new_char.position.x = x
		$Players.add_child(new_char)
		new_char.set_player_id.rpc(player)
		new_char.set_camera_enable.rpc_id(player, true)
		
		new_char.inventory.create_inventory.rpc(4,1, new_char.inventory.get_instance_id())
		#create_item_in_inventory(new_char.inventory, "TestItem2")
		
		new_char.create_backpack_slot_inv.rpc(new_char.backpack_slot_inv.get_instance_id())
		
		
	container = spawn_container(Vector3(5,1,5))
	
	#multiplayer_spawner.spawn()
	return

func spawn_container(pos):
	
	var container = CONTAINER.instantiate()
	$Containers.add_child(container)
	container.position = pos
	container.inventory.create_inventory.rpc(6,5, container.inventory.get_instance_id())
	fill_container(container, 1)
	return container
	
func create_item_in_inventory(inventory, item_name):
	var item = inventory.create_item(item_name)
	if !item:
		return
		
	if item.get_property("type") == "backpack":
		var new_inv = INVENTORY.instantiate()
		$InventoryContainers.add_child(new_inv)
		new_inv.create_inventory.rpc(item.get_property("width"),item.get_property("height"), new_inv.get_instance_id())
		#new_inv.connect_item.rpc(item.get_instance_id())
		inventory.connect_item.rpc(item.get_instance_id(), new_inv.get_instance_id())
		#item.set_property("connected_inv", new_inv.get_instance_id())
		#print("property: ", item.get_property("connected_inv"))
	return

func fill_container(container, num):
	for i in range(1):
		create_item_in_inventory(container.inventory, "Backpack")
	return

func create_control_inventory(inventory_grid):
	if inventory_grid is InventoryGrid:
		var ctrl_inv = CtrlInventoryGrid.new()
		ctrl_inv.inventory = inventory_grid
		$Inventory/HBoxContainer.add_child(ctrl_inv)
	elif inventory_grid is Inventory:
		print("HELLO THERE")
		var ctrl_inv = CtrlInventory.new()
		ctrl_inv.inventory = inventory_grid
		ctrl_inv.custom_minimum_size.x = 64
		$Inventory/HBoxContainer.add_child(ctrl_inv)
	return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
