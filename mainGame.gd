# Main.gd (Main scene script)
extends Node2D

var current_potato
var score = 0
var time_left = 5  # seconds per decision
var current_rules = []
var queue_manager: Node2D

# Dragging system
var draggable_sprites = []
var dragged_sprite = null
var drag_offset = Vector2()
const PHYSICAL_STAMP_Z_INDEX = 100
const APPLIED_STAMP_Z_INDEX = 50
const PASSPORT_Z_INDEX = 0

# Stamp system
const STAMP_ANIMATION_DURATION = 0.3  # Duration of the stamp animation in seconds
const STAMP_MOVE_DISTANCE = 50  # How far the stamp moves down

func generate_rules():
	current_rules = [
		"Purple Majesty always welcome.",
		"We need extra eyes!",
		"No Russet Burbanks allowed!",
		"All potatoes must be Fresh!",
		"Peeled potatoes BANNED today!",
		"No potatoes over 5 years old.",
		"Only males potatoes allowed today.",
		"Potatoes from Spudland must be arrested.",
		"Expired potatoes are not allowed."
	]
	# Randomly select 2-3 rules
	current_rules.shuffle()
	current_rules = current_rules.slice(0, randi() % 2 + 2)
	update_rules_display()

func update_rules_display():
	$"Label (RulesLabel)".text = "Current Rules:\n" + "\n".join(current_rules)
	
func is_potato_valid(potato_info: Dictionary) -> bool:
	for rule in current_rules:
		match rule: 
			"Purple Majesty always welcome.":
				if potato_info.type == "Purple Majesty":
					return true
			"We need extra eyes!":
				if potato_info.condition == "Extra Eyes":
					return true
			"No Russet Burbanks allowed!":
				if potato_info.type == "Russet Burbank":
					return false
			"All potatoes must be Fresh!":
				if potato_info.condition != "Fresh":
					return false
			"Peeled potatoes BANNED today!": 
				if potato_info.condition == "Peeled":
					return false
			"No potatoes over 5 years old.":
				var age = calculate_age(potato_info.date_of_birth)
				if age > 5: 
					return false
			"Only males potatoes allowed today.":
				if potato_info.sex != "Male":
					return false
			"Potatoes from Spudland must be arrested.":
				if potato_info.country_of_issue == "Spudland":
					return false
			"Expired potatoes are not allowed.":
				if is_expired(potato_info.expiration_date):
					return false
	return true

func _ready():
	queue_manager = $"Node2D (QueueManager)"  # Make sure to add QueueManager as a child of Main
	generate_rules()
	new_potato()
	draggable_sprites = [
		$"Sprite2D (Open Passport)",
		$"Sprite2D (Approval Stamp)",
		$"Sprite2D (Rejection Stamp)"
	]
	# Ensure sprites are in the scene tree and set initial z-index
	for sprite in draggable_sprites:
		if not is_instance_valid(sprite):
			push_warning("Sprite not found: " + sprite.name)
		else:
			if "Stamp" in sprite.name:
				sprite.z_index = PHYSICAL_STAMP_Z_INDEX
			else:
				sprite.z_index = PASSPORT_Z_INDEX

func _process(delta):
	$"Label (TimeLabel)".text = "Time: " + str(int($Timer.time_left))

func new_potato():
	var potato_info = {
		"name": get_random_name(),
		"type": get_random_type(),
		"condition": get_random_condition(),
		"sex": get_random_sex(), 
		"country_of_issue": get_random_country(),
		"date_of_birth": get_random_date(1, 10),
		"expiration_date": get_random_date(0, 2)
	}
	queue_manager.add_potato(potato_info)
	update_potato_info_display(potato_info)
	update_potato_texture(potato_info.type)
	$Timer.start(time_left)
	
func update_potato_info_display(potato_info: Dictionary):
	$"Sprite2D (Open Passport)/Label (PotatoHeader)".text = """{name}""".format(potato_info)
	$"Sprite2D (Open Passport)/Label (PotatoInfo)".text = """{date_of_birth}
	{sex} 
	{country_of_issue}
	{expiration_date} 
	{type}
	{condition}
	""".format(potato_info)

func generate_potato():
	# Generate random potato characteristics
	var potato = {
		"name": get_random_name(),
		"type": get_random_type(),
		"condition": get_random_condition(),
	}
	potato.description = "Name: %s\nType: %s\nCondition: %s" % [potato.name, potato.type, potato.condition]
	return potato

func get_random_name():
	var first_names = [
		"Spud", "Tater", "Mash", "Spudnik", "Tater Tot", "Mr. Potato", "Chip", 
		"Murph", "Yam", "Tato", "Spuddy", "Tuber"
		]
	var last_names = [
		"Ouwiw", "Sehi", "Sig", "Heechou", "Oufug", "Azej", 
		"Ekepa", "Nuz", "Chegee", "Kusee", "Houf", "Fito", "Mog", "Urife"
		]
	return "%s %s" % [first_names[randi() % first_names.size()], last_names[randi() % last_names.size()]]

func get_random_type():
	var types = ["Russet Burbank", "Yukon Gold", "Sweet Potato", "Purple Majesty", "Red Bliss"]
	return types[randi() % types.size()]

func get_random_condition():
	var conditions = ["Fresh", "Extra Eyes", "Rotten", "Sprouted", "Dehydrated", "Frozen"]
	return conditions[randi() % conditions.size()]

func get_random_sex():
	return ["Male", "Female"][randi() % 2]
	
func get_random_country():
	var countries = [
		"Spudland", "Potatopia", "Tuberstan", "North Yamnea", "Spuddington", 
		"Tater's Cross", "Mash Meadows", "Tuber Valley", "Chip Hill", 
		"Murphy's Landing", "Colcannon Corner", "Pratie Point"
		]
	return countries[randi() % countries.size()]
	
func get_random_date(years_ago_start: int, years_ago_end: int) -> String:
	var current_date = Time.get_date_dict_from_system()
	var year = current_date.year - years_ago_start - randi() % (years_ago_end - years_ago_start + 1)
	var month = randi() % 12 + 1
	var day = randi() % 28 + 1
	return "%04d-%02d-%02d" % [year, month, day]
	
func calculate_age(date_of_birth: String) -> int:
	var current_date = Time.get_date_dict_from_system()
	var birth_date = Time.get_datetime_dict_from_datetime_string(date_of_birth, false)
	var age = current_date.year - birth_date.year
	if current_date.month < birth_date.month or (current_date.month == birth_date.month and current_date.day < birth_date.day):
		age -= 1
	return age	
	
func is_expired(expiration_date: String) -> bool:
	var current_date = Time.get_date_dict_from_system()
	var expiry_date = Time.get_datetime_dict_from_datetime_string(expiration_date, false)
	if current_date.year > expiry_date.year:
		return true
	elif current_date.year == expiry_date.year:
		if current_date.month > expiry_date.month: 
			return true
		elif current_date.month == expiry_date.month:
			return current_date.day > expiry_date.day
	return false
	
func _on_button_welcome_button_pressed() -> void:
	process_decision(true)

func _on_button_no_entry_button_pressed() -> void:
	process_decision(false)

func process_decision(allowed):
	var potato_info = queue_manager.remove_potato()
	var correct_decision = is_potato_valid(potato_info)
	
	if (allowed and correct_decision) or (!allowed and !correct_decision):
		score += 1
		$"Label (JudgementInfo)".text = "You made the right choice, officer."
	else:
		$"Label (JudgementInfo)".text = "You have caused unnecessary suffering, officer..."
		score -= 1
	
	$"Label (ScoreLabel)".text = "Score: " + str(score)
	new_potato()
	
	if randi() % 5 == 0:  # 20% chance to change rules
		generate_rules()

func peek_front_potato():
	var front_potato_info = queue_manager.get_front_potato_info()
	# Use front_potato_info as needed

func _on_timer_timeout():
	# Player ran out of time, count as wrong decision
	score += 0
	$"Label (JudgementInfo)".text = "You run out of time and another customs officer beckons the spud over."
	$"Label (ScoreLabel)".text = "Score: " + str(score)
	if randi() % 5 == 0:  # 20% chance to change rules
		generate_rules()
	new_potato()

func update_potato_texture(potato_type: String):
	var texture_path = ""
	var texture_path_passport_photo = ""
	match potato_type:
		"Purple Majesty":
			texture_path = "res://potatoes/heads/purple_majesty_head.png"
			texture_path_passport_photo = "res://potatoes/document_photos/purple_majesty.png"
		"Red Bliss":
			texture_path = "res://potatoes/heads/red_bliss_head.png"
			texture_path_passport_photo = "res://potatoes/document_photos/red_bliss.png"
		"Russet Burbank":
			texture_path = "res://potatoes/heads/russet_burbank_head.png"
			texture_path_passport_photo = "res://potatoes/document_photos/russet_burbank.png"
		"Sweet Potato":
			texture_path = "res://potatoes/heads/sweet_potato_head.png"
			texture_path_passport_photo = "res://potatoes/document_photos/sweet_potato.png"
		"Yukon Gold":
			texture_path = "res://potatoes/heads/yukon_gold_head.png"
			texture_path_passport_photo = "res://potatoes/document_photos/yukon_gold.png"
	
	if texture_path != "":
		$"Sprite2D (PotatoMugshot)".texture = load(texture_path)
		
	if texture_path_passport_photo != "":
		$"Sprite2D (Open Passport)/Sprite2D (PassportPhoto)".texture = load(texture_path_passport_photo)


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var mouse_pos = get_global_mouse_position()
				dragged_sprite = find_topmost_sprite_at(mouse_pos)
				if dragged_sprite:
					drag_offset = mouse_pos - dragged_sprite.global_position
			else:
				dragged_sprite = null
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if dragged_sprite and "Stamp" in dragged_sprite.name:
				apply_stamp(dragged_sprite)
			# Removed the line that set dragged_sprite to null
	
	elif event is InputEventMouseMotion and dragged_sprite:
		dragged_sprite.global_position = get_global_mouse_position() - drag_offset

func find_topmost_sprite_at(pos: Vector2):
	var topmost_sprite = null
	for sprite in draggable_sprites:
		if sprite.get_rect().has_point(sprite.to_local(pos)):
			if not topmost_sprite or sprite.z_index > topmost_sprite.z_index:
				topmost_sprite = sprite
	return topmost_sprite

func apply_stamp(stamp):
	var mouse_pos = get_global_mouse_position()
	var stamped_object = find_stampable_object_at(mouse_pos)
	if stamped_object:
		# Hide the original stamp and make it non-draggable
		stamp.visible = false
		draggable_sprites.erase(stamp)
		dragged_sprite = null
		
		# Create a temporary visual stamp that moves down
		var temp_stamp = Sprite2D.new()
		temp_stamp.texture = stamp.texture
		temp_stamp.position = stamp.position
		temp_stamp.z_index = PHYSICAL_STAMP_Z_INDEX
		add_child(temp_stamp)
		
		# Create the final stamp that will be left on the passport
		var final_stamp = Sprite2D.new()
		var stamp_texture = "res://approved_stamp.png" if "Approval" in stamp.name else "res://denied_stamp.png"
		final_stamp.texture = load(stamp_texture)
		var final_stamp_x = stamp.position.x
		var final_stamp_y = stamp.position.y + STAMP_MOVE_DISTANCE
		var final_stamp_position = Vector2(final_stamp_x, final_stamp_y)
		final_stamp.position = stamped_object.to_local(final_stamp_position)
		final_stamp.z_index = APPLIED_STAMP_Z_INDEX
		final_stamp.modulate.a = 0  # Start invisible
		stamped_object.add_child(final_stamp)
		
		# Create and start the animation
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Move down
		tween.tween_property(temp_stamp, "position:y", 
			temp_stamp.position.y + STAMP_MOVE_DISTANCE, 
			STAMP_ANIMATION_DURATION / 2)
		
		# Fade in the final stamp when we hit the paper
		tween.tween_property(final_stamp, "modulate:a", 
			1.0, 0.1).set_delay(STAMP_ANIMATION_DURATION / 2)
		
		# Move back up
		tween.chain().tween_property(temp_stamp, "position:y", 
			temp_stamp.position.y, 
			STAMP_ANIMATION_DURATION / 2)
		
		# Remove the temporary stamp and restore the original stamp
		tween.chain().tween_callback(func():
			temp_stamp.queue_free()
			stamp.visible = true  # Make the original stamp visible again
			draggable_sprites.append(stamp)  # Re-add the original stamp to draggable_sprites
		)
		
func find_stampable_object_at(pos: Vector2):
	for sprite in draggable_sprites:
		if "Passport" in sprite.name and sprite.get_rect().has_point(sprite.to_local(pos)):
			return sprite
	return null

func get_highest_z_index():
	var highest = 0
	for sprite in draggable_sprites:
		highest = max(highest, sprite.z_index)
	return highest
	
