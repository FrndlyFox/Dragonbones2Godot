@tool
extends Control

# ROADMAP
# curves

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
		bones[bone_name].bone.owner = arm
	# bones bones bones

	# make slots (images)
	var slots = {}
	for slot_i in range(len(src_arm.slot)):
		var slot = src_arm.slot[slot_i]
		slots[slot.name] = {parent = slot.parent, z = slot_i}
	for src_slot in src_arm.skin[0].slot:
		var slot = Sprite2D.new()
		slot.name = src_slot.name
		slot.position = Vector2(src_slot.display[0].transform.x if src_slot.display[0].transform.has("x") else 0, 
														src_slot.display[0].transform.y if src_slot.display[0].transform.has("y") else 0)
		slot.rotation_degrees = src_slot.display[0].transform.skX if src_slot.display[0].transform.has("skX") else 0
		bones[slots[src_slot.name].parent].bone.add_child(slot)
		slot.owner = arm
		slot.texture = load(res_path.substr(0, res_path.rfind("_"))+"_texture/"+src_slot.display[0].name+".png")
		slot.z_as_relative = false
		slot.z_index = slots[src_slot.name].z

	# animations
	var src_anims = src_arm.animation

	var animplayer = AnimationPlayer.new()
	var animlib = AnimationLibrary.new()
	animlib.add_animation("RESET", Animation.new())
	animplayer.add_animation_library("", animlib)
	animplayer.name = "AnimationPlayer"
	arm.add_child(animplayer)
	animplayer.owner = arm

	for src_anim in src_anims:
		print(src_anim.name)
		var reset = animlib.get_animation("RESET")
		var anim = Animation.new()
		anim.set_length(src_anim.duration / src_arm.frameRate)
		anim.set_step(1 / src_arm.frameRate)
		if src_anim.playTimes == 0:
			anim.set_loop_mode(1)
		for src_bone in src_anim.bone:
			var path = src_bone.name
			var bone_parent = src_bone.name
			while bones[bone_parent].src.parent != src_root:
				bone_parent = bones[bone_parent].src.parent
				path = bone_parent+"/"+path
			print("\t" + src_bone.name + ":\t" + path)

			if src_bone.has("translateFrame"):
				var def_pos = bones[src_bone.name].bone.position
				var track = anim.add_track(0)
				anim.track_set_path(track, path+":position")
				if reset.find_track(path+":position", 0) < 0:
					var reset_track = reset.add_track(0)
					reset.track_set_path(reset_track, path+":position")
					reset.track_insert_key(reset_track,0,def_pos)
				var time = 0
				for frame in src_bone.translateFrame:
					var new_pos = def_pos
					if frame.has("x"):
						new_pos.x += frame.x
					if frame.has("y"):
						new_pos.y += frame.y
					anim.track_insert_key(track,time/src_arm.frameRate,new_pos)
					time += frame.duration if frame.has("duration") else 1

			if src_bone.has("rotateFrame"):
				var def_rot = bones[src_bone.name].bone.rotation
				var track = anim.add_track(0)
				anim.track_set_path(track, path+":rotation")
				if reset.find_track(path+":rotation", 0) < 0:
					var reset_track = reset.add_track(0)
					reset.track_set_path(reset_track, path+":rotation")
					reset.track_insert_key(reset_track,0,def_rot)
				var time = 0
				for frame in src_bone.rotateFrame:
					var new_rot = def_rot
					if frame.has("rotate"):
						new_rot += deg_to_rad(frame.rotate)
					anim.track_insert_key(track,time/src_arm.frameRate,new_rot)
					time += frame.duration if frame.has("duration") else 1

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
