extends Control
## Shop: 3 coin packs. Test build -> simulated gateway; store build -> real IAB.

signal closed()

const PACKS := [
    {"key": "pack_1", "g": "🪙", "tag": "شروعِ راه"},
    {"key": "pack_2", "g": "🪙🪙", "tag": "محبوب‌ترین"},
    {"key": "pack_3", "g": "🪙🪙🪙", "tag": "بستهٔ کامل"}
]

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

    var head := HBoxContainer.new()
    head.add_child(UiKit.hspacer())
    head.add_child(UiKit.label("🛒 فروشگاه سکه", 30, UiKit.GOLD, true))
    head.add_child(UiKit.hspacer())
    v.add_child(head)
    v.add_child(UiKit.label("داراییِ فعلی: " + UiKit.price_tag(Save.coins) + "  ·  پرداخت از طریق " + _vendor_name(), 17, UiKit.DIM, false, true))

    for p in PACKS:
        var coins := int(Rates.rate(p.key + "_coins"))
        var price := int(Rates.rate(p.key + "_price"))
        var card := UiKit.panel(UiKit.PANEL)
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 12)
        card.add_child(h)
        var g := UiKit.label(p.g, 30, UiKit.GOLD)
        g.custom_minimum_size.x = 120
        h.add_child(g)
        var tv := VBoxContainer.new()
        tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tv.add_theme_constant_override("separation", 4)
        tv.add_child(UiKit.label(UiKit.fa(coins) + " سکه", 24, UiKit.INK, true))
        tv.add_child(UiKit.label(str(p.tag), 16, UiKit.PURPLE))
        h.add_child(tv)
        var buy := UiKit.button(Rates.fa_price(price) + " تومان", 20)
        buy.custom_minimum_size.x = 170
        buy.pressed.connect(func(): _buy(p.key, coins, price))
        h.add_child(buy)
        v.add_child(card)

    v.add_child(UiKit.label("پرداخت امن داخل برنامه است؛ سکه‌ها بلافاصله اضافه می‌شوند.", 14, UiKit.DIM, false, true))
    var back := UiKit.ghost_button("بازگشت", 20)
    back.pressed.connect(func(): Sfx.play("click"); closed.emit())
    v.add_child(back)

func _vendor_name() -> String:
    match Rates.vendor():
        "bazaar": return "کافه‌بازار"
        "myket": return "مایکت"
    return "درگاه آزمایشی"

func _buy(key: String, coins: int, price: int) -> void:
    Sfx.play("click")
    Billing.start_purchase(key, coins, price,
        func():
            Save.add_coins(coins)
            Save.add_xp(3)
            Sfx.play("coin")
            Sfx.vibe(40),
        func(_why):
            Sfx.play("whoosh"))
