@tool
extends EditorPlugin

var dock

func _enter_tree() -> void:
	dock = preload("res://addons/Dragonbones2Godot/dock.tscn").instantiate()
	var picker = EditorResourcePicker.new()
	dock.get_node("VBoxContainer/ModelSelector").add_child(picker)
	picker.name = "EditorResourcePicker"
	picker.base_type = "JSON"
	picker.size_flags_horizontal = 3
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)
	preload("./reloader.gd").new()
	# print("db-import initialized")

func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.free()
