@tool
extends Control

@onready var picker = $VBoxContainer/ModelSelector/EditorResourcePicker

func _import_pressed() -> void:
	if picker.edited_resource:
		process_import(picker.edited_resource)

func process_import(res: Resource) -> void:
	var res_path = res.resource_path
	var src = res.data

	# make root
	var src_arm = src.armature[0]
	var arm = Node2D.new()
	arm.name = src_arm.name
	var src_root = src_arm.bone[0].name

	# make bones
	var bones = {}
	bones[src_root] = {bone=arm}
	var bones_list = []
	for bone_i in range(1, len(src_arm.bone)):
		var src_bone = src_arm.bone[bone_i]
		var bone
		bone = Node2D.new()
		bone.name = src_bone.name
		bone.position = Vector2(src_bone.transform.x if src_bone.transform.has("x") else 0, src_bone.transform.y if src_bone.transform.has("y") else 0)
		bone.rotation_degrees = src_bone.transform.skX if src_bone.transform.has("skX") else 0
		bones_list.append(src_bone.name)
		bones[src_bone.name] = {src = src_bone, bone = bone}
	
	# sort bones
	for bone_name in bones_list:
		bones[bones[bone_name].src.parent].bone.add_child(bones[bone_name].bone)
	# bones bones bones
	for bone_name in bones_list:
		bones[bone_name].bone.owner = arm

	# make slots (images)
	var slot_names = {}
	for slot in src_arm.slot:
		slot_names[slot.name] = slot.parent
	for src_slot in src_arm.skin[0].slot:
		var slot = Sprite2D.new()
		slot.name = src_slot.name
		slot.position = Vector2(src_slot.display[0].transform.x if src_slot.display[0].transform.has("x") else 0, 
														src_slot.display[0].transform.y if src_slot.display[0].transform.has("y") else 0)
		slot.rotation_degrees = src_slot.display[0].transform.skX if src_slot.display[0].transform.has("skX") else 0
		bones[slot_names[src_slot.name]].bone.add_child(slot)
		slot.owner = arm
		slot.texture = load(res_path.substr(0, res_path.rfind("_"))+"_texture/"+src_slot.display[0].name+".png")





	# pack scene
	var scene = PackedScene.new()
	var result = scene.pack(arm)
	if result == OK:
		var error = ResourceSaver.save(scene, res.resource_path.get_basename()+".tscn")  # Or "user://..."
		if error != OK:
			push_error(error)
		else:
			print(res_path + " successfully imported")
