extends Node
## Save: all persistent user data + admin overrides (ConfigFile at user://raznameh.cfg).

const PATH := "user://raznameh.cfg"

signal coins_changed(value: int)
signal xp_changed(xp: int, level: int, title: String)
signal history_toggled(on: bool)

var coins: int = 12
var xp: int = 0
var history: Array = []          # [{type, ts, title, summary}]
var last_daily: String = ""      # "2026-09-19"
var last_weekly: String = ""     # ISO week key e.g. "2026-W38"
var free_yesno_date: String = ""
var first_run: bool = true
var overrides: Dictionary = {}   # admin rate overrides (this device only)
var remote: Dictionary = {}      # last-known remote-config values (all devices)
var remote_ts: String = ""       # ISO time of last successful remote fetch
var admin_pin: String = "@Mir1383123485"
var sound_on: bool = true
var vibe_on: bool = true
var ad_cooldown_until: int = 0
var history_on: bool = true      # user toggle: record & show history
var notif_on: bool = true        # user toggle: daily notifications

const LEGACY_PIN := "1234"       # old default; auto-migrated on load

const LEVELS := [
    [0, "جذب‌شدهٔ راز"], [20, "کنجکاو"], [60, "جویا"], [120, "بینا"],
    [220, "رهرو"], [340, "راه‌سوخته"], [480, "عارف"], [640, "استاد رازنامه"]
]

func _ready() -> void:
    load_all()

func file_path() -> String:
    return PATH

func load_all() -> void:
    var cf := ConfigFile.new()
    if cf.load(PATH) != OK:
        return
    coins = cf.get_value("user", "coins", 12)
    xp = cf.get_value("user", "xp", 0)
    history = cf.get_value("user", "history", [])
    last_daily = cf.get_value("user", "last_daily", "")
    last_weekly = cf.get_value("user", "last_weekly", "")
    free_yesno_date = cf.get_value("user", "free_yesno_date", "")
    first_run = cf.get_value("user", "first_run", true)
    sound_on = cf.get_value("user", "sound_on", true)
    vibe_on = cf.get_value("user", "vibe_on", true)
    ad_cooldown_until = int(cf.get_value("user", "ad_cooldown_until", 0))
    history_on = cf.get_value("user", "history_on", true)
    notif_on = cf.get_value("user", "notif_on", true)
    overrides = cf.get_value("admin", "overrides", {})
    remote = cf.get_value("admin", "remote", {})
    remote_ts = cf.get_value("admin", "remote_ts", "")
    admin_pin = cf.get_value("admin", "pin", "@Mir1383123485")
    # migrate installs that still carry the old default PIN
    if str(admin_pin) == LEGACY_PIN:
        admin_pin = "@Mir1383123485"
        save_all()

func save_all() -> void:
    var cf := ConfigFile.new()
    cf.set_value("user", "coins", coins)
    cf.set_value("user", "xp", xp)
    cf.set_value("user", "history", history)
    cf.set_value("user", "last_daily", last_daily)
    cf.set_value("user", "last_weekly", last_weekly)
    cf.set_value("user", "free_yesno_date", free_yesno_date)
    cf.set_value("user", "first_run", first_run)
    cf.set_value("user", "sound_on", sound_on)
    cf.set_value("user", "vibe_on", vibe_on)
    cf.set_value("user", "ad_cooldown_until", ad_cooldown_until)
    cf.set_value("user", "history_on", history_on)
    cf.set_value("user", "notif_on", notif_on)
    cf.set_value("admin", "overrides", overrides)
    cf.set_value("admin", "remote", remote)
    cf.set_value("admin", "remote_ts", remote_ts)
    cf.set_value("admin", "pin", admin_pin)
    cf.save(PATH)

# ------------------------------------------------------------ coins / xp
func add_coins(amount: int) -> void:
    coins += amount
    if coins < 0:
        coins = 0
    save_all()
    coins_changed.emit(coins)

func add_xp(amount: int) -> void:
    xp += amount
    save_all()
    xp_changed.emit(xp, level(), level_title())

func level() -> int:
    var lv := 1
    for entry in LEVELS:
        if xp >= entry[0]:
            lv += 1 if LEVELS.find(entry) > 0 else lv
    var idx := 0
    for i in range(LEVELS.size()):
        if xp >= LEVELS[i][0]:
            idx = i
    return idx + 1

func level_title() -> String:
    var idx := 0
    for i in range(LEVELS.size()):
        if xp >= LEVELS[i][0]:
            idx = i
    return LEVELS[idx][1]

# ------------------------------------------------------------ history
func set_history_on(on: bool) -> void:
    if history_on == on:
        return
    history_on = on
    if not on:
        history.clear()   # privacy: erase stored readings when disabled
    save_all()
    history_toggled.emit(on)

func add_history(fortune_type: String, title: String, summary: String) -> void:
    if not history_on:
        return
    var item := {
        "type": fortune_type,
        "ts": Time.get_datetime_string_from_system(false, true),
        "title": title,
        "summary": summary
    }
    history.insert(0, item)
    if history.size() > 200:
        history = history.slice(0, 200)
    save_all()

# ------------------------------------------------------------ date helpers
static func today_key() -> String:
    var d := Time.get_date_dict_from_system()
    return "%04d-%02d-%02d" % [d.year, d.month, d.day]

static func week_key() -> String:
    var d := Time.get_date_dict_from_system()
    var dt := {"year": d.year, "month": d.month, "day": d.day}
    var unix := Time.get_unix_time_from_datetime_dict(dt)
    var weekday: int = Time.get_datetime_dict_from_unix_time(unix).weekday  # 0=Sunday
    var week := int((unix / 86400.0 + 4.0) / 7.0)
    return "W%d" % week
