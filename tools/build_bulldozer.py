"""Build the second game's rounded toy bulldozer in Blender."""
from pathlib import Path
import bpy
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
def v(p): return Vector((p[0], -p[2], p[1]))
def mat(name, color):
    m=bpy.data.materials.new(name)
    c=[int(color[i:i+2],16)/255 for i in (0,2,4)]
    c=[n/12.92 if n<=.04045 else ((n+.055)/1.055)**2.4 for n in c]
    m.diffuse_color=(*c,1)
    m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*c,1)
    p.inputs['Roughness'].default_value=.65
    return m
orange=mat('Tangerine paint','FCA15D')
yellow=mat('Sunny roof','FFCA52')
blue=mat('Blueberry tracks','344A79')
glass=mat('Pool blue windows','56BECF')
white=mat('Warm white','FFFBEF')
steel=mat('Blue hubs','8ACDE8')
black=mat('Friendly pupils','233A5A')
def finish(o,name,m,parent,bevel=0):
    o.name=name
    o.data.materials.append(m)
    o.parent=parent
    if bevel:
        mod=o.modifiers.new('Soft toy edges','BEVEL');mod.width=bevel;mod.segments=4
        o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    return o
def box(name,pos,size,m,parent,bevel=.12):
    bpy.ops.mesh.primitive_cube_add(size=1,location=v(pos))
    o=bpy.context.object;o.dimensions=(size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,name,m,parent,bevel)
def rod(name,a,b,r,m,parent):
    a,b=v(a),v(b)
    bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=r,depth=(b-a).length,location=(a+b)/2)
    o=bpy.context.object;o.rotation_mode='QUATERNION';o.rotation_quaternion=(b-a).to_track_quat('Z','Y')
    return finish(o,name,m,parent,.025)
def ball(name,pos,size,m,parent):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=v(pos))
    o=bpy.context.object;o.scale=(size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for f in o.data.polygons:f.use_smooth=True
    return finish(o,name,m,parent)
root=bpy.data.objects.new('Bulldozer',None);bpy.context.collection.objects.link(root)
box('Chunky orange chassis',(0,.7,0),(2.6,.65,3.0),orange,root,.25)
for x in [-1.18,1.18]:
    box('Soft track',(x,.53,0),(.78,.96,3.25),blue,root,.36)
    for z in [-1.0,0,1.0]:
        rod('Wheel',(x-.42,.52,z),(x+.42,.52,z),.34,steel,root)
        rod('Hub',(x-.45,.52,z),(x+.45,.52,z),.12,white,root)
box('Round rear body',(0,1.12,.92),(2.5,.65,1.0),orange,root,.24)
box('Cab',(0,1.85,.12),(1.65,1.8,1.65),glass,root,.24)
box('Sunny roof',(0,2.77,.12),(1.95,.22,1.95),yellow,root,.1)
box('Engine hood',(0,1.08,-1.05),(1.75,.6,1.05),orange,root,.2)
for z in [-.76,1.0]:
    for x in [-.40,.40]:
        ball('Eye',(x,2.05,z),(.29,.32,.1),white,root)
        ball('Pupil',(x+.025,2.05,z+(-.1 if z<0 else .1)),(.12,.17,.05),black,root)
    for i in range(7):
        x=-.4+i*.133
        ball('Smile',(x,1.56+.15*(x/.4)**2,z+(-.06 if z<0 else .06)),(.075,.045,.035),black,root)
for x in [-1.12,1.12]:
    box('Blade arm',(x,.51,-1.45),(.2,.24,1.2),blue,root,.08)
# A broad, blunt, slightly curved blade; the three panels form a shallow scoop.
box('Main pushing blade',(0,.7,-2.04),(3.0,1.28,.32),orange,root,.12)
for x in [-1.63,1.63]:
    o=box('Blade wing',(x,.7,-2.20),(.65,1.28,.32),orange,root,.1)
    o.rotation_euler.z = -.4 if x<0 else .4
box('Blunt cutting edge',(0,.17,-2.23),(3.75,.18,.25),white,root,.07)
rod('Exhaust',(1.0,1.3,.9),(1.0,1.8,.9),.075,blue,root)
ball('Beacon',(0,2.95,.5),(.16,.18,.16),orange,root)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art'/'bulldozer.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets'/'models'/'bulldozer.glb'),export_format='GLB',export_apply=True,use_selection=True)
print('Toy bulldozer exported.')
