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
func walk_to(world: Node, target: Vector2) -> bool:
 for tick in 240:
  if world.player.global_position.distance_to(target)<3: break
  world.player.set_external_movement(world.player.global_position.direction_to(target))
  world.player._physics_process(1.0/60)
 world.player.set_external_movement(Vector2.ZERO)
 return world.player.global_position.distance_to(target)<3

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
 world.restore_position(world.station_interaction_position("sell"))
 check("sell interaction", world.active_context=="sell")
 await shot("02-sell")
 world.restore_position(world.station_interaction_position("forge"))
 await settle()
 check("forge interaction",world.active_context=="forge")
 await shot("03-forge")
 world.restore_position(world.PLAYER_START)
 for target in [Vector2(410,669),Vector2(620,643),Vector2(740,648),Vector2(812,650)]:
  check("walk to "+str(target), walk_to(world,target))
 world._evaluate_context(world.player.global_position)
 check("quarry interaction",world.active_context=="ore_mountain")
 world.restore_position(Vector2(520,650))
 check("walk across the bottom of the road beside camp",walk_to(world,Vector2(535,691)))
 check("walk across the upper edge of the road beside camp",walk_to(world,Vector2(544,617)))
 world.restore_position(Vector2(252,662))
 check("enter the visible camp lane from the road",walk_to(world,Vector2(250,557)))
 check("walk through the camp lane between both stations",walk_to(world,Vector2(250,468)))
 check("sell stall base is solid",world._surface_collides(Vector2(112,505)))
 check("forge base is solid",world._surface_collides(Vector2(332,501)))
 world.restore_position(Vector2(550,660))
 check("cliff below the road blocks movement",world._surface_collides(Vector2(550,713)))
 check("forest behind the road blocks movement",world._surface_collides(Vector2(550,596)))
 world.restore_position(Vector2(805,652))
 check("copper base is solid while the mountain is intact",world._surface_collides(Vector2(805,610)))
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
 check("old mine pocket cannot extend into empty space",world._surface_collides(Vector2(1020,789)))
 world.restore_position(Vector2(647,648))
 check("turn directly off the main road onto the ramp",walk_to(world,Vector2(727,687)))
 await shot("04-fork")
 world.restore_position(world.MOSS_MINE_BRANCH_JUNCTION)
 for target in world.MOSS_MINE_BRANCH_ROUTE.slice(1):
  check("walk the mine branch to "+str(target), walk_to(world,target))
 world._evaluate_context(world.player.global_position)
 check("Mossvein mine entrance interaction",world.active_context=="enter:mossMine")
 await shot("05-mine-entrance")
 check("walk along the visible mine landing",walk_to(world,Vector2(1025,902)))
 check("holding down cannot cross the mine landing cliff",not walk_to(world,Vector2(1025,946)) and world.player.global_position.y<933.0)
 check("mine door surroundings remain solid",world._surface_collides(Vector2(930,857)))
 world.return_from_mine("mossMine")
 check("mine exit lands on the ramp",world.player.global_position.distance_to(world.MOSS_MINE_RETURN_POSITION)<1.0)
 check("old saves outside the cliff return to walkable ground",not world._surface_collides(world._nearest_safe_restore_position(Vector2(1015,780))))
 world.restore_position(world.MOSS_GATE_ANCHOR + Vector2(-110,20))
 check("Mossvein side of the portal",world.player.global_position.x<world.MOSS_GATE_ANCHOR.x)
 check("approach the closed gate until the visible field",walk_to(world,Vector2(1080,658)))
 check("locked portal blocks passage",not walk_to(world,Vector2(1120,658)) and world.player.global_position.x<world.MOSS_GATE_ANCHOR.x)
 await shot("06-portal-closed")
 state.unlock_world("moonglass")
 var transition: Node = world.portal_transitions["moonglass"]
 for frame in 150:
  if transition.is_passage_open(): break
  await process_frame
 check("the opening animation releases the passage",transition.is_passage_open())
 for target in world.gate_approach_route("moonglass").slice(1):
  check("cross through the arch to "+str(target),walk_to(world,target))
 await settle()
 await shot("07-portal-crossed")
 print("MOSS_OK" if checks.all(func(c):return c.passed) else "MOSS_FAILED")
 quit(0 if checks.all(func(c):return c.passed) else 1)
