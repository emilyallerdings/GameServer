extends StaticBody3D

@onready var inventory = $Inventory

# Called when the node enters the scene tree for the first time.
func _ready():
#	inventory = get_parent().get_parent().get_node("Inventory")
	pass # Replace with function body.

#@rpc("authority", "call_local", "reliable")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func get_inventory():
	return inventory

func interact():
	#print(inventory)
	#if inventory:
		#inventory.open_inventory($InventoryGrid)
	return
	
