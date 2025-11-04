extends CharacterBody2D

# --- Signals ---
signal health_updated(current, max)
signal exp_updated(current, max)
signal level_up(level)
signal wood_updated(new_total) # --- NEW SIGNAL ---

# --- Variables ---
# --- MODIFIED: Changed const to @export var ---
@export var SPEED: float = 150.0
const AXE_HITBOX_SCENE = preload("res://Scene/AxeHitbox.tscn")

# --- MODIFIED: Added @export ---
@export var max_health: int = 100
var health = max_health # This line automatically uses the exported value!

# --- MODIFIED: Changed to an Array of sounds ---
# (Make sure to change these paths to match your 3 sound files!)
const PLAYER_HIT_SOUNDS = [
	preload("res://Assets/Audio/player_hit_1.wav"),
	preload("res://Assets/Audio/player_hit_2.wav"),
	preload("res://Assets/Audio/player_hit_3.wav")
]

var can_take_damage = true
var is_attacking = false
var can_attack = true

@onready var animated_sprite = $AnimatedSprite2D
@onready var damage_cooldown_timer = $DamageCooldownTimer
@onready var attack_cooldown_timer = $AttackCooldownTimer
# --- NEW: Add a reference to the sound node ---
@onready var player_hit_sound = $PlayerHitSound

# This is still useful for tracking the last *movement* direction
var last_direction = Vector2(0, 1) 

# --- NEW: EXP and Leveling ---
var level = 1
var current_exp = 0
var exp_to_next_level = 100
var wood_count = 0 # --- NEW: Wood resource ---

# --- NEW: Level Up Screen ---
# We'll load this scene when we need it
var level_up_scene = preload("res://Scene/LevelUpScreen.tscn")

# --- NEW: Boolean check to prevent stacking screens ---
var is_leveling_up = false

# --- Godot Function ---
func _ready():
	# This line is so the level-up refill works
	health = max_health
	
	# --- MODIFIED: THIS IS THE FIX ---
	# We need to tell the HUD our starting values.
	# We just emit the signal. The HUD.gd script is
	# already set up to safely handle this.
	health_updated.emit(health, max_health)
	exp_updated.emit(current_exp, exp_to_next_level)
	
	# --- NEW: Emit the starting level ---
	level_up.emit(level)
	# --- NEW: Emit starting wood count ---
	wood_updated.emit(wood_count)
	
	# --- NEW: Ensure player starts at normal color ---
	animated_sprite.modulate = Color(1, 1, 1)


# --- Game Loop ---
# --- MODIFIED: Changed 'delta' to '_delta' to fix warning ---
func _physics_process(_delta):
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
	
	# --- MODIFIED ---
	# We now get the mouse direction and pass it to the animation function
	# so the player can look at the mouse while idle.
	var mouse_direction = global_position.direction_to(get_global_mouse_position())
	update_animation(input_direction, mouse_direction)


# --- Attack Logic ---
func attack():
	is_attacking = true
	can_attack = false
	attack_cooldown_timer.start()
	print("Attack started. Cooldown timer running.")

	var hitbox = AXE_HITBOX_SCENE.instantiate()

	# --- NEW: Get direction to mouse ---
	var attack_direction = global_position.direction_to(get_global_mouse_position())

	# --- NEW: Determine dominant axis for animation ---
	# This checks if the mouse is more horizontal (x) or vertical (y)
	if abs(attack_direction.x) > abs(attack_direction.y):
		# Horizontal attack (Left/Right)
		if attack_direction.x < 0:
			animated_sprite.play("attack_left")
			hitbox.global_position = global_position + Vector2(-25, 0)
			last_direction = Vector2.LEFT # Update last_direction for idle
		else:
			animated_sprite.play("attack_right")
			hitbox.global_position = global_position + Vector2(25, 0)
			last_direction = Vector2.RIGHT # Update last_direction for idle
	else:
		# Vertical attack (Up/Down)
		if attack_direction.y < 0:
			animated_sprite.play("attack_up")
			hitbox.global_position = global_position + Vector2(0, -25)
			last_direction = Vector2.UP # Update last_direction for idle
		else:
			animated_sprite.play("attack_down")
			hitbox.global_position = global_position + Vector2(0, 25)
			last_direction = Vector2.DOWN # Update last_direction for idle

	# This adds the hitbox as a sibling to the player (inside the "Entities" node)
	# which is correct for Y-Sorting.
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
	
	# --- NEW: Reset the player's color ---
	animated_sprite.modulate = Color(1, 1, 1)


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
		# --- MODIFIED ---
		# Emit the signal *after* taking damage
		health_updated.emit(health, max_health)
		
		print("Player health: ", health)
		can_take_damage = false
		damage_cooldown_timer.start()
		
		# --- NEW: Dim the player sprite to dark grey ---
		# You can change (0.3, 0.3, 0.3) to (0, 0, 0) for pure black
		animated_sprite.modulate = Color(0.3, 0.3, 0.3)
		
		# --- MODIFIED: Play a random player hit sound ---
		if is_instance_valid(player_hit_sound) and not PLAYER_HIT_SOUNDS.is_empty():
			# Pick a random sound from the array
			var random_sound = PLAYER_HIT_SOUNDS.pick_random()
			player_hit_sound.stream = random_sound
			player_hit_sound.play()
		
		if health <= 0:
			print("Player died!")
			get_tree().reload_current_scene()

# --- MODIFIED ---
# Now takes mouse_direction to determine idle animation
func update_animation(input_direction, mouse_direction):
	if input_direction == Vector2.ZERO:
		if is_attacking: return # Don't change to idle while attacking
		
		# --- NEW: Idle animation based on mouse direction ---
		if abs(mouse_direction.x) > abs(mouse_direction.y):
			if mouse_direction.x < 0:
				animated_sprite.play("idle_left")
				last_direction = Vector2.LEFT
			else:
				animated_sprite.play("idle_right")
				last_direction = Vector2.RIGHT
		else:
			if mouse_direction.y < 0:
				animated_sprite.play("idle_up")
				last_direction = Vector2.UP
			else:
				animated_sprite.play("idle_down")
				last_direction = Vector2.DOWN
	else:
		# --- This logic is the same: walk based on movement ---
		last_direction = input_direction # Store last *movement*
		if input_direction.x < 0: animated_sprite.play("walk_left")
		elif input_direction.x > 0: animated_sprite.play("walk_right")
		elif input_direction.y < 0: animated_sprite.play("walk_up")
		else: animated_sprite.play("walk_down")

# --- NEW: Function to collect wood ---
func add_wood(amount):
	wood_count += amount
	wood_updated.emit(wood_count)
	print("Wood collected! Total: ", wood_count)


# --- NEW: EXP and Leveling Functions ---
func add_exp(amount):
	current_exp += amount
	print("Gained ", amount, " EXP! Total: ", current_exp)
	
	# --- MODIFIED: Level Up Logic ---
	while current_exp >= exp_to_next_level:
		# We have enough to level up
		current_exp -= exp_to_next_level # Subtract the cost
		level += 1
		exp_to_next_level = int(exp_to_next_level * 1.5) # Increase cost for next level
		
		# Emit the level up signal
		level_up.emit(level)
		
		# Restore health on level up
		health = max_health
		health_updated.emit(health, max_health)
		
		# --- NEW: Show the power-up screen ---
		# We call this *after* updating health so the UI is correct
		show_level_up_screen()

	# Always update the EXP bar
	exp_updated.emit(current_exp, exp_to_next_level)

# --- NEW ---
# This function pauses the game and shows the level up screen
func show_level_up_screen():
	# --- NEW: Add this check! ---
	if is_leveling_up:
		return # A level up screen is already open!
		
	is_leveling_up = true
	
	# 1. Pause the game
	# Note: This pauses all nodes by default (enemies, player, spawner)
	get_tree().paused = true
	
	# 2. Create an instance of the level up screen
	var level_up_screen = level_up_scene.instantiate()
	
	# --- NEW: Tell the screen what level we are ---
	level_up_screen.set_level(level)
	
	# 3. Connect its "powerup_selected" signal to our "apply_powerup" function
	level_up_screen.powerup_selected.connect(apply_powerup)
	
	# 4. Add the screen to the game
	add_child(level_up_screen)

# --- NEW ---
# This function is called by the LevelUpScreen
func apply_powerup(powerup_key):
	print("Player selected powerup: ", powerup_key)
	
	# This is where we apply the stats!
	if powerup_key == "more_health":
		max_health += 20
		health = max_health # Heal to full
		health_updated.emit(health, max_health)
		
	elif powerup_key == "more_speed":
		SPEED += 25
		
	elif powerup_key == "more_damage":
		# We need to find our hitbox scene and update its *default* damage
		# This is a bit more advanced, for now, let's just do health/speed
		# (We'll add damage later if you want!)
		pass
	
	# --- IMPORTANT ---
	# 5. Unpause the game so it continues
	get_tree().paused = false
	
	# --- NEW: Reset the boolean check ---
	is_leveling_up = false
	
	# --- NEW: Re-check for level ups ---
	# This will re-run the `add_exp` logic and see if
	# we still have enough EXP to level up again.
	add_exp(0)
