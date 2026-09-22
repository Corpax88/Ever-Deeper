"""Authored 3D rig study. Never overwrites the game's approved 2D art.

Run with Blender 4.5: --background --python build_hero.py -- --render neutral
Native geometry/material construction, not image-generation or image editing.
"""
import bpy, math, json, argparse, sys
from pathlib import Path
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('--render', choices=['neutral', 'poses', 'animation', 'none'], default='neutral')
parser.add_argument('--samples', type=int, default=24)
parser.add_argument('--tool', choices=['worn','iron','runed','moonglass','ember','crusher','comet','crown','burrower','pulse','deepcore'], default='iron')
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
SOURCE_ROOT=ROOT
sys.path.insert(0,str(SOURCE_ROOT))
import motion_v3 as motion_v2
import gear_v3
import drill_v2
ROOT=SOURCE_ROOT/'v3'/args.tool
IS_DRILL=gear_v3.PROFILES[args.tool]['family']=='drill'
ROOT.mkdir(parents=True,exist_ok=True)
(ROOT/'qa').mkdir(exist_ok=True);(ROOT/'frames').mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'; scene.cycles.device = 'CPU'
scene.cycles.samples = args.samples; scene.cycles.use_denoising = True
scene.render.threads_mode = 'FIXED'; scene.render.threads = 6
scene.render.resolution_x = 512; scene.render.resolution_y = 640
scene.render.resolution_percentage = 100; scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'; scene.render.image_settings.color_mode = 'RGBA'
scene.render.fps = 60; scene.frame_start = 1; scene.frame_end = 300
scene.view_settings.view_transform = 'AgX'
scene.world.color = (.18,.18,.18)

def material(name, color, metal=0, rough=.45, texture=0):
    m=bpy.data.materials.new(name); m.use_nodes=True
    n=m.node_tree.nodes; l=m.node_tree.links; p=n.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Metallic'].default_value=metal; p.inputs['Roughness'].default_value=rough
    if texture:
        noise=n.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value=texture
        noise.inputs['Detail'].default_value=3
        ramp=n.new('ShaderNodeValToRGB')
        ramp.color_ramp.elements[0].position=.15; ramp.color_ramp.elements[0].color=(*(c*.60 for c in color),1)
        ramp.color_ramp.elements[1].position=.85; ramp.color_ramp.elements[1].color=(*(min(1,c*1.3) for c in color),1)
        l.new(noise.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs[0],p.inputs['Base Color'])
        bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.13;bump.inputs['Distance'].default_value=.012
        l.new(noise.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs['Normal'],p.inputs['Normal'])
    return m

skin=material('warm ochre skin',(.64,.295,.085),rough=.52)
skinlight=material('skin highlights',(.78,.40,.135),rough=.50)
coat=material('painted forest green canvas',(.022,.082,.039),rough=.73,texture=24)
coatedge=material('green raised seams',(.045,.13,.063),rough=.66)
leather=material('worn brown leather',(.145,.046,.012),rough=.56,texture=19)
leatherlight=material('leather edge',(.32,.125,.026),rough=.48,texture=23)
brass=material('aged warm brass',(.52,.265,.048),metal=.78,rough=.29,texture=48)
brasslight=material('polished brass edge',(.77,.43,.09),metal=.82,rough=.23)
iron=material('dark helmet iron',(.065,.059,.049),metal=.80,rough=.39,texture=35)
steel=material('iron pickaxe head',(.34,.36,.34),metal=.88,rough=.27,texture=55)
steeledge=material('honed pick edge',(.59,.62,.60),metal=.92,rough=.22)
hair=material('chestnut beard',(.135,.044,.010),rough=.80,texture=28)
hairlight=material('beard strands',(.235,.084,.018),rough=.75)
dark=material('dark creases',(.027,.015,.006),rough=.7)
white=material('ivory eyes',(.91,.89,.78),rough=.3)
pupil=material('dark pupils',(.005,.009,.007),rough=.19)
wood=material('wood shaft',(.28,.093,.018),rough=.51,texture=15)
lamp=material('amber lamp glass',(.95,.57,.06),metal=.15,rough=.2)
lamp.node_tree.nodes.get('Principled BSDF').inputs['Emission Color'].default_value=(1,.5,.035,1)
lamp.node_tree.nodes.get('Principled BSDF').inputs['Emission Strength'].default_value=.65

groups={}
def register(o, mat, group):
    o.data.materials.append(mat)
    if o.type=='MESH':
        for p in o.data.polygons:p.use_smooth=True
    groups.setdefault(group,[]).append(o)
    return o
def sphere(name, p, scale, mat, group='body', segments=32):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=20,location=p)
    o=bpy.context.object;o.name=name;o.scale=scale
    return register(o,mat,group)
def cube(name,p,size,mat,group='body',bevel=.02):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.name=name;o.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    mod=o.modifiers.new('rounded sewn edge','BEVEL');mod.width=bevel;mod.segments=3
    o.modifiers.new('weighted normals','WEIGHTED_NORMAL')
    return register(o,mat,group)
def tube(name, points, radius, mat, group='body', radii=None):
    c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.resolution_u=12
    c.bevel_depth=radius;c.bevel_resolution=3
    s=c.splines.new('BEZIER');s.bezier_points.add(len(points)-1)
    for i,(p,b) in enumerate(zip(points,s.bezier_points)):
        b.co=p;b.handle_left_type='AUTO';b.handle_right_type='AUTO'
        if radii:b.radius=radii[i]
    o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o)
    return register(o,mat,group)
def cylinder(name,a,b,r,mat,group='body',r2=None):
    a,b=Vector(a),Vector(b);d=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=40,radius1=r,radius2=r if r2 is None else r2,depth=d.length,location=(a+b)/2)
    o=bpy.context.object;o.name=name;o.rotation_mode='QUATERNION';o.rotation_quaternion=d.to_track_quat('Z','Y')
    bevel=o.modifiers.new('edge rounding','BEVEL');bevel.width=.006;bevel.segments=2
    return register(o,mat,group)
def oval_ring(name,z,rx,ry,r,mat,group='body',cy=0):
    pts=[(rx*math.cos(t),cy+ry*math.sin(t),z) for t in [i*math.tau/64 for i in range(65)]]
    return tube(name,pts,r,mat,group)
def rect_ring(name,x,y,z,w,h,r,mat,group='head'):
    pts=[(x-w/2,y,z-h/2+.025),(x-w/2,y,z+h/2-.025),(x-w/2+.025,y,z+h/2),
         (x+w/2-.025,y,z+h/2),(x+w/2,y,z+h/2-.025),(x+w/2,y,z-h/2+.025),
         (x+w/2-.025,y,z-h/2),(x-w/2+.025,y,z-h/2),(x-w/2,y,z-h/2+.025)]
    obj=tube(name,pts,r,mat,group)
    for b in obj.data.splines[0].bezier_points:b.handle_left_type='VECTOR';b.handle_right_type='VECTOR'
    return obj

# Stocky original proportions: broad boots, short torso, large square-glasses face.
for side in [-1,1]:
    x=side*.16
    side_id='R' if side<0 else 'L'
    side_group='foot.'+side_id
    sphere('trouser leg', (x,0,.39),(.125,.135,.24),coat,'leg.'+side_id)
    sphere('heavy boot sole',(x,-.075,.077),(.145,.23,.065),dark,side_group)
    sphere('rounded worn boot',(x,-.08,.145),(.137,.218,.11),leather,side_group)
    cylinder('boot upper',(x,.016,.17),(x,.016,.39),.125,leather,side_group,.106)
    pts=[(x+.128*math.cos(t),-.075+.202*math.sin(t),.11) for t in [i*math.tau/40 for i in range(41)]]
    tube('welt stitching',pts,.007,leatherlight,side_group)
    cylinder('boot folded top',(x,.016,.35),(x,.016,.40),.125,leatherlight,side_group)
    cube('boot front leather tongue',(x,-.11,.30),(.16,.026,.16),leather,side_group,.025)
    for z in [.26,.30,.34]:tube('boot crease',[(x-.07,-.129,z),(x,-.14,z-.012),(x+.07,-.129,z)],.005,leatherlight,side_group)

sphere('coat body',(0,.01,.84),(.34,.235,.405),coat)
oval_ring('coat lower hem',.49,.265,.188,.012,coatedge)
tube('coat front seam',[(0,-.20,.51),(0,-.217,.75),(0,-.205,.95),(0,-.16,1.16)],.008,coatedge)
for side in [-1,1]:
    pocket=cube('coat pocket',(side*.181,-.184,.60),(.135,.026,.155),coat,bevel=.022)
    pocket.rotation_euler[2]=side*.23
    tube('pocket welt',[(side*.12,-.206,.654),(side*.18,-.211,.66),(side*.235,-.176,.657)],.008,coatedge)
    for z in [.54,.75,.88,.99]:sphere('coat brass button',(side*.073,-.219 if z<.95 else -.198,z),(.015,.010,.015),brasslight,segments=16)
    collar=cube('leather collar',(side*.123,-.17,1.115),(.19,.047,.085),leather,bevel=.013)
    collar.rotation_euler[1]=side*.39
    sphere('collar rivet',(side*.11,-.197,1.11),(.011,.008,.011),brasslight,segments=16)
oval_ring('belt',.684,.312,.23,.031,leather)
rect_ring('belt buckle',0,-.255,.684,.113,.082,.013,brasslight,'body')
cylinder('buckle tongue',(-.01,-.271,.684),(.05,-.271,.684),.006,brasslight)
for x in [-.20,-.12,.14,.21]:cube('belt keeper',(x,-math.sqrt(max(.001,.23**2*(1-(x/.32)**2)))-.008,.684),(.025,.029,.087),brass,bevel=.005)

# Backpack with seams, straps, buckles and rolled bedroll.
cube('leather backpack',(0,.24,.97),(.49,.24,.56),leather,'body',.085)
cube('backpack lid',(0,.25,1.235),(.51,.26,.11),leatherlight,'body',.04)
for x in [-.17,.17]:
    cube('pack rear strap',(x,.367,1.015),(.038,.017,.45),leatherlight,'body',.009)
    rect_ring('pack buckle',x,.387,1.015,.065,.09,.008,brass,'body')
    tube('shoulder harness',[(x,.27,1.24),(x,.07,1.235),(x,-.135,1.16),(x*.88,-.222,.96),(x*.9,-.237,.75)],.028,leather)
    rect_ring('harness buckle',x,-.222,1.024,.064,.077,.008,brasslight,'body')
cylinder('rolled blanket',(-.30,.22,1.29),(.30,.22,1.29),.088,leatherlight)
for side in [-1,1]:
    pts=[]
    for i in range(85):
        t=i*.18;r=.008+.074*i/84
        pts.append((side*.304,.22+r*math.cos(t),1.29+r*math.sin(t)))
    tube('bedroll spiral',pts,.006,leather)

sphere('neck',(0,-.003,1.20),(.15,.14,.13),skin,'head')
sphere('head',(0,-.008,1.466),(.295,.252,.293),skin,'head')
for side in [-1,1]:
    sphere('ear',(side*.29,-.002,1.451),(.07,.054,.091),skin,'head')
    sphere('ear inner',(side*.321,-.042,1.449),(.028,.013,.052),leatherlight,'head')
    sphere('cheek',(side*.19,-.184,1.393),(.085,.045,.065),skinlight,'head')

# Beard volume, a shaped moustache and restrained individual strands.
sphere('beard jaw',(0,-.075,1.258),(.267,.21,.16),hair,'head')
for side in [-1,1]:sphere('sideburn',(side*.251,-.057,1.379),(.045,.11,.15),hair,'head')
for i in range(25):
    x=(i-12)*.019; a=abs(x)/.25
    pts=[]
    for z,mul in [(1.35,.94),(1.27,1),(1.17,.84),(1.12,.60)]:
        xx=x*mul;zz=z+.045*a
        yy=-.075-.21*math.sqrt(max(.03,1-(xx/.267)**2-((zz-1.258)/.16)**2))-.009
        pts.append((xx,yy,zz))
    tube('beard sculpt strand',pts,.010,hairlight if i%3==0 else hair,'head',[.5,1,.75,.06])
tube('smile',[(-.105,-.262,1.332),(0,-.285,1.307),(.105,-.262,1.332)],.011,dark,'head')
for side in [-1,1]:
    tube('curled moustache',[(side*.006,-.30,1.383),(side*.065,-.315,1.361),(side*.155,-.277,1.369),(side*.198,-.244,1.408)],.033,hair,'head',[.72,1,.85,.06])
    for k in range(3):tube('moustache strand',[(side*.03,-.329,1.373+k*.009),(side*.10,-.311,1.365+k*.006),(side*.176,-.265,1.394+k*.004)],.0035,hairlight,'head')
sphere('rounded broad nose',(0,-.286,1.434),(.088,.087,.064),skinlight,'head')
for side in [-1,1]:
    x=side*.124
    cube('square ivory eye',(x,-.241,1.524),(.181,.037,.142),white,'head',.021)
    sphere('round pupil',(x+.009,-.267,1.520),(.040,.012,.054),pupil,'head')
    sphere('eye glint',(x+.022,-.279,1.540),(.011,.005,.014),white,'head',16)
    rect_ring('square brass glasses',x,-.275,1.524,.206,.17,.012,brass,'head')
    tube('glasses temple',[(side*.228,-.274,1.552),(side*.272,-.12,1.555),(side*.293,-.016,1.545)],.009,brass,'head')
    tube('eyebrow',[(side*.047,-.25,1.633),(side*.12,-.24,1.643),(side*.207,-.209,1.628)],.017,hair,'head',[.5,1,.4])
tube('glasses bridge',[(-.024,-.281,1.54),(0,-.29,1.552),(.024,-.281,1.54)],.009,brass,'head')

# Iron dome and brass frame: half-ellipsoid surface with proper volume.
verts=[];faces=[]
for j in range(17):
    t=j/16*math.pi/2
    for i in range(64):
        a=i/64*math.tau;verts.append((.344*math.sin(t)*math.cos(a),.30*math.sin(t)*math.sin(a),1.65+.31*math.cos(t)))
for j in range(16):
    for i in range(64):
        n=j*64+i;m=j*64+(i+1)%64;faces.append((n,m,m+64,n+64))
mesh=bpy.data.meshes.new('helmet dome');mesh.from_pydata(verts,[],faces);mesh.update()
o=bpy.data.objects.new('iron dome',mesh);bpy.context.collection.objects.link(o);register(o,iron,'head')
solid=o.modifiers.new('helmet thickness','SOLIDIFY');solid.thickness=.012
oval_ring('helmet broad rim',1.651,.355,.315,.041,brass,'head')
oval_ring('helmet visor edge',1.628,.385,.354,.014,brasslight,'head',-.014)
oval_ring('helmet upper band',1.698,.34,.294,.018,brass,'head')
for xoff in [-.035,.035]:
    tube('helmet crown strip edge',[(xoff,.30*math.cos(t),1.65+.31*math.sin(t)) for t in [i*math.pi/32 for i in range(33)]],.014,brasslight,'head')
tube('helmet crown strip',[(0,.30*math.cos(t),1.65+.31*math.sin(t)) for t in [i*math.pi/32 for i in range(33)]],.039,brass,'head')
for i in range(12):
    a=i*math.tau/12
    sphere('helmet band rivet',(.355*math.cos(a),.31*math.sin(a),1.69),(.014,.014,.014),brasslight,'head',16)
for t in [.35,.7,1.05,1.4,1.75,2.1,2.45,2.8]:sphere('crown rivet',(0,.31*math.cos(t),1.65+.324*math.sin(t)),(.017,.017,.017),brasslight,'head',16)
cylinder('lamp bracket',(0,-.273,1.779),(0,-.345,1.779),.105,brass,'head')
cylinder('lamp bezel',(0,-.344,1.779),(0,-.386,1.779),.099,brasslight,'head')
cylinder('lamp dark inset',(0,-.384,1.779),(0,-.393,1.779),.080,iron,'head')
sphere('convex amber lens',(0,-.401,1.779),(.071,.024,.071),lamp,'head')

# Slightly larger head and shorter-looking body match the original chibi proportions.
# Apply a coherent shape transform to the whole authored head, including all details.
for o in groups.get('head',[]):
    base=Vector((0,0,1.20));o.location=base+(o.location-base)*1.12;o.scale*=1.12
    if o.type=='CURVE':
        # Curves were authored in world coordinates at object origin: scale about base.
        o.location=base-base*1.12

smooth=motion_v2.smooth
def bone_matrix(a,b,secondary=None):
    a,b=Vector(a),Vector(b);y=(b-a).normalized()
    if secondary is None:secondary=Vector((0,1,0))
    x=secondary-y*y.dot(secondary)
    if x.length<1e-5:x=Vector((1,0,0))-y*y.x
    x.normalize();z=x.cross(y).normalized()
    M=Matrix((x,y,z)).transposed().to_4x4();M.translation=a;return M

rest=motion_v2.rest(args.tool)
bpy.ops.object.armature_add(enter_editmode=True)
rig=bpy.context.object;rig.name='EverDeeper_Hero_Rig';arm=rig.data;arm.name='one anatomical skeleton'
arm.edit_bones.remove(arm.edit_bones[0])
def add_bone(name,a,b,parent=None,secondary=None):
    bone=arm.edit_bones.new(name);bone.head=a;bone.tail=b
    if parent:bone.parent=arm.edit_bones[parent]
    if secondary:bone.align_roll(bone_matrix(a,b,secondary).col[2].to_3d())
    return bone
add_bone('root',(0,0,0),(0,0,.2))
add_bone('body',(0,0,.65),(0,0,1.12),'root')
add_bone('hips',(0,0,.30),(0,0,.6),'root')
for side in ['R','L']:
    hip,knee,foot=rest['legs'][side]
    add_bone('thigh.'+side,hip,knee,'hips')
    add_bone('shin.'+side,knee,foot,'thigh.'+side)
    add_bone('foot.'+side,foot,foot+Vector((0,-.12,0)),'root')
add_bone('head',(0,0,1.20),(0,0,1.55),'body')
add_bone('tool',rest['rear'],rest['rear']+rest['axis']*.55,'root')
if IS_DRILL:add_bone('bit',Vector((-.035,-.543,1.055))+motion_v2.DRILL_OFFSET,Vector((-.035,-.855,1.055))+motion_v2.DRILL_OFFSET,'tool')
for side in ['R','L']:
    a,b,c=rest['arms'][side]
    add_bone('upper.'+side,a,b,'body');add_bone('lower.'+side,b,c,'upper.'+side)
    add_bone('hand.'+side,c,rest['grips'][side],'lower.'+side,rest['hand_axes'][side])
bpy.ops.object.mode_set(mode='OBJECT');rig.show_in_front=True

def bind(o,bone):
    # All authored objects are converted into mesh and given actual bone weights.
    bpy.context.view_layer.objects.active=o;o.select_set(True)
    if o.type=='CURVE':bpy.ops.object.convert(target='MESH');o=bpy.context.object
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bone.startswith('leg.'):
        side=bone[-1];u=o.vertex_groups.new(name='thigh.'+side);l=o.vertex_groups.new(name='shin.'+side)
        for v in o.data.vertices:
            w=smooth(((o.matrix_world@v.co).z-.31)/.12)
            u.add([v.index],w,'REPLACE');l.add([v.index],1-w,'REPLACE')
    else:
        vg=o.vertex_groups.new(name=bone);vg.add(list(range(len(o.data.vertices))),1,'REPLACE')
    mod=o.modifiers.new('skinned to hero','ARMATURE');mod.object=rig
    o.select_set(False)
    return o
bpy.ops.object.select_all(action='DESELECT')
for group,objects in list(groups.items()):
    for o in objects:bind(o,group)
groups.clear()

def sleeve(side):
    a,b,c=rest['arms'][side];points=[];weights=[];radii=[]
    for i in range(13):
        t=i/12
        if t<=.5:p=a.lerp(b,t*2)
        else:p=b.lerp(c,(t-.5)*2)
        points.append(p);radii.append(.103*(1-t)+.057*t+.006*math.sin(t*math.pi*5))
        weights.append(smooth((t-.35)/.30))
    vs=[];fs=[]
    for j,p in enumerate(points):
        tangent=points[min(j+1,12)]-points[max(j-1,0)];tangent.normalize()
        x=Vector((0,1,0));x=(x-tangent*x.dot(tangent)).normalized();y=tangent.cross(x)
        for i in range(20):
            t=i*math.tau/20;vs.append(p+radii[j]*(math.cos(t)*x+math.sin(t)*y))
    for j in range(12):
        for i in range(20):
            k=j*20+i;kn=j*20+(i+1)%20;fs.append((k,kn,kn+20,k+20))
    me=bpy.data.meshes.new('continuous sleeve '+side);me.from_pydata(vs,[],fs);me.update()
    o=bpy.data.objects.new('continuous shoulder elbow cuff '+side,me);bpy.context.collection.objects.link(o)
    register(o,coat,'unused')
    u=o.vertex_groups.new(name='upper.'+side);l=o.vertex_groups.new(name='lower.'+side)
    for j,w in enumerate(weights):
        ids=list(range(j*20,(j+1)*20));u.add(ids,1-w,'REPLACE');l.add(ids,w,'REPLACE')
    mod=o.modifiers.new('continuous two bone deformation','ARMATURE');mod.object=rig
    sub=o.modifiers.new('smooth elbow fabric','SUBSURF');sub.levels=1
    # One cuff, at wrist only. Never duplicate a cuff at the elbow.
    d=(c-b).normalized()
    cuff=cylinder('single brass wrist cuff '+side,c-d*.045,c+d*.006,.063,brass,'lower.'+side)
    for off in [-.04,.003]:cylinder('cuff edge '+side,c+d*off,c+d*(off+.006),.065,brasslight,'lower.'+side)

def hand(side):
    if IS_DRILL and side=='L':return drill_v2.support_hand(globals())
    grip=rest['grips'][side];axis=rest['hand_axes'][side];r=rest['radials'][side];cross=axis.cross(r).normalized()
    group='hand.'+side
    def P(x,y,z):return grip+axis*x+cross*y+r*z
    palm=sphere('palm '+side,P(-.002,0,.052),(.054,.040,.030),skin,group)
    # Set ellipsoid local X along shaft, Y across palm, Z away from shaft.
    palm.rotation_mode='QUATERNION';palm.rotation_quaternion=Matrix((axis,cross,r)).transposed().to_quaternion()
    wrist=rest['arms'][side][2]
    sphere('wrist volume '+side,wrist,(.042,.042,.043),skin,group)
    cylinder('palm wrist connection '+side,wrist,P(-.008,0,.05),.037,skin,group,.043)
    # Four distinct fingers wrap continuously around the same radius .023 shaft.
    for i in range(4):
        x=(i-1.5)*.023
        pts=[P(x,.020,.059),P(x,.042,.032),P(x,.039,-.008),P(x,.014,-.027),P(x,-.009,-.023)]
        tube('curled finger '+side+str(i),pts,.013,skinlight,group,[1,1,.95,.85,.65])
        tube('knuckle crease '+side+str(i),[P(x-.006,.041,.033),P(x,.045,.030),P(x+.006,.041,.032)],.0018,leatherlight,group)
    tube('opposing thumb '+side,[P(-.046,-.013,.059),P(-.063,-.025,.025),P(-.047,-.026,-.008),P(-.026,-.023,-.017)],.019,skinlight,group,[1,1,.85,.6])
for side in ['R','L']:sleeve(side);hand(side)

gear_v3.build(globals(),args.tool)

bpy.ops.object.select_all(action='DESELECT')
for group,objects in list(groups.items()):
    if group=='unused':continue
    for o in objects:bind(o,group)
groups.clear()

# Bone matrices are set in armature space, then Blender stores parent-relative keys.
# This produces a native editable Action and an actual deforming skinned mesh.
from rig_pose_v3 import create_applier
apply_pose=create_applier(rig,rest)
rest_mats={b.name:b.matrix_local.copy() for b in rig.data.bones}

# Mesh deformation is unnecessary while solving bone keys; evaluate it again
# before saving/rendering. Grip checks below use actual native bone matrices.
preview_mods=[m for o in scene.objects for m in o.modifiers if m.type=='ARMATURE' and m.show_viewport]
for m in preview_mods:m.show_viewport=False
checks=[]
spin=0.0
for frame in range(1,301):
    t=(frame-1)/60
    p=motion_v2.sample(t,args.tool);spin+=math.tau*gear_v3.PROFILES[args.tool].get('rotor_rps',0)*p['mine']/60;p['bit_angle']=spin;apply_pose(p)
    for b in rig.pose.bones:
        b.rotation_mode='QUATERNION'
        b.keyframe_insert('location',frame=frame);b.keyframe_insert('rotation_quaternion',frame=frame);b.keyframe_insert('scale',frame=frame)
    errors={}
    for side in ['R','L']:
        m=rig.pose.bones['hand.'+side].matrix@rest_mats['hand.'+side].inverted()
        actual=m@rest['grips'][side];errors[side]=(actual-p['grips'][side]).length
    if max(errors.values())>1e-5:raise ValueError(f'hand detached at {frame}: {errors}')
    checks.append({'frame':frame,'phase':p['phase'],'grip_errors':errors,'walk':p['walk'],'mine':p['mine'],'foot_lifts':p['foot_lifts']})
for m in preview_mods:m.show_viewport=True
bpy.context.view_layer.update()
if rig.animation_data and rig.animation_data.action:
    rig.animation_data.action.name=args.tool+'_Idle_Walk_Mine_Stop_60fps'
    for fc in rig.animation_data.action.fcurves:
        for k in fc.keyframe_points:k.interpolation='LINEAR'
scene.frame_set(1)

def area(name,loc,energy,size,color):
    bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name
    o.data.energy=energy;o.data.shape='DISK';o.data.size=size;o.data.color=color
    o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
area('warm large key',(-3,-4,5),400,4,(1,.76,.45))
area('soft cool fill',(3,-1,3),110,3,(.72,.85,1))
area('brass rim light',(-1,3,4),550,3,(1,.70,.32))
bpy.ops.object.camera_add(location=(3,-6,3.4));cam=bpy.context.object;cam.name='original style orthographic camera'
cam.data.type='ORTHO';cam.data.ortho_scale=2.28;scene.camera=cam
def camera(loc,target=(0,-.07,1.0),scale=2.28):
    cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
camera((-3,-6,3.4),(0,-.07,1.04),2.39)
rig['visual_approved']=False
rig['purpose']='Authored 3D study; original appearance and anatomical motion require visual review.'
rig['reference']=gear_v3.PROFILES[args.tool]['asset']
rig['gear_id']=args.tool
rig['cycle_seconds']=gear_v3.PROFILES[args.tool]['cycle']
(ROOT/'qa').mkdir(exist_ok=True);(ROOT/'frames').mkdir(exist_ok=True)
(ROOT/'qa'/'rig_checks.json').write_text(json.dumps({'frames':300,'max_grip_error':max(max(c['grip_errors'].values()) for c in checks),'visual_approved':False,'checks':checks},indent=2))
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/('hero-'+args.tool+'.blend')))
def render(name,frame=1):
    scene.frame_set(frame);scene.render.filepath=str(ROOT/'qa'/name);bpy.ops.render.render(write_still=True)
if args.render=='neutral':render('neutral.png')
if args.render=='poses':
    camera((6,-.65,3.2),(0,-.21,1.05),2.55)
    for name,frame in [('ready',1),('walk',73),('windup',157),('strike',166),('recovery',265)]:render(name+'.png',frame)
if args.render=='animation':
    camera((6,-.65,3.2),(0,-.21,1.05),2.55)
    scene.render.resolution_x=384;scene.render.resolution_y=480
    scene.render.filepath=str(ROOT/'frames'/'iron-');bpy.ops.render.render(animation=True)
print('BUILD_COMPLETE',str(ROOT/('hero-'+args.tool+'.blend')),flush=True)
