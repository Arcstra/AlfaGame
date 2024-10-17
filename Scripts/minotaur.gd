extends CharacterBody2D

var isWasEnemy = false
var damage = 1
var hp = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	pass


# Отзеркаливает персонажа 
# P.S. в будущем требует доработки
func flip():
	if velocity.x != 0:
		return
	
	$RayCast2D.target_position.x = -$RayCast2D.target_position.x
	$Sword/Collision.position.x = -$Sword/Collision.position.x
	$AnimatedSprite2D.flip_h = not $AnimatedSprite2D.flip_h


# Учитывает полученный урон, если здоровья < 0, то персонаж удаляется со сцены 
# P.S. в будущем требует доработки
func die(damage: int):
	if not isWasEnemy:
		flip()
		$Careful.start()
		$OneCareful.start()
	hp -= damage
	if hp <= 0:
		queue_free() # Удаляет со сцены
