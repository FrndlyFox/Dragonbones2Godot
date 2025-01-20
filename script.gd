@tool
extends Control

var model_path
var src
# @onready var path_picker = $VBoxContainer/ModelSelector/EditorResoucePicker

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func import_pressed() -> void:
	print("import pressed")
