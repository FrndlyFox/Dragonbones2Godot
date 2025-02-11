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
		var bone = Node2D.new()
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

	# animations
	var src_anims = src_arm.animation

	# animation groups
	var anim_groups = {}
	for src_anim in src_anims:
		if src_anim.name.begins_with("groups"):
			for g in src_anim.name.split("="):
				var group = Array(g.split("+"))
				if group[0] == "groups":
					continue
				anim_groups[group[0]] = group
				# anim_groups[group[0]].remove_at(0)
	print(anim_groups)

	var anim_groups_reversed = {}
	for group in anim_groups:
		for bone_i in range(anim_groups[group].size()):
			if bone_i != 0:
				anim_groups_reversed[anim_groups[group][bone_i]] = group
	print("\n\nreversed:\n")
	print(anim_groups_reversed)

	var anim_root = Node2D.new()
	anim_root.name = "Animations"
	arm.add_child(anim_root)
	anim_root.owner = arm

	# create animation players
	for group in anim_groups:
		var animplayer = AnimationPlayer.new()
		var animlib = AnimationLibrary.new()
		animplayer.name = group
		anim_root.add_child(animplayer)
		animplayer.owner = arm
		animplayer.add_animation_library("", animlib)
		anim_groups[group][0] = animplayer
	# print(anim_groups)


	for src_anim in src_anims:
		if src_anim.name.begins_with("groups"):
			continue
		print(src_anim.name)
		for src_bone in src_anim.bone:
			var bone_parent = src_bone.name
			while not anim_groups_reversed.has(bone_parent):
				bone_parent = bones[bone_parent].src.parent
			var group = anim_groups_reversed[bone_parent]
			var animlib = anim_groups[group][0].get_animation_library("")
			if not animlib.has_animation("RESET"):
				animlib.add_animation("RESET", Animation.new())

			var anim
			if animlib.has_animation(src_anim.name):
				anim = animlib.get_animation(src_anim.name)
			else:
				anim = Animation.new()
				anim.set_length(src_anim.duration / src_arm.frameRate)
				anim.set_step(1 / src_arm.frameRate)
			print("|\t"+src_bone.name)

			if src_bone.has("translateFrame"):
				var track = anim.add_track(0)
				var path = src_bone.name
				bone_parent = src_bone.name
				while not anim_groups_reversed.has(bone_parent):
					bone_parent = bones[bone_parent].src.parent
					path = bone_parent+"/"+path
				path = "../"+path+":position"
				print("|\t|\tt: "+path)
				anim.track_set_path(track, path)
				var time = 0
				for frame in src_bone.translateFrame:
					pass
#TODO keyframes
			if src_bone.has("rotateFrame"):
				var track = anim.add_track(0)
				var path = src_bone.name
				bone_parent = src_bone.name
				while not anim_groups_reversed.has(bone_parent):
					bone_parent = bones[bone_parent].src.parent
					path = bone_parent+"/"+path
				path = "../"+path+":rotation"
				print("|\t|\tr: "+path)
				anim.track_set_path(track, path)
				var time = 0
				for frame in src_bone.rotateFrame:
					pass
				# print("|\t|\tframe")

			animlib.add_animation(src_anim.name, anim)





	# pack scene
	var scene = PackedScene.new()
	var result = scene.pack(arm)
	if result == OK:
		var error = ResourceSaver.save(scene, res.resource_path.get_basename()+".tscn")  # Or "user://..."
		if error != OK:
			push_error(error)
		else:
			print(res_path + " successfully imported")

