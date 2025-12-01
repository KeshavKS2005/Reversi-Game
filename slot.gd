extends TextureRect

var grid_pos : Vector2i
var state : int = 0
signal slot_clicked(pos)
@onready var piece_sprite = $PieceSprite
func _ready():
	piece_sprite.visible = false
	#print("dfdf")
	#gui_input.connect(_on_gui_input)

func set_grid_pos(pos):
	grid_pos = pos
func set_state(new_state):
	state = new_state
	if state == 0:
		piece_sprite.hide()
	elif state == 1 : 
		piece_sprite.show()
		piece_sprite.modulate = Color.BLACK
	else :
		piece_sprite.show()
		piece_sprite.modulate= Color.WHITE
		
func _gui_input(event):
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if state == 0:
			slot_clicked.emit(grid_pos)
			
