extends Node

class LootTable:
	var min:int
	var max:int
	var loot:Dictionary

var loot_tables:Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	read_loot_tables()
	print(loot_tables)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func get_table(key):
	return loot_tables.get(key)

func read_loot_tables():
	var dir = DirAccess.open("res://LootTables/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				var name = file_name.split(".")[0]
				
				var table:LootTable = load_file(file_name)
				
				loot_tables[name] = table
			file_name = dir.get_next()
	pass
	
func load_file(file_name):
	
	var file = FileAccess.open("res://LootTables/" + file_name, FileAccess.READ)
	
	var dict = {}
	var line = file.get_csv_line()
	var min = line[0]
	var max = line[1]
	
	line = file.get_csv_line()
	while line.size() == 2:
		dict[line[0]] = int(line[1])
		line = file.get_csv_line()
	
	var table:LootTable = LootTable.new()
	table.loot = dict
	table.min = min
	table.max = max
	
	return table

func get_rand_item(loot_table:String):
	var table = get_table(loot_table)
	var total = 0
	for values in table.loot.values():
		total += values
	var rand = randi_range(0,total-1)
	
	for key in table.loot.keys():
		if rand < table.loot.get(key):
			return key
		else:
			rand -= table.loot.get(key)
		
		
