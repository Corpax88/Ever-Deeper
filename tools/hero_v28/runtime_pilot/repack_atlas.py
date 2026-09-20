"""Repack the private native target without rebuilding or changing its geometry.

Run on a retained prepared.blend. Report useful UV area before any new bake.
This is a diagnostic candidate, never production or automatic art acceptance.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys

import bpy
import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from constant_donor_probe import digest, get_array, TARGET_NAME


def geometry_fingerprint(mesh):
    h = hashlib.sha256()
    for collection, name, width, dtype in (
        (mesh.vertices, 'co', 3, np.float32),
        (mesh.edges, 'vertices', 2, np.int32),
        (mesh.loops, 'vertex_index', 1, np.int32),
        (mesh.polygons, 'loop_start', 1, np.int32),
        (mesh.polygons, 'loop_total', 1, np.int32),
        (mesh.polygons, 'material_index', 1, np.int32),
        (mesh.polygons, 'use_smooth', 1, np.bool_),
        (mesh.corner_normals, 'vector', 3, np.float32),
    ):
        h.update(get_array(collection, name, width, dtype).tobytes())
    for vertex in mesh.vertices:
        for group in vertex.groups:
            h.update(f'{group.group}:{group.weight.hex()};'.encode())
        h.update(b'\n')
    return h.hexdigest()


def uv_inventory(mesh):
    uv = get_array(mesh.uv_layers.active.data, 'uv', 2, np.float32)
    assert np.isfinite(uv).all()
    mesh.calc_loop_triangles()
    loops = get_array(mesh.loop_triangles, 'loops', 3, np.int32)
    p = uv[loops].astype(np.float64)
    a = np.abs((p[:, 1, 0]-p[:, 0, 0])*(p[:, 2, 1]-p[:, 0, 1])
               -(p[:, 1, 1]-p[:, 0, 1])*(p[:, 2, 0]-p[:, 0, 0]))*.5
    polys = get_array(mesh.loop_triangles, 'polygon_index', 1, np.int32)
    mats = get_array(mesh.polygons, 'material_index', 1, np.int32)[polys]
    return {'summed_triangle_area': float(a.sum()),
            'zero_area_triangles': int((a < 1e-14).sum()),
            'bounds': [uv.min(0).tolist(), uv.max(0).tolist()],
            'materials': [{'name': m.name, 'area': float(a[mats == i].sum())}
                          for i, m in enumerate(mesh.materials) if (mats == i).any()]}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--texture-size', type=int, default=2048)
    p.add_argument('--island-margin', type=float, default=.00004)
    args = p.parse_args(sys.argv[sys.argv.index('--')+1:])
    source = Path(bpy.data.filepath).resolve()
    output = args.output.resolve()
    assert source.name == 'prepared.blend'
    assert output != source.parent and not output.exists()
    assert not output.is_relative_to(HERE.parents[2])
    assert 0 <= args.island_margin <= .001
    assert 1024 <= args.texture_size <= 4096
    target = bpy.data.objects[TARGET_NAME]
    before_geometry = geometry_fingerprint(target.data)
    before_uv = uv_inventory(target.data)
    bpy.ops.object.select_all(action='DESELECT')
    target.select_set(True)
    bpy.context.view_layer.objects.active = target
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=np.deg2rad(66),
                             island_margin=args.island_margin,
                             margin_method='SCALED', area_weight=.2,
                             correct_aspect=True, scale_to_bounds=True)
    bpy.ops.object.mode_set(mode='OBJECT')
    after_geometry = geometry_fingerprint(target.data)
    assert before_geometry == after_geometry, 'UV-only operation changed native geometry'
    after_uv = uv_inventory(target.data)
    assert after_uv['summed_triangle_area'] > .1, after_uv
    output.mkdir(parents=True)
    prep = json.loads(source.with_name('preparation.json').read_text())
    prep.update(texture_size=args.texture_size, atlas_repack={
        'source_prepared_sha256': digest(source), 'script_sha256': digest(__file__),
        'geometry_sha256_before': before_geometry, 'geometry_sha256_after': after_geometry,
        'island_margin': args.island_margin, 'margin_method': 'SCALED',
        'before': before_uv, 'after': after_uv,
        'limits': 'UV coverage diagnostic. Padding, surface fidelity and runtime cost unapproved.'})
    (output/'preparation.json').write_text(json.dumps(prep, indent=2)+'\n')
    motion_source = source.with_name('motion-before-flow20.json')
    if not motion_source.exists(): motion_source = source.with_name('motion.json')
    shutil.copyfile(motion_source, output/'motion.json')
    bpy.context.scene['native_runtime_preparation'] = str(output/'preparation.json')
    bpy.ops.wm.save_as_mainfile(filepath=str(output/'prepared.blend'))
    print('NATIVE_ATLAS_REPACK_COMPLETE', json.dumps(prep['atlas_repack']), flush=True)


if __name__ == '__main__':
    main()
