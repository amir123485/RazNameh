extends Control
## Coffee scene: cup with swirling coffee, steam particles, symbols fade in.

signal result_ready(result: Dictionary)

var mode := ""

var symbols: Array = []
var cup_center := Vector2(360, 560)
var cup_r := 210.0
var swirl := 0.0
var show_progress := 0.0
var done := false

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    symbols = Fortunes.coffee_draw(3)
    var l := UiKit.label("فنجان را برمی‌گردانیم…", 24, UiKit.GOLD, true)
    l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    l.offset_top = 30
    add_child(l)
    _steam()
    var tw2 := create_tween()
    tw2.tween_interval(0.8)
    tw2.tween_property(self, "show_progress", 1.0, 2.6)
    tw2.tween_callback(func(): done = true)
    var go := UiKit.button("دیدن تفسیر ✦", 22)
    go.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    go.offset_top = -120
    go.offset_bottom = -60
    go.offset_left = -110
    go.offset_right = 110
    go.grow_horizontal = Control.GROW_DIRECTION_BOTH
    go.modulate.a = 0.0
    add_child(go)
    var tw := create_tween()
    tw.tween_interval(3.2)
    tw.tween_property(go, "modulate:a", 1.0, 0.5)
    go.pressed.connect(func():
        Sfx.play("click")
        _emit_result())

func _steam() -> void:
    var p := CPUParticles2D.new()
    p.position = cup_center + Vector2(0, -cup_r - 20)
    p.amount = 14
    p.lifetime = 2.6
    p.direction = Vector2.UP
    p.spread = 24
    p.gravity = Vector2(0, -22)
    p.initial_velocity_min = 12
    p.initial_velocity_max = 30
    p.scale_amount_min = 4.0
    p.scale_amount_max = 10.0
    p.color = Color(0.85, 0.82, 0.95, 0.10)
    add_child(p)

func _process(delta: float) -> void:
    swirl += delta * (0.8 if show_progress < 1.0 else 0.25)
    queue_redraw()

func _draw() -> void:
    # saucer + cup
    draw_circle(cup_center, cup_r + 26, Color(0.13, 0.10, 0.24))
    draw_arc(cup_center, cup_r + 26, 0, TAU, 64, UiKit.LINE, 2.0)
    draw_circle(cup_center, cup_r, Color(0.05, 0.035, 0.10))
    draw_arc(cup_center, cup_r, 0, TAU, 64, UiKit.GOLD, 2.5)
    # handle
    draw_arc(cup_center + Vector2(cup_r + 34, 10), 34, -1.2, 1.2, 24, UiKit.GOLD, 3.0)
    # coffee surface swirl
    var center := cup_center
    for i in range(5):
        var rr := cup_r * (0.85 - 0.13 * i)
        var start := swirl * (1.0 + i * 0.35)
        draw_arc(center, rr, start, start + TAU * 0.75, 48, Color(0.29, 0.19, 0.12, 0.5 - i * 0.06), 5.0)
    # symbols appear on the surface
    for i in range(symbols.size()):
        var threshold := 0.25 + 0.25 * i
        if show_progress >= threshold:
            var a := clampf((show_progress - threshold) / 0.2, 0.0, 1.0)
            var pos := cup_center + Vector2(0, -60 + i * 62)
            _draw_symbol(symbols[i], pos, a)

func _draw_symbol(sym: Dictionary, pos: Vector2, a: float) -> void:
    var paths: Array = sym.paths
    var col := Color(0.85, 0.78, 0.62, a)
    for path in paths:
        var pts := PackedVector2Array()
        var arr: Array = path
        for i in range(0, arr.size(), 2):
            pts.append(pos + Vector2(arr[i] * 1.6, arr[i + 1] * 1.6))
        draw_polyline(pts, col, 3.0, true)
    if a > 0.9:
        draw_string(UiKit.font(true), Vector2(pos.x - 80, pos.y + 42), str(sym.name),
            HORIZONTAL_ALIGNMENT_CENTER, 160, 15, Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, a))

func _emit_result() -> void:
    if symbols.is_empty():
        symbols = Fortunes.coffee_draw(3)
    var items := []
    var summary := ""
    for s in symbols:
        items.append({"head": "☕ " + str(s.name), "sub": "نمادِ ته‌فنجان", "body": str(s.meaning)})
        summary += str(s.name) + " "
    result_ready.emit({
        "title": "فال قهوه — " + UiKit.fa(symbols.size()) + " نماد",
        "items": items,
        "summary": summary.strip_edges(),
        "footer": "نمادها، بذرِ فکرند؛ معنایش را قلبِ تو می‌دانست."
    })
