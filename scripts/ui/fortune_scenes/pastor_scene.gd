extends Control
## Pastor scene (فال ورق): cascade of light mini playing cards then 3 cards deal + flip.

signal result_ready(result: Dictionary)

var mode := ""

var cards: Array = []
var views: Array = []
var positions := [Vector2(57, 400), Vector2(267, 400), Vector2(477, 400)]
var card_size := Vector2(186, 272)
var _flips := 0

const SUIT_GLYPHS := ["♠", "♥", "♦", "♣"]
const RED_COL := Color("c0392b")
const BLACK_COL := Color("26222e")

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    cards = Fortunes.pastor_draw(3)
    var l := UiKit.label("ورق را بنداز و سه ورق بکش ✦", 24, UiKit.GOLD, true)
    l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    l.offset_top = 30
    add_child(l)
    _riffle()

func _riffle() -> void:
    # cascade of 26 mini playing cards (light faces + suit glyphs) raining down
    for i in range(26):
        var c := MiniCard.new()
        var suit_i := i % 4
        c.glyph = SUIT_GLYPHS[suit_i]
        c.suit_col = RED_COL if suit_i == 1 or suit_i == 2 else BLACK_COL
        c.size = Vector2(58, 84)
        c.pivot_offset = c.size / 2
        c.position = Vector2(300 + (i % 5) * 24 - 48, -110)
        c.rotation = randf_range(-0.4, 0.4)
        add_child(c)
        var tw := create_tween()
        tw.tween_interval(i * 0.035)
        tw.tween_property(c, "position:y", 880 + (i % 7) * 26, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        tw.parallel().tween_property(c, "rotation", randf_range(-0.7, 0.7), 0.5)
        if i == 25:
            tw.tween_callback(_deal)
        # independent fade-out so the pile dissolves while the deal starts
        var tf := create_tween()
        tf.tween_interval(i * 0.035 + 0.55)
        tf.tween_property(c, "modulate:a", 0.0, 0.7)
        tf.tween_callback(c.queue_free)

func _deal() -> void:
    Sfx.play("whoosh")
    Sfx.vibe(25)
    for i in range(3):
        var cv := preload("res://scripts/ui/card_view.gd").new()
        cv.setup({"glyph": cards[i].glyph, "name": cards[i].title, "num": ""}, card_size)
        cv.position = Vector2(267, 780)
        cv.modulate.a = 0.0
        add_child(cv)
        views.append(cv)
        var tw := create_tween()
        tw.tween_interval(0.18 * i)
        tw.tween_property(cv, "modulate.a", 1.0, 0.15)
        tw.parallel().tween_property(cv, "position", positions[i], 0.4).set_trans(Tween.TRANS_CUBIC)
        tw.tween_callback(cv.flip)
        cv.flipped.connect(func():
            _flips += 1
            if _flips == 3:
                _emit())
    for i in range(3):
        var lab := UiKit.label(["ورقِ اول", "ورقِ دوم", "ورقِ سوم"][i], 17, UiKit.GOLD, true)
        lab.position = positions[i] + Vector2(0, card_size.y + 8)
        lab.custom_minimum_size.x = card_size.x
        add_child(lab)

func _emit() -> void:
    var items := []
    var summary := ""
    for i in range(3):
        var c: Dictionary = cards[i]
        items.append({"head": c.glyph + " " + str(c.title), "sub": str(c.meaning), "body": str(c.tone)})
        summary += str(c.title) + " "
    result_ready.emit({
        "title": "فال پاستور — سه ورقِ تو",
        "items": items,
        "summary": summary.strip_edges(),
        "overall": Fortunes.overall_pastor(cards),
        "footer": ""
    })

## A small light-colored playing card that visibly reads as "ورق" while falling.
class MiniCard extends Control:
    var glyph := "♠"
    var suit_col := Color("26222e")
    func _process(_delta: float) -> void:
        queue_redraw()
    func _draw() -> void:
        var r := Rect2(Vector2.ZERO, size)
        var sb := StyleBoxFlat.new()
        sb.bg_color = Color("f6efdd")
        sb.set_corner_radius_all(7)
        sb.border_width_left = 2
        sb.border_width_right = 2
        sb.border_width_top = 2
        sb.border_width_bottom = 2
        sb.border_color = Color("b8a988")
        draw_style_box(sb, r)
        var gf := ThemeDB.fallback_font
        var gs := int(size.y * 0.42)
        draw_string(gf, Vector2(0, size.y / 2.0 + gs * 0.34), glyph,
            HORIZONTAL_ALIGNMENT_CENTER, size.x, gs, suit_col)
        draw_string(gf, Vector2(5, gs * 0.95), glyph, HORIZONTAL_ALIGNMENT_LEFT, 30, int(gs * 0.45), suit_col)
        draw_string(gf, Vector2(size.x - 35, size.y - 6), glyph, HORIZONTAL_ALIGNMENT_LEFT, 30, int(gs * 0.45), suit_col)
