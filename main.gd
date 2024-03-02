class_name CGOL
extends Node2D


# config
const CELL_SIZE: int = 16
const GRID_SIZE: Vector2i = Vector2i(60, 60)
const COLOR_ACTIVE: Color = Color('#FFFFFF')
const COLOR_INACTIVE: Color = Color('#101010')

# variables
const DRAW_SIZE: Vector2 = Vector2(CELL_SIZE, CELL_SIZE)
const MOUSE_MAX: Vector2i = GRID_SIZE * CELL_SIZE
const NEIGHBOR_OFFSETS: Array[Vector2i] = [
    Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
    Vector2i(-1,  0),                  Vector2i(1,  0),
    Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1),
]
static var current_state: bool = false
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

func get_cell(x: int, y: int) -> Cell:
    return cells[x + y * GRID_SIZE.x]

func get_cell_color(x: int, y: int) -> Color:
    return COLOR_ACTIVE if get_cell(x, y).active else COLOR_INACTIVE

func toggle_cell(x: int, y: int) -> void:
    var cell: Cell = get_cell(x, y)
    cell.active = not cell.active

func get_active_neighbors(x: int, y: int) -> int:
    var active_neighbors = 0
    for offset in NEIGHBOR_OFFSETS:
        var nx: int = x + offset.x
        var ny: int = y + offset.y
        if nx < 0 or nx >= GRID_SIZE.x or ny < 0 or ny >= GRID_SIZE.y:
            continue
        # use last state to check for active neighbors
        if get_cell(nx, ny).active_last:
            active_neighbors += 1
    return active_neighbors

func update_cell(x: int, y: int) -> void:
    var cell: Cell = get_cell(x, y)
    var active_neighbors: int = get_active_neighbors(x, y)
    # apply game of life rules (use last state to set new state)
    cell.active = active_neighbors == 2 or active_neighbors == 3 if cell.active_last else active_neighbors == 3

func next_frame() -> void:
    # flip states
    current_state = not current_state
    # update cells
    for x in GRID_SIZE.x:
        for y in GRID_SIZE.y:
            update_cell(x, y)


# cell
class Cell:
    # cell states that work off of a boolean flip.
    # states will take turns being used as the current active state and the cached previous state
    var _states: Array[bool] = [false, false]
    # used to set or get the current state of the cell
    var active: bool:
        set(value):
            _states[int(CGOL.current_state)] = value
        get:
            return _states[int(CGOL.current_state)]
    # used to check the last state of the cell
    var active_last: bool:
        get:
            return _states[int(not CGOL.current_state)]


# godot
func _ready() -> void:
    create_cells()

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed('cgol_next_frame'):
        next_frame()
        queue_redraw()

func _input(event: InputEvent) -> void:
    if not event is InputEventMouseButton:
        return
    var mouse_event: InputEventMouseButton = event as InputEventMouseButton
    if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
        return
    var mpos: Vector2 = mouse_event.position
    if mpos.x < 0 or mpos.x >= MOUSE_MAX.x or mpos.y < 0 or mpos.y >= MOUSE_MAX.y:
        return
    var x: int = int(mpos.x / CELL_SIZE)
    var y: int = int(mpos.y / CELL_SIZE)
    toggle_cell(x, y)
    queue_redraw()

func _draw() -> void:
    draw_cells()
