extends Node
## Rates: default economy values + admin overrides. Every price/reward lookup
## goes through here so the hidden admin panel can retune everything live.

const DEFAULTS := {
    "ad_reward": 5,
    "daily_bonus": 2,
    "weekly_bonus": 15,
    "ad_cooldown_sec": 30,
    "price_yesno": 8,
    "price_hafez": 10,
    "price_love": 12,
    "price_candle": 15,
    "price_pastor": 18,
    "price_coffee": 25,
    "price_tarot3": 35,
    "price_tarot6": 75,
    "pack_1_coins": 50,
    "pack_1_price": 15000,
    "pack_2_coins": 150,
    "pack_2_price": 35000,
    "pack_3_coins": 300,
    "pack_3_price": 60000,
    "vendor": "test",           # test | bazaar | myket
    "tapsell_app_key": "",
    "tapsell_ad_unit": "rewarded-default"
}

var _flavor_vendor := ""

func _ready() -> void:
    var f := FileAccess.open("res://data/vendor.json", FileAccess.READ)
    if f != null:
        var parsed = JSON.parse_string(f.get_as_text())
        if parsed is Dictionary and parsed.has("vendor"):
            _flavor_vendor = str(parsed.vendor)

func rate(key: String):
    if Save != null and Save.overrides.has(key):
        return Save.overrides[key]
    var v = DEFAULTS.get(key)
    if v == null:
        printerr("RATE MISSING KEY: '" + str(key) + "' type=" + str(typeof(key)))
    return v

func price(fortune_id: String) -> int:
    var key := "price_" + fortune_id
    return int(rate(key))

func set_override(key: String, value) -> void:
    Save.overrides[key] = value
    Save.save_all()

func reset_overrides() -> void:
    Save.overrides = {}
    Save.save_all()

func vendor() -> String:
    return str(get("vendor"))

func is_store_build() -> bool:
    return vendor() == "bazaar" or vendor() == "myket"

func vendor_package() -> String:
    match vendor():
        "bazaar":
            return "com.farsitel.bazaar"
        "myket":
            return "ir.mservices.market"
    return ""

static func fa_num(n) -> String:
    var s := str(n)
    var out := ""
    for ch in s:
        if ch >= "0" and ch <= "9":
            out += char(0x06F0 + ch.to_int())
        else:
            out += ch
    return out

static func fa_price(n) -> String:
    var s := str(int(n))
    var grouped := ""
    var count := 0
    for i in range(s.length() - 1, -1, -1):
        grouped = s[i] + grouped
        count += 1
        if count % 3 == 0 and i > 0:
            grouped = "," + grouped
    return fa_num(grouped)
