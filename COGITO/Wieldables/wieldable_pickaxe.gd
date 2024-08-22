extends CogitoWieldable

@export_group("Pickaxe Settings")
@export var damage_area: Area3D

@export_group("Audio")
@export var swing_sound: AudioStream

@export var is_hoe: bool = true  # Add a flag to indicate if this pickaxe can also act as a hoe

var trigger_has_been_pressed: bool = false

func _ready():
	if wieldable_mesh:
		wieldable_mesh.hide()
		
	damage_area.body_entered.connect(_on_body_entered)

# Primary action called by the Player Interaction Component when the pickaxe is wielded.
func action_primary(_passed_item_reference: InventoryItemPD, _is_released: bool):
	if _is_released:
		return
	
	# Not swinging if the animation player is playing. This enforces swing rate.
	if animation_player.is_playing():
		return
	
	animation_player.play(anim_action_primary)
	audio_stream_player_3d.stream = swing_sound
	audio_stream_player_3d.play()
	
	# If the pickaxe can also act as a hoe, till the soil
	if is_hoe:
		till_soil()

# Function to handle tilling the soil if the pickaxe is also a hoe
func till_soil():
	var player_interaction_component = CogitoSceneManager._current_player_node.player_interaction_component
	var grid_position = get_target_grid_position()
	
	if player_interaction_component and grid_position:
		player_interaction_component.till_soil_at_position(grid_position)

# Handle collision with objects for damage
func _on_body_entered(collider):
	if collider.has_signal("damage_received"):
		collider.damage_received.emit(item_reference.wieldable_damage)

# Example method to get the grid position the player is targeting
func get_target_grid_position() -> Vector3:
	var raycast = CogitoSceneManager._current_player_node.player_interaction_component.interaction_raycast
	if raycast.is_colliding():
		return raycast.get_collision_point()
	
	# If no valid target is found, return the player's current position as a fallback
	return CogitoSceneManager._current_player_node.global_transform.origin
