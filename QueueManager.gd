extends Node2D

var PotatoPerson = preload("res://PotatoPerson.tscn")
var path: Path2D
var curve: Curve2D
var max_potatoes: int = 10
var potatoes: Array = []
var spawn_point: Vector2

func _ready():
	var path_node_path: NodePath = ^"../Path2D (SpuddyQueue)"
	path = get_node(path_node_path)
	curve = path.curve
	spawn_point = curve.get_point_position(0)
	print("Path loaded, spawn point set to: ", spawn_point)

func add_potato(potato_info: Dictionary):
	if potatoes.size() >= max_potatoes:
		print("Maximum number of potatoes reached")
		return
	
	var potato = PotatoPerson.instantiate()
	add_child(potato)
	potato.position = spawn_point
	potato.current_point = 0
	potato.target_point = 0
	potato.potato_info = potato_info
	potatoes.push_front(potato)
	print("Potato added. Total potatoes: ", potatoes.size())
	print("Added potato info: ", potato_info)
	update_positions()

func remove_potato() -> Dictionary:
	if potatoes.size() > 0:
		var potato = potatoes.pop_back()
		var info = potato.potato_info
		potato.queue_free()
		print("Potato removed. Total potatoes: ", potatoes.size())
		print("Removed potato info: ", info)
		update_positions()
		return info
	return {}

func update_positions():
	var point_count = curve.get_point_count()
	var potato_count = potatoes.size()
	print("Updating positions for ", potato_count, " potatoes")
	
	if potato_count > 0:
		for i in range(potato_count):
			var target_point = min(point_count - 1, point_count - 1 - i)
			potatoes[potato_count - 1 - i].target_point = target_point
			print("Potato ", potato_count - 1 - i, " target point set to: ", target_point)

func _process(delta):
	for potato in potatoes:
		if potato.current_point < potato.target_point:
			var next_point = potato.current_point + 1
			var current_pos = curve.get_point_position(potato.current_point)
			var next_pos = curve.get_point_position(next_point)
			var target_pos = potato.position.move_toward(next_pos, delta * 50)
			
			if target_pos.distance_to(next_pos) < 1:
				potato.current_point = next_point
			
			potato.position = target_pos
		else:
			var target_pos = curve.get_point_position(potato.target_point)
			potato.position = potato.position.move_toward(target_pos, delta * 50)

func get_front_potato_info() -> Dictionary:
	if potatoes.size() > 0:
		return potatoes.back().potato_info
	return {}

func debug_add_potatoes(count: int):
	for i in range(count):
		var info = {
			"name": "Debug Potato " + str(i),
			"type": "Debug Type",
			"condition": "Fresh"
		}
		add_potato(info)
	print("Debug: Added ", count, " potatoes")
