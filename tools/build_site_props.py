"""Blender source for the shared soft-edged construction-site building block.
The yard assembles these into cabins, containers, barriers, a crane and materials.
"""
from pathlib import Path
import bpy

root = Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.mesh.primitive_cube_add(size=1)
block = bpy.context.object
block.name = 'SiteBlock'
bevel = block.modifiers.new('Soft toy edges', 'BEVEL')
bevel.width = .065
bevel.segments = 3
block.modifiers.new('Weighted face normals', 'WEIGHTED_NORMAL')
mat = bpy.data.materials.new('Paint supplied by the game')
mat.diffuse_color = (1, 1, 1, 1)
block.data.materials.append(mat)
bpy.ops.wm.save_as_mainfile(filepath=str(root / 'art' / 'site_props.blend'))
bpy.ops.export_scene.gltf(filepath=str(root / 'assets' / 'models' / 'site_block.glb'), export_format='GLB', use_selection=True, export_apply=True)
print('Soft construction-site block exported.')
