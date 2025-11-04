extends CanvasLayer

# This signal will be sent to the player when a button is clicked
# It will carry the "key" of the powerup (e.g., "more_health")
signal powerup_selected(powerup_key)

# This is where we define our powerups.
# We'll pick 3 random ones from this dictionary.
var all_powerups = {
	"more_health": "Max Health +20",
	"more_speed": "Move Speed +25",
	"more_damage": "Axe Damage +10", # --- NEW POWERUP ---
	"more_chop_speed": "Chop Speed +25" # --- NEW POWERUP ---
}

# --- NEW: Add a reference to our new Title Label ---
@onready var title_label = $VBoxContainer/TitleLabel

# Get references to the buttons on our UI
@onready var option_button_1 = $VBoxContainer/OptionButton1
@onready var option_button_2 = $VBoxContainer/OptionButton2
@onready var option_button_3 = $VBoxContainer/OptionButton3

var presented_options = [] # This will store the keys for the 3 buttons
var current_level = 1 # This will be set by the player

# --- NEW: This function is called by the player ---
func set_level(new_level):
	current_level = new_level
	
	# Check if the label is ready yet
	if is_instance_valid(title_label):
		title_label.text = "You reached Level " + str(current_level) + "!"


func _ready():
	# This node needs to run *while the game is paused*.
	process_mode = PROCESS_MODE_ALWAYS
	
	# --- NEW: Set the title text ---
	# (This will run again, but it's good to have as a default)
	if is_instance_valid(title_label):
		title_label.text = "You reached Level " + str(current_level) + "!"
	
	# Get a list of all available powerup keys
	var powerup_keys = all_powerups.keys()
	
	# --- Choose 3 Random, Unique Options ---
	# (For now, we only have 2, so it will show both)
	presented_options.clear()
	powerup_keys.shuffle() # Randomize the list
	
	for i in min(powerup_keys.size(), 3): # Get up to 3 options
		presented_options.append(powerup_keys[i])
	
	# --- Set the Button Text ---
	# We use set_text() for the text and connect() for the signal
	
	# --- MODIFIED: Added checks to prevent crashes ---
	
	# Check for Option 1
	if presented_options.size() > 0 and is_instance_valid(option_button_1):
		var key1 = presented_options[0]
		var text_value = all_powerups.get(key1, "ERROR") # Get text, or "ERROR" if key is bad
		option_button_1.text = text_value
		option_button_1.pressed.connect(_on_button_pressed.bind(key1))
	elif is_instance_valid(option_button_1):
		option_button_1.visible = false # Hide button if it exists but we have no option

	# Check for Option 2
	if presented_options.size() > 1 and is_instance_valid(option_button_2):
		var key2 = presented_options[1]
		var text_value = all_powerups.get(key2, "ERROR")
		option_button_2.text = text_value
		option_button_2.pressed.connect(_on_button_pressed.bind(key2))
	elif is_instance_valid(option_button_2):
		option_button_2.visible = false # Hide button if it exists but we have no option
		
	# Check for Option 3
	if presented_options.size() > 2 and is_instance_valid(option_button_3):
		var key3 = presented_options[2]
		var text_value = all_powerups.get(key3, "ERROR")
		option_button_3.text = text_value
		option_button_3.pressed.connect(_on_button_pressed.bind(key3))
	elif is_instance_valid(option_button_3):
		option_button_3.visible = false # Hide button if it exists but we have no option


# This one function handles ALL button presses
func _on_button_pressed(powerup_key):
	# 1. Emit the signal back to the player
	powerup_selected.emit(powerup_key)
	
	# 2. Destroy this screen
	queue_free()
