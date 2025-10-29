extends Area2D

const DAMAGE = 100 # How much damage the axe swing does.

# This array prevents hitting the same enemy multiple times with one swing.
var hit_enemies = []

# This function is called automatically when another physics body enters the Area2D.
func _on_body_entered(body):
	# Check if the body is an enemy AND we haven't hit it yet.
	if body.is_in_group("enemy") and not body in hit_enemies:
		# Call its take_damage function.
		body.take_damage(DAMAGE)
		# Add it to the list of hit enemies.
		hit_enemies.append(body)

# This function is called when the self-destruct timer runs out.
func _on_timer_timeout():
	queue_free() # Destroy the hitbox.
