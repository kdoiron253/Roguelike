extends CharacterBody2D

var speed : int = 200

func _process(_delta):
	var direction = Input.get_vector("Left", "Right", "Up", "Down")
	move(direction)


func move(_direction : Vector2):
	move_and_slide()
