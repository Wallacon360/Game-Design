extends Area2D

var exp_value = 25 # Default value, will be overwritten by enemy

# --- All movement and attraction variables have been removed ---
# var player = null
# var velocity = Vector2.ZERO

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	# --- Simplified ---
	# We don't need to get the player, we just
	# wait for them to walk into our Area2D.
	
	# Play the animation (make sure you have one named "idle")
	animated_sprite.play("idle")


# --- REMOVED ---
# The entire _physics_process function is gone.
# The gem will no longer move, float, or fly to the player.


# This signal is connected from the Area2D in the editor
func _on_body_entered(body):
	# Check if the body that entered is the player
	if body.is_in_group("player"):
		# Give the EXP to the player
		body.add_exp(exp_value)
		
		# Destroy the gem
		queue_free()
