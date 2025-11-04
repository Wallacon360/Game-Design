extends CharacterBody2D

# --- Variables ---
const SPEED = 25.0 # Make enemies a bit slower than the player
const DAMAGE = 5 # NEW: How much damage this enemy deals on contact
# --- MODIFIED: Changed const to @export var ---
@export var KNOCKBACK_SPEED: float = 200.0 # NEW: How fast the enemy is knocked back
@export var exp_reward: int = 25 # NEW: How much EXP this enemy gives

# NEW: Health variables
# --- MODIFIED: Added @export ---
@export var max_health: int = 400
var health = max_health

# This will hold a reference to the player object.
var player = null

var is_hit = false # NEW: State to check if enemy is in hitstun
var is_dead = false # NEW: State to check if enemy is dead

@onready var animated_sprite = $AnimatedSprite2D
# NEW: Get the collision shape to disable it on death
@onready var collision_shape = $CollisionShape2D

# --- Preload the EXPGem scene ---
# (Make sure this path is correct!)
const EXP_GEM_SCENE = preload("res://Scene/EXPGem.tscn")

# --- Godot Functions ---
func _ready():
	player = get_tree().get_first_node_in_group("player")
	health = max_health # NEW: Make sure health is full when spawned
	
	# --- MODIFIED: THIS IS THE FIX for the yellow warning ---
	# We check if the signal is *not* already connected before connecting it.
	# This stops the "already connected" warning.
	if not animated_sprite.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		animated_sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
	

# --- MODIFIED: Changed 'delta' to '_delta' to fix warning ---
func _physics_process(_delta):
	# NEW: If dead, stop all logic and physics
	if is_dead:
		# This stops the dead body from sliding
		velocity = velocity.lerp(Vector2.ZERO, 0.05)
		move_and_slide()
		return
		
	# NEW: If hit, apply knockback (with friction) and don't do anything else
	if is_hit:
		# This slows down the knockback velocity automatically
		velocity = velocity.lerp(Vector2.ZERO, 0.05) 
		move_and_slide()
		return # Skip the rest of the logic (chasing, animation)

	# --- Normal Chase Logic ---
	if not player:
		return

	# --- NEW PUSH-AWAY LOGIC ---
	# We check if we are *currently* touching the player.
	var is_colliding = get_slide_collision_count() > 0
	var chase = true
	
	if is_colliding:
		var collision = get_slide_collision(0) # Get the first collision
		if is_instance_valid(collision.get_collider()) and collision.get_collider().is_in_group("player"):
			# It's the player! Stop chasing and apply friction.
			# This lets the player push the enemy.
			chase = false
			velocity = velocity.lerp(Vector2.ZERO, 0.1) # Apply "brakes"
	
	if chase:
		# We are not colliding with the player, so chase them.
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * SPEED
	
	move_and_slide()
	
	update_animation()

# --- Custom Functions ---

# NEW: This function will be called by the player's attack
func take_damage(amount):
	# NEW: Don't take damage if already hit or dead
	if is_hit or is_dead: 
		return

	health -= amount
	print("Enemy health: ", health)
	
	if health <= 0:
		# --- NEW DEATH LOGIC ---
		is_dead = true
		animated_sprite.play("death") # Play your new animation
		
		# --- Spawn the EXP Gem ---
		var gem = EXP_GEM_SCENE.instantiate()
		gem.exp_value = exp_reward # Set its value
		# Add it to the main scene (inside the YSort node)
		get_parent().add_child(gem)
		gem.global_position = global_position # Drop it where the enemy died
		
		# Stop all movement
		velocity = Vector2.ZERO
		
		# --- MODIFIED: THIS IS THE FIX ---
		# Disable collision so the player can walk through the dead body
		# We use "set_deferred" to wait for a safe time to change physics
		collision_shape.set_deferred("disabled", true)
		
		# We DON'T call queue_free() here. We wait for the animation.
		
	else:
		# --- NEW: Start the Hit Effect ---
		is_hit = true
		
		# 1. Play the "hit" animation
		animated_sprite.play("hit")
		
		# 2. Flash a different color
		# We'll tint it bright white. This will make your green sprite
		# flash a bright, washed-out green color.
		animated_sprite.modulate = Color(3, 3, 3) # Changed from red tint to white flash
		
		# 3. Apply knockback
		if player: # Make sure we still have the player reference
			# Calculate direction *away* from the player and apply speed
			var knockback_direction = player.global_position.direction_to(global_position)
			velocity = knockback_direction * KNOCKBACK_SPEED


func update_animation():
	if velocity.x < 0:
		animated_sprite.play("walk_left")
	elif velocity.x > 0:
		animated_sprite.play("walk_right")
	elif velocity.y < 0:
		animated_sprite.play("walk_up")
	else:
		animated_sprite.play("walk_down")


# NEW: Add this function.
# This function is called when *any* animation finishes on the sprite.
func _on_animated_sprite_2d_animation_finished():
	# We only care if the animation that *just finished* was our "hit" animation
	if animated_sprite.animation == "hit":
		# 1. Reset the state
		is_hit = false 
		
		# 2. Reset the color
		animated_sprite.modulate = Color(1, 1, 1) # Set back to normal (white)
		
		# 3. Go back to a normal animation
		# (so it doesn't get "stuck" on the last frame of "hit")
		update_animation()
	
	# --- NEW ---
	# If the "death" animation finished, *now* we remove the body
	if animated_sprite.animation == "death":
		queue_free()
