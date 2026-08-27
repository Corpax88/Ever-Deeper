extends SceneTree

var failed := false

func _initialize() -> void:
    call_deferred("_run")

func check(condition: bool, message: String) -> void:
    if condition:
        print("PASS: ", message)
    else:
        failed = true
        push_error("FAIL: " + message)

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
    check(scene.successes >= 0, "progress state initialized")

    scene.current_mode = 0
    scene.mode_rounds_left = 2
    var before: int = scene.successes
    scene._on_button_pressed()
    await process_frame
    check(scene.successes == before + 1, "normal press counts as success")

    scene.attempts = 10
    scene.misses = 0
    scene.intervals = [0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10]
    scene._update_profile()
    check(scene.current_profile == "AUTOCLICKER", "autoclicker pattern is detected")

    scene.attempts = 10
    scene.misses = 0
    scene.intervals = [2.0, 2.1, 2.0, 2.2, 2.0, 2.1]
    scene._update_profile()
    check(scene.current_profile == "HESITATOR", "hesitation pattern is detected")

    scene.attempts = 10
    scene.misses = 4
    scene.intervals = [0.8, 0.9, 0.8, 0.9, 0.8, 0.9]
    scene._update_profile()
    check(scene.current_profile == "MISCLICKER", "misclick pattern is detected")

    scene.current_mode = 3
    scene.mode_rounds_left = 2
    before = scene.successes
    scene.double_first_ms = 0
    scene._on_button_pressed()
    scene._on_button_pressed()
    await process_frame
    check(scene.successes == before + 1, "double-tap challenge succeeds")

    print("SELFTEST_RESULT=", "FAIL" if failed else "PASS")
    quit(1 if failed else 0)
