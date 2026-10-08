extends Control
## History: past readings, tap to expand.

signal closed()

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var v := VBoxContainer.new()
    v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    v.offset_left = 18
    v.offset_right = -18
    v.offset_top = 10
    v.offset_bottom = -10
    v.add_theme_constant_override("separation", 12)
    add_child(v)

    v.add_child(UiKit.label("📜 تاریخچهٔ فال‌ها", 28, UiKit.GOLD, true))

    if not Save.history_on:
        var off_panel := UiKit.panel(Color("2b2347"))
        off_panel.add_child(UiKit.label("ثبت تاریخچه در تنظیمات خاموش است؛ فال‌های جدید ذخیره نمی‌شوند.", 18, UiKit.GOLD, false, true))
        v.add_child(off_panel)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    v.add_child(scroll)
    var inner := VBoxContainer.new()
    inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    inner.add_theme_constant_override("separation", 10)
    scroll.add_child(inner)

    if Save.history.is_empty():
        inner.add_child(UiKit.panel(UiKit.PANEL))
        inner.get_child(inner.get_child_count() - 1).add_child(
            UiKit.label("هنوز فالی نگرفتی؛ اولین فالت منتظر است ✦", 18, UiKit.DIM))
    for h in Save.history:
        var p := UiKit.panel(UiKit.PANEL)
        var pv := VBoxContainer.new()
        pv.add_theme_constant_override("separation", 4)
        p.add_child(pv)
        pv.add_child(UiKit.label(str(h.title), 20, UiKit.PURPLE, true))
        pv.add_child(UiKit.label(str(h.ts).replace("T", " — "), 13, UiKit.DIM))
        pv.add_child(UiKit.label(str(h.summary), 16, UiKit.INK, false, true))
        inner.add_child(p)
    # touch-drag anywhere on the page must scroll it (not only the scrollbar)
    UiKit.scroll_friendly(scroll)

    var back := UiKit.ghost_button("بازگشت", 20)
    back.pressed.connect(func(): Sfx.play("click"); closed.emit())
    v.add_child(back)
