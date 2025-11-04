extends Area2D

# --- MODIFIED: Separate Damage Types ---
@export var AxeDamage: int = 20  # Damage for enemies
@export var ChopDamage: int = 100 # Damage for trees

# --- MODIFIED: Changed to an Array of sounds ---
# (Make sure to change these paths to match your 2 sound files!)
const AXE_HIT_SOUNDS = [
	preload("res://Assets/Audio/axe_hit_1.wav"),
	preload("res://Assets/Audio/axe_hit_2.wav")
]

# This array prevents hitting the same body multiple times with one swing.
var hit_bodies_this_swing = [] # Renamed for clarity

# --- NEW: Add a reference to the sound node ---
@onready var axe_hit_sound = $AxeHitSound

# This function is called automatically when another physics body enters the Area2D.
func _on_body_entered(body):
	# Check if we haven't hit this body yet with this swing
	if body in hit_bodies_this_swing:
		return

	var damage_to_deal = 0
	
	# --- MODIFIED: Apply damage based on group ---
	if body.is_in_group("enemy"):
		damage_to_deal = AxeDamage
	elif body.is_in_group("trees"):
		damage_to_deal = ChopDamage
	else:
		return # Not an enemy or a tree, so do nothing

	# Call its take_damage function
	body.call_deferred("take_damage", damage_to_deal)
	
	# Play a sound
	if is_instance_valid(axe_hit_sound) and not AXE_HIT_SOUNDS.is_empty():
		var random_sound = AXE_HIT_SOUNDS.pick_random()
		axe_hit_sound.stream = random_sound
		axe_hit_sound.play()
	
	# Add it to the list of hit bodies for this swing
	hit_bodies_this_swing.append(body)


# This function is called when the self-destruct timer runs out.
func _on_timer_timeout():
	queue_free() # Destroy the hitbox.
