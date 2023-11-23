extends TileMap

# most of this is from abitawake.com with updates to work with
# newer engine and to fit in with the needed game idea

# TODO: add in player and enemy scenes and randomly place them
var player_scene : PackedScene = preload("res://Scenes/Player/player.tscn")
var enemy_scene : PackedScene = preload("res://Scenes/Enemies/axolotl.tscn")
var coin_scene : PackedScene = preload("res://Scenes/Items/coin.tscn")

@export var map_width : int = 80
@export var map_height : int = 50
@export var min_room_size : int = 8
@export var min_room_factor : float = 0.4

# enum Tiles { GROUND, TREE, WATER, ROOF }
# atlas coordinates
var LAYER : int = 0  # the default layer is ground
var ATLAS : int = 0  # the default tileset

var enemy_number = 20

# TODO: place exit in another random room
# TODO: add in monsters and treasure to the rooms (leaves)
# TODO: random floor and roof tiles to chose from
var ROOF = Vector2i(12, 13)  # was 12, 13
var GROUND = Vector2i(12, 7)

var tree := {}
var leaves := []
var leaf_id = 0
var rooms := []

var room_tiles := []


func _ready():
	generate()


func generate():
	clear()
	fill_roof()
	start_tree()
	create_leaf(0)
	create_rooms()
	join_rooms()
	
	# if a room wasn't made, leaving for the maze factor
	# tested and made to work
	clear_deadends()
	place_player()
	for i in range(enemy_number):
		place_enemies()
	
	# TODO: loop through list of items to place and place
	place_items()
	
	# TODO: place exit and make it active only when all items picked up


func fill_roof():
	for x in range(0, map_width):
		for y in range(0, map_height):
			var pos = Vector2i(x, y)
			set_cell(LAYER, pos, ATLAS, ROOF)


# a BSP tree with a root leaf with one cell of padding
func start_tree():
	rooms = []
	tree = {}
	leaves = []
	leaf_id = 0

	tree[leaf_id] = { "x": 1, "y": 1, "w": map_width - 2, "h": map_height - 2 }
	leaf_id += 1


# recursively divide up map into rooms
func create_leaf(parent_id):
	var x = tree[parent_id].x
	var y = tree[parent_id].y
	var w = tree[parent_id].w
	var h = tree[parent_id].h
	
	# for connecting tree leaves later
	tree[parent_id].center = { x = floor(x + w/2), y = floor(y + h/2) }
	
	# is there space for a split in the tree
	var can_split = false
	
	# randonly split horizonally or vertically
	# horizontally if not enough width, vertically if not enough height
	var split_type = choose(["h", "v"])
	if (min_room_factor * w < min_room_size): split_type = "h"
	elif (min_room_factor * h < min_room_size): split_type = "v"
	
	var leaf1 := {}
	var leaf2 := {}
	var room_size
	
	# try and split the leaf if a room will fit
	if (split_type == "v"):
		room_size = min_room_factor * w
		if (room_size >= min_room_size):
			var w1 = randi_range(room_size, (w - room_size))
			var w2 = w - w1
			leaf1 = { x = x, y = y, w = w1, h = h, split = "v" }
			leaf2 = { x = x + w1, y = y, w = w2, h = h, split = "v" }
			can_split = true
	else:
		room_size = min_room_factor * h
		if (room_size >= min_room_size):
			var h1 = randi_range(room_size, (h - room_size))
			var h2 = h - h1
			leaf1 = { x = x, y = y, w = w, h = h1, split = "h" }
			leaf2 = { x = x, y = y + h1, w = w, h = h2, split = "h" }
			can_split = true
	
	# split if rooms fit
	if (can_split):
		leaf1.parent_id = parent_id
		tree[leaf_id] = leaf1
		tree[parent_id].l = leaf_id
		leaf_id += 1
		
		leaf2.parent_id = parent_id
		tree[leaf_id] = leaf2
		tree[parent_id].r = leaf_id
		leaf_id += 1
		
		# append leaves as branches from the parent
		leaves.append([tree[parent_id].l, tree[parent_id].r])
		
		# recursion, try and create for leaves / rooms
		create_leaf(tree[parent_id].l)
		create_leaf(tree[parent_id].r)


# create a room in leaf only 75% of the time
func create_rooms():
	for leafid in tree:
		var leaf = tree[leafid]
		if (leaf.has("l")): continue  # if children, no rooms built
		
		if chance(75):
			var room := {}
			room.id = leafid
			room.w = randi_range(min_room_size, leaf.w) - 1
			room.h = randi_range(min_room_size, leaf.h) - 1
			room.x = leaf.x + floor((leaf.w - room.w) / 2) + 1
			room.y = leaf.y + floor((leaf.h - room.h) / 2) + 1
			room.split = leaf.split
			
			room.center = Vector2()
			room.center.x = floor(room.x + room.w/2)
			room.center.y = floor(room.y + room.h/2)
			rooms.append(room)
	
	# draw in the rooms
	for i in range (rooms.size()):
		var r = rooms[i]
		for x in range(r.x, r.x + r.w):
			for y in range(r.y, r.y + r.h):
				var pos = Vector2i(x, y)
				set_cell(LAYER, pos, ATLAS, GROUND)


# get the rooms to join
func join_rooms():
	for sister in leaves:
		var a = sister[0]
		var b = sister [1]
		connect_leaves(tree[a], tree[b])


func connect_leaves(leaf1, leaf2):
	var x = min(leaf1.center.x, leaf2.center.x)
	var y = min(leaf1.center.y, leaf2.center.y)
	var w = 1
	var h = 1
	
	# vertical corridor
	if (leaf1.split == "h"):
		x -= floor(w/2.0) + 1
		h = abs(leaf1.center.y - leaf2.center.y)
	else:
		# horizontal corridor
		y -= floor(h/2.0) + 1
		w = abs(leaf1.center.x - leaf2.center.x)
	
	# make sure it is within the map
	x = 0 if (x < 0) else x
	y = 0 if (y < 0) else y
	
	for i in range(x, x+w):
		for j in range(y, y+h):
			var pos = Vector2i(i, j)
			if (get_cell_atlas_coords(LAYER, pos) == ROOF):
				set_cell(LAYER, pos, ATLAS, GROUND)


# TODO: place character in a random room
func place_player():
	# get random location, place player
	var player = player_scene.instantiate() as CharacterBody2D
	var tile = random_location()
	var pos = map_to_local(tile)
	# debug purposes: 
	print(tile, pos)
	player.position = pos
	$".".add_child(player)

# TODO: place enemies
func place_enemies():
	# get random location, place x number of enemies
	var enemy = enemy_scene.instantiate() as Area2D

	var tile = random_location()
	var pos = map_to_local(tile)
	enemy.position = pos
	$Enemies.add_child(enemy)


# TODO: place items
func place_items():
	var item = coin_scene.instantiate() as Area2D
	
	var tile = random_location()
	var pos = map_to_local(tile)
	item.position = pos
	$Items.add_child(item)


func random_location():
	# get a random room from the room list
	var random_number = randi() % room_tiles.size()
	# return location
	return room_tiles[random_number]


func clear_deadends():
	for cell in get_used_cells(LAYER):
		if (get_cell_atlas_coords(LAYER, cell) != GROUND): continue
		
		var roof_count = check_nearby(cell.x, cell.y)
		if roof_count < 2:
			room_tiles.append(cell)
		# to get rid of dead end halls
		#if roof_count == 3:
		#	set_cell(LAYER, cell, ATLAS, ROOF)


func check_nearby(x, y):
	var count = 0
	if get_cell_atlas_coords(LAYER, Vector2i(x, y-1)) == ROOF:  count += 1
	if get_cell_atlas_coords(LAYER, Vector2i(x, y+1)) == ROOF:  count += 1
	if get_cell_atlas_coords(LAYER, Vector2i(x-1, y)) == ROOF:  count += 1
	if get_cell_atlas_coords(LAYER, Vector2i(x+1, y)) == ROOF:  count += 1
	return count


# utilities
# picks one in a list
func choose(choices):
	var randi_index = randi() % choices.size()
	return choices[randi_index]


# the percent chance something will happen
func chance(num):
	if randi() %  100 <= num : return true
	else : return false

