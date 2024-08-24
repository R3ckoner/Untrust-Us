extends Area3D

@export var collision_shape: CollisionShape3D  # Reference to the CollisionShape3D

var plot_min: Vector3  # Calculated minimum bounds of the plot
var plot_max: Vector3  # Calculated maximum bounds of the plot

func _ready():
    _update_plot_bounds()

func _update_plot_bounds():
    if collision_shape and collision_shape.shape is BoxShape3D:
        var box_shape = collision_shape.shape as BoxShape3D
        var shape_transform = collision_shape.global_transform

        var half_extents = box_shape.extents
        plot_min = shape_transform.origin - half_extents
        plot_max = shape_transform.origin + half_extents

        print("Plot bounds updated: (", plot_min, ") to (", plot_max, ")")

# Optionally, you can call this function manually if you need to update bounds dynamically
func update_bounds():
    _update_plot_bounds()
