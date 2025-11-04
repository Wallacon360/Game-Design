# tree.gd — with health-based idle variants
# Root: keep your existing `extends` line (e.g., `extends StaticBody2D`)
# Add/replace the body with this version. Create 3 idle animations in SpriteFrames:
# - "idle_full" (health > 65%)
# - "idle_mid" (32% < health <= 65%)
# - "idle_low" (health <= 32%)


@export var max_health: int = 100
var current_health: int
var is_dead := false


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


const WOOD_DROP_SCENE := preload("res://Scene/Wood.tscn") # adjust path if needed


const THRESHOLD_MID := 0.65
const THRESHOLD_LOW := 0.32


func _ready() -> void:
current_health = max_health
_play_idle_for_current_health()


func take_damage(amount: int) -> void:
if is_dead:
return


current_health -= amount


if current_health <= 0:
is_dead = true
# Let the player walk over the stump while the fall anim plays
collision_shape.set_deferred("disabled", true)
animated_sprite.stop()
animated_sprite.frame = 0
animated_sprite.play("fall")
return


# Choose the hit animation based on remaining health bands
var hit_anim: String
if current_health <= int(max_health * THRESHOLD_LOW):
hit_anim = "hit_3"
elif current_health <= int(max_health * THRESHOLD_MID):
hit_anim = "hit_2"
else:
hit_anim = "hit_1"


# Restart the chosen hit anim from frame 0 each time
animated_sprite.stop()
animated_sprite.frame = 0
animated_sprite.play(hit_anim)


func _on_animated_sprite_2d_animation_finished() -> void:
match animated_sprite.animation:
"hit_1", "hit_2", "hit_3":
_play_idle_for_current_health()
"fall":
if WOOD_DROP_SCENE:
var wood := WOOD_DROP_SCENE.instantiate()
get_parent().add_child(wood)
wood.global_position = global_position
queue_free()


func _play_idle_for_current_health() -> void:
# Picks the appropriate idle variant for the current health band
var idle_anim: String = _idle_anim_for_health(current_health)
animated_sprite.play(idle_anim)


func _idle_anim_for_health(hp: int) -> String:
if hp <= int(max_health * THRESHOLD_LOW):
return "idle_low"
elif hp <= int(max_health * THRESHOLD_MID):
return "idle_mid"
else:
return "idle_full"
