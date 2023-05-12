extends Area2D

var player: Player

func _on_body_entered(body):
	if player:
		player.velocity.x = 0.0
