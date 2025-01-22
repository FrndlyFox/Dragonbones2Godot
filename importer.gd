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
		var arm = Node2D.new()
		arm.name = src_arm.name
		root.add_child(arm)
		arm.owner = root

		var src_root = src_arm.bone[0].name
		var bones = {}
		bones[src_root] = {bone=arm}
		var bones_names = []
		for bone_i in range(1, len(src_arm.bone)):
			var src_bone = src_arm.bone[bone_i]
			var bone = Node2D.new()
			bone.name = src_bone.name
			bone.position = Vector2(src_bone.transform.x if src_bone.transform.has("x") else 0, src_bone.transform.y if src_bone.transform.has("y") else 0)
			bone.rotation_degrees = src_bone.transform.skX if src_bone.transform.has("skX") else 0
			bones_names.append(src_bone.name)
			bones[src_bone.name] = {src = src_bone, bone = bone}
		
		print(bones_names)
		print(bones)
		# bones_names.reverse()
		for bname in bones_names:
			bones[bones[bname].src.parent].bone.add_child(bones[bname].bone)
		for bname in bones_names:
			bones[bname].bone.owner = root

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







	var scene = PackedScene.new()
	var result = scene.pack(root)
	if result == OK:
		var error = ResourceSaver.save(scene, res.resource_path.get_basename()+".tscn")  # Or "user://..."
		if error != OK:
			push_error(error)
