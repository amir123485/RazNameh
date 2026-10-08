extends Control
## Love scene: two hearts orbit, merge, compatibility counts up.

signal result_ready(result: Dictionary)

var mode := ""

var data: Dictionary = {}
var t := 0.0
var merge := 0.0
var shown_pct := 0
var _emitted := false

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    data = Fortunes.love_msg()
    var l := UiKit.label("دو دل را به هم می‌رسانیم…", 24, UiKit.GOLD, true)
    l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    l.offset_top = 30
    add_child(l)
    Sfx.play("heart")
    var tw := create_tween()
    tw.tween_property(self, "merge", 1.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tw.tween_callback(func():
        var go := UiKit.button("دیدن پیام ✦", 22)
        go.name = "Go"
        go.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
        go.offset_top = -120
        go.offset_bottom = -60
        go.offset_left = -110
        go.offset_right = 110
        go.grow_horizontal = Control.GROW_DIRECTION_BOTH
        add_child(go)
        go.pressed.connect(func(): Sfx.play("click"); _emit()))

func _process(delta: float) -> void:
    t += delta
    if merge >= 1.0 and shown_pct < int(data.compat):
        shown_pct = mini(int(data.compat), shown_pct + 2)
    queue_redraw()

func _draw() -> void:
    var c := Vector2(360, 480)
    var sep := (1.0 - merge)
    var off := 120 + 190 * sep
    var pulse := 1.0 + 0.06 * sin(t * 4.0)
    var beat := 1.0 + 0.12 * maxf(0.0, sin(t * 9.0)) * merge
    # orbiting hearts
    var a := t * (1.6 - merge)
    var p1 := c + Vector2(cos(a), sin(a) * 0.45) * off
    var p2 := c - Vector2(cos(a), sin(a) * 0.45) * off
    _heart(p1, 34 * pulse, Color(0.85, 0.35, 0.5, 0.95))
    _heart(p2, 34 * pulse, Color(0.55, 0.35, 0.85, 0.95))
    if merge > 0.35:
        var ma := clampf((merge - 0.35) / 0.65, 0, 1)
        _heart(c, 60 * beat * ma, Color(0.9, 0.3, 0.45, ma))
    if merge >= 1.0:
        var f := UiKit.font(true)
        draw_string(f, Vector2(0, c.y + 140), "سازگاری: " + UiKit.fa(shown_pct) + "٪",
            HORIZONTAL_ALIGNMENT_CENTER, 720, 42, UiKit.GOLD)

func _heart(pos: Vector2, r: float, col: Color) -> void:
    var pts := PackedVector2Array()
    for i in range(40):
        var ang := TAU * i / 40.0
        var x := 16.0 * pow(sin(ang), 3)
        var y := -(13.0 * cos(ang) - 5.0 * cos(2 * ang) - 2.0 * cos(3 * ang) - cos(4 * ang))
        pts.append(pos + Vector2(x, y) * r / 16.0)
    draw_colored_polygon(pts, col)
    draw_polyline(pts + PackedVector2Array([pts[0]]), col.lightened(0.25), 2.0, true)

func _emit() -> void:
    if _emitted:
        return
    _emitted = true
    var pct: int = int(data.compat)
    var key := "msg_high" if pct >= 85 else ("msg_mid" if pct >= 72 else "msg_low")
    result_ready.emit({
        "title": "فال عشق — سازگاری " + UiKit.fa(pct) + " درصد",
        "items": [
            {"head": "♥ پیامِ احساسی", "sub": "بر اساس همین امروز", "body": str(data.msg)},
            {"head": "سطرِ حافظ", "sub": "", "body": str(data.poem)}
        ],
        "summary": "سازگاری " + UiKit.fa(pct) + "٪",
        "overall": Fortunes.overall_love(data),
        "footer": "عشق را عدد نسنجد؛ عدد فقط بادی است که پرچم را نشان می‌دهد."
    })
