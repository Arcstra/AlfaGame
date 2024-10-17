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
	# Если луч кого-то заметил
	if target != null:
		isWasEnemy = true
		$OneCareful.stop()
		fight()
	# Режим настороженности
	elif isWasEnemy:
		$Careful.start()
		$OneCareful.start()
		isWasEnemy = false
	
	# В зависимости от направления движения, определяет направление персонажа
	if velocity.x > 0:
		$RayCast2D.target_position.x = abs($RayCast2D.target_position.x)
		$Sword/Collision.position.x = abs($Sword/Collision.position.x)
		$AnimatedSprite2D.flip_h = false
	elif velocity.x < 0:
		$RayCast2D.target_position.x = -abs($RayCast2D.target_position.x)
		$Sword/Collision.position.x = -abs($Sword/Collision.position.x)
		$AnimatedSprite2D.flip_h = true
		
	# Функция, которая передвигает персонажа. Использует position и velocity
	move_and_slide()


# Отзеркаливает персонажа 
# P.S. в будущем требует доработки
func flip():
	if velocity.x != 0:
		return
	
	$RayCast2D.target_position.x = -$RayCast2D.target_position.x
	$Sword/Collision.position.x = -$Sword/Collision.position.x
	$AnimatedSprite2D.flip_h = not $AnimatedSprite2D.flip_h


# Ведение боя
func fight():
	var positionTarget = $RayCast2D.get_collision_point()
	var rangeTarget = positionTarget - nextPosition
	if rangeTarget.length() <= range and canHit:
		hit()
		canHit = false
		$Cooldown.start()
	elif rangeTarget.length() > range:
		nextPosition = positionTarget


# Наносит урон всем, кому можно
func hit():
	for body in $Sword.get_overlapping_bodies():
		# Если есть функция, считывающая урон и если он недруг
		if body.has_method("die") and not body.is_in_group("dwarf's friend"):
			body.die(damage)


# Учитывает полученный урон, если здоровья < 0, то персонаж удаляется со сцены 
# P.S. в будущем требует доработки
func die(damage: int):
	if not isWasEnemy:
		flip()
		$Careful.start() # Запускает таймер
		$OneCareful.start() # Запускает таймер
	hp -= damage
	if hp <= 0:
		queue_free() # Удаляет со сцены


# Срабатывает каждый раз, когда время кулдауна закончилось
func _on_cooldown_timeout() -> void:
	canHit = true


# Останавливает режим настороженности у персонажа
func _on_careful_timeout() -> void:
	$OneCareful.stop()


# Во время режима настороженности, разворачивает персонажа
func _on_one_careful_timeout() -> void:
	flip()
