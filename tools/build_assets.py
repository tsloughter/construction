"""Run with Blender: blender -b --python tools/build_assets.py.

Builds the toy excavator and the pebble. The saved .blend files are editable;
the game uses the exported GLBs, so Blender isn't needed to run the project.
Static parts are merged per pivot so each vehicle is a handful of meshes.
"""
import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import bpy
from toy_parts import ball, box, empty, export, join, material, reset_scene, rod, wheel

(ROOT / 'assets' / 'models').mkdir(parents=True, exist_ok=True)
reset_scene()

yellow = material('Sunshine yellow', 'FFC637')
dark = material('Blueberry rubber', '344A79', 0.0, .9)
tread = material('Toy tread', '46618F', 0.0, .9)
steel = material('Sky blue hubs', '86CFEC', 0.0, .7)
glass = material('Pool blue windows', '56BECF', 0.0, .6)
black = material('Friendly pupils', '233A5A', 0.0, .9)
lamp = material('Warm white', 'FFFBEF', 0.0, .9)
orange = material('Tangerine bucket', 'FF9454', 0.0, .7)

root = empty('LittleDigger')
chassis = empty('Chassis', parent=root)
body = [box('Soft chassis', (0,.65,0), (2.7,.65,2.9), yellow, chassis, .25)]
for x in (-1.20, 1.20):
    side = 'Left' if x < 0 else 'Right'
    body.append(box(side+' soft track', (x,.55,0), (.85,1.0,3.4), dark, chassis, .40))
    for i, z in enumerate((-1.03, 0, 1.03)):
        wheel(side+' wheel '+str(i), (x,.55,z), .35, .9, steel, lamp, tread, chassis)
join('Chassis body', body)

upper = empty('Upper', (0,1.15,0), root)
cabin = [box('Round yellow body', (0,.35,.15), (2.8,.8,2.8), yellow, upper, .3),
         box('Plump back', (0,.68,.95), (2.7,.9,1.0), yellow, upper, .28),
         box('Cab', (-.6,1.2,-.1), (1.45,1.7,1.65), glass, upper, .24),
         box('Sunny roof', (-.6,2.07,-.1), (1.7,.23,1.95), yellow, upper, .10)]
# A friendly face on the front cab window only, so the digger always looks
# where it is going.
face_z = -.95
for x in (-.93, -.31):
    cabin.append(ball('White eye', (x,1.45,face_z), (.25,.29,.10), lamp, upper))
    cabin.append(ball('Pupil', (x+.04,1.44,face_z-.095), (.10,.15,.045), black, upper, 10, 8))
for i in range(7):
    x = -.94+i*.11
    y = 1.00+.17*((x+.61)/.33)**2
    cabin.append(ball('Smile', (x,y,face_z-.04), (.07,.055,.025), black, upper, 8, 6))
cabin.append(ball('Orange button', (.73,1.0,.8), (.2,.15,.2), orange, upper))
join('Upper body', cabin)

boom = empty('Boom', (.35,.66,-.55), upper)
join('Boom arm', [box('Chunky boom', (0,.1,-1.50), (.58,.57,3.3), yellow, boom, .23),
                  rod('Big boom hinge', (-.4,0,0), (.4,0,0), .31, orange, boom, 24),
                  rod('Blue boom joint', (-.37,0,-3.1), (.37,0,-3.1), .29, steel, boom, 24)])
stick = empty('Stick', (0,0,-3.1), boom)
join('Stick arm', [box('Chunky little arm', (0,0,-1.43), (.43,.45,3.1), yellow, stick, .19)])
bucket = empty('Bucket', (0,0,-3), stick)
# A wide, rounded scoop, with no sharp teeth or tiny mechanical parts.
scoop = [box('Bucket floor', (0,-.62,-.48), (1.9,.25,1.45), orange, bucket, .10),
         box('Bucket back', (0,-.24,.16), (1.9,.85,.24), orange, bucket, .10)]
for x in (-.88, .88):
    scoop.append(box('Bucket side', (x,-.29,-.43), (.22,.9,1.42), orange, bucket, .1))
scoop.append(rod('Bucket joint', (-.6,0,0), (.6,0,0), .23, steel, bucket, 24))
join('Scoop', scoop)
empty('CarrySocket', (0,-.05,-.50), bucket)
boom.rotation_euler.x = math.radians(52)
stick.rotation_euler.x = math.radians(-110)
bucket.rotation_euler.x = math.radians(58)
export('excavator', ROOT)

reset_scene()
rock_mat = material('Pebble base', 'FFFFFF', 0, .95)
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=.72)
rock = bpy.context.object
rock.name = 'Pebble'
random.seed(14)
for vert in rock.data.vertices:
    vert.co *= random.uniform(.93, 1.07)
    vert.co.z *= .82
for face in rock.data.polygons:
    face.use_smooth = True
rock.data.materials.append(rock_mat)
soft = rock.modifiers.new('Soft pebble', 'SUBSURF')
soft.levels = 1
export('boulder', ROOT)
print('Little Digger toy assets built.')
