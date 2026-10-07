extends Control
## Tarot scene: modes "yesno" (1 card), "tarot3" (past/present/future), "tarot6" (hexagram).

signal result_ready(result: Dictionary)

var mode := "yesno"
var cards: Array = []
var card_views: Array = []
var positions: Array = []
var labels: Array = []
var _done_count := 0

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var count := 1
    if mode == "tarot3":
        count = 3
    elif mode == "tarot6":
        count = 6
    cards = Fortunes.tarot_draw(count)
    _layout(count)
    _intro(count)

func _layout(count: int) -> void:
    var cs := Vector2(150, 232)
    if count == 6:
        cs = Vector2(128, 198)
    positions.clear()
    var cx := 360.0
    var cy := 380.0
    if count == 1:
        positions.append(Vector2(cx - cs.x / 2, cy - cs.y / 2))
    elif count == 3:
        var gap := 18
        var total := cs.x * 3 + gap * 2
        var x0 := 360 - total / 2
        for i in range(3):
            positions.append(Vector2(x0 + i * (cs.x + gap), cy - cs.y / 2))
    else:
        var rx := 230
        var ry := 240
        for i in range(6):
            var ang := -PI / 2 + TAU * i / 6.0
            positions.append(Vector2(cx + cos(ang) * rx - cs.x / 2, cy + 30 + sin(ang) * ry - cs.y / 2))
    for i in range(count):
        var cv := preload("res://scripts/ui/card_view.gd").new()
        cv.setup(cards[i], cs)
        cv.position = positions[i]
        cv.flipped.connect(_on_card_flipped)
        add_child(cv)
        card_views.append(cv)

func _intro(count: int) -> void:
    var head := "نیتِ تو شنیده شد ✦ یک کارت بکش" if count == 1 else "کارت‌ها را بکش تا وا شود"
    var l := UiKit.label(head, 24, UiKit.GOLD, true)
    l.name = "Head"
    l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    l.offset_top = 30
    add_child(l)
    # deck at bottom
    var deck := UiKit.panel(UiKit.PANEL2)
    deck.custom_minimum_size = Vector2(190, 120)
    deck.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    deck.offset_top = -190
    deck.offset_bottom = -70
    deck.offset_left = -95
    deck.offset_right = 95
    deck.grow_horizontal = Control.GROW_DIRECTION_BOTH
    var dv := VBoxContainer.new()
    dv.alignment = BoxContainer.ALIGNMENT_CENTER
    deck.add_child(dv)
    dv.add_child(UiKit.label("✶", 30, UiKit.GOLD))
    dv.add_child(UiKit.label("برای کشیدن، لمس کن", 17, UiKit.DIM))
    add_child(deck)
    deck.name = "Deck"
    deck.gui_input.connect(func(ev: InputEvent):
        if ev is InputEventScreenTouch and ev.pressed:
            _deal(deck))
    deck.mouse_filter = Control.MOUSE_FILTER_STOP

func _deal(deck: Control) -> void:
    deck.queue_free()
    Sfx.play("whoosh")
    Sfx.vibe(25)
    var card_size: Vector2 = card_views[0].size
    for i in range(card_views.size()):
        var cv = card_views[i]
        cv.position = Vector2(360 - card_size.x / 2, 1050 - card_size.y / 2)
        cv.modulate.a = 0.0
        var tw := create_tween()
        tw.tween_interval(0.15 * i)
        tw.tween_property(cv, "modulate:a", 1.0, 0.2)
        tw.parallel().tween_property(cv, "position", positions[i], 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        tw.tween_interval(0.1)
        tw.tween_callback(cv.flip)
    if mode == "tarot6":
        _draw_links()

func _draw_links() -> void:
    await get_tree().create_timer(0.3).timeout
    var links := LineDrawer.new()
    links.card_views = card_views
    add_child(links)

func _on_card_flipped() -> void:
    _done_count += 1
    if _done_count == card_views.size():
        await get_tree().create_timer(0.7).timeout
        _emit_result()

func _position_label(i: int, text: String) -> void:
    var l := UiKit.label(text, 17, UiKit.GOLD, true)
    var cv = card_views[i]
    l.position = cv.position + Vector2(0, cv.size.y + 6)
    l.custom_minimum_size.x = cv.size.x
    add_child(l)
    labels.append(l)

func _emit_result() -> void:
    var yn := ""
    if mode == "yesno":
        yn = Fortunes.yesno_from_cards(cards)
        var big := UiKit.label("جوابِ نیت: " + yn, 40, UiKit.GOOD if yn == "بله" else (UiKit.BAD if yn == "خیر" else UiKit.DIM), true)
        big.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
        big.offset_top = -230
        big.offset_bottom = -160
        add_child(big)
        Sfx.vibe(40)
    if mode == "tarot3":
        _position_label(0, "گذشته")
        _position_label(1, "حال")
        _position_label(2, "آینده")
    if mode == "tarot6":
        var names := ["وضعیت", "مانع", "راهنما", "پنهان", "توصیه", "نتیجه"]
        for i in range(6):
            _position_label(i, names[i])
    await get_tree().create_timer(0.6 if mode == "yesno" else 0.2).timeout

    var items := []
    var title := ""
    var summary := ""
    if mode == "yesno":
        title = "نیت بله و خیر"
        var c: Dictionary = cards[0]
        items.append({"head": yn + " — " + c.name, "sub": c.keywords, "body": c.meaning})
        summary = yn + " (" + c.name + ")"
    else:
        var names: Array = ["گذشته", "حال", "آینده"] if mode == "tarot3" else ["وضعیت", "مانع", "راهنما", "پنهان", "توصیه", "نتیجه"]
        title = "تاروت " + UiKit.fa(cards.size()) + " کارتی"
        for i in range(cards.size()):
            var c: Dictionary = cards[i]
            items.append({"head": names[i] + " — " + c.name, "sub": c.keywords, "body": c.meaning})
        var names_arr := []
        for c2 in cards:
            names_arr.append(str(c2.name))
        summary = ", ".join(names_arr)
    result_ready.emit({"title": title, "items": items, "summary": summary, "footer": ""})

class LineDrawer extends Control:
    var card_views: Array = []
    func _ready() -> void:
        set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        modulate.a = 0.0
        create_tween().tween_property(self, "modulate:a", 1.0, 1.0)
    func _draw() -> void:
        if card_views.size() < 6:
            return
        var pts := []
        for cv in card_views:
            pts.append(cv.position + cv.size / 2.0)
        var order := [0, 2, 4, 1, 3, 5, 0, 3, 5, 2, 1, 4, 0]
        for i in range(order.size() - 1):
            draw_line(pts[order[i]], pts[order[i + 1]], Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.28), 2.0)
