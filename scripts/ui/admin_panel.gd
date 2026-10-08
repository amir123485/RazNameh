extends Control
## Admin panel: edit every rate live (persists to user config).
## Reachable only via settings → tap version 5× → PIN.

signal closed()

var _fields: Array = []

const FIELD_DEFS := [
    ["ad_reward", "سکهٔ هر تبلیغ"],
    ["daily_bonus", "سکهٔ ورود روزانه"],
    ["weekly_bonus", "هدیهٔ هفتگی"],
    ["ad_cooldown_sec", "فاصلهٔ تبلیغ‌ها (ثانیه)"],
    ["price_yesno", "قیمت: نیت بله/خیر"],
    ["price_hafez", "قیمت: فال حافظ"],
    ["price_love", "قیمت: فال عشق"],
    ["price_candle", "قیمت: فال شمع"],
    ["price_pastor", "قیمت: فال ورق"],
    ["price_coffee", "قیمت: فال قهوه"],
    ["price_tarot3", "قیمت: تاروت ۳"],
    ["price_tarot6", "قیمت: تاروت ۶"],
    ["pack_1_coins", "بستهٔ ۱: تعداد سکه"],
    ["pack_1_price", "بستهٔ ۱: تومان"],
    ["pack_2_coins", "بستهٔ ۲: تعداد سکه"],
    ["pack_2_price", "بستهٔ ۲: تومان"],
    ["pack_3_coins", "بستهٔ ۳: تعداد سکه"],
    ["pack_3_price", "بستهٔ ۳: تومان"],
    ["tapsell_app_key", "کلید تپسل (appKey)"],
    ["tapsell_ad_unit", "شناسهٔ واحد تبلیغ"],
]

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var v := VBoxContainer.new()
    v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    v.offset_left = 18
    v.offset_right = -18
    v.offset_top = 10
    v.offset_bottom = -10
    v.add_theme_constant_override("separation", 10)
    add_child(v)

    v.add_child(UiKit.label("⚙ پنل مدیریت", 28, UiKit.GOLD, true))
    v.add_child(UiKit.label("مقادیر خالی = پیش‌فرض. تغییرات بلافاصله اعمال و ذخیره می‌شود.", 14, UiKit.DIM, false, true))

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    v.add_child(scroll)
    var inner := VBoxContainer.new()
    inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    inner.add_theme_constant_override("separation", 8)
    scroll.add_child(inner)

    for def in FIELD_DEFS:
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 10)
        var lab := UiKit.label(str(def[1]), 17)
        lab.custom_minimum_size.x = 300
        row.add_child(lab)
        var e := LineEdit.new()
        e.custom_minimum_size = Vector2(240, 62)
        e.add_theme_font_override("font", UiKit.font())
        e.add_theme_font_size_override("font_size", UiKit.fs(18))
        e.alignment = HORIZONTAL_ALIGNMENT_CENTER
        var cur = Rates.rate(str(def[0]))
        if str(def[0]) == "tapsell_app_key" or str(def[0]) == "tapsell_ad_unit":
            e.text = str(cur) if str(cur) != "" else ""
            e.placeholder_text = "(خالی)"
        else:
            e.text = str(cur)
        e.set_meta("key", str(def[0]))
        row.add_child(e)
        _fields.append(e)
        inner.add_child(row)

    # vendor selector
    var vrow := HBoxContainer.new()
    vrow.add_theme_constant_override("separation", 10)
    vrow.add_child(UiKit.label("فروشگاه پرداخت", 17))
    var vend := OptionButton.new()
    vend.custom_minimum_size = Vector2(240, 62)
    vend.add_theme_font_override("font", UiKit.font())
    vend.add_theme_font_size_override("font_size", UiKit.fs(18))
    for item in ["test", "bazaar", "myket"]:
        vend.add_item(item)
    vend.select(["test", "bazaar", "myket"].find(Rates.vendor()))
    vend.item_selected.connect(func(idx): Rates.set_override("vendor", ["test", "bazaar", "myket"][idx]))
    vrow.add_child(vend)
    inner.add_child(vrow)

    # pin change
    var prow := HBoxContainer.new()
    prow.add_theme_constant_override("separation", 10)
    prow.add_child(UiKit.label("رمز جدید پنل", 17))
    var pe := LineEdit.new()
    pe.custom_minimum_size = Vector2(240, 62)
    pe.secret = true
    pe.add_theme_font_override("font", UiKit.font())
    pe.add_theme_font_size_override("font_size", UiKit.fs(18))
    prow.add_child(pe)
    var psave := UiKit.ghost_button("ثبت رمز", 16)
    psave.pressed.connect(func():
        if pe.text.length() >= 4:
            Save.admin_pin = pe.text
            Save.save_all()
            pe.text = ""
            Sfx.play("coin"))
    prow.add_child(psave)
    inner.add_child(prow)

    # action buttons
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 10)
    v.add_child(h)
    var save := UiKit.button("ذخیره و اعمال ✦", 20)
    save.pressed.connect(_save_all)
    h.add_child(save)
    var reset := UiKit.ghost_button("بازگشت به پیش‌فرض", 18)
    reset.pressed.connect(func():
        Rates.reset_overrides()
        Sfx.play("chime")
        _refresh())
    h.add_child(reset)
    h.add_child(UiKit.hspacer())
    var back := UiKit.ghost_button("خروج", 18)
    back.pressed.connect(func(): closed.emit())
    h.add_child(back)

func _save_all() -> void:
    for e in _fields:
        var key: String = e.get_meta("key")
        var txt: String = e.text.strip_edges()
        if txt == "":
            Save.overrides.erase(key)
            continue
        if key.begins_with("tapsell") or key == "vendor":
            Rates.set_override(key, txt)
        else:
            Rates.set_override(key, int(txt))
    Save.save_all()
    Sfx.play("coin")
    Sfx.vibe(30)

func _refresh() -> void:
    for e in _fields:
        var key: String = e.get_meta("key")
        var cur = Rates.rate(key)
        e.text = "" if not Save.overrides.has(key) else str(cur)
