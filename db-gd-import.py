import json
import math
from sys import argv
# from pprintpp import pprint


with open(argv[1]) as src_file:
    src = json.loads( src_file.read() )
with open(argv[2]) as scene_file:
    scene = scene_file.read()


arm = src['armature'][0]
root = arm['bone'][0]['name']

bones = {}
for bone_i,bone in enumerate(arm['bone']):
    if bone_i == 0:
        continue
    bones[bone['name']] = bone
    print(bone)        
    scene += f'[node name="{bone['name']}" type="Node2D" parent="{'.' if bone['parent'] == root else bone['parent']}"]\n'
    scene += f'position = Vector2({bone['transform']['x'] if 'x' in bone['transform'].keys() else 0}, {bone['transform']['y']})\n'
    scene += f'rotation = {round(math.radians(bone['transform']['skX']-0), 8)}\n\n'

slots_parents = {}
for slot in arm['slot']:
    slots_parents[slot['name']] = slot['parent']
print(slots_parents)
for slot_i,slot in enumerate(arm['skin'][0]['slot']):
    print(slot)
    slot_parent = slots_parents[slot['name']]
    slot_parent_full = slots_parents[slot['name']]
    while bones[slot_parent]['parent']!= 'root':
        slot_parent = bones[slot_parent]['parent']
        slot_parent_full = f'{slot_parent}/{slot_parent_full}'
    scene += f'[node name="{slot['name']}" type="Sprite2D" parent="{slot_parent_full}"]\n'
    scene += f'rotation = {round(math.radians(slot['display'][0]['transform']['skX']+0), 8)}\n'
    scene += f'position = Vector2({slot['display'][0]['transform']['x']}, \
{slot['display'][0]['transform']['y']})\n\n'


print(scene)

with open(argv[3], 'w') as file:
    file.write(scene)
