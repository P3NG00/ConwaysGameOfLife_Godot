class_name Cell
extends Sprite2D


# variables
var active: bool = false:
	set(value):
		active = value
		update_color()
	get:
		return active


# functions
func update_color() -> void:
	modulate = Master.color_active if active else Master.color_inactive


# godot
func _ready() -> void:
	update_color()
