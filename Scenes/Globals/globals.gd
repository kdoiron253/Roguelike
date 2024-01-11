extends Node

signal stat_changed

@onready var sword_scene = preload("res://Scenes/Player/sword.tscn")

var player_pos : Vector2

var health = 100:
	set(value):
		if value > health:
			health = min(value, 100)
		else:
			health = value
		stat_changed.emit()
		print(health)
