extends Control
## Pastor scene (فال ورق): riffle cascade then 3 cards deal + flip.

signal result_ready(result: Dictionary)

var mode := ""

var cards: Array = []
var views: Array = []
var positions := [Vector2(60, 420), Vector2(285, 420), Vector2(510, 420)]
var card_size := Vector2(150, 220)
var _flips := 0

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    cards = Fortunes.pastor_draw(3)
    var l := UiKit.label("ورق را بنداز و سه ورق بکش ✦", 24, UiKit.GOLD, true)
    l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    l.offset_top = 30
    add_child(l)
    _riffle()

func _riffle() -> void:
    # cascade of 52 mini-cards falling
    for i in range(26):
        var c := ColorRect.new()
        c.color = Color(0.16 + 0.004 * i, 0.13, 0.3, 1.0)
        c.size = Vector2(52, 76)
        c.position = Vector2(320 - 26 + (i % 5) * 11 - 20, -100)
        c.pivot_offset = c.size / 2
        c.rotation = randf_range(-0.4, 0.4)
        add_child(c)
        var tw := create_tween()
        tw.tween_interval(i * 0.035)
        tw.tween_property(c, "position:y", 900 + (i % 7) * 24, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        tw.parallel().tween_property(c, "rotation", randf_range(-0.7, 0.7), 0.5)
        if i == 25:
            tw.tween_callback(_deal)

func _deal() -> void:
    Sfx.play("whoosh")
    Sfx.vibe(25)
    for i in range(3):
        var cv := preload("res://scripts/ui/card_view.gd").new()
        cv.setup({"glyph": cards[i].glyph, "name": cards[i].title, "num": ""}, card_size)
        cv.position = Vector2(285, 700)
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
        "footer": ""
    })
