extends Node
## Headless UI flow test: builds every fortune scene + result screen
## (verifies the scroll-friendly fix code path runs clean on all modes).
## Run: godot --headless --path . res://scripts/tests/test_flow.tscn

var done_count := 0
var total := 0

func _ready() -> void:
    print("== UI flow test ==")
    var ids := ["yesno", "tarot3", "tarot6", "coffee", "pastor", "candle", "hafez", "love"]
    total = ids.size()
    for id in ids:
        _run_one(id)
    await get_tree().create_timer(2.0).timeout
    if done_count == total:
        print("ALL FLOWS OK (%d/%d)" % [done_count, total])
        get_tree().quit(0)
    else:
        printerr("FLOW FAILURES: %d/%d built" % [done_count, total])
        get_tree().quit(1)

func _run_one(id: String) -> void:
    var flow: Control = preload("res://scripts/ui/fortune_flow.gd").new()
    flow.setup("__free_" + id + "__")
    flow.finished.connect(func(_a, _b, _c): pass)
    flow.closed.connect(func(): pass)
    add_child(flow)
    flow._launch_scene()
    # let scene _ready run, then force result emission
    await get_tree().process_frame
    await get_tree().process_frame
    var sc: Control = flow.get_child(flow.get_child_count() - 1)
    if sc == flow:
        printerr("no scene child for " + id)
        return
    if sc.has_method("_light"):   # candle: sets interp before result
        sc._light()
    if sc.has_method("_emit_result"):
        sc._emit_result()          # async: emits after a short timer
    elif sc.has_method("_emit"):
        sc._emit()
    elif sc.has_method("_show_result") and id == "candle":
        sc._show_result()
    await get_tree().create_timer(1.4).timeout
    # result screen should now exist: look for a ScrollContainer in flow
    var scroll := _find_scroll(flow)
    if scroll != null:
        var eaters := _stop_eaters(scroll)
        if eaters == 0:
            done_count += 1
            print("  [FLOW OK] " + id + " -> result built, drag-scroll friendly")
        else:
            printerr("  [FLOW FAIL] " + id + " -> " + str(eaters) + " STOP controls eat drags")
    else:
        printerr("  [FLOW FAIL] " + id + " -> no result screen")
    flow.queue_free()

func _find_scroll(node: Node) -> ScrollContainer:
    for c in node.get_children():
        if c is ScrollContainer:
            return c
        var deeper := _find_scroll(c)
        if deeper != null:
            return deeper
    return null

func _stop_eaters(node: Node) -> int:
    var n := 0
    for c in node.get_children():
        if c is PanelContainer and c.mouse_filter == Control.MOUSE_FILTER_STOP:
            n += 1
        n += _stop_eaters(c)
    return n
