extends CanvasLayer

# Get references to our new bars
@onready var health_bar = $HealthBar
@onready var exp_bar = $EXPBar
# --- NEW ---
# Get a reference to our new label
@onready var health_label = $HealthLabel
# --- NEW: Add a reference to the level label ---
@onready var level_label = $LevelLabel
# --- NEW: Add a reference to the wood label ---
@onready var wood_label = $WoodLabel


# --- NEW ---
# This function runs when the node is added to the scene
func _ready():
	# This tells the HUD to keep running, even when the game
	# is paused (get_tree().paused = true).
	# This is ESSENTIAL for the level up screen.
	process_mode = PROCESS_MODE_ALWAYS


# --- MODIFIED ---
# Renamed "max" to "p_max" to fix the warning
func _on_dwarf_player_health_updated(current, p_max):
	# NEW: Check if the bar is ready before using it
	# This fixes the "null instance" error
	if health_bar:
		# Update the health bar's max value and current value
		health_bar.max_value = p_max
		health_bar.value = current
	
	# --- NEW ---
	# Update the label's text to show the ratio
	if health_label:
		# We use str() to convert the numbers to text
		# We use int() to make sure they are whole numbers (e.g., 90, not 90.0)
		health_label.text = str(int(current)) + " / " + str(int(p_max))

# --- MODIFIED ---
# Renamed "max" to "p_max" to fix the warning
func _on_dwarf_player_exp_updated(current, p_max):
	# NEW: Check if the bar is ready before using it
	# This fixes the "null instance" error
	if exp_bar:
		# Update the EXP bar's max value and current value
		exp_bar.max_value = p_max
		exp_bar.value = current

# --- MODIFIED: Renamed function to match Godot's auto-generated signal name ---
func _on_DwarfPlayer_level_up(new_level):
	if is_instance_valid(level_label):
		level_label.text = "Level: " + str(new_level)

# --- NEW: This function will be connected to the player's 'wood_updated' signal ---
func _on_dwarf_player_wood_updated(new_total):
	if is_instance_valid(wood_label):
		wood_label.text = "Wood: " + str(new_total)
