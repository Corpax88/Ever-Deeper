extends SceneTree
var main: Node
var state: Node
var out: String
var checks: Array=[]
func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
 checks.append({"name":label,"passed":ok})
 FileAccess.open(out.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.all(func(c):return c.passed)},"\t"))
 if not ok: print("CHECK_FAILED ",label)
func settle() -> void: await create_timer(0.4).timeout
func shot(label: String) -> void:
 if main.phase == "mine": main.mine_world.queue_redraw()
 if main.phase == "depth": main.depth_world.queue_redraw()
 await settle();await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(label+".png"))
func run() -> void:
 out=OS.get_environment("WALL_OUT");DirAccess.make_dir_recursive_absolute(out)
 state=root.get_node("RunState")
 main=load("res://scenes/main/main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(2.0).timeout;main._start_new_game();await settle()
 main.quick_tutorial.open(true);await shot("01-surface-quest")
 var hud: Node=main.premium_hud
 var panel: Control=hud.progression_goal_panel
 check("quest has no background",panel.get_theme_stylebox("panel") is StyleBoxEmpty)
 check("quest passes input",not panel.snapshot().input_blocking)
 check("skip clears quest",not main.quick_tutorial._skip.get_global_rect().intersects(panel.get_global_rect()))
 main.quick_tutorial.dismiss();state.pickaxe_level=4
 main.achievement_toast.clear()
 main._dev_jump_mine("mossMine",1);await settle()
 var w: Node=main.mine_world
 var cell: Vector2i=Vector2i(-1,-1)
 for c in w.blocks:
  if w._is_barrier_role(String(w.blocks[c].get("role",""))): cell=c;break
 check("authored D1 barrier found",cell.x>=0)
 var block: Dictionary=w.blocks[cell]
 var gate: String=String(block.role)
 var anchor: Vector2=w._cell_center(cell)
 w.restore_position(anchor+Vector2(0,100));w.player.set_facing(Vector2.UP)
 main.set_process(false);w.set_process(false);w.current_target=cell;w._request_redraw()
 check("wall begins at zero of ten",w._target_label(block)=="WALL · 0 / 10 HITS")
 await shot("02-wall-zero")
 for i in range(1,10):
  w._strike_barrier_group(cell,w.blocks[cell],i==2)
  check("D1 actual hit "+str(i),w._target_label(w.blocks[cell])=="WALL · %d / 10 HITS" % i)
  if i in [1,9]: await shot("03-wall-"+str(i))
 w._strike_barrier_group(cell,w.blocks[cell]);await shot("04-wall-open")
 check("tenth D1 hit opens wall",state.barrier_hits("mossMine:d1:"+gate)==10 and not w.blocks.has(cell))
 check("local D1 completion",w.get_node("PassageFeedback").text=="PASSAGE OPEN · 10 / 10")
 w.set_process(true);main.set_process(true)
 main._dev_jump_mine("mossMine",2);await settle();w=main.depth_world
 var idx: int=-1
 for i in w.rocks.size():
  if bool(w.rocks[i].drill_gated) and not bool(w.rocks[i].broken): idx=i;break
 check("authored D2 barrier found",idx>=0)
 var rock: Dictionary=w.rocks[idx]
 w._clear_circle(Vector2(rock.position),500.0)
 for cavern in w.caverns:
  if not cavern.discovered and not cavern.boundary.is_empty(): w._discover_cavern_from_cell(int(cavern.boundary[0]))
 w.player.camera.position_smoothing_enabled=false
 w.restore_position(Vector2(rock.position)+Vector2(0,100));w.player.set_facing(Vector2.UP)
 main.set_process(false);w.set_process(false);w.current_target_kind="rock";w.current_target_rock=idx;w._request_redraw()
 check("D2 gate is actually exposed",w._rock_is_exposed(idx))
 check("D2 player reached gate",w.player.global_position.distance_to(Vector2(rock.position))<300)
 check("D2 wall begins at zero",w._rock_target_label(rock)=="WALL · 0 / 10 HITS")
 await shot("05-depth-wall-zero")
 for i in range(1,10):
  w._strike_drill_gate(idx,i==2)
  check("D2 actual hit "+str(i),w._rock_target_label(w.rocks[idx])=="WALL · %d / 10 HITS" % i)
  if i==9: await shot("06-depth-wall-nine")
 w._strike_drill_gate(idx);await shot("07-depth-open")
 check("D2 tenth hit opens",bool(w.rocks[idx].broken))
 w.set_process(true);main.set_process(true)
 main._dev_jump_surface();await settle()
 main.set_process(false)
 for goal in [{"hud_title":"Next: Forge a stronger pickaxe","hud_action":"Collect copper and return to camp","requirements":[{"id":"a","name":"Copper","owned":4,"required":10},{"id":"b","name":"Gold","owned":2,"required":10}]},{"hud_title":"Next: Keep digging","hud_action":"Find the next passage","requirements":[]}]:
  hud.set_progression_goal(goal);await process_frame;hud.apply_iphone_layout_for_test(hud.get_viewport_rect().size);await process_frame
  check("quest clears Mine",not panel.get_global_rect().intersects(main.mine_button.get_global_rect()))
  check("quest clears Bag",not panel.get_global_rect().intersects(hud.bag_button.get_global_rect()))
  check("quest clears minimap",not panel.get_global_rect().intersects(hud.minimap_layout_rect()))
  await shot("08-layout-"+str(goal.requirements.size()))
 print("WALL_FOCUS_OK" if checks.all(func(c):return c.passed) else "WALL_FOCUS_FAILED")
 quit(0 if checks.all(func(c):return c.passed) else 1)
