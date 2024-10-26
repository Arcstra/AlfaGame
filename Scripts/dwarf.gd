extends CharacterBody2D

const range = 46
const SPEED = 160
const JUMP_VELOCITY = -330.0
const MAX_JUMPS = 8
const MAX_LEVITATION = 2
const LENGTH_BLOCK = 16

@onready var nextPosition: Vector2 = position # ГЛОБАЛЬНАЯ ПОЗИЦИЯ!!!
@onready var predPosition: Vector2 = position
@onready var lastOnFloor: Vector2i = position
@onready var sizeCollision = $CollisionShape2D.shape.size
var canHit = true
var isWasEnemy = false
var hp = 10
var damage = 2
var targetPosition = Vector2(128, 352) # 4 11
var nextJump = false
var globalGraph: Dictionary

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	print("NEWFRAME")
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if is_on_floor():
		lastOnFloor = position
	nextPosition = get_next_position(targetPosition)
	#print(nextPosition)
	if abs(nextPosition.x - position.x) > 1:
		if position.x < nextPosition.x:
			velocity.x = SPEED
		else:
			velocity.x = -SPEED
	else:
		velocity.x = 0
	if nextJump and is_on_floor():
		velocity.y = JUMP_VELOCITY
		nextJump = false
		print("JUMP!!!")
		
	var target = $RayCast2D.get_collider()
	# Если луч кого-то заметил
	if target != null and target.has_method("die") and not target.is_in_group("dwarf's friend"):
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
	predPosition = position


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
		targetPosition = positionTarget


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


func is_ground(coords: Vector2) -> bool:
	var id = get_parent().get_node("Ground").get_cell_source_id(Vector2i(coords) / 32)
	return id != -1

# Функция вычисляющая траекторию прыжка
func check_path(positionA: Vector2i, positionB: Vector2i, isFly: bool):
	if positionA == positionB:
		return positionA
	
	if positionA.x == positionB.x:
		for y in range(min(positionA.y, positionB.y) + 1, max(positionA.y, positionB.y)):
			if not is_ground(Vector2i(positionA.x, y) * LENGTH_BLOCK):
				return positionA
		if positionA.y < positionB.y:
			return positionA + Vector2i(0, 1)
		else:
			return positionA + Vector2i(0, -1)
	
	if positionA.y == positionB.y:
		var isGood: bool = true
		for x in range(min(positionA.x, positionB.x) + 1, max(positionA.x, positionB.x)):
			if not is_ground(Vector2i(x, positionA.y + 1) * LENGTH_BLOCK):
				isGood = false
				break
		if isGood:
			if positionA.x < positionB.x:
				return positionA + Vector2i(1, 0)
			else:
				return positionA + Vector2i(-1, 0)
	
	var topPosition: Vector2i
	if isFly:
		topPosition.y = lastOnFloor.y / LENGTH_BLOCK - MAX_JUMPS
	else:
		topPosition.y = positionA.y - MAX_JUMPS
	if positionA.x < positionB.x:
		topPosition.x = min(positionA.x + (positionA.y - topPosition.y) * MAX_LEVITATION, positionB.x - 1)
	else:
		topPosition.x = max(positionA.x - (positionA.y - topPosition.y) * MAX_LEVITATION, positionB.x + 1)
	
	if topPosition.y > positionB.y:
		return positionA
	
	var way: Array
	var positionNow = topPosition
	while positionNow.x != positionA.x:
		if positionNow.y < positionA.y:
			way.append(positionNow + Vector2i(0, 1))
			positionNow += Vector2i(0, 1)
		elif positionNow.y > positionA.y:
			way.append(positionNow + Vector2i(0, -1))
			positionNow += Vector2i(0, -1)
		if positionA.x < positionNow.x:
			way.append(positionNow + Vector2i(-1, 0))
			positionNow += Vector2i(-1, 0)
		else:
			way.append(positionNow + Vector2i(1, 0))
			positionNow += Vector2i(1, 0)
	while positionNow.y < positionA.y:
		if positionNow.y < positionA.y:
			way.append(positionNow + Vector2i(0, 1))
			positionNow += Vector2i(0, 1)
		else:
			way.append(positionNow + Vector2i(0, -1))
			positionNow += Vector2i(0, -1)
	way.reverse()
	way.append(topPosition)
	positionNow = topPosition
	while positionNow.x != positionB.x:
		if positionB.x < positionNow.x:
			way.append(positionNow + Vector2i(-1, 0))
			positionNow += Vector2i(-1, 0)
		else:
			way.append(positionNow + Vector2i(1, 0))
			positionNow += Vector2i(1, 0)
		if positionNow.y < positionB.y:
			way.append(positionNow + Vector2i(0, 1))
			positionNow += Vector2i(0, 1)
		elif positionNow.y > positionB.y:
			way.append(positionNow + Vector2i(0, -1))
			positionNow += Vector2i(0, -1)
	while positionNow.y < positionB.y:
		if positionNow.y < positionB.y:
			way.append(positionNow + Vector2i(0, 1))
			positionNow += Vector2i(0, 1)
		else:
			way.append(positionNow + Vector2i(0, -1))
			positionNow += Vector2i(0, -1)
	#print(positionA, positionB, way, topPosition)
	if way.is_empty():
		return positionA
	for node in way:
		if is_ground(node * LENGTH_BLOCK):
			return positionA
		for i in range(1, (sizeCollision.y - 32) / LENGTH_BLOCK + 1):
			if is_ground(node * LENGTH_BLOCK + Vector2i(0, -32 / LENGTH_BLOCK) * i):
				return positionA
		for i in range(1, sizeCollision.x / LENGTH_BLOCK + 1):
			if is_ground(node * LENGTH_BLOCK + Vector2i(32 / LENGTH_BLOCK, 0) * i):
				return positionA
			if is_ground(node * LENGTH_BLOCK + Vector2i(-32 / LENGTH_BLOCK, 0) * i):
				return positionA
	print(positionA, positionB, way, topPosition, "OK")
	return way[1]


func dfs(positionNow: Vector2i, isFly: bool):
	var usedDFS: Dictionary
	var s: Array
	var g: Dictionary
	s.append(positionNow)
	usedDFS[positionNow] = false
	#print(positionNow, "DFS")
	while not s.is_empty():
		var sNow = Vector2i(1e9, 1e9)
		var imin = 0
		
		for i in range(len(s)):
			if abs(s[i].x - positionNow.x) + abs(s[i].y - positionNow.y) < abs(sNow.x - positionNow.x) + abs(sNow.y - positionNow.y):
				sNow = s[i]
				imin = i
		s.remove_at(imin)
		
		if usedDFS[sNow]:
			continue
		
		if positionNow.y - sNow.y > MAX_JUMPS or abs(positionNow.x - sNow.x) > MAX_JUMPS * 2 - 1 - positionNow.y + sNow.y:
			continue
		
		var positionUp = sNow + Vector2i(0, -1)
		if not usedDFS.has(positionUp):
			usedDFS[positionUp] = false
			if not is_ground(positionUp * LENGTH_BLOCK):
				s.append(positionUp)
		
		var positionRight = sNow + Vector2i(1, 0)
		if not usedDFS.has(positionRight):
			usedDFS[positionRight] = false
			if not is_ground(positionRight * LENGTH_BLOCK):
				s.append(positionRight)
		
		var positionDown = sNow + Vector2i(0, 1)
		if not usedDFS.has(positionDown):
			usedDFS[positionDown] = false
			if not is_ground(positionDown * LENGTH_BLOCK):
				s.append(positionDown)
		if is_ground(positionDown * LENGTH_BLOCK):
			#print(positionNow, sNow)
			var newPosition = check_path(positionNow, sNow, isFly)
			#print(positionNow, sNow, newPosition)
			if newPosition != positionNow:
				#print(positionNow, sNow, newPosition)
				g[sNow] = newPosition
		
		var positionLeft = sNow + Vector2i(-1, 0)
		if not usedDFS.has(positionLeft):
			usedDFS[positionLeft] = false
			if not is_ground(positionLeft * LENGTH_BLOCK):
				s.append(positionLeft)
		
		usedDFS[sNow] = true
	print(positionNow, g)
	return g


func get_next_position(target):
	var s: Array
	target = Vector2i(target) / LENGTH_BLOCK + Vector2i(0, 32 / LENGTH_BLOCK - 1)
	var positionStart = Vector2i(position) / LENGTH_BLOCK + Vector2i(0, 32 / LENGTH_BLOCK - 1)
	var graph: Dictionary
	var pred: Dictionary
	var used: Dictionary
	
	s.append(positionStart)
	used[positionStart] = false
	
	if positionStart != Vector2i(lastOnFloor) / LENGTH_BLOCK:
		var sNow: Vector2i
		var iNow: int
		
		sNow = s[0]
		s.pop_back()
		
		var g = dfs(sNow, true)
		graph[sNow] = g
		for key in g:
			if not used.has(key):
				used[key] = false
				s.append(key)
				pred[key] = sNow
		used[sNow] = true
	
	while not s.is_empty():
		var sNow: Vector2i
		var imin: int = 1e9
		var iNow: int
		
		for i in range(len(s)):
			if abs(s[i].x - target.x) + abs(s[i].y - target.y) < imin:
				iNow = i
				imin = abs(s[i].x - target.x) + abs(s[i].y - target.y)
		
		sNow = s[iNow]
		s.remove_at(iNow)
		
		if sNow == target:
			break
		
		if used[sNow] == true:
			continue
		
		#print(sNow)
		used[sNow] = true
		#print(used)
		var g
		if globalGraph.has([sNow, false]):
			g = globalGraph[[sNow, false]]
		else:
			g = dfs(sNow, false)
			globalGraph[[sNow, false]] = g
		graph[sNow] = g
		for key in g:
			if not used.has(key):
				used[key] = false
				s.append(key)
				pred[key] = sNow
	
	var curr = target
	if not pred.has(curr):
		return position
		
	while pred[curr] != positionStart:
		curr = pred[curr]
	print(curr)
	curr = graph[positionStart][curr]
	print(positionStart, curr)
	if not is_ground((curr - Vector2i(0, 32 / LENGTH_BLOCK - 1)) * LENGTH_BLOCK + Vector2i(0, 32)) and is_on_floor():
		nextJump = true
	#print("MOVE")
	return curr * LENGTH_BLOCK + Vector2i(16 / (32 / LENGTH_BLOCK), 16)


# Срабатывает каждый раз, когда время кулдауна закончилось
func _on_cooldown_timeout() -> void:
	canHit = true


# Останавливает режим настороженности у персонажа
func _on_careful_timeout() -> void:
	$OneCareful.stop()


# Во время режима настороженности, разворачивает персонажа
func _on_one_careful_timeout() -> void:
	flip()
