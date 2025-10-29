extends Node2D

# 1. Add these variables here, at the top of the script.
const ENEMY_SCENE = preload("res://Scene/enemy.tscn")
@onready var spawn_location = $Path2D/SpawnLocation


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # We don't need anything here yet.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass # Or here.


# 2. Replace the 'pass' in this function with the spawning code.
func _on_timer_timeout():
	# Create a new instance of the enemy.
	var new_enemy = ENEMY_SCENE.instantiate()
	
	# Choose a random spot along the spawn path.
	spawn_location.progress_ratio = randf()
	
	# Set the enemy's position to that random spot.
	new_enemy.global_position = spawn_location.position
	
	# Add the new enemy to the game world.
	add_child(new_enemy)
