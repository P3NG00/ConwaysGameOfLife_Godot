extends Node2D


# config
const CELL_SIZE: int = 16
const GRID_SIZE: Vector2i = Vector2i(60, 60)
const COLOR_ACTIVE: Color = Color('#FFFFFF')
const COLOR_INACTIVE: Color = Color('#101010')

# variables
const DRAW_SIZE: Vector2 = Vector2(CELL_SIZE, CELL_SIZE)
var cells: Array[Cell]


# functions
func create_cells() -> void:
    for x in GRID_SIZE.x:
        for y in GRID_SIZE.y:
            cells.append(Cell.new())

func draw_cells() -> void:
    for x in GRID_SIZE.x:
        for y in GRID_SIZE.y:
            draw_cell(x, y)

func draw_cell(x: int, y: int) -> void:
    var draw_pos: Vector2 = Vector2(x, y) * CELL_SIZE
    var color = get_cell_color(x, y)
    draw_rect(Rect2(draw_pos, DRAW_SIZE), color)

func get_cell_index(x: int, y: int) -> int:
    return x + y * GRID_SIZE.x

func get_cell(x: int, y: int) -> Cell:
    return cells[get_cell_index(x, y)]

func get_cell_color(x: int, y: int) -> Color:
    return COLOR_ACTIVE if get_cell(x, y).active else COLOR_INACTIVE

func toggle_cell(x: int, y: int) -> void:
    var cell: Cell = get_cell(x, y)
    cell.active = not cell.active

func handle_click(x: int, y: int) -> void:
    toggle_cell(x, y)
    queue_redraw()


# cell
class Cell:
    var active: bool = false
    # TODO keep track of last state for comparison while updating active state


# godot
func _ready() -> void:
    create_cells()

func _input(event: InputEvent) -> void:
    if not event is InputEventMouseButton:
        return
    var mouse_event: InputEventMouseButton = event as InputEventMouseButton
    if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
        return
    var x: int = int(mouse_event.position.x / CELL_SIZE)
    var y: int = int(mouse_event.position.y / CELL_SIZE)
    handle_click(x, y)

func _draw() -> void:
    draw_cells()
