extends Area2D

# This will be set by the tree that drops it
var wood_amount = 1

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Play the wood item's animation (if it has one)
	# Make sure you have an "idle" animation
	if animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")


# This signal is connected from the Area2D
func _on_body_entered(body):
	# Check if the body that entered is the player
	if body.is_in_group("player"):
		# Give the wood to the player
		body.add_wood(wood_amount)
		
		# Destroy the wood drop
		queue_free()
