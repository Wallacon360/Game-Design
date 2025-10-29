extends CharacterBody2D

# --- Variables ---
const SPEED = 150.0
const AXE_HITBOX_SCENE = preload("res://Scene/AxeHitbox.tscn")

var max_health = 100
var health = max_health

var can_take_damage = true
var is_attacking = false
var can_attack = true

@onready var animated_sprite = $AnimatedSprite2D
@onready var damage_cooldown_timer = $DamageCooldownTimer
@onready var attack_cooldown_timer = $AttackCooldownTimer
var last_direction = Vector2(0, 1)


# --- Game Loop ---
func _physics_process(delta):
	# Check for the attack button press
	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		attack()

	# Stop movement while attacking
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Handle regular movement
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction.normalized() * SPEED
	move_and_slide()
	check_for_enemy_collisions()
	update_animation(input_direction)


# --- Attack Logic ---
func attack():
	is_attacking = true
	can_attack = false
	attack_cooldown_timer.start()
	print("Attack started. Cooldown timer running.")

	var hitbox = AXE_HITBOX_SCENE.instantiate()

	# Use global_position to place the hitbox correctly in the game world
	if last_direction.x < 0:
		animated_sprite.play("attack_left")
		hitbox.global_position = global_position + Vector2(-25, 0)
	elif last_direction.x > 0:
		animated_sprite.play("attack_right")
		hitbox.global_position = global_position + Vector2(25, 0)
	elif last_direction.y < 0:
		animated_sprite.play("attack_up")
		hitbox.global_position = global_position + Vector2(0, -25)
	else:
		animated_sprite.play("attack_down")
		hitbox.global_position = global_position + Vector2(0, 25)

	get_parent().add_child(hitbox)


# --- Signal Functions ---
func _on_attack_cooldown_timer_timeout():
	can_attack = true # Allow the player to attack again
	print("Cooldown finished. Player can attack again!")

func _on_animated_sprite_2d_animation_finished():
	var anim_name = animated_sprite.get_animation()
	if anim_name.begins_with("attack"):
		is_attacking = false # Allow movement again

func _on_damage_cooldown_timer_timeout():
	can_take_damage = true # Allow the player to take damage again


# --- Other Functions ---
func check_for_enemy_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("enemy"):
			var enemy = collision.get_collider()
			take_damage(enemy.DAMAGE)

func take_damage(amount):
	if can_take_damage:
		health -= amount
		print("Player health: ", health)
		can_take_damage = false
		damage_cooldown_timer.start()
		if health <= 0:
			print("Player died!")
			get_tree().reload_current_scene()

func update_animation(input_direction):
	if input_direction == Vector2.ZERO:
		if is_attacking: return # Don't change to idle while attacking
		if last_direction.x < 0: animated_sprite.play("idle_left")
		elif last_direction.x > 0: animated_sprite.play("idle_right")
		elif last_direction.y < 0: animated_sprite.play("idle_up")
		else: animated_sprite.play("idle_down")
	else:
		last_direction = input_direction
		if input_direction.x < 0: animated_sprite.play("walk_left")
		elif input_direction.x > 0: animated_sprite.play("walk_right")
		elif input_direction.y < 0: animated_sprite.play("walk_up")
		else: animated_sprite.play("walk_down")
