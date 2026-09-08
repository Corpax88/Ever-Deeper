"""Shared action selection and native face authoring for the dad model."""
import bpy,json,math
import hero_expression_v7 as face

def face_sample(t,mode):
    if mode=='mine':return face.sample(t)
    return {'blink':max(face.blink_at(t,.40),face.blink_at(t,3.13)),
            'focus':0.,'gaze_x':.16*math.sin(t*math.tau/3.6),'gaze_down':.18}

def author_faces():
    for o in bpy.context.scene.objects:
        if o.type!='MESH' or not o.data.shape_keys:continue
        keys=o.data.shape_keys;names=[k.name for k in keys.key_blocks if k.name!='Basis'];actions={}
        for mode,count in [('idle',216),('walk',216),('mine',261)]:
            keys.animation_data_clear()
            for i in range(count+1):
                q=face_sample(i/60,mode)
                for name in names:
                    key=keys.key_blocks[name];key.value=q[{'Blink':'blink','LookX':'gaze_x','LookDown':'gaze_down','Focus':'focus'}[name]]
                    key.keyframe_insert('value',frame=i+1)
            action=keys.animation_data.action;action.name='Dad '+mode+' '+o.name;action.use_fake_user=True;actions[mode]=action.name
            for layer in action.layers:
                for strip in layer.strips:
                    for bag in strip.channelbags:
                        for fc in bag.fcurves:
                            for k in fc.keyframe_points:k.interpolation='LINEAR'
                            cyc=fc.modifiers.new('CYCLES');cyc.mode_before='REPEAT';cyc.mode_after='REPEAT'
        keys['dad_actions']=json.dumps(actions)

def select(mode):
    r=bpy.data.objects['EverDeeper_Hero_Rig']
    action=bpy.data.actions[json.loads(r['action_modes'])[mode]]
    r.animation_data.action=action
    if action.slots:r.animation_data.action_slot=action.slots[0]
    for o in bpy.context.scene.objects:
        if o.type!='MESH' or not o.data.shape_keys:continue
        keys=o.data.shape_keys
        if 'dad_actions' not in keys:continue
        action=bpy.data.actions[json.loads(keys['dad_actions'])[mode]];keys.animation_data.action=action
        if action.slots:keys.animation_data.action_slot=action.slots[0]
    bpy.context.scene.frame_set(1)
