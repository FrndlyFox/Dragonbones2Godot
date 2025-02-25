@tool
extends EditorPlugin

var dock

func _enter_tree() -> void:
	dock = preload("res://addons/Dragonbones2Godot/dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)
	preload("./reloader.gd").new()
	# print("db-import initialized")

func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.free()
