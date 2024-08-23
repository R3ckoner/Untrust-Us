extends CogitoWieldable

@export_group("Pickaxe Settings")
@export var damage_area: Area3D

@export_group("Interaction")
@export var trigger_layer: int = 3  # Collision layer to trigger the interaction, adjustable in inspector

@export_group("Audio")
@export var swing_sound: AudioStream

@export var is_hoe: bool = true  # Add a flag to indicate if this pickaxe can also act as a hoe
@export var grid_size: float = 1.0  # Size of the grid for snapping
@export var highlight_material: StandardMaterial3D  # Material to use for the grid highlight
@export var highlight_size: Vector3 = Vector3(1, 1, 1)  # Size of the highlight, adjust as necessary
@export var highlight_offset: float = 0.05  # Slight offset to avoid z-fighting
@export var horizontal: bool = true  # Boolean to control orientation of the highlight

var trigger_has_been_pressed: bool = false
var can_till: bool = false  # Track whether tilling is allowed
var plot_area: Area3D  # Reference to the Plot area in the scene
var highlight_instance: MeshInstance3D  # Instance for the highlight mesh

func _ready():
    print("Pickaxe ready. Setting up...")

    if wieldable_mesh:
        wieldable_mesh.hide()

    damage_area.body_entered.connect(_on_damage_area_body_entered)

    # Search for the Plot node dynamically in the current scene
    plot_area = _find_plot_area()
    if plot_area:
        plot_area.body_entered.connect(_on_plot_area_body_entered)
        plot_area.body_exited.connect(_on_plot_area_body_exited)
        print("Plot area found and signals connected.")
    else:
        push_error("Plot area (Area3D) not found in the scene!")

    _create_highlight_instance()
    set_process(true)

func _find_plot_area() -> Area3D:
    var root = get_tree().root
    for child in root.get_children():
        if child.name == "menu_template_manager":
            continue  # Skip the menu_template_manager node
        var plot_node = child.get_node_or_null("Plot") as Area3D
        if plot_node:
            return plot_node
    return null

func _create_highlight_instance():
    highlight_instance = MeshInstance3D.new()
    highlight_instance.mesh = QuadMesh.new()  # Use a QuadMesh to act as the highlight
    highlight_instance.mesh.size = Vector2(grid_size, grid_size)  # Set the size of the QuadMesh
    highlight_instance.material_override = highlight_material
    highlight_instance.visible = false  # Start with the highlight hidden

    if horizontal:
        highlight_instance.rotation_degrees = Vector3(-90, 0, 0)  # Rotate to lie flat if horizontal is true
    else:
        highlight_instance.rotation_degrees = Vector3(0, 0, 0)  # Keep it vertical if horizontal is false

    add_child(highlight_instance)
    print("Highlight instance created.")

# Function to handle when the player enters the plot area
func _on_plot_area_body_entered(body: Node):
    print("Body entered plot area: ", body.name)
    if body.collision_layer == trigger_layer:
        print("Player entered plot area. Tilling enabled.")
        can_till = true  # Allow tilling

# Function to handle when the player exits the plot area
func _on_plot_area_body_exited(body: Node):
    print("Body exited plot area: ", body.name)
    if body.collision_layer == trigger_layer:
        print("Player exited plot area. Tilling disabled.")
        can_till = false  # Disable tilling
        highlight_instance.visible = false  # Hide the highlight when leaving the plot area

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
    if is_hoe and can_till:
        till_soil()

# Function to handle tilling the soil if the pickaxe is also a hoe
func till_soil():
    var player_interaction_component = CogitoSceneManager._current_player_node.player_interaction_component
    var grid_position = get_target_grid_position()

    if player_interaction_component and grid_position:
        player_interaction_component.till_soil_at_position(grid_position)

# Handle collision with objects for damage
func _on_damage_area_body_entered(collider):
    if collider.has_signal("damage_received"):
        collider.damage_received.emit(item_reference.wieldable_damage)

# Method to get the grid position the player is targeting
func get_target_grid_position() -> Vector3:
    var camera = CogitoSceneManager._current_player_node.camera
    var screen_center = camera.get_viewport().get_visible_rect().size / 2
    var from = camera.project_ray_origin(screen_center)
    var to = from + camera.project_ray_normal(screen_center) * 1000  # Cast a ray forward into the distance

    var query = PhysicsRayQueryParameters3D.new()
    query.from = from
    query.to = to
    query.collision_mask = trigger_layer  # Adjust this as needed

    var space_state = get_world_3d().direct_space_state
    var result = space_state.intersect_ray(query)

    if result and result.has("position"):
        var collision_point = result["position"]

        # Snap the collision point to the grid
        var snapped_position = Vector3(
            floor(collision_point.x / grid_size) * grid_size + grid_size / 2,
            collision_point.y,
            floor(collision_point.z / grid_size) * grid_size + grid_size / 2
        )

        # Update the highlight position and make it visible
        highlight_instance.global_transform.origin = snapped_position + Vector3(0, highlight_offset, 0)
        highlight_instance.visible = true

        return snapped_position

    # If no valid target is found, return the player's current position as a fallback
    highlight_instance.visible = false  # Hide the highlight if nothing is targeted
    return CogitoSceneManager._current_player_node.global_transform.origin

func _process(delta):
    if can_till:
        get_target_grid_position()  # Update the highlight in real-time based on where the player is looking
