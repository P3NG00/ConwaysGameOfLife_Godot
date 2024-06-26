class_name CGOL
extends Node2D


# config
const DEFAULT_CELL_SIZE: int = 16
const COLOR_ACTIVE: Color = Color('#FFFFFF')
# const COLOR_INACTIVE: Color = Color('#101010')

# constants
const NEIGHBOR_OFFSETS: Array[Vector2i] = [
    Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
    Vector2i(-1,  0),                  Vector2i(1,  0),
    Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1),
]

# references
@onready var timer: Timer = $Timer
@onready var label_playing: Label = $UI/MarginContainer/LabelPlaying

# cell variables
static var current_state: bool = false
var cells: Array[Cell]

# display variables
var cell_size: int = DEFAULT_CELL_SIZE
var cell_draw_size: Vector2i = Vector2i(cell_size, cell_size)
var cell_grid_size: Vector2i # TODO remove, make infinite
var cell_grid_draw_size: Vector2i

# view drag variables
var mouse_drag_position_last: Vector2i = Vector2i.ZERO
var camera_offset: Vector2i = Vector2i.ZERO


# functions
func get_mouse_position() -> Vector2i:
    return get_viewport().get_mouse_position()

func adjust_grid_size_to_viewport() -> void:
    # ceil to make sure the grid is always big enough to cover the viewport
    cell_grid_size = (get_viewport_rect().size / cell_size).ceil()
    cell_grid_draw_size = cell_grid_size * cell_size

func create_cells() -> void:
    cells.clear()
    for x in cell_grid_size.x:
        for y in cell_grid_size.y:
            cells.append(Cell.new())
    queue_redraw()

func draw_cells() -> void:
    # draw cells
    for x in cell_grid_size.x:
        for y in cell_grid_size.y:
            draw_cell(x, y)

func draw_cell(x: int, y: int) -> void:
    # inactive color drawn as background, active color drawn as cell
    if not get_cell(x, y).active:
        return
    var draw_pos: Vector2i = Vector2i(x, y) * cell_size
    draw_rect(Rect2(draw_pos + camera_offset, cell_draw_size), COLOR_ACTIVE)

func get_cell(x: int, y: int) -> Cell:
    return cells[x + y * cell_grid_size.x]

func toggle_cell(x: int, y: int) -> void:
    var cell: Cell = get_cell(x, y)
    cell.active = not cell.active

func get_active_neighbors(x: int, y: int) -> int:
    var active_neighbors = 0
    for offset in NEIGHBOR_OFFSETS:
        # add grid size to fix negative modulo when wrapping around
        var nx: int = (x + offset.x + cell_grid_size.x) % cell_grid_size.x
        var ny: int = (y + offset.y + cell_grid_size.y) % cell_grid_size.y
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
    for x in cell_grid_size.x:
        for y in cell_grid_size.y:
            update_cell(x, y)
    queue_redraw()

func toggle_cell_under_mouse() -> void:
    var mpos: Vector2i = get_mouse_position() - camera_offset
    if mpos.x < 0 or mpos.x >= cell_grid_draw_size.x or mpos.y < 0 or mpos.y >= cell_grid_draw_size.y:
        return
    mpos /= cell_size
    toggle_cell(mpos.x, mpos.y)
    queue_redraw()

func update_mouse_drag() -> void:
    var mpos: Vector2i = get_mouse_position()
    camera_offset += mpos - mouse_drag_position_last
    mouse_drag_position_last = mpos
    queue_redraw()

func adjust_cell_size(adjustment: int) -> void:
    cell_size = max(1, cell_size + adjustment)
    cell_draw_size = Vector2i(cell_size, cell_size)
    cell_grid_draw_size = cell_grid_size * cell_size
    queue_redraw()

static func cell_state_index_current() -> int:
    return int(current_state)

static func cell_state_index_last() -> int:
    return int(not current_state)

func play() -> void:
    timer.start()
    label_playing.text = 'playing!'

func pause() -> void:
    timer.stop()
    label_playing.text = 'paused.'

func toggle_play_pause() -> void:
    play() if timer.is_stopped() else pause()


# cell
class Cell:
    # cell states that work off of a boolean flip.
    # states will take turns being used as the current active state and the cached previous state
    var _states: Array[bool] = [false, false]
    # used to set or get the current state of the cell
    var active: bool:
        set(value): _states[CGOL.cell_state_index_current()] = value
        get: return _states[CGOL.cell_state_index_current()]
    # used to check the last state of the cell
    var active_last: bool:
        get: return _states[CGOL.cell_state_index_last()]


# godot
func _ready() -> void:
    camera_offset = Vector2i.ZERO
    adjust_grid_size_to_viewport()
    create_cells()
    pause()

func _process(_delta: float) -> void:
    # play/pause
    if Input.is_action_just_pressed('cgol_play_pause'):
        toggle_play_pause()
    # next frame
    if Input.is_action_just_pressed('cgol_next_frame'):
        next_frame()
    # view drag
    if Input.is_action_just_pressed('cgol_drag_view'):
        mouse_drag_position_last = get_mouse_position()
    if Input.is_action_pressed('cgol_drag_view'):
        update_mouse_drag()
    # view zoom
    if Input.is_action_just_pressed('cgol_zoom_in'):
        adjust_cell_size(1)
    if Input.is_action_just_pressed('cgol_zoom_out'):
        adjust_cell_size(-1)

func _unhandled_input(event: InputEvent) -> void:
    # toggle cell under mouse
    # hardcoded to prevent toggling behind UI
    if not event is InputEventMouseButton:
        return
    var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
    if mouse_button_event.button_index != MOUSE_BUTTON_LEFT or not mouse_button_event.pressed:
        return
    toggle_cell_under_mouse()

func _draw() -> void:
    draw_cells()
