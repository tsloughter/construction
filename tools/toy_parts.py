"""Shared Blender helpers for the toy vehicles.

Positions use Godot coordinates (X right, Y up, -Z forward). Every helper
returns the object it made so parts can be merged with `join` afterwards.
"""
import bpy
from mathutils import Vector


def reset_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)


def v(p):
    return Vector((p[0], -p[2], p[1]))


def material(name, hex_color, metallic=0.0, roughness=0.65):
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


def empty(name, pos=(0, 0, 0), parent=None):
    o = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(o)
    o.parent = parent
    o.location = v(pos)
    return o


def finish(o, name, mat, parent, bevel=0, segments=2):
    o.name = name
    if mat:
        o.data.materials.append(mat)
    if bevel:
        mod = o.modifiers.new('Soft toy edges', 'BEVEL')
        mod.width = bevel
        mod.segments = segments
        o.modifiers.new('Weighted normals', 'WEIGHTED_NORMAL')
    o.parent = parent
    return o


def box(name, pos, size, mat, parent=None, bevel=0.03):
    bpy.ops.mesh.primitive_cube_add(size=1, location=v(pos))
    o = bpy.context.object
    o.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(o, name, mat, parent, bevel)


def rod(name, a, b, radius, mat, parent=None, verts=16):
    a, b = v(a), v(b)
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=(b-a).length, location=(a+b)/2)
    o = bpy.context.object
    o.rotation_mode = 'QUATERNION'
    o.rotation_quaternion = (b-a).to_track_quat('Z', 'Y')
    return finish(o, name, mat, parent, 0.012)


def ball(name, pos, size, mat, parent, segments=16, rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1, location=v(pos))
    o = bpy.context.object
    o.scale = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for face in o.data.polygons:
        face.use_smooth = True
    return finish(o, name, mat, parent)


def wheel(name, center, radius, width, rim, hub, tread, parent, nubs=8):
    """A rolling wheel: rim cylinder along X with a hub and raised tread nubs,
    merged into one object whose local Y axis is the axle so the game can spin it."""
    import math
    x, y, z = center
    parts = [rod(name, (x-width/2, y, z), (x+width/2, y, z), radius, rim, parent, 20)]
    parts.append(rod(name+' hub', (x-width/2-.02, y, z), (x+width/2+.02, y, z), radius*.4, hub, parent, 16))
    for i in range(nubs):
        t = 2*math.pi*i/nubs
        nub = box(name+' tread', (x, y+radius*math.cos(t), z+radius*math.sin(t)), (width*.7, radius*.26, radius*.36), tread, parent, 0)
        nub.rotation_euler.x = t
        parts.append(nub)
    return join(name, parts)


def join(name, objects):
    """Apply modifiers and merge the objects into one mesh. The first object's
    origin and parent are kept, so pass the pivot piece first."""
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.convert(target='MESH')
    if len(objects) > 1:
        bpy.ops.object.join()
    o = bpy.context.object
    o.name = name
    bpy.ops.object.select_all(action='DESELECT')
    return o


def export(stem, root):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.save_as_mainfile(filepath=str(root/'art'/(stem+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(root/'assets'/'models'/(stem+'.glb')), export_format='GLB', use_selection=True, export_apply=True, export_yup=True)
