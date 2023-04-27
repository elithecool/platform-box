extends CharacterBody2D

var speed = 10
var gravity = 20
var player = null
var direction = 1

func _physics_process(delta):
	velocity.x += speed * direction
	velocity.y += gravity
	if is_on_wall():
		direction = direction * -1
	
	move_and_slide()
