extends Control
## Root orchestrator: screen stack, top bar (coins/level), navigation.

var top_bar: Control
var coin_label: Label
var level_label: Label
var screen_holder: Control
var current_screen: Control = null
var home: Control = null

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build_bg()
    _build_top_bar()
    screen_holder = Control.new()
    screen_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen_holder.offset_top = 86
    screen_holder.offset_bottom = -64
    screen_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(screen_holder)
    _build_bottom_bar()
    Sfx.ambient_on()
    goto_home()
    if Save.first_run:
        Save.first_run = false
        Save.save_all()
        _show_welcome()
    if OS.get_cmdline_user_args().has("--tour"):
        _tour()

func _tour() -> void:
    var dir := "/home/z/my-project/tour"
    DirAccess.make_dir_recursive_absolute(dir)
    var shot := func(name_: String):
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png(dir + "/" + name_ + ".png")
        print("TOUR SHOT: " + name_)
    await get_tree().create_timer(1.2).timeout
    await shot.call("01_home")
    var steps := [["tarot6", "02_tarot6_deal", 1.0], ["coffee", "03_coffee", 4.2], ["pastor", "03b_pastor", 3.5], ["candle", "04_candle", 2.0], ["hafez", "05_hafez", 5.0], ["love", "06_love", 4.0]]
    for step in steps:
        open_fortune(step[0])
        await get_tree().create_timer(0.4).timeout
        if current_screen != null and current_screen.has_method("_launch_scene"):
            current_screen._launch_scene()
        await get_tree().create_timer(step[1 + 1]).timeout
        var sc: Control = null
        if current_screen.get_child_count() > 0:
            sc = current_screen.get_child(current_screen.get_child_count() - 1)
        if sc != null:
            if sc.has_method("_deal"):
                var deck: Node = sc.get_node_or_null("Deck")
                if deck != null:
                    sc._deal(deck)
                    await get_tree().create_timer(4.5).timeout
            if sc.has_method("_light"):
                sc._light()
                await get_tree().create_timer(3.6).timeout
            if sc.has_method("_emit") and step[0] == "hafez" and "phase" in sc:
                sc.phase = 3
                sc._emit()
                await get_tree().create_timer(0.4).timeout
            if sc.has_method("_emit") and step[0] == "love":
                sc._emit()
                await get_tree().create_timer(0.4).timeout
        await shot.call(step[1])
        await get_tree().create_timer(0.2).timeout
    open_shop()
    await get_tree().create_timer(0.8).timeout
    await shot.call("07_shop")
    open_history()
    await get_tree().create_timer(0.8).timeout
    await shot.call("08_history")
    open_settings()
    await get_tree().create_timer(0.8).timeout
    await shot.call("09_settings")
    open_admin_login()
    await get_tree().create_timer(0.8).timeout
    await shot.call("10_admin_login")
    get_tree().quit()

func _build_bg() -> void:
    var bg := _StarField.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

func _build_top_bar() -> void:
    top_bar = PanelContainer.new()
    top_bar.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.08, 0.06, 0.15, 0.97), 0, UiKit.LINE))
    top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    top_bar.offset_bottom = 86
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 10)
    top_bar.add_child(h)
    var title := UiKit.label("✦ رازنامه", 26, UiKit.GOLD, true)
    title.custom_minimum_size.x = 132
    title.custom_minimum_size.x = 130
    h.add_child(title)
    h.add_child(UiKit.hspacer())
    var coin_chip := UiKit.panel(UiKit.PANEL2)
    var ch := HBoxContainer.new()
    ch.add_theme_constant_override("separation", 6)
    coin_chip.add_child(ch)
    coin_label = UiKit.label("🪙 " + UiKit.fa(Save.coins), 22, UiKit.GOLD, true)
    ch.add_child(coin_label)
    h.add_child(coin_chip)
    var lvl_chip := UiKit.panel(UiKit.PANEL2)
    var lh := HBoxContainer.new()
    lh.add_theme_constant_override("separation", 6)
    lvl_chip.add_child(lh)
    level_label = UiKit.label(UiKit.fa(Save.level()) + "· " + Save.level_title(), 18, UiKit.PURPLE, true)
    lh.add_child(level_label)
    h.add_child(lvl_chip)
    h.add_child(UiKit.hspacer())
    var hist_btn := UiKit.button("تاریخچه", 18, UiKit.PANEL2)
    hist_btn.custom_minimum_size.x = 108
    hist_btn.pressed.connect(func(): Sfx.play("click"); open_history())
    h.add_child(hist_btn)
    var gear := UiKit.button("تنظیمات", 18, UiKit.PANEL2)
    gear.custom_minimum_size.x = 108
    gear.pressed.connect(func(): Sfx.play("click"); open_settings())
    h.add_child(gear)
    add_child(top_bar)
    Save.coins_changed.connect(func(v): coin_label.text = "🪙 " + UiKit.fa(v))
    Save.xp_changed.connect(func(_x, lv, t): level_label.text = UiKit.fa(lv) + "· " + t)

func _build_bottom_bar() -> void:
    var bar := PanelContainer.new()
    bar.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.08, 0.06, 0.15, 0.97), 0, UiKit.LINE))
    bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    bar.offset_top = -64
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 10)
    bar.add_child(h)
    var home_btn := UiKit.button("خانه", 20, UiKit.PANEL2)
    home_btn.custom_minimum_size.x = 110
    home_btn.pressed.connect(func(): Sfx.play("click"); goto_home())
    h.add_child(home_btn)
    h.add_child(UiKit.hspacer())
    var ad_btn := UiKit.button("🎬 تبلیغ ببین +" + UiKit.fa(Rates.rate("ad_reward")), 20, Color("2c5a4e"))
    ad_btn.pressed.connect(func(): Sfx.play("click"); _watch_ad(ad_btn))
    h.add_child(ad_btn)
    h.add_child(UiKit.hspacer())
    var shop_btn := UiKit.button("🛒 فروشگاه سکه", 20, Color("5a4a2c"))
    shop_btn.custom_minimum_size.x = 150
    shop_btn.pressed.connect(func(): Sfx.play("click"); open_shop())
    h.add_child(shop_btn)
    add_child(bar)

func _watch_ad(btn: Button) -> void:
    if Ads.busy:
        _toast("تبلیغ در حال پخش است…")
        return
    if Ads.cooldown_active():
        var left := int(ceil((Save.ad_cooldown_until - Time.get_ticks_msec()) / 1000.0))
        _toast("کمی صبر کن؛ " + UiKit.fa(left) + " ثانیهٔ دیگر")
        return
    Ads.show_rewarded()

func set_screen(s: Control) -> void:
    for c in screen_holder.get_children():
        c.queue_free()
    current_screen = s
    screen_holder.add_child(s)

func goto_home() -> void:
    home = preload("res://scripts/ui/home_screen.gd").new()
    home.open_fortune.connect(open_fortune)
    set_screen(home)

func open_fortune(fortune_id: String) -> void:
    var flow: Control = preload("res://scripts/ui/fortune_flow.gd").new()
    flow.setup(fortune_id)
    flow.closed.connect(goto_home)
    flow.finished.connect(_on_fortune_done)
    set_screen(flow)

func _on_fortune_done(fortune_id: String, title: String, summary: String) -> void:
    Save.add_history(fortune_id, title, summary)

func open_shop() -> void:
    var s: Control = preload("res://scripts/ui/shop_screen.gd").new()
    s.closed.connect(goto_home)
    set_screen(s)

func open_history() -> void:
    var s: Control = preload("res://scripts/ui/history_screen.gd").new()
    s.closed.connect(goto_home)
    set_screen(s)

func open_settings() -> void:
    var s: Control = preload("res://scripts/ui/settings_screen.gd").new()
    s.closed.connect(goto_home)
    s.admin_requested.connect(open_admin_login)
    set_screen(s)

func open_admin_login() -> void:
    var s: Control = preload("res://scripts/ui/admin_login.gd").new()
    s.closed.connect(goto_home)
    s.auth_ok.connect(open_admin_panel)
    set_screen(s)

func open_admin_panel() -> void:
    var s: Control = preload("res://scripts/ui/admin_panel.gd").new()
    s.closed.connect(goto_home)
    set_screen(s)

func _toast(text: String) -> void:
    var t := UiKit.label(text, 20, UiKit.INK, true)
    var p := UiKit.panel(Color(0.12, 0.10, 0.22, 0.95))
    p.add_child(t)
    p.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    p.offset_bottom = -80
    p.offset_top = -130
    p.offset_left = 60
    p.offset_right = -60
    p.grow_horizontal = Control.GROW_DIRECTION_BOTH
    add_child(p)
    var tw := create_tween()
    tw.tween_interval(1.8)
    tw.tween_property(p, "modulate:a", 0.0, 0.5)
    tw.tween_callback(p.queue_free)

func _show_welcome() -> void:
    var dim := ColorRect.new()
    dim.color = Color(0, 0, 0, 0.75)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    var p := UiKit.panel(UiKit.PANEL)
    p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    p.custom_minimum_size = Vector2(560, 0)
    p.grow_horizontal = Control.GROW_DIRECTION_BOTH
    p.grow_vertical = Control.GROW_DIRECTION_BOTH
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 14)
    p.add_child(v)
    v.add_child(UiKit.label("به رازنامه خوش آمدی ✦", 28, UiKit.GOLD, true))
    v.add_child(UiKit.label("با " + UiKit.fa(12) + " سکهٔ هدیه شروع کن!\n\nهر روز ورود کنی سکه می‌گیری؛ با دیدن تبلیغ هم ۵ سکه می‌گیری. فال‌ها فقط برای سرگرمی و الهام‌بخشی‌اند، نه توصیهٔ واقعی.", 20, UiKit.INK, false, true))
    var ok := UiKit.button("شروع می‌کنم ✦", 22)
    ok.pressed.connect(func():
        Sfx.play("chime")
        dim.queue_free()
        p.queue_free())
    v.add_child(ok)
    add_child(p)

class _StarField extends Control:
    var pts: Array = []
    var t := 0.0
    func _ready() -> void:
        randomize()
        for i in range(70):
            pts.append({"p": Vector2(randf() * 720, randf() * 1280), "s": randf_range(0.5, 2.0), "ph": randf() * TAU})
    func _process(delta: float) -> void:
        t += delta
        queue_redraw()
    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), UiKit.BG)
        for p in pts:
            var a := 0.25 + 0.55 * (0.5 + 0.5 * sin(t * 1.3 + p.ph))
            draw_circle(p.p, p.s, Color(0.83, 0.76, 0.95, a))
