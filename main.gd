extends Node2D


# variables
@export var cell_size: int = 16
@export var grid_size: Vector2i = Vector2i(16, 16)
@export var color_active: Color = Color.WHITE
@export var color_inactive: Color = Color.BLACK

# constants
const cell_scene: PackedScene = preload('res://cell.tscn')


# functions
func create_cells() -> void:
	var offset: Vector2 = ((Vector2(grid_size) * cell_size) / 2) - (Vector2(cell_size, cell_size) / 2)
	for x in grid_size.x:
		for y in grid_size.y:
			var cell: Cell = cell_scene.instantiate()
			var new_position: Vector2 = (Vector2(x, y) * cell_size) - offset
			cell.position = new_position
			add_child(cell)


# godot
func _ready() -> void:
	Master.color_active = color_active
	Master.color_inactive = color_inactive
	create_cells()
