"""Actual skinned eyelid surfaces for the approved v28 eye apertures."""
import bpy, math
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

def create_blink(rig):
 s=bpy.context.scene;dep=bpy.context.evaluated_depsgraph_get()
 face=bpy.data.objects['v17 unified expressive face']
 ft=BVHTree.FromObject(face,dep)
 kd=KDTree(len(face.data.vertices))
 for v in face.data.vertices:kd.insert(face.matrix_world@v.co,v.index)
 kd.balance();tints=face.data.color_attributes['facial_tint']
 whites=sorted([o for o in s.objects if o.name.startswith('v17 inset curved eye aperture')],key=lambda o:o.name)
 glints=[o for o in s.objects if o.name.startswith('v17 quiet eye highlight')]
 lids=[];N=57;ROWS=10
 for eye in whites:
  tree=BVHTree.FromObject(eye,dep)
  edge=[eye.matrix_world@v.co for v in eye.data.vertices[-112:]]
  vs=[Vector() for _ in range(N*ROWS)];fs=[]
  for j in range(ROWS-1):
   for k in range(N-1):q=j*N+k;fs.append((q,q+1,q+N+1,q+N))
  me=bpy.data.meshes.new('v28 articulated upper lid');me.from_pydata(vs,[],fs);me.update()
  o=bpy.data.objects.new('v28 articulated upper lid',me);s.collection.objects.link(o)
  me.materials.append(face.data.materials[0])
  attr=me.color_attributes.new(name='facial_tint',type='FLOAT_COLOR',domain='POINT')
  for j in range(ROWS):
   for k in range(N):
    _,idx,_=kd.find(edge[k]+Vector((0,0,.008)))
    attr.data[j*N+k].color=tints.data[idx].color
  for f in me.polygons:f.use_smooth=True
  g=o.vertex_groups.new(name='head');g.add(list(range(len(vs))),1,'REPLACE')
  mod=o.modifiers.new('native head skin','ARMATURE');mod.object=rig
  lids.append((o,edge,tree))
 def blink(amount):
  for o,edge,tree in lids:
   o.hide_render=amount<.002
   if amount<.002:continue
   for j in range(ROWS):
    t=j/(ROWS-1)
    for k in range(N):
     upper=edge[k];lower=edge[(112-k)%112]
     q=upper.lerp(lower,t*amount)
     q.z+=.006*(1-t)-.003*t*amount
     hit,_,_,_=tree.ray_cast(Vector((q.x,-1,q.z)),Vector((0,1,0)),2)
     if hit is None:hit,_,_,_=ft.ray_cast(Vector((q.x,-1,q.z)),Vector((0,1,0)),2)
     q.y=(hit.y if hit is not None else upper.y)-.0035-.001*math.sin(math.pi*t)
     o.data.vertices[j*N+k].co=q
   o.data.update()
  for o in glints:o.hide_render=amount>.2
 blink(0)
 return blink
