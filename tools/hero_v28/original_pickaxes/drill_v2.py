"""Native Deepcore geometry and a purpose-built supporting palm."""
import math
from mathutils import Vector
from motion_v2 import DRILL_OFFSET

def support_hand(api):
    sphere,tube,cylinder=(api[n] for n in ['sphere','tube','cylinder'])
    skin,light=(api[n] for n in ['skin','skinlight'])
    g=api['rest']['grips']['L'];w=api['rest']['arms']['L'][2];group='hand.L'
    sphere('support palm',g+Vector((0,.012,-.024)),(.069,.065,.026),skin,group)
    sphere('support wrist',w,(.041,.041,.041),skin,group)
    cylinder('support heel of palm',w,g+Vector((.01,.025,-.024)),.037,skin,group,.044)
    for i in range(4):
        x=(i-1.5)*.026;rise=.013*abs(i-1.5)
        pts=[g+Vector((x,.024,-.020+rise)),g+Vector((x,-.024,-.021+rise)),g+Vector((x,-.058,-.003+rise)),g+Vector((x,-.067,.018+rise))]
        tube('support curled finger '+str(i),pts,.0125,light,group,[1,1,.9,.65])
    tube('support opposing thumb',[g+Vector((.05,.025,-.023)),g+Vector((.075,.005,-.006)),g+Vector((.081,-.02,.022))],.018,light,group,[1,.85,.60])

def build(api):
    cylinder,sphere,cube,tube=(api[n] for n in ['cylinder','sphere','cube','tube'])
    brass,edge,iron,leather=(api[n] for n in ['brass','brasslight','iron','leather'])
    green=api['material']('Deepcore luminous green core',(.006,.30,.060),metal=.28,rough=.23)
    p=green.node_tree.nodes.get('Principled BSDF');p.inputs['Emission Color'].default_value=(.01,.48,.10,1);p.inputs['Emission Strength'].default_value=.35
    x=-.035;z=1.055
    cylinder('drill rear iron cap',(x,-.18,z),(x,-.24,z),.105,iron,'tool')
    cylinder('drill rear brass rim',(x,-.18,z),(x,-.193,z),.111,brass,'tool')
    cylinder('drill energy core',(x,-.23,z),(x,-.46,z),.078,green,'tool')
    for y in [-.255,-.285,-.315,-.345,-.375,-.405,-.435]:
        cylinder('core coil divider',(x,y,z),(x,y-.008,z),.081,iron,'tool')
    for y in [-.235,-.463]:
        cylinder('barrel brace',(x,y,z),(x,y-.023,z),.107,brass,'tool')
        for i in range(8):
            t=i*math.tau/8
            sphere('barrel bolt',(x+.106*math.cos(t),y-.011,z+.106*math.sin(t)),(.009,.009,.009),edge,'tool',16)
    for a in [math.pi/4,3*math.pi/4,5*math.pi/4,7*math.pi/4]:
        xx=x+.098*math.cos(a);zz=z+.098*math.sin(a)
        cylinder('long brass chassis rail',(xx,-.24,zz),(xx,-.47,zz),.012,brass,'tool')
    for side in [-1,1]:
        xx=x+side*.108
        cylinder('side power bezel',(xx,-.207,z),(xx+side*.014,-.207,z),.067,brass,'tool')
        cylinder('side black ring',(xx+side*.014,-.207,z),(xx+side*.019,-.207,z),.052,iron,'tool')
        sphere('side green power lens',(xx+side*.022,-.207,z),(.008,.041,.041),green,'tool')
        for zz in [z-.067,z+.067]:cube('side window frame',(xx,-.35,zz),(.018,.175,.012),iron,'tool',.004)
    cylinder('top iron piston',(x,-.22,z+.112),(x,-.445,z+.112),.022,iron,'tool')
    for y in [-.23,-.42]:cylinder('piston brass bearing',(x,y,z+.112),(x,y-.025,z+.112),.030,brass,'tool')
    # Rear pistol grip is separate from the forward housing support surface.
    grip=api['rest']['grips']['R']-DRILL_OFFSET;axis=api['rest']['hand_axes']['R']
    cylinder('pistol grip',grip-axis*.097,grip+axis*.112,.027,leather,'tool')
    cylinder('pistol grip butt',grip-axis*.109,grip-axis*.084,.034,brass,'tool')
    tube('trigger guard',[(x,-.26,.977),(x,-.316,.962),(x,-.315,.898),(x,-.255,.879)],.011,brass,'tool')
    cylinder('trigger',(x,-.282,.969),(x,-.292,.938),.007,iron,'tool')
    cylinder('stationary nose collar',(x,-.487,z),(x,-.535,z),.106,brass,'tool')
    cylinder('dark bit bearing',(x,-.532,z),(x,-.543,z),.093,iron,'tool')
    # Only this group rotates; hands remain attached to the stationary tool bone.
    cylinder('rotating tapered bit',(x,-.543,z),(x,-.855,z),.097,brass,'bit',.004)
    points=[]
    for i in range(241):
        f=i/240;a=f*math.tau*4.5;r=.098*(1-f)+.003
        points.append((x+r*math.cos(a),-.543-.308*f,z+r*math.sin(a)))
    tube('bit helical cutting ridge',points,.0065,edge,'bit',[1-i/270 for i in range(241)])
    for group in ['tool','bit']:
        for obj in api['groups'].get(group,[]):obj.location+=DRILL_OFFSET
