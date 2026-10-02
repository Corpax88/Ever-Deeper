extends RefCounted
func apply(visual:Node) -> Dictionary:
	var equipment=visual.equipment
	if not equipment.verified: equipment._initialize()
	var mesh:MeshInstance3D=equipment.hero_mesh
	var native_from_vertex:Transform3D=visual.rig.AXIS.affine_inverse()*mesh.global_transform
	var mask:=Image.new();mask.load_png_from_buffer(FileAccess.get_file_as_bytes('res://assets/native-worn/cloth.png.raw'))
	var names:Dictionary={}
	for i in mesh.skin.get_bind_count():
		var n:String=String(mesh.skin.get_bind_name(i))
		if n.is_empty(): n=visual.rig.skeleton.get_bone_name(mesh.skin.get_bind_bone(i))
		names[n]=i
	var counts:Dictionary={}
	for kind in ['original_mesh','body_mesh']:
		var original:Mesh=equipment.get(kind)
		var revised:=ArrayMesh.new();var changed:int=0
		for surface in original.get_surface_count():
			var arrays:Array=original.surface_get_arrays(surface)
			var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var uv:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
			var bones:PackedInt32Array=arrays[Mesh.ARRAY_BONES]
			var weights:PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
			var influences:int=weights.size()/vertices.size()
			for i in vertices.size():
				var color:Color=mask.get_pixel(clampi(int(uv[i].x*mask.get_width()),0,mask.get_width()-1),clampi(int(uv[i].y*mask.get_height()),0,mask.get_height()-1))
				if color.r<.80: continue
				var w:Dictionary={}
				for k in influences:
					if weights[i*influences+k]>.00001:w[bones[i*influences+k]]=weights[i*influences+k]
				for side in ['R','L']:
					var upper:int=names['upper.'+side];var lower:int=names['lower.'+side];var body:int=names.body
					if float(w.get(upper,0))<.10:continue
					var native:Vector3=native_from_vertex*vertices[i]
					var start:Vector3=visual.rig.rest['upper.'+side].origin
					var axis:Vector3=(visual.rig.rest['lower.'+side].origin-start).normalized()
					var along:float=(native-start).dot(axis)
					var transfer:float=float(w.get(lower,0))
					w[lower]=float(w.get(lower,0))-transfer;w[upper]=float(w.get(upper,0))+transfer
					var shoulder:float=(1.0-smoothstep(-.02,.16,along))*.04
					var blend:float=float(w[upper])*shoulder
					w[upper]=float(w[upper])-blend;w[body]=float(w.get(body,0))+blend
					changed+=1;break
				var ranked:Array=w.keys();ranked.sort_custom(func(a,b):return float(w[a])>float(w[b]))
				var total:float=0
				for k in mini(influences,ranked.size()):total+=float(w[ranked[k]])
				for k in influences:
					bones[i*influences+k]=int(ranked[k]) if k<ranked.size() else 0
					weights[i*influences+k]=float(w[ranked[k]])/total if k<ranked.size() else 0
			arrays[Mesh.ARRAY_BONES]=bones;arrays[Mesh.ARRAY_WEIGHTS]=weights
			revised.add_surface_from_arrays(original.surface_get_primitive_type(surface),arrays)
			revised.surface_set_material(surface,original.surface_get_material(surface))
		equipment.set(kind,revised);counts[kind]=changed
	mesh.mesh=equipment.original_mesh if equipment.current=='worn' else equipment.body_mesh
	return counts
