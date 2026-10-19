"""Run with Blender: blender -b --python tools/build_assets.py.

The modeling helpers accept Godot coordinates (X right, Y up, -Z forward).
The saved .blend is editable; the game uses exported GLBs, so Blender isn't
needed to open or run the Godot project.
"""
import bpy
import math
import random
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "models"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def v(p):
    return Vector((p[0], -p[2], p[1]))

def material(name, hex_color, metallic=0.0, roughness=0.55):
    srgb = tuple(int(hex_color[i:i+2], 16) / 255 for i in (0, 2, 4))
    c = tuple(n / 12.92 if n <= .04045 else ((n + .055) / 1.055)**2.4 for n in srgb)
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*c, 1)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*c, 1)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    return m

yellow = material('Sunshine yellow', 'FFC637', 0.0, .65)
light_yellow = material('Butter yellow', 'FFE68B', 0.0, .8)
dark = material('Blueberry rubber', '344A79', 0.0, .9)
rubber = dark
steel = material('Sky blue hubs', '86CFEC', 0.0, .7)
glass = material('Pool blue windows', '56BECF', 0.0, .6)
black = material('Friendly pupils', '233A5A', 0.0, .9)
lamp = material('Warm white', 'FFFBEF', 0.0, .9)
orange = material('Tangerine bucket', 'FF9454', 0.0, .7)

def empty(name, pos=(0,0,0), parent=None):
    o = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(o)
    o.parent = parent
    o.location = v(pos)
    return o

def finish(o, name, mat, parent, bevel=0):
    o.name = name
    if mat:
        o.data.materials.append(mat)
    if bevel:
        mod = o.modifiers.new('Machined edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 4
        o.modifiers.new('Weighted normals', 'WEIGHTED_NORMAL')
    o.parent = parent
    return o

def box(name, pos, size, mat, parent=None, bevel=0.03):
    bpy.ops.mesh.primitive_cube_add(size=1, location=v(pos))
    o = bpy.context.object
    o.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(o, name, mat, parent, bevel)

def rod(name, a, b, radius, mat, parent=None, verts=12):
    a, b = v(a), v(b)
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=(b-a).length, location=(a+b)/2)
    o = bpy.context.object
    o.rotation_mode = 'QUATERNION'
    o.rotation_quaternion = (b-a).to_track_quat('Z', 'Y')
    return finish(o, name, mat, parent, 0.012)

def profile(name, points, width, mat, parent):
    # points are (height, forward Z), extruded across X.
    verts = [v((x, y, z)) for x in (-width/2, width/2) for y,z in points]
    n = len(points)
    faces = [tuple(reversed(range(n))), tuple(range(n,2*n))]
    for i in range(n):
        j = (i+1) % n
        faces.append((i,j,j+n,i+n))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    o = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(o)
    finish(o, name, mat, parent, 0.035)
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode='OBJECT')
    o.select_set(False)
    return o


def ball(name, pos, size, mat, parent):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=1, location=v(pos))
    o = bpy.context.object
    o.scale = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for face in o.data.polygons:
        face.use_smooth = True
    return finish(o, name, mat, parent)

root = empty('LittleDigger')
chassis = empty('Chassis', parent=root)
box('Soft chassis', (0,.65,0), (2.7,.65,2.9), yellow, chassis, .25)
for x in (-1.20,1.20):
    side = 'Left' if x < 0 else 'Right'
    box(side+' soft track', (x,.55,0), (.85,1.0,3.4), dark, chassis, .40)
    for i,z in enumerate((-1.03,0,1.03)):
        rod(side+' wheel '+str(i), (x-.45,.55,z),(x+.45,.55,z),.35,steel,chassis,24)
        rod(side+' wheel hub '+str(i),(x-.47,.55,z),(x+.47,.55,z),.14,lamp,chassis,20)
upper=empty('Upper',(0,1.15,0),root)
box('Round yellow body',(0,.35,.15),(2.8,.8,2.8),yellow,upper,.3)
box('Plump back',(0,.68,.95),(2.7,.9,1.0),yellow,upper,.28)
box('Cab',(-.6,1.2,-.1),(1.45,1.7,1.65),glass,upper,.24)
box('Sunny roof',(-.6,2.07,-.1),(1.7,.23,1.95),yellow,upper,.10)
# A friendly face on the front cab window only, so the digger always looks
# where it is going.
face_z = -.95
for x in (-.93,-.31):
    ball('White eye',(x,1.45,face_z),(.25,.29,.10),lamp,upper)
    ball('Pupil',(x+.04,1.44,face_z-.095),(.10,.15,.045),black,upper)
for i in range(7):
    x=-.94+i*.11
    y=1.00+.17*((x+.61)/.33)**2
    ball('Smile',(x,y,face_z-.04),(.07,.055,.025),black,upper)
ball('Orange button',(.73,1.0,.8),(.2,.15,.2),orange,upper)
boom=empty('Boom',(.35,.66,-.55),upper)
box('Chunky boom',(0,.1,-1.50),(.58,.57,3.3),yellow,boom,.23)
rod('Big boom hinge',(-.4,0,0),(.4,0,0),.31,orange,boom,24)
rod('Blue boom joint',(-.37,0,-3.1),(.37,0,-3.1),.29,steel,boom,24)
stick=empty('Stick',(0,0,-3.1),boom)
box('Chunky little arm',(0,0,-1.43),(.43,.45,3.1),yellow,stick,.19)
bucket=empty('Bucket',(0,0,-3),stick)
# A wide, rounded scoop, with no sharp teeth or tiny mechanical parts.
box('Bucket floor',(0,-.62,-.48),(1.9,.25,1.45),orange,bucket,.10)
box('Bucket back',(0,-.24,.16),(1.9,.85,.24),orange,bucket,.10)
for x in (-.88,.88):
    box('Bucket side',(x,-.29,-.43),(.22,.9,1.42),orange,bucket,.1)
rod('Bucket joint',(-.6,0,0),(.6,0,0),.23,steel,bucket,24)
empty('CarrySocket',(0,-.05,-.50),bucket)
boom.rotation_euler.x=math.radians(52)
stick.rotation_euler.x=math.radians(-110)
bucket.rotation_euler.x=math.radians(58)

def save_asset(stem):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art'/(stem+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(stem+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)

save_asset('excavator')
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
rock_mat=material('Pebble base','FFFFFF',0,.95)
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=.72)
rock=bpy.context.object
rock.name='Pebble'
random.seed(14)
for vert in rock.data.vertices:
    vert.co *= random.uniform(.93,1.07)
    vert.co.z *= .82
for face in rock.data.polygons:
    face.use_smooth=True
rock.data.materials.append(rock_mat)
bevel=rock.modifiers.new('Soft pebble','SUBSURF')
bevel.levels=1
save_asset('boulder')
print('Little Digger toy assets built.')
