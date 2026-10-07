extends Control
## Candle scene: light the candle, flame flickers + wax drips, interpretation.

signal result_ready(result: Dictionary)

var mode := ""

var interp: Dictionary = {}
var lit := false
var t := 0.0
var flame_h := 0.0
var match_pos := Vector2(80, 900)
var _result_shown := false

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var l := UiKit.label("شمعِ نیت را روشن کن ✦", 24, UiKit.GOLD, true)
    l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    l.offset_top = 30
    add_child(l)

    var hint := UiKit.label("روی کبریت لمس کن", 18, UiKit.DIM)
    hint.name = "Hint"
    hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    hint.offset_top = -260
    hint.offset_bottom = -225
    hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
    add_child(hint)

    var match_btn := UiKit.button("کبریت ✦", 26, Color("5a3a2c"))
    match_btn.name = "Match"
    match_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    match_btn.offset_top = -140
    match_btn.offset_bottom = -70
    match_btn.offset_left = -90
    match_btn.offset_right = 90
    match_btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
    add_child(match_btn)
    match_btn.pressed.connect(_light)

func _light() -> void:
    if lit:
        return
    lit = true
    Sfx.play("flame")
    Sfx.vibe(30)
    var hint := get_node_or_null("Hint")
    if hint:
        hint.queue_free()
    var match_btn := get_node_or_null("Match")
    if match_btn:
        match_btn.queue_free()
    interp = Fortunes.candle_draw()
    var tw := create_tween()
    tw.tween_property(self, "flame_h", 1.0, 1.4).set_trans(Tween.TRANS_SINE)
    tw.tween_interval(1.6)
    tw.tween_callback(_show_result)

func _process(delta: float) -> void:
    t += delta
    queue_redraw()

func _show_result() -> void:
    if _result_shown:
        return
    _result_shown = true
    var kind: String = "شعلهٔ روشن" 
    var items := [{"head": "✦ " + str(interp.t), "sub": "زبانِ شعله", "body": str(interp.m)}]
    var polarity := "میانه"
    if interp in Fortunes.candle.good:
        polarity = "خوش‌یُمن"
    elif interp in Fortunes.candle.bad:
        polarity = "نیاز به احتیاط"
    result_ready.emit({
        "title": "فال شمع — " + polarity,
        "items": items,
        "summary": str(interp.t),
        "footer": "شمع باد را می‌شناسد؛ نیتِ آرام، شعلهٔ پایدارتر."
    })

func _draw() -> void:
    var base := Vector2(360, 980)
    # glow
    if lit:
        var glow_r := 120 + 26 * sin(t * 5.1) + 90 * flame_h
        draw_circle(base + Vector2(0, -170), glow_r, Color(1.0, 0.75, 0.35, 0.05 + 0.04 * flame_h))
        draw_circle(base + Vector2(0, -170), glow_r * 0.55, Color(1.0, 0.8, 0.4, 0.06))
    # candle body
    var w := 90.0
    var h := 190.0
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.93, 0.88, 0.78)
    sb.set_corner_radius_all(10)
    draw_style_box(sb, Rect2(base - Vector2(w / 2, h), Vector2(w, h)))
    # melted top
    draw_circle(base - Vector2(0, h - 4), w / 2 - 6, Color(0.97, 0.94, 0.87))
    # holder
    draw_rect(Rect2(base + Vector2(-w / 2 - 22, -18), Vector2(w + 44, 22)), Color("3a3160"))
    draw_rect(Rect2(base + Vector2(-w / 2 - 40, 2), Vector2(w + 80, 12)), Color("2a2450"))
    # wick
    var tip := base + Vector2(0, -h - 8)
    draw_line(base - Vector2(0, h), tip, Color(0.2, 0.15, 0.1), 3.0)
    # flame
    if lit and flame_h > 0.02:
        var fh := 66.0 * flame_h * (1.0 + 0.10 * sin(t * 7.3) + 0.05 * sin(t * 13.7))
        var fw := 20.0 + 3.0 * sin(t * 5.9)
        var lean := 4.0 * sin(t * 3.7)
        var outer := PackedVector2Array([
            tip + Vector2(-fw, 6), tip + Vector2(-fw * 0.8, -fh * 0.45),
            tip + Vector2(lean, -fh), tip + Vector2(fw * 0.8, -fh * 0.45), tip + Vector2(fw, 6)
        ])
        draw_colored_polygon(outer, Color(1.0, 0.62, 0.18, 0.85))
        var inner := PackedVector2Array([
            tip + Vector2(-fw * 0.45, 5), tip + Vector2(lean * 0.7, -fh * 0.62), tip + Vector2(fw * 0.45, 5)
        ])
        draw_colored_polygon(inner, Color(1.0, 0.93, 0.65, 0.95))
        draw_circle(tip + Vector2(lean, -fh * 0.30), 4, Color(1, 1, 1, 0.9))
    # unlit match hint arrow
    if not lit:
        draw_string(UiKit.font(), Vector2(280, 1130), "نیتت را بگو و کبریت را بزن", HORIZONTAL_ALIGNMENT_CENTER, 160, 0, Color(0, 0, 0, 0))
