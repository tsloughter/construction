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

yellow = material('Ochre enamel', 'ECA92E', 0.25, 0.35)
light_yellow = material('Warm highlights', 'FFCD65', 0.2)
dark = material('Graphite steel', '273338', 0.65)
rubber = material('Track pads', '242D2D', 0.1, 0.8)
steel = material('Brushed piston steel', 'A6BEC1', 0.8, 0.25)
glass = material('Smoky blue glazing', '315C6D', 0.6, 0.19)
black = material('Rubber trim', '14242A', 0.2)
lamp = material('Work lights', 'FFF3CA', 0.1, 0.2)
orange = material('Beacon amber', 'FF702E', 0.25, 0.25)

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
        mod.segments = 2
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

root = empty('Excavator')
chassis = empty('Chassis', parent=root)
box('Undercarriage', (0,.65,0), (2.6,.5,3.25), dark, chassis, .12)
rod('Slew bearing', (0,.82,0), (0,1.23,0), 1.05, dark, chassis, 48)
for x in (-1.3,1.3):
    side = 'Left' if x < 0 else 'Right'
    box(side+' track core', (x,.55,0), (.79,.84,3.9), rubber, chassis, .3)
    for z in (-1.5,-.9,-.3,.3,.9,1.5):
        rod(side+' road wheel', (x-.42,.53,z), (x+.42,.53,z), .31, dark, chassis, 16)
        rod(side+' hub', (x-.44,.53,z), (x+.44,.53,z), .15, yellow, chassis, 12)
    # Individual track shoes around a stadium-shaped path.
    for i in range(42):
        t = i/42 * (6.0 + 2*math.pi*.42)
        if t < 3:
            z,y,angle = -1.5+t,.98,0
        elif t < 3+math.pi*.42:
            a=(t-3)/.42
            z,y,angle=1.5+.42*math.sin(a),.56+.42*math.cos(a),a
        elif t < 6+math.pi*.42:
            z,y,angle=1.5-(t-3-math.pi*.42),.14,0
        else:
            a=(t-6-math.pi*.42)/.42
            z,y,angle=-1.5-.42*math.sin(a),.56-.42*math.cos(a),a
        o=box(side+' tread %02d'%i,(x,y,z),(.89,.09,.18),dark,chassis,.015)
        o.rotation_euler.x=angle
        box(side+' track grip %02d'%i,(x,y+.055 if y>.56 else y-.055,z),(.92,.035,.055),rubber,chassis,.005)

upper = empty('Upper', (0,1.15,0), root)
box('Upper deck', (0,.2,0), (2.9,.45,3.45), yellow, upper,.14)
box('Counterweight', (.1,.63,1.05), (2.8,.93,1.12), yellow, upper,.22)
box('Rear bumper', (.1,.32,1.63), (2.77,.2,.15), black, upper)
box('Engine hood', (.72,.68,.15), (1.18,.66,1.3), yellow, upper,.1)
for i in range(7):
    box('Engine vent %d'%i,(1.326,.69,-.27+i*.13),(.022,.28,.055),dark,upper,.003)
box('Cab floor', (-.8,.47,-.37), (1.26,.2,1.67), dark, upper,.06)
box('Cab glazing', (-.83,1.25,-.43), (1.13,1.46,1.47), glass, upper,.1)
box('Cab roof', (-.83,2.03,-.43), (1.32,.17,1.72), yellow, upper,.07)
for x in (-1.43,-.23):
    for z in (-1.14,.31):
        box('Cab pillar',(x,1.28,z),(.075,1.53,.09),black,upper,.015)
    box('Cab midrail',(x,1.0,-.42),(.08,.06,1.45),black,upper,.01)
box('Front windshield crossbar',(-.83,1.01,-1.19),(1.15,.07,.045),black,upper,.01)
box('Windshield wiper',(-.76,1.35,-1.2),(.034,.6,.03),dark,upper,.004)
box('Door handle',(-1.46,1.13,-.07),(.045,.08,.25),steel,upper)
box('Entry step',(-1.52,.23,-.5),(.36,.12,.65),dark,upper)
for z in (-.9,.12):
    rod('Grab rail',(-1.51,.63,z),(-1.51,1.3,z),.035,yellow,upper)
rod('Exhaust',(1.0,.94,.9),(1.0,1.6,.9),.075,black,upper)
rod('Beacon mount',(.0,1.28,1.0),(.0,1.45,1.0),.12,dark,upper)
rod('Amber beacon',(.0,1.45,1.0),(.0,1.68,1.0),.12,orange,upper)
for x in (-1.25,-.4):
    box('Headlamp housing',(x,1.93,-1.3),(.25,.2,.13),black,upper)
    box('Headlamp lens',(x,1.93,-1.38),(.18,.12,.03),lamp,upper)

boom = empty('Boom', (.35,.66,-.55), upper)
profile('Boom casting', [(-.22,.18),(.27,.15),(.47,-1.3),(.27,-3.1),(-.13,-3.15),(.03,-1.3)], .48, yellow, boom)
for x in (-.29,.29):
    rod('Boom hinge',(x-.04,0,0),(x+.04,0,0),.27,dark,boom)
    rod('Boom pin',(x-.05,0,-3.1),(x+.05,0,-3.1),.21,steel,boom)
rod('Boom cylinder',(.0,.40,-.3),(.0,.58,-1.58),.13,dark,boom)
rod('Boom piston',(.0,.58,-1.58),(.0,.32,-2.55),.07,steel,boom)
for x in (-.14,.14):
    rod('Hydraulic hose',(x,.55,-.45),(x,.57,-1.25),.028,black,boom)
    rod('Hydraulic hose',(x,.57,-1.25),(x,.34,-2.68),.028,black,boom)
stick=empty('Stick',(0,0,-3.1),boom)
profile('Dipper casting', [(-.16,.22),(.23,.16),(.26,-.75),(.12,-3.0),(-.13,-3.03),(-.24,-.6)], .36, yellow, stick)
rod('Stick cylinder',(0,.31,-.2),(0,.41,-1.55),.11,dark,stick)
rod('Stick piston',(0,.41,-1.55),(0,.17,-2.65),.065,steel,stick)
rod('Bucket pin',(-.4,0,-3.0),(.4,0,-3.0),.17,dark,stick)
bucket=empty('Bucket',(0,0,-3.0),stick)
bucket_profile=[(.12,.18),(-.53,.2),(-.75,-.15),(-.75,-.92),(-.58,-1.17),(-.48,-1.17),(-.61,-.82),(-.6,-.18),(-.43,.04),(.12,.04)]
profile('Bucket curved shell',bucket_profile,1.64,dark,bucket)
side_profile=[(.15,.2),(-.52,.2),(-.76,-.15),(-.76,-.95),(-.55,-1.2),(-.23,-.82),(.13,-.15)]
for x in (-.82,.82):
    o=profile('Bucket cheek',side_profile,.095,yellow,bucket)
    o.location.x=x
    rod('Bucket boss',(x-.07,0,0),(x+.07,0,0),.21,dark,bucket)
for x in (-.66,-.33,0,.33,.66):
    box('Digging tooth',(x,-.58,-1.29),(.16,.13,.39),steel,bucket,.025)
    box('Wear strip',(x,-.81,-.52),(.09,.06,.58),black,bucket,.01)
empty('CarrySocket',(0,-.20,-.55),bucket)

# Rest pose is a low, open bucket. Game IK replaces these rotations.
boom.rotation_euler.x=math.radians(45)
stick.rotation_euler.x=math.radians(-110)
bucket.rotation_euler.x=math.radians(65)

bpy.ops.object.select_all(action='DESELECT')
for o in bpy.context.scene.objects:
    o.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art'/'excavator.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'excavator.glb'), export_format='GLB', use_selection=True, export_apply=True, export_yup=True)

# A hand-shaped, faceted boulder; shared mesh, different scales in Godot.
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
rock_mats=[material('Granite %d'%i,c,0,.94) for i,c in enumerate(['697274','7B8280','8A9089','555F62','9CA095'])]
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=.7)
rock=bpy.context.object
rock.name='Boulder'
random.seed(14)
for vert in rock.data.vertices:
    vert.co *= random.uniform(.83,1.13)
    vert.co.x *= 1.08
    vert.co.z *= .86
for mat in rock_mats:
    rock.data.materials.append(mat)
for face in rock.data.polygons:
    face.material_index=random.choices(range(5),[4,5,3,1,1])[0]
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art'/'boulder.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'boulder.glb'),export_format='GLB',use_selection=True,export_apply=True)
print('EARTHWORK assets built successfully.')
