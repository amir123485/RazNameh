extends Control
## Hafez scene: book opens, sparkle, beyt types out then tafsir fades.

signal result_ready(result: Dictionary)

var mode := ""

var poem: Dictionary = {}
var shown := 0.0
var phase := 0   # 0 closed, 1 opening, 2 typing, 3 done
var sparkles: Array = []

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    poem = Fortunes.hafez_draw()
    var l := UiKit.label("کتابِ حافظ را باز می‌کنیم…", 24, UiKit.GOLD, true)
    l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    l.offset_top = 30
    add_child(l)
    phase = 1
    Sfx.play("page")
    var tw := create_tween()
    tw.tween_interval(0.8)
    tw.tween_callback(func(): phase = 2)
    for i in range(18):
        sparkles.append({"p": Vector2(randf_range(80, 640), randf_range(220, 900)), "ph": randf() * TAU, "s": randf_range(1.5, 3.5)})
    set_process(true)

func _process(delta: float) -> void:
    if phase == 2:
        shown += delta * 14.0
        if shown >= poem.b.length():
            shown = poem.b.length()
            phase = 3
            Sfx.play("chime")
    queue_redraw()

func _draw() -> void:
    # book
    var c := Vector2(360, 560)
    var pw := 240.0
    var ph := 320.0
    var open := clampf((0.0 if phase < 1 else (1.0 if phase >= 2 else 0.5)), 0.0, 1.0)
    # pages
    var left := Rect2(c - Vector2(pw, ph / 2), Vector2(pw, ph))
    var right := Rect2(c, Vector2(pw, ph))
    var paper := Color(0.93, 0.89, 0.80)
    var edge := Color("6b5aa5")
    _page(left, paper, edge)
    _page(right, paper, edge)
    # spine
    draw_line(c + Vector2(0, -ph / 2), c + Vector2(0, ph / 2), edge, 3.0)
    # text on right page
    var text_col := Color("3a2c1a")
    if phase >= 2:
        var f := UiKit.font(true)
        var s: String = str(poem.b)
        var part := s.substr(0, mini(int(shown), s.length()))
        draw_multiline_string(f, c + Vector2(-pw + 18, -ph / 2 + 46), part,
            HORIZONTAL_ALIGNMENT_RIGHT, pw - 30, 22, 8, text_col)
        draw_string(UiKit.font(), c + Vector2(-pw + 18, ph / 2 - 20), "— حافظ",
            HORIZONTAL_ALIGNMENT_LEFT, 120, 16, Color("8a6b3a"))
    for sp in sparkles:
        var a := 0.35 + 0.45 * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 320.0 + sp.ph))
        draw_circle(sp.p, sp.s, Color(0.9, 0.82, 0.55, a))

func _page(r: Rect2, paper: Color, edge: Color) -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color = paper
    sb.border_width_left = 2
    sb.border_width_right = 2
    sb.border_width_top = 2
    sb.border_width_bottom = 2
    sb.border_color = edge
    sb.set_corner_radius_all(8)
    draw_style_box(sb, r)

func _input(event: InputEvent) -> void:
    if phase == 3 and event is InputEventScreenTouch and event.pressed:
        var done_btn := get_node_or_null("DoneBtn")
        if done_btn == null:
            var b := UiKit.button("دیدن تفسیر ✦", 22)
            b.name = "DoneBtn"
            b.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
            b.offset_top = -120
            b.offset_bottom = -60
            b.offset_left = -110
            b.offset_right = 110
            b.grow_horizontal = Control.GROW_DIRECTION_BOTH
            add_child(b)
            b.pressed.connect(func(): Sfx.play("click"); _emit())

func _emit() -> void:
    result_ready.emit({
        "title": "فال حافظ",
        "items": [
            {"head": "❦ بیتِ فال", "sub": "غزلِ حافظ", "body": str(poem.b)},
            {"head": "تعبیر و تفسیر", "sub": "", "body": str(poem.t)}
        ],
        "summary": str(poem.b),
        "footer": "حافظ، آینهٔ دل است؛ تفسیر را با حالِ خودت بخوان."
    })
