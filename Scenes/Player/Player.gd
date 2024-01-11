extends CharacterBody2D

@onready var tile_map = $".."
@onready var sprite_2d = $Sprite2D
@onready var ray_cast = $RayCast2D

var is_moving = false
var sword_damage = 10

# adapted from RetroBright YouTube tutorial (2D movement in godot 4 using tilemap)

func _physics_process(_delta):
	if is_moving == false: return
	
	if global_position == sprite_2d.global_position:
		is_moving = false
		return
	
	sprite_2d.global_position = sprite_2d.global_position.move_toward(global_position, 1)
	Globals.player_pos = global_position


func _process(_delta):
	if is_moving: return
	
	if Input.is_action_pressed("Left"): move(Vector2.LEFT)
	elif Input.is_action_pressed("Right"): move(Vector2.RIGHT)
	elif Input.is_action_pressed("Up"): move(Vector2.UP)
	elif Input.is_action_pressed("Down"): move(Vector2.DOWN)
	
	if (Input.is_action_pressed("Primary Action")):
		# TODO: attack and cause damage
		var sword = Globals.sword_scene.instantiate()
		sword.damage = sword_damage
		sword.position = position + Vector2(3, 0)
		$".".add_child(sword)


func move(direction : Vector2):
	# get current cell and new cell
	var current_tile : Vector2i = tile_map.local_to_map(global_position)
	var target_tile : Vector2i = Vector2i(
		current_tile.x + int(direction.x),
		current_tile.y + int(direction.y))
		
	# get custom data layer from target tile
	var tile_data: TileData = tile_map.get_cell_tile_data(0, target_tile)
	if tile_data.get_custom_data(("Walkable")) == false: return
	
	ray_cast.target_position = direction * 16
	ray_cast.force_raycast_update()
	
	if ray_cast.is_colliding():
		return
	
	# move player
	is_moving = true
	global_position = tile_map.map_to_local(target_tile)
	sprite_2d.global_position = tile_map.map_to_local(current_tile)


func hit():
	Globals.health -= 5
