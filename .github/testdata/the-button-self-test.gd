extends SceneTree

var failed := false

func _init() -> void:
    call_deferred("_run")

func check(condition: bool, message: String) -> void:
    if condition:
        print("PASS: ", message)
    else:
        failed = true
        push_error("FAIL: " + message)

func set_intervals(scene, values: Array) -> void:
    scene.intervals.clear()
    for value in values:
        scene.intervals.append(float(value))

func _run() -> void:
    var packed := load("res://main.tscn")
    check(packed != null, "main scene loads")
    if packed == null:
        quit(1)
        return

    var scene = packed.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame

    check(scene.main_button != null, "main button exists")
    check(scene.behaviors.size() >= 20, "adaptive behavior pool loaded")
    check(scene.modifiers.size() >= 10, "modifier pool loaded")

    scene.current_behavior = "plain"
    var before: int = scene.successes
    scene._on_button_pressed()
    await process_frame
    check(scene.successes == before + 1, "plain press counts as success")

    scene.attempts = 10
    scene.misses = 0
    set_intervals(scene, [0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10])
    scene._update_profile()
    check(scene.current_profile == "AUTOCLICKER", "autoclicker pattern is detected")

    scene.attempts = 10
    scene.misses = 0
    set_intervals(scene, [2.0, 2.1, 2.0, 2.2, 2.0, 2.1])
    scene._update_profile()
    check(scene.current_profile == "HESITATOR", "hesitation pattern is detected")

    scene.attempts = 10
    scene.misses = 4
    set_intervals(scene, [0.8, 0.9, 0.8, 0.9, 0.8, 0.9])
    scene._update_profile()
    check(scene.current_profile == "MISCLICKER", "misclick pattern is detected")

    var combos := {}
    scene.attempts = 30
    scene.misses = 2
    set_intervals(scene, [0.7,0.8,0.9,0.7,0.8,0.9])
    scene._update_profile()
    for i in range(800):
        var behavior: String = scene._choose_behavior()
        var mods: Array[String] = scene._choose_modifiers(behavior)
        combos[behavior + ":" + ",".join(mods)] = true
    check(combos.size() >= 30, "composer generates varied combinations")

    print("SELFTEST_RESULT=", "FAIL" if failed else "PASS")
    quit(1 if failed else 0)
