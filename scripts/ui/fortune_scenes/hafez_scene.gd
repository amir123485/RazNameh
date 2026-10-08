extends Control
## Hafez scene: one big illuminated page opens, the beyt types onto it, then tafsir.

signal result_ready(result: Dictionary)

var mode := ""

var poem: Dictionary = {}
var shown := 0.0
var phase := 0   # 0 closed, 1 opening, 2 typing, 3 done
var page_open := 0.0
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
    var sig := UiKit.label("✦ حافظ", 17, Color("8a6b3a"))
    sig.name = "Sig"
    sig.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    sig.custom_minimum_size.x = 220
    sig.position = Vector2(164, 768)
    sig.visible = false
    add_child(sig)
    var tw := create_tween()
    tw.tween_property(self, "page_open", 1.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tw.tween_callback(func(): phase = 2)
    for i in range(18):
        sparkles.append({"p": Vector2(randf_range(80, 640), randf_range(220, 900)), "ph": randf() * TAU, "s": randf_range(1.5, 3.5)})
    set_process(true)

func _process(delta: float) -> void:
    if phase >= 2:
        var sig := get_node_or_null("Sig")
        if sig != null:
            sig.visible = true
    if phase == 2:
        shown += delta * 14.0
        var s := _poem_text()
        if shown >= s.length():
            shown = s.length()
            phase = 3
            Sfx.play("chime")
    queue_redraw()

func _poem_text() -> String:
    return str(poem.b).replace("|", "\n").strip_edges()

func _draw() -> void:
    # single big page, centered
    var c := Vector2(360, 580)
    var pw := 440.0 * page_open
    var ph := 520.0 * page_open
    if page_open <= 0.01:
        return
    var page := Rect2(c - Vector2(pw / 2, ph / 2), Vector2(pw, ph))
    var paper := Color(0.93, 0.89, 0.80)
    var edge := Color("6b5aa5")
    _page(page, paper, edge)
    # inner ornament frame
    var inset := 14.0
    var inner := Rect2(page.position + Vector2(inset, inset), page.size - Vector2(inset * 2, inset * 2))
    var gold := Color("b08d46")
    _frame(inner, gold)
    # corner stars
    var gf := ThemeDB.fallback_font
    for corner in [inner.position + Vector2(10, 10), Vector2(inner.end.x - 10, inner.position.y + 10),
            Vector2(inner.position.x + 10, inner.end.y - 10), inner.end - Vector2(10, 10)]:
        draw_circle(corner, 3.0, gold)
    # typed beyt on the page (two centered mesras)
    if phase >= 2 and page_open > 0.95:
        var text_col := Color("3a2c1a")
        var f := UiKit.font(true)
        var s: String = _poem_text()
        var part := s.substr(0, mini(int(shown), s.length()))
        var text_area := Rect2(inner.position + Vector2(14, 96), inner.size - Vector2(28, 160))
        draw_multiline_string(f, text_area.position, part,
            HORIZONTAL_ALIGNMENT_CENTER, text_area.size.x, 25, 6, text_col)
    for sp in sparkles:
        var a := 0.35 + 0.45 * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 320.0 + sp.ph))
        draw_circle(sp.p, sp.s, Color(0.9, 0.82, 0.55, a))

func _page(r: Rect2, paper: Color, edge: Color) -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color = paper
    sb.shadow_color = Color(0, 0, 0, 0.45)
    sb.shadow_size = 18
    sb.border_width_left = 2
    sb.border_width_right = 2
    sb.border_width_top = 2
    sb.border_width_bottom = 2
    sb.border_color = edge
    sb.set_corner_radius_all(12)
    draw_style_box(sb, r)

func _frame(r: Rect2, col: Color) -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0, 0, 0, 0)
    sb.border_width_left = 2
    sb.border_width_right = 2
    sb.border_width_top = 2
    sb.border_width_bottom = 2
    sb.border_color = col
    sb.set_corner_radius_all(7)
    draw_style_box(sb, r)

func _input(event: InputEvent) -> void:
    if phase == 3 and event is InputEventScreenTouch and event.pressed:
        var done_btn := get_node_or_null("DoneBtn")
        if done_btn == null:
            var b := UiKit.button("دیدن تفسیر ✦", 22)
            b.name = "DoneBtn"
            b.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
            b.offset_top = -140
            b.offset_bottom = -70
            b.offset_left = -140
            b.offset_right = 140
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
        "overall": Fortunes.overall_hafez(poem),
        "footer": "حافظ، آینهٔ دل است؛ تفسیر را با حالِ خودت بخوان."
    })
