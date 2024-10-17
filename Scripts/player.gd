extends CharacterBody2D


const SPEED = 320.0
const JUMP_VELOCITY = -200.0

var canHit = true # Имеет ли возможность ударить
var damage = 1
var hp = 5


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("hit") and canHit:
		hit()
		canHit = false
		$Cooldown.start() # Запускает таймер кулдауна


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if velocity.x > 0:
		$Sword/Collision.position.x = abs($Sword/Collision.position.x)
		$AnimatedSprite2D.flip_h = false
	elif velocity.x < 0:
		$Sword/Collision.position.x = -abs($Sword/Collision.position.x)
		$AnimatedSprite2D.flip_h = true
	
	move_and_slide()


# Наносит урон всем, кому можно
func hit():
	for body in $Sword.get_overlapping_bodies():
		if body.has_method("die") and not body.is_in_group("player's friend"):
			body.die(damage)


# Учитывает полученный урон, если здоровья < 0, то персонаж удаляется со сцены 
# P.S. в будущем требует доработки
func die(damage: int):
	hp -= damage
	if hp <= 0:
		queue_free() # Удаляет со сцены


# Срабатывает каждый раз, когда время кулдауна закончилось
func _on_cooldown_timeout() -> void:
	canHit = true
