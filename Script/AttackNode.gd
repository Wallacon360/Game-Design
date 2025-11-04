extends Node

const AXE_HITBOX_SCENE = preload("res://Scene/AxeHitbox.tscn")

# This function will be called by the player to spawn a hitbox
func spawn_axe_hitbox():
	var hitbox = AXE_HITBOX_SCENE.instantiate()
	return hitbox
