@tool
extends Control

@onready var picker = $VBoxContainer/ModelSelector/EditorResourcePicker

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func import_pressed() -> void:
	print("import pressed")
	if picker.edited_resource:
		print(type_string(typeof( picker.edited_resource )))
		process_import(picker.edited_resource)


func process_import(res: Resource) -> void:
	var res_path = res.resource_path
	var src = res.data
	var root = Node2D.new()

	for src_arm in src.armature:
		var arm = Skeleton2D.new()
		arm.name = src_arm.name
		root.add_child(arm)
		arm.owner = root
		var src_root = src_arm.bone[0].name

		var ik = {}
		if src_arm.has("ik"):
			for bone in src_arm.ik:
				ik[bone.target] = bone

		var bones = {}
		bones[src_root] = {bone=arm}
		var bones_names = []
		for bone_i in range(1, len(src_arm.bone)):
			var src_bone = src_arm.bone[bone_i]
			var bone
			if src_bone.name in ik:
				bone = Node2D.new()
				bone.editor_description = str(ik[src_bone.name])
			else:
				bone = Bone2D.new()
			bone.name = src_bone.name
			bone.position = Vector2(src_bone.transform.x if src_bone.transform.has("x") else 0, src_bone.transform.y if src_bone.transform.has("y") else 0)
			bone.rotation_degrees = src_bone.transform.skX if src_bone.transform.has("skX") else 0
			bones_names.append(src_bone.name)
			bones[src_bone.name] = {src = src_bone, bone = bone}
		
		print(bones_names)
		print(bones)
		# bones_names.reverse()
		for bone_name in bones_names:
			bones[bones[bone_name].src.parent].bone.add_child(bones[bone_name].bone)
		# bones bones bones
		for bone_name in bones_names:
			bones[bone_name].bone.owner = root

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
			slot.owner = root
			
			# var texture = Texture2D.new()
			slot.texture = load(res_path.substr(0, res_path.rfind("_"))+"_texture/"+src_slot.display[0].name+".png")
			# print(res_path.substr(0, res_path.rfind("_"))+"_texture/"+src_slot.name+".png")
		
		# TODO#1 setting rest for bones
		# for i in range(arm.get_bone_count()):
			# arm.get_bone(i).set_rest(arm.get_bone(i).transform)





	var scene = PackedScene.new()
	var result = scene.pack(root)
	if result == OK:
		var error = ResourceSaver.save(scene, res.resource_path.get_basename()+".tscn")  # Or "user://..."
		if error != OK:
			push_error(error)
