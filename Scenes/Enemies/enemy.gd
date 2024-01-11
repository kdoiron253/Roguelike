extends CharacterBody2D
class_name Enemy


var is_player_near : bool = false
var is_searching : bool = false
var health : int = 20
var speed : int = 20


# TODO: move towards player and attack
func _process(_delta):
	var direction : Vector2 = (Globals.player_pos - position).normalized()
	velocity = direction * speed
	if is_searching:
		move_and_slide()


func hit():
	health -= 5
	print(health)
	if health <= 0:
		queue_free()


func _on_attack_area_body_entered(_body):
	is_player_near = true


func _on_attack_area_body_exited(_body):
	is_player_near = false


func attack():
	if is_player_near:
		Globals.health -= 5


func _on_notice_area_body_entered(_body):
	is_searching = true


func _on_notice_area_body_exited(_body):
	is_searching = false
