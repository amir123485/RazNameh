extends Node
## RazNameh headless test runner. Run:
##   godot --headless --path . res://tests/test_main.tscn

var failures := 0
var passes := 0

func _ready() -> void:
    print("== RazNameh tests ==")
    test_rates()
    test_save()
    test_fortunes()
    test_data_integrity()
    test_admin_override()
    test_ui_kit()
    test_overall_readings()
    test_history_toggle()
    test_notif_data()
    test_remote_config()
    print("== done: %d failures ==" % failures)
    if failures == 0:
        print("ALL TESTS PASSED")
    get_tree().quit(1 if failures > 0 else 0)

func check(cond: bool, name: String) -> void:
    if cond:
        passes += 1
        print("  [PASS] " + name)
    else:
        failures += 1
        print("  [FAIL] " + name)

# ---------------------------------------------------------------- rates
func test_rates() -> void:
    print("- rates")
    check(Rates.rate("price_tarot6") == 75, "tarot6 default 75")
    check(Rates.price("yesno") == 8, "yesno price 8")
    check(Rates.price("tarot6") == 75, "tarot6 via price()")
    check(Rates.rate("ad_reward") == 5, "ad reward 5")
    check(int(Rates.rate("pack_3_price")) <= 60000, "max pack <= 60k")
    check(Rates.fa_num(75) == "۷۵", "fa_num")
    check(Rates.fa_price(60000) == "۶۰,۰۰۰", "fa_price grouping")

# ---------------------------------------------------------------- save
func test_save() -> void:
    print("- save")
    var c0: int = Save.coins
    Save.add_coins(10)
    check(Save.coins == c0 + 10, "add_coins")
    Save.add_coins(-100000)
    check(Save.coins == 0, "coins clamped at 0")
    Save.add_coins(c0 + 10 - 0)  # restore-ish
    Save.coins = c0
    Save.add_history("test", "تیتر", "خلاصه")
    check(Save.history.size() >= 1, "history insert")
    Save.history.clear()
    Save.add_xp(5)
    check(Save.level() >= 1, "level >= 1")
    check(Save.level_title() != "", "level title")

# ------------------------------------------------------------ fortunes
func test_fortunes() -> void:
    print("- fortunes")
    var t6 := Fortunes.tarot_draw(6)
    check(t6.size() == 6, "tarot draw 6")
    var t3 := Fortunes.tarot_draw(3)
    check(t3.size() == 3, "tarot draw 3")
    for c in t6:
        check(c.has("name") and c.has("meaning") and c.has("yn"), "card fields " + str(c.get("id")))
    var yn := Fortunes.yesno_from_cards(t6)
    check(yn in ["بله", "خیر", "نامشخص"], "yesno domain")
    var cof := Fortunes.coffee_draw(3)
    check(cof.size() == 3 and cof[0].has("paths"), "coffee symbols")
    var cd := Fortunes.candle_draw()
    check(cd.has("t") and cd.has("m"), "candle draw")
    var ps := Fortunes.pastor_draw(3)
    check(ps.size() == 3 and ps[0].has("glyph"), "pastor draw")
    var hf := Fortunes.hafez_draw()
    check(hf.has("b") and hf.has("t"), "hafez draw")
    var lv := Fortunes.love_msg()
    check(lv.compat >= 0 and lv.msg != "", "love msg")

# ------------------------------------------------------- data integrity
func test_data_integrity() -> void:
    print("- data integrity")
    check(Fortunes.tarot_major.size() == 22, "22 major arcana")
    check(Fortunes.coffee_symbols.size() >= 16, ">= 16 coffee symbols")
    for s in Fortunes.coffee_symbols:
        check(Array(s.paths).size() >= 1, "symbol has path: " + str(s.name))
    check(Fortunes.hafez.size() >= 20, ">= 20 hafez poems")
    check(Fortunes.pastor.rank_meanings.keys().size() == 13, "13 ranks")
    check(Fortunes.pastor.suit_tones.keys().size() == 4, "4 suits")
    check(Fortunes.candle.good.size() + Fortunes.candle.mid.size() + Fortunes.candle.bad.size() >= 14, "candle pool")

# ------------------------------------------------------- admin override
func test_admin_override() -> void:
    print("- admin overrides")
    Rates.set_override("price_tarot6", 90)
    check(Rates.price("tarot6") == 90, "override applies")
    Rates.set_override("ad_reward", 7)
    check(Rates.rate("ad_reward") == 7, "ad reward override")
    Rates.reset_overrides()
    check(Rates.price("tarot6") == 75, "reset restores default")
    var pin0: String = Save.admin_pin
    Save.admin_pin = "9999"
    check(Save.admin_pin == "9999", "pin change")
    Save.admin_pin = pin0

# ------------------------------------------------------------- ui kit
func test_ui_kit() -> void:
    print("- ui kit")
    check(UiKit.price_tag(0) == "رایگان", "free tag")
    check(UiKit.price_tag(25).contains("۲۵"), "price tag fa digits")

# ------------------------------------------------- overall readings (v1.1)
func test_overall_readings() -> void:
    print("- overall readings (tafsir kolli)")
    # every generator returns a substantial Persian paragraph
    var t3 := Fortunes.tarot_draw(3)
    var o1: String = Fortunes.overall_tarot(t3, ["گذشته", "حال", "آینده"])
    check(o1.length() > 60, "tarot overall length")
    var yn := Fortunes.yesno_from_cards([Fortunes.tarot_draw(1)[0]])
    check(Fortunes.overall_yesno([Fortunes.tarot_draw(1)[0]], yn).length() > 40, "yesno overall length")
    var ps := Fortunes.pastor_draw(3)
    check(Fortunes.overall_pastor(ps).length() > 60, "pastor overall length")
    check(Fortunes.overall_coffee(Fortunes.coffee_draw(3)).length() > 60, "coffee overall length")
    var cd := Fortunes.candle_draw()
    for pol in ["good", "mid", "bad"]:
        check(Fortunes.overall_candle(cd, pol).length() > 40, "candle overall " + pol)
    var hf := Fortunes.hafez_draw()
    check(Fortunes.overall_hafez(hf).length() > 60, "hafez overall length")
    for pct in [90, 78, 65]:
        check(Fortunes.overall_love({"compat": pct}).length() > 40, "love overall " + str(pct))
    # stability: 30 draws never crash and never empty
    var ok_all := true
    for i in range(30):
        if Fortunes.overall_tarot(Fortunes.tarot_draw(6), ["a","b","c","d","e","f"]).length() < 40:
            ok_all = false
    check(ok_all, "30x tarot6 overall stable")

# ------------------------------------------------- history toggle (v1.1)
func test_history_toggle() -> void:
    print("- history on/off")
    var prev: bool = Save.history_on
    Save.set_history_on(false)
    check(Save.history_on == false, "history off")
    var before: int = Save.history.size()
    Save.add_history("test", "تیتر", "خلاصه")
    check(Save.history.size() == before, "no recording when off")
    check(before == 0, "history cleared on off")
    Save.set_history_on(true)
    Save.add_history("test", "تیتر", "خلاصه")
    check(Save.history.size() == 1, "recording when on")
    Save.history.clear()
    Save.history_on = prev

# ------------------------------------------------- notification data (v1.1)
func test_notif_data() -> void:
    print("- notification data")
    var msgs: PackedStringArray = Notif.load_msgs()
    check(msgs.size() >= 24, ">= 24 notification messages")
    var uniq := {}
    for m in msgs:
        uniq[m] = true
    check(uniq.size() == msgs.size(), "notification messages unique")
    check(Notif.plugin == null, "notif plugin inert on desktop")

# --------------------------------------------- remote config + vendor (v1.2)
func test_remote_config() -> void:
    print("- remote config (global tariffs)")
    # default pin migrated to the new passphrase
    check(Save.admin_pin == "@Mir1383123485", "admin pin default")
    # flavor present (test flavor in this repo state)
    check(Rates.vendor() in ["test", "bazaar", "myket"], "vendor flavor domain")
    check(Rates.vendor() == "test", "test flavor until re-flavored")
    # apply a simulated remote file: allowed keys, unknown keys, _keys, empties
    var sample := "{\"_note\":\"x\",\"price_tarot6\":120,\"price_hafez\":\"18\",\"ad_reward\":\"\",\"vendor\":\"bazaar\",\"pack_2_price\":40000}"
    check(Rates._apply_remote(sample), "remote json parses")
    check(Save.remote.get("price_tarot6", 0) == 120, "remote int applied")
    check(Save.remote.get("price_hafez", "") == "18", "remote numeric string kept")
    check(not Save.remote.has("ad_reward"), "remote empty value skipped")
    check(not Save.remote.has("vendor"), "vendor not remotely settable")
    check(Save.remote.size() == 3, "whitelist enforced")
    check(Rates.price("tarot6") == 120, "remote reaches price()")
    # local admin override beats remote
    Rates.set_override("price_tarot6", 90)
    check(Rates.price("tarot6") == 90, "local override beats remote")
    Rates.reset_overrides()
    check(Rates.price("tarot6") == 120, "remote again after reset")
    # malformed json rejected
    check(not Rates._apply_remote("not json"), "malformed remote rejected")
    # cleanup so UI flows use defaults
    Save.remote = {}
    Save.remote_ts = ""
    Save.overrides = {}
    Save.save_all()
    check(Rates.price("tarot6") == 75, "cleanup restores default")
