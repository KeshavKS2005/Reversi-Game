extends Control

@onready var player_start_btn = $VBoxContainer/PlayerStartButton
@onready var ai_start_btn = $VBoxContainer/AIStartButton
@onready var quit_btn = $VBoxContainer/QuitButton
@onready var rules_btn = $VBoxContainer/RulesButton

#@onready var enable_timer_check = $VBoxContainer2/EnableTimerCheck
#@onready var minutes_spinbox = $VBoxContainer2/MinutesSpinBox

@onready var enable_timer_check = $EnableTimerCheck
@onready var minutes_spinbox = $MinutesSpinBox

@onready var undo_check = $UndoCheck
@onready var confirm_start_btn = $StartGameButton

var selected_ai_mode: bool = false 

func _ready():
	player_start_btn.pressed.connect(_on_player_vs_player_selected)
	ai_start_btn.pressed.connect(_on_player_vs_ai_selected)
	quit_btn.pressed.connect(_on_quit_pressed)
	rules_btn.pressed.connect(_on_rules_pressed)
	confirm_start_btn.pressed.connect(_on_confirm_start_pressed)
	confirm_start_btn.disabled = true
	
func _on_rules_pressed():
	get_tree().change_scene_to_file("res://RulesPage.tscn")

func _on_player_vs_player_selected():
	selected_ai_mode = false
	print("Mode selected: 2 Player")
	_enable_start_button()
	

func _on_player_vs_ai_selected():
	selected_ai_mode = true
	print("Mode selected: AI")
	_enable_start_button()
	
func _enable_start_button():
	confirm_start_btn.disabled = false
func _on_confirm_start_pressed():
	GameGlobals.is_ai_mode = selected_ai_mode
	
	GameGlobals.is_timer_enabled = enable_timer_check.button_pressed
	if GameGlobals.is_timer_enabled:
		GameGlobals.timer_duration = int(minutes_spinbox.value) * 60
	
	GameGlobals.is_undo_enabled = undo_check.button_pressed
	
	get_tree().change_scene_to_file("res://board.tscn")

func _on_quit_pressed():
	get_tree().quit()
