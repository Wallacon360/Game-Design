extends CharacterBody2D

# --- Variables ---
const SPEED = 25.0 # Make enemies a bit slower than the player
const DAMAGE = 5 # NEW: How much damage this enemy deals on contact

# NEW: Health variables
var max_health = 100
var health = max_health

# This will hold a reference to the player object.
var player = null

@onready var animated_sprite = $AnimatedSprite2D

# --- Godot Functions ---
func _ready():
	player = get_tree().get_first_node_in_group("player")
	health = max_health # NEW: Make sure health is full when spawned

func _physics_process(delta):
	if not player:
		return

	var direction = global_position.direction_to(player.global_position)
	velocity = direction * SPEED
	
	move_and_slide()
	
	update_animation()

# --- Custom Functions ---

# NEW: This function will be called by the player's attack
func take_damage(amount):
	health -= amount
	print("Enemy health: ", health) # NEW: For testing
	
	if health <= 0:
		queue_free() # NEW: The enemy dies

func update_animation():
	if velocity.x < 0:
		animated_sprite.play("walk_left")
	elif velocity.x > 0:
		animated_sprite.play("walk_right")
	elif velocity.y < 0:
		animated_sprite.play("walk_up")
	else:
		animated_sprite.play("walk_down")
