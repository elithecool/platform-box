class_name Player
extends CharacterBody2D

enum State { Idle, Run, Jump, Fall, FastFall, Dash, AirDash, WallSlide, Crouch, DashRun }
@export var current_state = State.Idle

# All the important variables. 
@export var SPEED = 300.0
@export var JUMP_VELOCITY = -400.0
@export var dash_speed = 150.0
@export var dash_length = .1
@export_range(0.0, 1.0) var friction = 0.1
@export_range(0.0 , 1.0) var acceleration = 0.25
@export var can_dash = true

signal grounded_updated(is_grounded)

var wall_slide_speed = 100
var wall_slide_accel = 10
var wall_slide_gravity = 100
var is_wall_sliding : bool = false
var wall_jump = 150
var crouch_speed = 200.0

var is_grounded
var is_air_dashing = false
var on_ground = false

@onready var dash = $player_dash
@onready var coyote_timer = $coyote_timer

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_jumps = 2
var jump_count = 0


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") && jump_count < max_jumps:
		velocity.y = JUMP_VELOCITY
		$AnimatedSprite2D.play("jump")
		if !coyote_timer.is_stopped():
			velocity.y = JUMP_VELOCITY
		jump_count += 1
		$JumpSound.play()
		current_state = State.Jump
		print("State: Jump")
		
	elif Input.is_action_just_released("jump"):
		_jump_cut()
	
	else:
		if is_on_floor():
			jump_count = 0
		

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = lerp(velocity.x, direction * SPEED, acceleration)
		current_state = State.Run
		print("State: Run")
		$AnimatedSprite2D.play("run")
		if Input.is_action_pressed("left"):
			$AnimatedSprite2D.flip_h = true
		elif Input.is_action_pressed("right"):
			$AnimatedSprite2D.flip_h = false
	else:
		velocity.x = lerp(velocity.x, 0.0, friction)
		$AnimatedSprite2D.play("idle")
		current_state = State.Idle
		print("State: Idle")
		

	
	move_and_slide()
	
	if is_on_floor():
		on_ground = true
		current_state = State.Idle
	else:
		on_ground = false 
		if velocity.y < 0:
			$AnimatedSprite2D.play("jump")
			current_state = State.Jump
			print("State: Jump")
		else:
			$AnimatedSprite2D.play("fall")
			current_state = State.Fall
			print("State: Fall")
	
	
	# Was grounded variables.
	var was_grounded = is_grounded
	is_grounded = is_on_floor()
	on_ground = is_on_floor()
	
	
	if was_grounded == null || is_grounded != was_grounded:
		emit_signal("grounded_updated", is_grounded)
	
	if was_grounded && !is_on_floor():
		coyote_timer.start()
	
	# Dash state.
	if Input.is_action_just_pressed("dash") and can_dash == true:
		dash.start_dash(dash_length)
		velocity.x = lerp(velocity.x, velocity.x * dash_speed, dash_length)
		$AnimatedSprite2D.play("dash")
		$DashSound.play()
		can_dash = false
		$dash_cooldown.start()
		current_state = State.Dash
		print("State: Dash")
		if not is_on_floor():
			is_air_dashing = true
			velocity.y = JUMP_VELOCITY
			_jump_cut()
			current_state = State.AirDash
		else:
			velocity.y += gravity * delta
			current_state = State.Dash
			is_air_dashing = false
		
	var other_speed = dash_speed if dash.is_dashing() else SPEED
	
	# Handle rotation of sprite and collision shape on slope.
	if is_on_floor():
		var normal: Vector2 = get_floor_normal()
		$AnimatedSprite2D.rotation = atan2(normal.x, -normal.y)
		$LightOccluder2D.rotation = atan2(normal.x, -normal.y)
		$normal_shape.rotation = atan2(normal.x, -normal.y)
	elif not is_on_floor():
		$AnimatedSprite2D.rotation = 0
		$LightOccluder2D.rotation = 0
		$normal_shape.rotation = 0
		$crouch_shape.rotation = 0
	
	
	
	
	
	
	# Wall slide state.
	if(next_to_wall() and !is_on_floor()):
		if((Input.get_axis("left", "right")) or abs(Input.get_joy_axis(0,0)) > 0.3):
			is_wall_sliding = true
		else:
			is_wall_sliding = false
	else:
		is_wall_sliding = false
	
	if(is_wall_sliding == true):
		velocity.y += (wall_slide_gravity * delta)
		velocity.y = min(velocity.y, wall_slide_speed)
		$AnimatedSprite2D.play("wall_slide")
		if Input.is_action_pressed("left"):
			$AnimatedSprite2D.flip_h = false
		elif Input.is_action_pressed("right"):
			$AnimatedSprite2D.flip_h = true
		$WallSlideSound.play()
		current_state = State.WallSlide
		print("State: Wall Slide")
	
	
	
	
	
	# Wall jumping.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			$JumpSound.play()
		if next_to_wall() && Input.is_action_pressed("right"):
			velocity.y = JUMP_VELOCITY * 1.4 
			velocity.x = 8 * -SPEED
			$JumpSound.play()
		elif next_to_wall() && Input.is_action_pressed("left"):
			velocity.y = JUMP_VELOCITY * 1.4 
			velocity.x = 8 * SPEED
			$JumpSound.play()
	
	
	
	
	
	
	
	# Fast fall.
	if Input.is_action_pressed("down"):
		self.position = Vector2(self.position.x, self.position.y + 1)
		gravity = 980 * 3
		current_state = State.FastFall
	else:
		gravity = 980
	# Crouch state.
	if Input.is_action_pressed("crouch"):
		$crouch_shape.disabled = false
		$normal_shape.disabled = true
		$AnimatedSprite2D.position.x = 0
		$AnimatedSprite2D.position.y = 12.25
		$AnimatedSprite2D.play("crouch")
		current_state = State.Crouch
		print("State: Crouch")
		$JumpSound.stop()
		SPEED = 200.0
		JUMP_VELOCITY = 0.0
		
	else:
		$crouch_shape.disabled = true
		$normal_shape.disabled = false
		$AnimatedSprite2D.position.x = 0
		$AnimatedSprite2D.position.y = 0
		$AnimatedSprite2D.scale.x = 1
		$AnimatedSprite2D.scale.y = 1
		SPEED = 300.0
		JUMP_VELOCITY = -400.0
		
	# Dash run state.
	if Input.is_action_pressed("dash_run"):
		if direction:
			SPEED = 300.0 * 3
			dash_speed = 90.0
			current_state = State.DashRun
			$AnimatedSprite2D.play("dash_run")
	else:
		SPEED = 300.0
		dash_speed = 150.0
	
func _jump_cut():
	if velocity.y < -100.0:
		velocity.y = -100.0



func _on_dash_cooldown_timeout():
	can_dash = true
	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			$CanvasLayer2/PauseMenu.unpause()
		else:
			$CanvasLayer2/PauseMenu.pause()





	

func next_to_wall():
	return next_to_right_wall() or next_to_left_wall()

func next_to_right_wall():
	return $right_wall.is_colliding()
	return $right_wall2.is_colliding()
	return $right_wall3.is_colliding()

func next_to_left_wall():
	return $left_wall.is_colliding()
	return $left_wall2.is_colliding()
	return $left_wall3.is_colliding()
