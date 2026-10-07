extends Control
## Simulated payment gateway dialog (test builds).

var coins := 0
var price := 0
var _stage := 0   # 0 choosing, 1 processing, 2 done/cancelled

func instance(coins_: int, price_: int) -> Control:
    var d := new()
    d.coins = coins_
    d.price = price_
    return d

func _init(coins_: int = 0, price_: int = 0) -> void:
    coins = coins_
    price = price_

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var dim := ColorRect.new()
    dim.color = Color(0, 0, 0, 0.7)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    var p := UiKit.panel(UiKit.PANEL)
    p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    p.custom_minimum_size = Vector2(540, 0)
    p.grow_horizontal = Control.GROW_DIRECTION_BOTH
    p.grow_vertical = Control.GROW_DIRECTION_BOTH
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 14)
    p.add_child(v)
    v.add_child(UiKit.label("درگاه پرداخت (آزمایشی)", 24, UiKit.GOLD, true))
    v.add_child(UiKit.label("خرید " + UiKit.fa(coins) + " سکه به قیمت " + Rates.fa_price(price) + " تومان\n\n⚠ این نسخهٔ تست است و پول واقعی نقل نمی‌شود.", 18))
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 10)
    v.add_child(h)
    var ok := UiKit.button("پرداخت موفق (تست)", 20, UiKit.GOOD)
    ok.pressed.connect(func(): _stage = 2; Sfx.play("coin"))
    h.add_child(ok)
    var no := UiKit.ghost_button("انصراف", 20)
    no.pressed.connect(func(): _stage = -1)
    h.add_child(no)
    add_child(p)

func run() -> int:
    while _stage == 0:
        await get_tree().create_timer(0.1).timeout
    var r := 1 if _stage == 2 else 0
    await get_tree().create_timer(0.05).timeout
    return r
