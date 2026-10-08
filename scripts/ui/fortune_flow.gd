extends Control
## FortuneFlow: intent sheet -> price gate -> scene -> result panel -> save.

signal closed()
signal finished(fortune_id: String, title: String, summary: String)

var fortune_id := ""
var free_mode := false
var scene_root: Control = null

const META := {
    "yesno": {"name": "نیت بله و خیر", "intent": true, "intent_ph": "نیتت را در دل بگو… (اختیاری)"},
    "tarot3": {"name": "تاروت ۳ کارتی", "intent": true, "intent_ph": "نیت یا پرسشت را در دل بگو…"},
    "tarot6": {"name": "تاروت ۶ کارتی", "intent": true, "intent_ph": "نیت یا پرسشت را در دل بگو…"},
    "coffee": {"name": "فال قهوه", "intent": false, "intent_ph": ""},
    "pastor": {"name": "فال پاستور (ورق)", "intent": false, "intent_ph": ""},
    "candle": {"name": "فال شمع", "intent": false, "intent_ph": ""},
    "hafez": {"name": "فال حافظ", "intent": false, "intent_ph": ""},
    "love": {"name": "فال عشق", "intent": false, "intent_ph": "", "two_names": true}
}

func setup(id: String) -> void:
    free_mode = id.begins_with("__free_")
    if free_mode:
        fortune_id = id.trim_prefix("__free_").trim_suffix("__")
    else:
        fortune_id = id

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build()

func _build() -> void:
    var meta: Dictionary = META.get(fortune_id, {"name": fortune_id, "intent": false, "intent_ph": ""})
    var price := 0 if free_mode else Rates.price(fortune_id)
    var v := VBoxContainer.new()
    v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    v.offset_left = 18
    v.offset_right = -18
    v.offset_top = 10
    v.offset_bottom = -10
    v.add_theme_constant_override("separation", 14)
    add_child(v)

    var head := UiKit.label(meta.name, 30, UiKit.GOLD, true)
    v.add_child(head)

    if price > 0:
        v.add_child(UiKit.label("هزینهٔ این فال: " + UiKit.price_tag(price), 20, UiKit.INK, true))

    var sheet := UiKit.panel(UiKit.PANEL)
    sheet.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var sv := VBoxContainer.new()
    sv.add_theme_constant_override("separation", 12)
    sheet.add_child(sv)
    v.add_child(sheet)

    # two names for love
    if meta.get("two_names", false):
        sv.add_child(UiKit.label("نام تو", 18, UiKit.DIM))
        var e1 := LineEdit.new()
        e1.placeholder_text = "مثلاً آرزو"
        e1.custom_minimum_size.y = 68
        _style_edit(e1)
        sv.add_child(e1)
        sv.add_child(UiKit.label("نام آن شخص", 18, UiKit.DIM))
        var e2 := LineEdit.new()
        e2.placeholder_text = "مثلاً سعید"
        e2.custom_minimum_size.y = 68
        _style_edit(e2)
        sv.add_child(e2)
        sheet.set_meta("e1", e1)
        sheet.set_meta("e2", e2)

    if meta.get("intent", false):
        sv.add_child(UiKit.label("نیت", 18, UiKit.DIM))
        var e := LineEdit.new()
        e.placeholder_text = str(meta.intent_ph)
        e.custom_minimum_size.y = 68
        _style_edit(e)
        sv.add_child(e)
        sheet.set_meta("intent", e)

    sv.add_child(UiKit.label("یک لحظه چشم ببند، سه نفس عمیق بکش و بعد شروع کن ✦", 17, UiKit.DIM, false, true))

    # buttons
    var bh := HBoxContainer.new()
    bh.add_theme_constant_override("separation", 10)
    v.add_child(bh)
    var back := UiKit.ghost_button("بازگشت", 20)
    back.custom_minimum_size.x = 170
    back.pressed.connect(func(): Sfx.play("click"); closed.emit())
    bh.add_child(back)
    bh.add_child(UiKit.hspacer())
    var start := UiKit.button("آغاز فال ✦", 22)
    start.custom_minimum_size.x = 248
    start.pressed.connect(func(): _on_start(price))
    bh.add_child(start)

    if price > 0 and Save.coins < price:
        var warn := UiKit.label("سکه کافی نداری — با تبلیغ یا فروشگاه سکه جمع کن", 17, UiKit.BAD, true, true)
        v.add_child(warn)
        var quick := HBoxContainer.new()
        quick.add_theme_constant_override("separation", 10)
        v.add_child(quick)
        var adq := UiKit.button("🎬 تبلیغ ببین +" + UiKit.fa(Rates.rate("ad_reward")), 18, Color("2c5a4e"))
        adq.pressed.connect(func(): Ads.show_rewarded())
        quick.add_child(adq)
        var shopq := UiKit.button("🛒 فروشگاه", 18, Color("5a4a2c"))
        shopq.pressed.connect(func():
            var m := get_parent().get_parent()
            if m.has_method("open_shop"):
                m.open_shop())
        quick.add_child(shopq)

func _style_edit(e: LineEdit) -> void:
    e.add_theme_font_override("font", UiKit.font())
    e.add_theme_font_size_override("font_size", UiKit.fs(20))
    var sb := UiKit.panel_style(UiKit.PANEL2, 12, UiKit.LINE)
    e.add_theme_stylebox_override("normal", sb)
    e.add_theme_stylebox_override("focus", UiKit.panel_style(UiKit.PANEL2, 12, UiKit.GOLD))
    e.alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _on_start(price: int) -> void:
    if price > 0:
        if Save.coins < price:
            Sfx.play("whoosh")
            return
        Save.add_coins(-price)
        Save.add_xp(maxi(2, price / 5))
    else:
        if fortune_id == "yesno":
            Save.free_yesno_date = Save.today_key()
            Save.save_all()
        Save.add_xp(2)
    Sfx.play("chime")
    Sfx.vibe(20)
    _launch_scene()

func _launch_scene() -> void:
    for c in get_children():
        c.queue_free()
    var scenes := {
        "yesno": "res://scripts/ui/fortune_scenes/tarot_scene.gd",
        "tarot3": "res://scripts/ui/fortune_scenes/tarot_scene.gd",
        "tarot6": "res://scripts/ui/fortune_scenes/tarot_scene.gd",
        "coffee": "res://scripts/ui/fortune_scenes/coffee_scene.gd",
        "pastor": "res://scripts/ui/fortune_scenes/pastor_scene.gd",
        "candle": "res://scripts/ui/fortune_scenes/candle_scene.gd",
        "hafez": "res://scripts/ui/fortune_scenes/hafez_scene.gd",
        "love": "res://scripts/ui/fortune_scenes/love_scene.gd"
    }
    var sc: Control = load(scenes[fortune_id]).new()
    sc.mode = fortune_id
    if free_mode:
        sc.mode = "yesno"
    sc.result_ready.connect(_show_result)
    add_child(sc)

func _show_result(result: Dictionary) -> void:
    Sfx.play("chime")
    for c in get_children():
        c.queue_free()
    var v := VBoxContainer.new()
    v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    v.offset_left = 18
    v.offset_right = -18
    v.offset_top = 14
    v.offset_bottom = -14
    v.add_theme_constant_override("separation", 12)
    add_child(v)

    v.add_child(UiKit.label("✦ " + str(result.title), 30, UiKit.GOLD, true))
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    v.add_child(scroll)
    var inner := VBoxContainer.new()
    inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    inner.add_theme_constant_override("separation", 10)
    scroll.add_child(inner)

    for item in result.items:
        var p := UiKit.panel(UiKit.PANEL)
        var pv := VBoxContainer.new()
        pv.add_theme_constant_override("separation", 6)
        p.add_child(pv)
        pv.add_child(UiKit.label(str(item.head), 21, UiKit.PURPLE, true))
        if str(item.get("sub", "")) != "":
            pv.add_child(UiKit.label(str(item.sub), 16, UiKit.DIM, false, true))
        pv.add_child(UiKit.label(str(item.body), 19, UiKit.INK, false, true))
        inner.add_child(p)

    # overall reading (تفسیر کلی) — highlighted gold-bordered synthesis
    if str(result.get("overall", "")) != "":
        var op := PanelContainer.new()
        var osb := UiKit.panel_style(Color("2b2347"), 18, UiKit.GOLD)
        osb.border_width_left = 2
        osb.border_width_right = 2
        osb.border_width_top = 2
        osb.border_width_bottom = 2
        op.add_theme_stylebox_override("panel", osb)
        var ov := VBoxContainer.new()
        ov.add_theme_constant_override("separation", 6)
        op.add_child(ov)
        ov.add_child(UiKit.label("🧿 تفسیر کلی", 22, UiKit.GOLD, true))
        ov.add_child(UiKit.label(str(result.overall), 19, UiKit.INK, false, true))
        inner.add_child(op)

    if str(result.get("footer", "")) != "":
        inner.add_child(UiKit.label(str(result.footer), 17, UiKit.GOLD))
    inner.add_child(UiKit.label("این فال صرفاً جنبهٔ سرگرمی و الهام‌بخشی دارد و توصیهٔ واقعی نیست.", 13, UiKit.DIM, false, true))

    var done := UiKit.button("پایان و ذخیره ✦", 22)
    done.custom_minimum_size.y = 64
    done.pressed.connect(func():
        Sfx.play("click")
        finished.emit(fortune_id, str(result.title), str(result.summary))
        closed.emit())
    v.add_child(done)
