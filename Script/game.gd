extends Node2D

const ENEMY_SCENE = preload("res://Scene/enemy.tscn")
# --- NEW: Preload the Tree scene ---
const TREE_SCENE = preload("res://Scene/Tree.tscn")

# 1. Find the player using its group
var dwarf_player = null

# NEW: Add a reference to our new YSort node
# (Make sure you named it "Entities" in your scene)
@onready var y_sort_node = $Entities

# We can define the spawn distance here
@export var spawn_radius: int = 200

# --- NEW: Tree Generation ---
# --- MODIFIED: Tuned values for better density ---
@export var CHUNK_SIZE: int = 500 # How big each "area" is (in pixels)
@export var MIN_TREES_PER_CHUNK: int = 3
@export var MAX_TREES_PER_CHUNK: int = 8

# This keeps track of which chunks we've already generated
var visited_chunks = {}
# This tracks the player's current chunk
var current_chunk = Vector2i.ZERO


func _ready():
	dwarf_player = get_tree().get_first_node_in_group("player")
	
	if not dwarf_player:
		print("ERROR: Could not find node in group 'player'! Make sure your player is in that group.")
	
	# NEW: Check if the YSort node was found
	if not y_sort_node:
		print("ERROR: Could not find 'Entities' YSort node! Make sure you created it and named it correctly.")
	
	# NEW: Wait a frame for the player to be ready, then generate the first chunk
	# This prevents the player from spawning before the world
	await get_tree().create_timer(0.1).timeout
	check_chunk_generation()


# We now use _process to check for chunk changes
# --- MODIFIED: Changed 'delta' to '_delta' to fix warning ---
func _process(_delta):
	# Make sure the player is valid before checking
	if not is_instance_valid(dwarf_player):
		return
		
	# This will check if the player has moved to a new chunk
	# and spawn trees if necessary.
	check_chunk_generation()


# --- NEW FUNCTION ---
# This function handles all the logic for spawning trees in new areas
func check_chunk_generation():
	# 1. Calculate the player's current chunk coordinates
	var player_pos = dwarf_player.global_position
	# --- MODIFIED: Use float division for accuracy ---
	var player_chunk = Vector2i(int(player_pos.x / CHUNK_SIZE), int(player_pos.y / CHUNK_SIZE))
	
	# 2. Check if the player has moved to a new chunk
	if player_chunk != current_chunk:
		current_chunk = player_chunk
		# We've entered a new chunk, generate trees for it
		generate_trees_in_chunk(current_chunk)
		
		# --- OPTIONAL: Generate for surrounding chunks ---
		# This makes the world feel bigger, as you'll see
		# trees appear in the distance.
		generate_trees_in_chunk(current_chunk + Vector2i.UP)
		generate_trees_in_chunk(current_chunk + Vector2i.DOWN)
		generate_trees_in_chunk(current_chunk + Vector2i.LEFT)
		generate_trees_in_chunk(current_chunk + Vector2i.RIGHT)
		# --- NEW: Add diagonals so it looks more natural ---
		generate_trees_in_chunk(current_chunk + Vector2i(1, 1))
		generate_trees_in_chunk(current_chunk + Vector2i(1, -1))
		generate_trees_in_chunk(current_chunk + Vector2i(-1, 1))
		generate_trees_in_chunk(current_chunk + Vector2i(-1, -1))

# --- NEW FUNCTION ---
# This function spawns a random number of trees inside a given chunk
func generate_trees_in_chunk(chunk_coords: Vector2i):
	# 1. Check if we have *already* generated trees for this chunk
	if visited_chunks.has(chunk_coords):
		return # We have, so do nothing.
	
	# 2. This is a new chunk! Mark it as "visited".
	visited_chunks[chunk_coords] = true
	
	# 3. Calculate how many trees to spawn
	var num_trees = randi_range(MIN_TREES_PER_CHUNK, MAX_TREES_PER_CHUNK)
	
	# 4. Find the top-left corner of this chunk in world coordinates
	var chunk_origin = Vector2(chunk_coords) * CHUNK_SIZE
	
	# 5. Spawn the trees
	for i in num_trees:
		var tree = TREE_SCENE.instantiate()
		
		# Pick a random location *inside* this chunk
		var x_pos = randf_range(chunk_origin.x, chunk_origin.x + CHUNK_SIZE)
		var y_pos = randf_range(chunk_origin.y, chunk_origin.y + CHUNK_SIZE)
		
		tree.global_position = Vector2(x_pos, y_pos)
		
		# Add the tree to the YSort node
		y_sort_node.add_child(tree)


func _on_timer_timeout():
	if not is_instance_valid(dwarf_player):
		dwarf_player = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(dwarf_player):
			return
		
	var new_enemy = ENEMY_SCENE.instantiate()
	
	var player_pos = dwarf_player.global_position
	var random_angle = randf() * 2 * PI
	var offset = Vector2(spawn_radius, 0).rotated(random_angle)
	new_enemy.global_position = player_pos + offset
	
	# --- CHANGED LINE ---
	# Add the new enemy to the YSort node so it gets sorted
	if y_sort_node:
		y_sort_node.add_child(new_enemy)
	else:
		# Fallback just in case
		add_child(new_enemy)
