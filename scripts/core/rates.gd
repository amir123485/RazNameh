extends Node
## Rates: default economy values + admin overrides + remote config.
## Every price/reward lookup goes through here.
## Priority: device admin override (this device only)  >  remote config
## (all devices, from the GitHub JSON file)  >  built-in default.

signal remote_done(ok: bool, msg: String)

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
    "tapsell_ad_unit": "rewarded-default",
    "remote_config_url": "https://raw.githubusercontent.com/amir123485/RazNameh/main/data/remote_config.json"
}

## Keys the remote config file is allowed to set. "vendor" and
## "remote_config_url" are deliberately excluded for safety.
const REMOTE_KEYS := [
    "ad_reward", "daily_bonus", "weekly_bonus", "ad_cooldown_sec",
    "price_yesno", "price_hafez", "price_love", "price_candle",
    "price_pastor", "price_coffee", "price_tarot3", "price_tarot6",
    "pack_1_coins", "pack_1_price", "pack_2_coins", "pack_2_price",
    "pack_3_coins", "pack_3_price", "tapsell_app_key", "tapsell_ad_unit"
]

const REMOTE_URL_FALLBACK := "https://cdn.jsdelivr.net/gh/amir123485/RazNameh@main/data/remote_config.json"

var _flavor_vendor := ""
var _fetching := false

func _ready() -> void:
    var f := FileAccess.open("res://data/vendor.json", FileAccess.READ)
    if f != null:
        var parsed = JSON.parse_string(f.get_as_text())
        if parsed is Dictionary and parsed.has("vendor"):
            _flavor_vendor = str(parsed.vendor)
    # remote config: fetch shortly after startup so it never blocks launch
    var t := Timer.new()
    t.wait_time = 3.0
    t.one_shot = true
    t.timeout.connect(fetch_remote_now)
    add_child(t)
    t.start()

func rate(key: String):
    if Save != null and Save.overrides.has(key):
        return Save.overrides[key]
    if Save != null and Save.remote.has(key):
        return Save.remote[key]
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

# ------------------------------------------------------------ remote config
## Fetch the global tariff file (all users). Called automatically ~3 s
## after launch and from the admin panel's "check now" button.
func fetch_remote_now() -> void:
    if _fetching:
        return
    var url := str(rate("remote_config_url")).strip_edges()
    if url == "":
        return
    _fetching = true
    var ok := await _try_url(url)
    if not ok and url != REMOTE_URL_FALLBACK:
        ok = await _try_url(REMOTE_URL_FALLBACK)
    _fetching = false
    if not ok:
        remote_done.emit(false, "دریافت تنظیمات راه دور ناموفق بود (اینترنت؟)")

func _try_url(url: String) -> bool:
    var http := HTTPRequest.new()
    http.timeout = 10.0
    add_child(http)
    var err := http.request(url, PackedStringArray(["User-Agent: RazNameh/1.2"]))
    if err != OK:
        http.queue_free()
        return false
    var res: Array = await http.request_completed
    http.queue_free()
    var result: int = res[0]
    var code: int = res[1]
    if result != HTTPRequest.RESULT_SUCCESS or code != 200:
        return false
    return _apply_remote(str(res[3].get_string_from_utf8()))

func _apply_remote(text: String) -> bool:
    var parsed = JSON.parse_string(text)
    if not (parsed is Dictionary):
        return false
    var fresh := {}
    for k in parsed.keys():
        var key := str(k)
        if key.begins_with("_") or not (key in REMOTE_KEYS):
            continue
        var val = parsed[k]
        match typeof(val):
            TYPE_INT, TYPE_FLOAT:
                fresh[key] = int(val)
            TYPE_STRING:
                var s := str(val).strip_edges()
                if s != "":
                    fresh[key] = s
    Save.remote = fresh
    Save.remote_ts = Time.get_datetime_string_from_system(false, true)
    Save.save_all()
    remote_done.emit(true, "تنظیمات راه دور اعمال شد (%d مقدار)" % fresh.size())
    return true

## Payment backend for THIS build: flavor from the packed data/vendor.json
## (test/bazaar/myket) unless the admin explicitly overrides it on device.
func vendor() -> String:
    if Save != null and Save.overrides.has("vendor"):
        return str(Save.overrides["vendor"])
    if _flavor_vendor != "":
        return _flavor_vendor
    return str(DEFAULTS.get("vendor", "test"))

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
