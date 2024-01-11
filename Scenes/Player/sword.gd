extends Area2D

var damage : int


func _on_body_entered(body):
	if body.name == "Player":
		return
	
	if body.is_in_group("Enemy"):
		body.hit(damage)
