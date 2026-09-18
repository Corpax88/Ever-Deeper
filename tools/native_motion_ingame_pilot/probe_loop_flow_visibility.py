"""Four original-rig images to reject occluded proposals before a bank rebuild."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import sys
import bpy

ROOT=Path(__file__).resolve().parents[2]
HERE=Path(__file__).resolve().parent
p=argparse.ArgumentParser(description=__doc__)
for name in ('native-tools','pivot','output'):
    p.add_argument('--'+name,type=Path,required=True)
p.add_argument('--side-waypoint-only',action='store_true')
p.add_argument('--side-cycle',action='store_true')
p.add_argument('--overhead-load',action='store_true')
p.add_argument('--body-weight',action='store_true')
a=p.parse_args(sys.argv[sys.argv.index('--')+1:])
assert not a.output.exists()
a.output.mkdir(parents=True)
sha=lambda path:hashlib.sha256(Path(path).read_bytes()).hexdigest()
assert sha(bpy.data.filepath)=='94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
assert sha(a.native_tools/'worn/hero.blend')=='0f90a49329acfd6db5b62cfbe6361efce1c79bea4a9d57a93fab130d46ac5b2b'
assert sha(a.pivot)=='cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
report={'complete':False,'visual_accepted':False,'production_accepted':False,
        'scope':'Four native visibility stills only; not gameplay or temporal approval',
        'source_hashes':{str(path.relative_to(ROOT)):sha(path) for path in (Path(__file__),HERE/'loop_flow_motion.py')},
        'renders':[]}
sys.argv=['blender','--','--native-tools',str(a.native_tools),'--output',str(a.output/'setup'),
          '--gear','worn','--direction','up','--native-motion-pilot','--native-states','idle',
          '--native-loop-counts','idle=1','--validate-only','--threads','2']
env=runpy.run_path(str(ROOT/'tools/hero_v28/export_hero.py'))
sys.path.insert(0,str(HERE))
from loop_flow_motion import LoopFlowMotion
motion=LoopFlowMotion(json.loads((HERE/'working-surface-selection.json').read_text()),
                      json.loads((HERE/'upper-body-hinge-selection.json').read_text()),
                      json.loads(a.pivot.read_text()),.70,.30,True)
if a.side_waypoint_only or a.side_cycle:
    from side_return_motion import SideReturnMotion
    motion=SideReturnMotion(json.loads((HERE/'working-surface-selection.json').read_text()),
                      json.loads((HERE/'upper-body-hinge-selection.json').read_text()),
                      json.loads(a.pivot.read_text()),a.overhead_load)
    report['source_hashes']['tools/native_motion_ingame_pilot/side_return_motion.py']=sha(HERE/'side_return_motion.py')
    report['scope']='One native side-waypoint still only; not a full cycle or temporal approval'
    if a.side_cycle:
        report['scope']='50 real-rig cycle frames on the .68-second native clock; not gameplay or visual acceptance'
        report['cycle_seconds']=.68
        report['frame_rate']=[1250,17]
        from loop_flow_motion import native_phase
if a.body_weight:
    assert not a.side_waypoint_only
    from body_weight_motion import BodyWeightMotion
    motion=BodyWeightMotion(json.loads((HERE/'working-surface-selection.json').read_text()),
                      json.loads((HERE/'upper-body-hinge-selection.json').read_text()),
                      json.loads(a.pivot.read_text()))
    report['source_hashes']['tools/native_motion_ingame_pilot/side_return_motion.py']=sha(HERE/'side_return_motion.py')
    report['source_hashes']['tools/native_motion_ingame_pilot/body_weight_motion.py']=sha(HERE/'body_weight_motion.py')
    if not a.side_cycle:report['scope']='Three native load/contact/compression stills; not a full cycle or gameplay approval'
report['selection']=motion.selection()
env['view']('up',(6,6))
scene,rig=env['s'],env['r']
try:
    phases=((0,0.),) if a.side_waypoint_only else ((49,.953448275862069),(0,0.),(400,.40),(523,.5238095238095238))
    if a.side_cycle: phases=tuple((i,native_phase(i/50)) for i in range(50))
    elif a.body_weight:phases=((380,.38),(550,.55),(590,.59))
    for index,q in phases:
        pose=motion.waypoint_pose() if a.side_waypoint_only else motion.sample('mine',q)
        for modifier in env['skin']: modifier.show_viewport=False
        posed=dict(pose)
        posed['head']=posed['head']@env['head_offset']
        env['apply'](posed)
        grip=max((((rig.pose.bones['hand.'+s].matrix @ rig.data.bones['hand.'+s].matrix_local.inverted())
                   @ env['rest']['grips'][s])-pose['grips'][s]).length for s in ('R','L'))
        length=max(abs((rig.pose.bones[n].tail-rig.pose.bones[n].head).length-rig.data.bones[n].length)
                   for n in ('upper.R','lower.R','upper.L','lower.L','thigh.R','shin.R','thigh.L','shin.L'))
        reach=max((w-s).length for s,e,w in pose['arms'].values())
        assert grip<1e-5 and length<1e-5 and reach<.70999,(grip,length,reach)
        env['blink'](0.)
        for modifier in env['skin']: modifier.show_viewport=True
        bpy.context.view_layer.update()
        name=f'visibility-mine-{index:03}'
        png=a.output/(name+'.png')
        scene.render.filepath=str(png)
        env['mask'].base_path=str(a.output)
        env['mask'].file_slots[0].path='mask-'+name+'-'
        scene.frame_current=1
        bpy.ops.render.render(write_still=True)
        report['renders'].append({'index':index,'phase':q,'path':png.name,'sha256':sha(png),
                                  'grip_error':grip,'arm_length_error':length,'maximum_reach':reach})
        print('VISIBILITY_STILL',index,flush=True)
    report['complete']=True
finally:
    (a.output/'report.json').write_text(json.dumps(report,indent=2)+'\n')
