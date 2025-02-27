@tool
extends Control

# ROADMAP
# curves

# VARS REFERENCE
# bones = {
# 	<name> = {
# 		model: {},
# 		bone: Node2D
#		}
# }
# 	
# }
#
# slots = {
# 	<name> = {
# 		slot: Sprite2D,
# 		parent: String,
# 		z: int
# 	}
# }
#
# atlas_regions = {
# 	<slot_name>: Rect2
# }
#
# skins = [
# 	{
# 		slots = {
# 			<name> = {
# 				slot: Sprite2D,
# 				parent: String = <bone name>,
# 				display_index: int,
# 				z: int,
# 				displays = [
# 					{
# 						name: String
# 						pos: Vector2,
# 						scl: Vector2,
# 						rot: int
# 					}
# 				]
# 			}
# 		}
# 	}
# ]

@onready var modelpicker = %Main/Properties/Properties/Model
@onready var atlaspicker = %Main/Properties/Properties/Atlas

func _atlas_mode_toggled(toggled_on: bool) -> void:
	%Main/Properties/Properties/Atlas.visible = toggled_on
	%Main/Properties/Labels/Atlas.visible = toggled_on

func _import_pressed() -> void:
	if modelpicker.edited_resource:
		process_import(modelpicker.edited_resource,
			%Main/Properties/Properties/AtlasMode.button_pressed,
			atlaspicker.edited_resource)

func process_import(model_res: Resource, atlas_mode: bool = false, atlas_res: Resource = null) -> void:
	var model_path = model_res.resource_path
	var model = model_res.data
	var atlas
	var atlas_path
	if atlas_mode:
		atlas = atlas_res.data
		atlas_path = model_path.get_base_dir()+"/"+atlas.imagePath

	# make root
	var model_arm = model.armature[0]
	var arm = Node2D.new()
	arm.name = model.name
	var model_root = model_arm.bone[0].name

	# make bones
	var bones = {}
	bones[model_root] = {bone=arm}
	var bones_list = []
	for bone_i in range(1, len(model_arm.bone)):
		var model_bone = model_arm.bone[bone_i]
		var bone = Node2D.new()
		bone.name = model_bone.name
		bone.position = Vector2(model_bone.transform.x if model_bone.transform.has("x") else 0, model_bone.transform.y if model_bone.transform.has("y") else 0)
		bone.rotation_degrees = model_bone.transform.skX if model_bone.transform.has("skX") else 0
		bones_list.append(model_bone.name)
		bones[model_bone.name] = {model = model_bone, bone = bone}
	
	# sort bones
	for bone_name in bones_list:
		bones[bones[bone_name].model.parent].bone.add_child(bones[bone_name].bone)
		bones[bone_name].bone.owner = arm
	# bones bones bones

	# parse atlas regions, slots and skins
	var atlas_regions = {}
	if atlas_mode:
		for slot in atlas.SubTexture:
			atlas_regions[slot.name] = Rect2(slot.x, slot.y, slot.width, slot.height)
	var slots = {}
	for slot_i in range(len(model_arm.slot)):
		var slot = model_arm.slot[slot_i]
		slots[slot.name] = {display_index = slot.displayIndex if slot.has("displayIndex") else 0,
												parent = slot.parent, z = slot_i}

	var skins = []
	for model_skin in model_arm.skin:
		var skin = {}
		skin.slots = {}
		for model_slot in model_skin.slot:
			var slot = {}
			slot.parent = slots[model_slot.name].parent
			slot.display_index = slots[model_slot.name].display_index
			slot.z = slots[model_slot.name].z
			slot.displays = []
			for model_display in model_slot.display:
				var display = {name = model_display.name,
											pos = Vector2(),
											scl = Vector2(),
											rot = 0, region = Rect2()}
				if model_display.has("transform"):
					display.pos = Vector2(model_display.transform.x if model_display.transform.has("x") else 0,
																model_display.transform.y if model_display.transform.has("y") else 0)
					display.scl = Vector2(model_display.transform.scX if model_display.transform.has("scX") else 1,
																model_display.transform.scY if model_display.transform.has("scY") else 1)
					display.rot = deg_to_rad(model_display.transform.skX) if model_display.transform.has("skX") else 0
				if atlas_mode:
					display.region = atlas_regions[model_display.name]

				slot.displays.append(display)
				skin.slots[model_slot.name] = slot
		skins.append(skin)
	# Log.prn(skins)

	# make slots
	for slot_name in skins[0].slots:
		var model_slot = skins[0].slots[slot_name]
		var slot = Sprite2D.new()
		skins[0].slots[slot_name].slot = slot
		slot.name = slot_name
		bones[model_slot.parent].bone.add_child(slot)
		slot.owner = arm
		slot.z_as_relative = false
		slot.z_index = model_slot.z
		if atlas_mode:
			slot.texture = load(atlas_path)
			slot.region_enabled = true
		if model_slot.display_index >= 0:
			var display = model_slot.displays[model_slot.display_index]
			slot.position = display.pos
			slot.scale = display.scl
			slot.rotation = display.rot
			if atlas_mode:
				slot.region_rect = atlas_regions[display.name]
			else:
				slot.texture = load(model_path.substr(0, model_path.rfind("_"))+"_texture/"+display.name+".png")


	# animations
	var animplayer = AnimationPlayer.new()
	var animlib = AnimationLibrary.new()
	animlib.add_animation("RESET", Animation.new())
	animplayer.add_animation_library("", animlib)
	animplayer.name = "AnimationPlayer"
	arm.add_child(animplayer)
	animplayer.owner = arm

	for model_anim in model_arm.animation:
		# print(model_anim.name)
		var reset = animlib.get_animation("RESET")
		var anim = Animation.new()
		animlib.add_animation(model_anim.name, anim)
		anim.set_length(model_anim.duration / model_arm.frameRate)
		anim.set_step(1 / model_arm.frameRate)
		if model_anim.playTimes == 0:
			anim.set_loop_mode(1)

#-- bones ---------------------------------------------------------------------
		for model_bone in (model_anim.bone if model_anim.has("bone") else []):
			var path = String(arm.get_path_to(bones[model_bone.name].bone))
			# print("\t" + model_bone.name + ":\t" + path)

			if model_bone.has("translateFrame"):
				var def_pos = bones[model_bone.name].bone.position
				var track = anim.add_track(0)
				anim.track_set_path(track, path+":position")
				if reset.find_track(path+":position", 0) < 0:
					var reset_track = reset.add_track(0)
					reset.track_set_path(reset_track, path+":position")
					reset.track_insert_key(reset_track,0,def_pos)
				var time = 0
				for frame in model_bone.translateFrame:
					var new_pos = def_pos
					if frame.has("x"):
						new_pos.x += frame.x
					if frame.has("y"):
						new_pos.y += frame.y
					anim.track_insert_key(track,time/model_arm.frameRate,new_pos)
					time += frame.duration if frame.has("duration") else 1

			if model_bone.has("rotateFrame"):
				var def_rot = bones[model_bone.name].bone.rotation
				var track = anim.add_track(0)
				anim.track_set_path(track, path+":rotation")
				if reset.find_track(path+":rotation", 0) < 0:
					var reset_track = reset.add_track(0)
					reset.track_set_path(reset_track, path+":rotation")
					reset.track_insert_key(reset_track,0,def_rot)
				var time = 0
				for frame in model_bone.rotateFrame:
					var new_rot = def_rot
					if frame.has("rotate"):
						new_rot += deg_to_rad(frame.rotate)
					anim.track_insert_key(track,time/model_arm.frameRate,new_rot)
					time += frame.duration if frame.has("duration") else 1

#-- slots ---------------------------------------------------------------------
		for model_slot in (model_anim.slot if model_anim.has("slot") else []):
			var slot = skins[0].slots[model_slot.name]
			var path = String(arm.get_path_to(slot.slot))
			# print(model_slot.name+": "+path)
			if model_slot.has("displayFrame"):
				var pos_track = anim.add_track(0)
				anim.value_track_set_update_mode(pos_track,1)
				var scl_track = anim.add_track(0)
				anim.value_track_set_update_mode(scl_track,1)
				var rot_track = anim.add_track(0)
				anim.value_track_set_update_mode(rot_track,1)
				var reg_track = anim.add_track(0)
				anim.value_track_set_update_mode(reg_track,1)
				if not atlas_mode:
					if reset.find_track(path+":texture", 0) < 0:
						var reset_track = reset.add_track(0)
						reset.track_set_path(reset_track, path+":texture")
						reset.track_insert_key(reset_track,0,slot.slot.texture)
				else:
					if reset.find_track(path+":region_rect", 0) < 0:
						var reset_track = reset.add_track(0)
						reset.track_set_path(reset_track, path+":region_rect")
						reset.track_insert_key(reset_track,0,slot.slot.region_rect)

				var time = 0
				for frame in model_slot.displayFrame:
					var dis_index = frame.value if frame.has("value") else 0
					var display = skins[0].slots[model_slot.name].displays[dis_index]
					anim.track_set_path(pos_track, path+":position")
					anim.track_insert_key(pos_track,time/model_arm.frameRate,display.pos if dis_index >= 0 else Vector2())
					anim.track_set_path(scl_track, path+":scale")
					anim.track_insert_key(scl_track,time/model_arm.frameRate,display.scl if dis_index >= 0 else Vector2(1,1))
					anim.track_set_path(rot_track, path+":rotation")
					anim.track_insert_key(rot_track,time/model_arm.frameRate,display.rot if dis_index >= 0 else 0)

					if atlas_mode:
						anim.track_set_path(reg_track, path+":region_rect")
						anim.track_insert_key(reg_track,time/model_arm.frameRate,display.region if dis_index >= 0 else Rect2())
					else:
						pass
					time += frame.duration if frame.has("duration") else 1





	# pack scene
	var scene = PackedScene.new()
	var result = scene.pack(arm)
	if result == OK:
		var error = ResourceSaver.save(scene, model_path.get_basename()+".tscn")  # Or "user://..."
		if error != OK:
			push_error(error)
		else:
			print(model_path + " successfully imported")

