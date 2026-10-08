extends Control
## Admin login: passphrase gate (default @Mir1383123485, changeable in panel).

signal closed()
signal auth_ok()

var pin := ""
var field: LineEdit

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var v := VBoxContainer.new()
    v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    v.custom_minimum_size = Vector2(640, 0)
    v.grow_horizontal = Control.GROW_DIRECTION_BOTH
    v.grow_vertical = Control.GROW_DIRECTION_BOTH
    v.add_theme_constant_override("separation", 14)
    add_child(v)
    var p := UiKit.panel(UiKit.PANEL)
    p.add_child(v)
    v.add_child(UiKit.label("🔐 ورود مدیر", 26, UiKit.GOLD, true))
    v.add_child(UiKit.label("رمز پنل مدیریت را وارد کنید", 16, UiKit.DIM))
    field = LineEdit.new()
    field.custom_minimum_size = Vector2(0, 74)
    field.secret = true
    field.secret_character = "•"
    field.alignment = HORIZONTAL_ALIGNMENT_CENTER
    field.add_theme_font_override("font", UiKit.font())
    field.add_theme_font_size_override("font_size", UiKit.fs(22))
    field.add_theme_stylebox_override("normal", UiKit.panel_style(UiKit.PANEL2, 12, UiKit.LINE))
    field.add_theme_stylebox_override("focus", UiKit.panel_style(UiKit.PANEL2, 12, UiKit.GOLD))
    field.text_changed.connect(func(_t): _clear_err())
    field.text_submitted.connect(func(_t): _check())
    v.add_child(field)
    var err := UiKit.label("", 16, UiKit.BAD)
    err.name = "Err"
    v.add_child(err)
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 10)
    v.add_child(h)
    var cancel := UiKit.ghost_button("انصراف", 20)
    cancel.pressed.connect(func(): closed.emit())
    h.add_child(cancel)
    h.add_child(UiKit.hspacer())
    var ok := UiKit.button("ورود", 20)
    ok.custom_minimum_size.x = 170
    ok.pressed.connect(_check)
    h.add_child(ok)
    add_child(p)

func _clear_err() -> void:
    var e := get_node_or_null("Err")
    if e != null:
        e.text = ""

func _check() -> void:
    var code := field.text.strip_edges()
    if code == Save.admin_pin:
        Sfx.play("chime")
        auth_ok.emit()
    else:
        Sfx.play("whoosh")
        Sfx.vibe(60)
        field.text = ""
        var e := get_node_or_null("Err")
        if e != null:
            e.text = "رمز اشتباه است!"
