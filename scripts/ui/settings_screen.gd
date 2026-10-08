extends Control
## Settings: sound, vibration, about + hidden admin entry (tap version 5 times).

signal closed()
signal admin_requested()

var _taps := 0
var _reset_timer := 0.0

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var v := VBoxContainer.new()
    v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    v.offset_left = 18
    v.offset_right = -18
    v.offset_top = 10
    v.offset_bottom = -10
    v.add_theme_constant_override("separation", 14)
    add_child(v)

    v.add_child(UiKit.label("تنظیمات", 28, UiKit.GOLD, true))

    var sound_card := UiKit.panel(UiKit.PANEL)
    var sh := HBoxContainer.new()
    sound_card.add_child(sh)
    sh.add_child(UiKit.label("🔊 صدا", 21))
    sh.add_child(UiKit.hspacer())
    var sb := _switch(Save.sound_on)
    sb.toggled.connect(func(on):
        Save.sound_on = on
        Save.save_all()
        if on:
            Sfx.ambient_on()
        else:
            Sfx.ambient_off())
    sh.add_child(sb)
    v.add_child(sound_card)

    var vibe_card := UiKit.panel(UiKit.PANEL)
    var vh := HBoxContainer.new()
    vibe_card.add_child(vh)
    vh.add_child(UiKit.label("📳 لرزش", 21))
    vh.add_child(UiKit.hspacer())
    var vb := _switch(Save.vibe_on)
    vb.toggled.connect(func(on): Save.vibe_on = on; Save.save_all())
    vh.add_child(vb)
    v.add_child(vibe_card)

    var notif_card := UiKit.panel(UiKit.PANEL)
    var nh := HBoxContainer.new()
    notif_card.add_child(nh)
    var nv := VBoxContainer.new()
    nv.add_theme_constant_override("separation", 2)
    nh.add_child(nv)
    nv.add_child(UiKit.label("🔔 اعلان‌های روزانه", 21))
    nv.add_child(UiKit.label("دو بار در روز، پیام‌های تازه و متفاوت", 15, UiKit.DIM))
    nh.add_child(UiKit.hspacer())
    var nb := _switch(Save.notif_on)
    nb.toggled.connect(func(on):
        Save.notif_on = on
        Save.save_all()
        Sfx.play("click")
        Notif.apply())
    nh.add_child(nb)
    v.add_child(notif_card)

    var hist_card := UiKit.panel(UiKit.PANEL)
    var hh := HBoxContainer.new()
    hist_card.add_child(hh)
    var hv := VBoxContainer.new()
    hv.add_theme_constant_override("separation", 2)
    hh.add_child(hv)
    hv.add_child(UiKit.label("📜 ثبت تاریخچهٔ فال‌ها", 21))
    hv.add_child(UiKit.label("با خاموش‌کردنش، فال‌های جدید ذخیره نمی‌شوند و سابقه پاک می‌شود", 15, UiKit.DIM, false, true))
    hh.add_child(UiKit.hspacer())
    var hb := _switch(Save.history_on)
    hb.toggled.connect(func(on):
        Sfx.play("click")
        Save.set_history_on(on))
    hh.add_child(hb)
    v.add_child(hist_card)

    var about := UiKit.panel(UiKit.PANEL)
    var av := VBoxContainer.new()
    av.add_theme_constant_override("separation", 6)
    about.add_child(av)
    av.add_child(UiKit.label("دربارهٔ رازنامه", 21, UiKit.GOLD, true))
    av.add_child(UiKit.label("رازنامه یک اپ سرگرمی فال و تاروت است.\nنسخهٔ " + UiKit.fa("1.2.0") + " — ساخته‌شده با Godot 4.7\n\n⚠ همهٔ فال‌ها جنبهٔ سرگرمی و الهام‌بخشی دارند و هیچ توصیهٔ واقعی، طبی، مالی یا عاطفی‌ای نیستند.", 16, UiKit.INK, false, true))
    var ver := UiKit.label("v1.2.0", 13, UiKit.DIM)
    ver.name = "VersionLabel"
    av.add_child(ver)
    ver.mouse_filter = Control.MOUSE_FILTER_STOP
    ver.gui_input.connect(func(ev: InputEvent):
        if ev is InputEventScreenTouch and ev.pressed:
            _tap_secret())
    v.add_child(about)
    about.size_flags_vertical = Control.SIZE_EXPAND_FILL

    var back := UiKit.ghost_button("بازگشت", 20)
    back.pressed.connect(func(): Sfx.play("click"); closed.emit())
    v.add_child(back)

func _switch(on: bool) -> CheckButton:
    var c := CheckButton.new()
    c.button_pressed = on
    c.scale = Vector2(1.3, 1.3)
    c.position.y = 8
    return c

func _tap_secret() -> void:
    _taps += 1
    if _taps >= 5:
        _taps = 0
        Sfx.play("chime")
        admin_requested.emit()

func _process(delta: float) -> void:
    _reset_timer += delta
    if _reset_timer > 2.0:
        _taps = 0
        _reset_timer = 0.0
    else:
        pass
