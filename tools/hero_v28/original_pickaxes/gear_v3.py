"""Interchangeable native tools, keeping the game's source artwork.

Pick heads use closed, textured relief meshes derived from source alpha.
Handles are round solid geometry with the source's shaft texture wrapped on.
This preserves the actual ornamentation instead of inventing replacement icons.
"""
import bpy,json,math
from pathlib import Path
from mathutils import Vector
import drill_v2
ROOT=Path(__file__).parent
PROFILES=json.loads((ROOT/'gear_profiles.json').read_text())

def textured(api,path):
    m=api['material']('original artwork '+path.stem,(.35,.28,.16),metal=.40,rough=.38)
    n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF')
    image=bpy.data.images.load(str(path),check_existing=True)
    tex=n.new('ShaderNodeTexImage');tex.image=image;tex.interpolation='Linear'
    l.new(tex.outputs['Color'],p.inputs['Base Color'])
    return m,image

def pickaxe(api,kind):
    cfg=PROFILES[kind];mat,img=textured(api,ROOT/'v3/references'/cfg['asset'])
    cylinder,tube=api['cylinder'],api['tube']
    rear=api['rest']['rear'];axis=api['rest']['axis'];radial=Vector((0,axis.z,-axis.y));side=Vector((1,0,0))
    w,h=img.size;px=list(img.pixels);scale=.55/(cfg['head_x']-44)
    def T(x,y=0,z=0):return rear+axis*((x-44)*scale)+radial*y+side*z
    # Matching cylindrical shaft allows full physical finger wraps in all views.
    shaft=cylinder('round source-textured shaft',T(8),T(cfg['head_x']+6),.023,mat,'tool')
    # Cylinder was authored along local Z. Remap to the source shaft strip.
    uv=shaft.data.uv_layers.active
    for poly in shaft.data.polygons:
        for li in poly.loop_indices:
            co=shaft.data.vertices[shaft.data.loops[li].vertex_index].co
            depth=((cfg['head_x']+6)-8)*scale
            u=(8+(co.z/depth+.5)*(cfg['head_x']-2))/w
            v=1-(cfg['shaft_y']+math.sin(math.atan2(co.y,co.x))*7)/h
            uv.data[li].uv=(u,v)
    metal=api['iron'] if kind=='worn' else api['brass']
    for x in [9,97,cfg['head_start']-2]:
        cylinder('source shaft ferrule',T(x-2),T(x+2),.0265,metal,'tool')
    if kind!='worn':
        for i in range(5):
            angle=i*math.tau/5
            api['sphere']('ferrule rivet',T(97,.026*math.cos(angle),.026*math.sin(angle)),(.004,.004,.004),api['brasslight'],'tool',12)
    # One solid alpha-derived head, textured on both sides. No billboard.
    # Pixel cells share vertices; the silhouette and any interior holes are
    # closed with side faces. The boundary uses the source alpha at 50%.
    def opaque(x,y):
        return cfg['head_start']<=x<w and 0<=y<h and px[(y*w+x)*4+3]>.50
    occupied={(x,y) for y in range(h) for x in range(cfg['head_start'],w) if opaque(x,y)}
    vs=[];fs=[];uvs=[];mi=[];index={}
    thick=.024 if kind=='crusher' else .012
    def vertex(x,y,sign):
        key=(x,y,sign)
        if key not in index:
            # A shallow convex surface gives depth while retaining the profile.
            extra=.008*math.sin(math.pi*(x-cfg['head_start'])/max(1,w-cfg['head_start']))
            index[key]=len(vs);vs.append(T(x,(y-(h-cfg['shaft_y']))*scale,sign*(thick+extra)))
        return index[key]
    def face(points,material=0):
        fs.append(tuple(vertex(*v) for v in points));uvs.append([(v[0]/w,v[1]/h) for v in points]);mi.append(material)
    for x,y in sorted(occupied):
        face([(x,y,1),(x+1,y,1),(x+1,y+1,1),(x,y+1,1)])
        face([(x,y,-1),(x,y+1,-1),(x+1,y+1,-1),(x+1,y,-1)])
        for dx,dy,a,b in [(-1,0,(x,y),(x,y+1)),(1,0,(x+1,y+1),(x+1,y)),(0,-1,(x+1,y),(x,y)),(0,1,(x,y+1),(x+1,y+1))]:
            if (x+dx,y+dy) not in occupied:
                face([(*a,-1),(*b,-1),(*b,1),(*a,1)],1)
    me=bpy.data.meshes.new('closed original silhouette '+kind);me.from_pydata(vs,[],[tuple(reversed(f)) for f in fs]);me.update()
    o=bpy.data.objects.new('original relief head '+kind,me);bpy.context.collection.objects.link(o)
    api['register'](o,mat,'tool');o.data.materials.append(api['brass'] if kind in ['crown','ember'] else api['iron'])
    uv=me.uv_layers.new(name='OriginalArtwork')
    for poly,coords,m in zip(me.polygons,uvs,mi):
        poly.use_smooth=(m==1);poly.material_index=m
        for li,co in zip(poly.loop_indices,coords):uv.data[li].uv=co
    o['source_artwork']=cfg['asset'];o['closed_relief_mesh']=True

def build(api,kind):
    if PROFILES[kind]['family']=='pickaxe':return pickaxe(api,kind)
    drill_v2.build(api)
    if kind=='deepcore':return
    groups=api['groups'];material=api['material']
    if kind=='burrower':
        # Burrower: dark, enclosed iron motor with amber power indicator.
        dark=material('Burrower dark machined steel',(.06,.055,.045),metal=.83,rough=.34,texture=40)
        amber=material('Burrower amber indicator',(.75,.30,.025),metal=.2,rough=.2)
        amber.node_tree.nodes.get('Principled BSDF').inputs['Emission Color'].default_value=(.8,.25,.01,1)
        amber.node_tree.nodes.get('Principled BSDF').inputs['Emission Strength'].default_value=.35
        for o in groups['tool']:
            if any(v in o.name for v in ['core coil','long brass chassis','top iron piston','piston brass']):o.hide_render=True
            if 'energy core' in o.name or 'side window' in o.name:o.data.materials[0]=dark
            if 'side green' in o.name:o.data.materials[0]=amber
        # A properly enclosed housing rather than recoloring a luminous core.
        off=api['motion_v2'].DRILL_OFFSET
        api['cylinder']('Burrower enclosed motor',Vector((-.035,-.232,1.055))+off,Vector((-.035,-.46,1.055))+off,.097,dark,'tool')
        for o in groups['bit']:o.data.materials[0]=api['steel']
    else:
        blue=material('Pulse electric cyan',(.006,.44,.64),metal=.25,rough=.20)
        p=blue.node_tree.nodes.get('Principled BSDF');p.inputs['Emission Color'].default_value=(.01,.7,1,1);p.inputs['Emission Strength'].default_value=.6
        for o in groups['tool']:
            if 'energy core' in o.name or 'side green' in o.name:o.data.materials[0]=blue
        for o in groups['bit']:o.data.materials[0]=blue if 'helical' in o.name else api['steel']
