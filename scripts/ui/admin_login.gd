extends Control
## Admin login: PIN gate (default 1234, changeable in panel).

signal closed()
signal auth_ok()

var pin := ""
var dots: Label

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var v := VBoxContainer.new()
    v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    v.custom_minimum_size = Vector2(520, 0)
    v.grow_horizontal = Control.GROW_DIRECTION_BOTH
    v.grow_vertical = Control.GROW_DIRECTION_BOTH
    v.add_theme_constant_override("separation", 14)
    add_child(v)
    var p := UiKit.panel(UiKit.PANEL)
    p.add_child(v)
    v.add_child(UiKit.label("🔐 ورود مدیر", 26, UiKit.GOLD, true))
    dots = UiKit.label("", 30, UiKit.INK, true)
    v.add_child(dots)
    v.add_child(UiKit.label("رمز پنل مدیریت را وارد کنید", 16, UiKit.DIM))
    var grid := GridContainer.new()
    grid.columns = 3
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    v.add_child(grid)
    for n in [1, 2, 3, 4, 5, 6, 7, 8, 9]:
        grid.add_child(_key(str(n)))
    var empty := Control.new()
    grid.add_child(empty)
    grid.add_child(_key("۰"))
    grid.add_child(_key("⌫"))
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 10)
    v.add_child(h)
    var cancel := UiKit.ghost_button("انصراف", 20)
    cancel.pressed.connect(func(): closed.emit())
    h.add_child(cancel)
    h.add_child(UiKit.hspacer())
    var ok := UiKit.button("ورود", 20)
    ok.pressed.connect(_check)
    h.add_child(ok)
    add_child(p)

func _key(txt: String) -> Button:
    var b := UiKit.button(txt, 24, UiKit.PANEL2)
    b.custom_minimum_size = Vector2(120, 72)
    b.pressed.connect(func():
        Sfx.play("click")
        if txt == "⌫":
            pin = pin.substr(0, maxi(0, pin.length() - 1))
        elif pin.length() < 6:
            pin += txt.replace("۰", "0")
        dots.text = "•".repeat(pin.length()))
    return b

func _check() -> void:
    if pin == Save.admin_pin:
        Sfx.play("chime")
        auth_ok.emit()
    else:
        Sfx.play("whoosh")
        Sfx.vibe(60)
        pin = ""
        dots.text = "رمز اشتباه!"
