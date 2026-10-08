extends Control
## Home: fortune grid + daily/weekly bonuses + "today card" banner.

signal open_fortune(fortune_id: String)

const FORTUNES := [
    {"id": "yesno", "name": "نیت بله و خیر", "g": "☯", "desc": "یک کارت، یک جواب روشن"},
    {"id": "tarot3", "name": "تاروت ۳ کارتی", "g": "✦", "desc": "گذشته، حال، آینده"},
    {"id": "tarot6", "name": "تاروت ۶ کارتی", "g": "✵", "desc": "تحلیل کامل نیت"},
    {"id": "coffee", "name": "فال قهوه", "g": "☕", "desc": "نمادهای ته‌فنجان"},
    {"id": "pastor", "name": "فال پاستور (ورق)", "g": "♠", "desc": "سه ورق، سه پیام"},
    {"id": "candle", "name": "فال شمع", "g": "🔥", "desc": "شعله و نیت"},
    {"id": "hafez", "name": "فال حافظ", "g": "❦", "desc": "غزل و تفسیر"},
    {"id": "love", "name": "فال عشق", "g": "♥", "desc": "سازگاری دو نفر"}
]

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 12)
    v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    v.offset_left = 18
    v.offset_right = -18
    v.offset_top = 10
    v.offset_bottom = -10
    add_child(v)

    # ---- today card / daily banner
    var today_free := Save.free_yesno_date != Save.today_key()
    var banner := UiKit.panel(UiKit.PANEL2)
    var bh := HBoxContainer.new()
    bh.add_theme_constant_override("separation", 10)
    banner.add_child(bh)
    var btxt := VBoxContainer.new()
    btxt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btxt.add_theme_constant_override("separation", 4)
    btxt.add_child(UiKit.label("کارت امروز", 22, UiKit.GOLD, true))
    btxt.add_child(UiKit.label("نیتِ بله/خیر امروزِ تو — رایگان" if today_free else "کارتِ امروز را گرفتی؛ فردا دوباره بیا ✦", 17, UiKit.DIM, false, true))
    bh.add_child(btxt)
    var take := UiKit.button("بگیر" if today_free else "گرفتم", 18, UiKit.GOLD if today_free else UiKit.PANEL2)
    take.pressed.connect(func():
        Sfx.play("click")
        if Save.free_yesno_date != Save.today_key():
            open_fortune.emit("__free_yesno__")
        else:
            open_fortune.emit("yesno"))
    bh.add_child(take)
    v.add_child(banner)

    # ---- daily + weekly chips row
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    v.add_child(row)
    var daily_ready := Save.last_daily != Save.today_key()
    var weekly_ready := Save.last_weekly != Save.week_key()
    row.add_child(_bonus_chip("🎁 سکهٔ روزانه +" + UiKit.fa(Rates.rate("daily_bonus")), daily_ready, _claim_daily))
    row.add_child(_bonus_chip("🏆 هدیهٔ هفته +" + UiKit.fa(Rates.rate("weekly_bonus")), weekly_ready, _claim_weekly))

    # ---- grid
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    v.add_child(grid)
    for f in FORTUNES:
        grid.add_child(_fortune_card(f))

    v.add_child(UiKit.label("فال‌ها فقط برای سرگرمی و الهام‌بخشی‌اند ✦", 14, UiKit.DIM))

func _bonus_chip(text: String, ready: bool, cb: Callable) -> Control:
    var p := UiKit.panel(UiKit.PANEL if ready else Color(0.13, 0.11, 0.22, 0.6))
    p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var b := UiKit.button(text if ready else text.replace("+", ""), 16, UiKit.GOLD if ready else Color("3a3160"), ready)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.pressed.connect(func():
        if not ready:
            return
        Sfx.play("click")
        cb.call()
        _refresh())
    p.add_child(b)
    return p

func _claim_daily() -> void:
    if Save.last_daily == Save.today_key():
        return
    Save.last_daily = Save.today_key()
    Save.add_coins(int(Rates.rate("daily_bonus")))
    Sfx.play("coin")
    Sfx.vibe(20)

func _claim_weekly() -> void:
    if Save.last_weekly == Save.week_key():
        return
    Save.last_weekly = Save.week_key()
    Save.add_coins(int(Rates.rate("weekly_bonus")))
    Save.add_xp(5)
    Sfx.play("chime")
    Sfx.vibe(30)

func _fortune_card(f: Dictionary) -> Control:
    var p := UiKit.panel(UiKit.PANEL)
    p.custom_minimum_size = Vector2(336, 196)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 4)
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    p.add_child(v)
    var g := UiKit.label(f.g, 44, UiKit.PURPLE)
    v.add_child(g)
    v.add_child(UiKit.label(f.name, 21, UiKit.INK, true))
    v.add_child(UiKit.label(f.desc, 15, UiKit.DIM))
    var price := Rates.price(f.id)
    v.add_child(UiKit.label(UiKit.price_tag(price), 17, UiKit.GOLD if price > 0 else UiKit.GOOD, true))
    p.gui_input.connect(func(ev: InputEvent):
        if ev is InputEventScreenTouch and ev.pressed:
            Sfx.play("click")
            Sfx.vibe(15)
            open_fortune.emit(f.id))
    p.mouse_filter = Control.MOUSE_FILTER_STOP
    return p

func _refresh() -> void:
    var m := get_parent().get_parent()
    if m != null and m.has_method("goto_home"):
        m.goto_home()
