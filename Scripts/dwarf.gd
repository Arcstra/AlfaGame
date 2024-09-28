extends CharacterBody2D

const range = 46
const SPEED = 160

var nextPosition = position + Vector2(0, -10)
var canHit = true
var isWasEnemy = false
var hp = 10
var damage = 2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if (nextPosition - position).length() > 10:
		if nextPosition < position:
			velocity.x = -SPEED
		elif position < nextPosition:
			velocity.x = SPEED
	else:
		velocity.x = 0
		
	var target = $RayCast2D.get_collider()
	if target != null:
		isWasEnemy = true
		$OneCareful.stop()
		fight()
	elif isWasEnemy:
		$Careful.start()
		$OneCareful.start()
		isWasEnemy = false
	
	if velocity.x > 0:
		$RayCast2D.target_position.x = abs($RayCast2D.target_position.x)
		$Sword/Collision.position.x = abs($Sword/Collision.position.x)
		$AnimatedSprite2D.flip_h = false
	elif velocity.x < 0:
		$RayCast2D.target_position.x = -abs($RayCast2D.target_position.x)
		$Sword/Collision.position.x = -abs($Sword/Collision.position.x)
		$AnimatedSprite2D.flip_h = true
		
	move_and_slide()


func flip():
	if velocity.x != 0:
		return
	
	$RayCast2D.target_position.x = -$RayCast2D.target_position.x
	$Sword/Collision.position.x = -$Sword/Collision.position.x
	$AnimatedSprite2D.flip_h = not $AnimatedSprite2D.flip_h


func fight():
	var positionTarget = $RayCast2D.get_collision_point()
	var rangeTarget = positionTarget - nextPosition
	if rangeTarget.length() <= range and canHit:
		hit()
		canHit = false
		$Cooldown.start()
	elif rangeTarget.length() > range:
		nextPosition = positionTarget


func hit():
	for body in $Sword.get_overlapping_bodies():
		if body.has_method("die"):
			body.die(damage)


func die(damage: int):
	if not isWasEnemy:
		flip()
		$Careful.start()
		$OneCareful.start()
	hp -= damage
	if hp <= 0:
		queue_free()


func _on_cooldown_timeout() -> void:
	canHit = true


func _on_careful_timeout() -> void:
	$OneCareful.stop()


func _on_one_careful_timeout() -> void:
	flip()
