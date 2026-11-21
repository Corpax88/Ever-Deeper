extends SceneTree
var main: Node
var state: Node
var out: String
var checks: Array=[]
var capture_sizes: Array=[]
func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
 checks.append({"name":label,"passed":ok})
 FileAccess.open(out.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.all(func(c):return c.passed),"actual_viewport":[root.size.x,root.size.y],"capture_sizes":capture_sizes},"\t"))
 if not ok: print("CHECK_FAILED ",label)
func settle() -> void: await create_timer(0.4).timeout
func shot(label: String) -> void:
 if main.phase == "mine": main.mine_world.queue_redraw()
 if main.phase == "depth": main.depth_world.queue_redraw()
 await settle();await RenderingServer.frame_post_draw
 var frame: Image=root.get_texture().get_image()
 capture_sizes.append([frame.get_width(),frame.get_height()])
 frame.save_png(out.path_join(label+".png"))
func run() -> void:
 out=OS.get_environment("WALL_OUT");DirAccess.make_dir_recursive_absolute(out)
 var expected: PackedStringArray=OS.get_environment("WALL_EXPECTED_SIZE").split(",")
 if expected.size()==2:
  check("actual framebuffer matches requested mobile size",root.size==Vector2i(int(expected[0]),int(expected[1])))
 state=root.get_node("RunState")
 main=load("res://scenes/main/main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(2.0).timeout
 main._start_new_game()
 await settle()
 main.quick_tutorial.dismiss()
 var world: Node = main.surface_world
 await shot("01-start")
 world.restore_position(world.station_interaction_position("forge"))
 await settle()
 check("forge interaction",world.active_context=="forge")
 await shot("02-forge")
 world.restore_position(world.PLAYER_START)
 for target in [Vector2(410,669),Vector2(620,643),Vector2(740,648),Vector2(812,650)]:
  for tick in 240:
   if world.player.global_position.distance_to(target)<3: break
   world.player.set_external_movement(world.player.global_position.direction_to(target))
   world.player._physics_process(1.0/60)
  world.player.set_external_movement(Vector2.ZERO)
  check("walk to "+str(target),world.player.global_position.distance_to(target)<3)
 world._evaluate_context(world.player.global_position)
 check("quarry interaction",world.active_context=="ore_mountain")
 var seen := {}
 for hit in 500:
  world._update_ore_mountain_visual(float(world.ore_mountain_hp)/360.0,true)
  var asset: String=world.ore_mountain_sprite.texture.resource_path
  if not seen.has(asset):
   seen[asset]=true
   await shot(asset.get_file().get_basename())
  if world.ore_mountain_hp==0: break
  world._mine_ore_mountain_once()
 check("all painted stages",seen.size()==4)
 check("mined to depletion",world.ore_mountain_hp==0)
 print("MOSS_OK" if checks.all(func(c):return c.passed) else "MOSS_FAILED")
 quit(0 if checks.all(func(c):return c.passed) else 1)
