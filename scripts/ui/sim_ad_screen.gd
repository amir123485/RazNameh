extends Control
## Simulated rewarded-ad screen: 5s countdown, then reward.

var _left := 5
var _finished := false
var _label: Label

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color(0.03, 0.02, 0.06, 0.96)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var v := VBoxContainer.new()
    v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    v.grow_horizontal = Control.GROW_DIRECTION_BOTH
    v.grow_vertical = Control.GROW_DIRECTION_BOTH
    v.add_theme_constant_override("separation", 16)
    add_child(v)
    v.add_child(UiKit.label("🎬 تبلیغ", 30, UiKit.GOLD, true))
    _label = UiKit.label("پاداش شما تا " + UiKit.fa(_left) + " ثانیه دیگر…", 22)
    v.add_child(_label)
    v.add_child(UiKit.label("(نسخهٔ تست — تبلیغ شبیه‌سازی‌شده)", 15, UiKit.DIM))
    var skip := UiKit.ghost_button("بستن تبلیغ", 18)
    skip.pressed.connect(func():
        if _left > 0:
            _finished = true
            get_viewport().set_input_as_handled())
    v.add_child(skip)
    var timer := Timer.new()
    timer.wait_time = 1.0
    timer.timeout.connect(_tick)
    add_child(timer)
    timer.start()

func _tick() -> void:
    _left -= 1
    if _left <= 0:
        _label.text = "✅ تبلیغ کامل شد!"
        _finished = true
    else:
        _label.text = "پاداش شما تا " + UiKit.fa(_left) + " ثانیه دیگر…"

func run() -> int:
    while not _finished:
        await get_tree().create_timer(0.1).timeout
    var r := 1 if _left <= 0 else 0
    return r
