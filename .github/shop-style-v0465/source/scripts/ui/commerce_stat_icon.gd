extends Control
var kind: String = "power"
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func _draw() -> void:
 var c: Vector2 = size*0.5
 var r: float = minf(size.x,size.y)*0.36
 var ink: Color = Color("c2b9ad")
 if "time" in kind or "speed" in kind or "interval" in kind:
  draw_arc(c,r,0,TAU,32,ink,1.8,true)
  draw_line(c,c+Vector2(0,-r*0.72),ink,1.8,true)
  draw_line(c,c+Vector2(r*0.5,0),ink,1.8,true)
  draw_line(c+Vector2(-r*0.3,-r-4),c+Vector2(r*0.3,-r-4),ink,2,true)
 elif "area" in kind or "radius" in kind:
  for y in 2:
   for x in 2: draw_rect(Rect2(c+Vector2((x-1)*r+1,(y-1)*r+1),Vector2(r-3,r-3)),ink,false,1.7)
 else:
  var pts: PackedVector2Array = []
  for i in 16: pts.append(c+Vector2.from_angle(float(i)*TAU/16.0)*(r if i%2==0 else r*0.38))
  pts.append(pts[0]);draw_polyline(pts,ink,1.7,true)
