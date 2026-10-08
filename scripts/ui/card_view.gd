extends Control
## CardView: animated tarot-style card. Draws back → flips to face.

signal flipped()

var face_data: Dictionary = {}
var is_face_up := false
var glow := 0.0
var _t := 0.0

func setup(data: Dictionary, card_size: Vector2) -> void:
    face_data = data
    custom_minimum_size = card_size
    size = card_size
    pivot_offset = card_size / 2.0

func _process(delta: float) -> void:
    _t += delta
    glow = maxf(0.0, glow - delta * 0.8)
    queue_redraw()

func flip() -> void:
    if is_face_up:
        return
    Sfx.play("flip")
    Sfx.vibe(15)
    var tw := create_tween()
    tw.tween_property(self, "scale:x", 0.02, 0.22).set_trans(Tween.TRANS_SINE)
    tw.tween_callback(func(): is_face_up = true)
    tw.tween_property(self, "scale:x", 1.0, 0.26).set_trans(Tween.TRANS_BACK)
    tw.tween_callback(func():
        glow = 1.0
        flipped.emit())

func _draw() -> void:
    var r := Rect2(Vector2.ZERO, size)
    var radius := 18
    var col := Color("2a1f4d") if not is_face_up else Color("f3ead2")
    var border := UiKit.GOLD if is_face_up else Color("6b5aa5")
    _round_rect(r, radius, col, border)
    if is_face_up:
        var cx := size.x / 2.0
        var cy := size.y / 2.0
        # glyph
        var f := UiKit.font()
        var gsize := int(size.y * 0.32)
        var gf := ThemeDB.fallback_font
        draw_string(gf, Vector2(0, cy + gsize * 0.35), str(face_data.get("glyph", "✦")),
            HORIZONTAL_ALIGNMENT_CENTER, size.x, gsize, UiKit.PURPLE)
        # name
        draw_string(UiKit.font(true), Vector2(0, size.y - 16), str(face_data.get("name", "")),
            HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color("5a4a2c"))
        # num
        if str(face_data.get("num", "")) != "":
            draw_string(UiKit.font(true), Vector2(0, 38), str(face_data.num),
                HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, UiKit.GOLD)
        # corner stars
        for corner in [Vector2(14, 24), Vector2(size.x - 14, 24)]:
            draw_circle(corner, 3.0, UiKit.GOLD)
    else:
        # ornamental back: starburst
        var c := size / 2.0
        for i in range(12):
            var ang := TAU * i / 12.0 + _t * 0.15
            var a: Vector2 = c + Vector2(cos(ang), sin(ang)) * size.y * 0.30
            var b: Vector2 = c + Vector2(cos(ang + 0.3), sin(ang + 0.3)) * size.y * 0.30
            draw_line(a, b, Color(0.55, 0.47, 0.85, 0.35), 2.0)
        draw_circle(c, size.y * 0.12, Color(0.42, 0.34, 0.72, 0.9))
        var gf := ThemeDB.fallback_font
        draw_string(gf, Vector2(c.x - 40, c.y + 10), "✶", HORIZONTAL_ALIGNMENT_CENTER, 80, 26, UiKit.GOLD)
    if glow > 0.0:
        var sb := StyleBoxFlat.new()
        sb.bg_color = Color(0, 0, 0, 0)
        sb.border_width_left = 3
        sb.border_width_right = 3
        sb.border_width_top = 3
        sb.border_width_bottom = 3
        sb.border_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, glow)
        sb.set_corner_radius_all(radius)
        draw_style_box(sb, r)

func _round_rect(r: Rect2, radius: int, fill: Color, border: Color) -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color = fill
    sb.border_width_left = 2
    sb.border_width_right = 2
    sb.border_width_top = 2
    sb.border_width_bottom = 2
    sb.border_color = border
    sb.set_corner_radius_all(radius)
    draw_style_box(sb, r)
