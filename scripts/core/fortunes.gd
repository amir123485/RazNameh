extends Node
## Fortunes: data access + draw logic for every fortune type.

var tarot_major: Array = []
var tarot_minor_cfg: Dictionary = {}
var coffee_symbols: Array = []
var candle: Dictionary = {}
var pastor: Dictionary = {}
var hafez: Array = []
var love: Dictionary = {}

func _ready() -> void:
    tarot_major = _load("res://data/tarot_major.json")
    tarot_minor_cfg = _load("res://data/tarot_minor.json")
    coffee_symbols = _load("res://data/coffee_symbols.json")
    candle = _load("res://data/candle_interp.json")
    pastor = _load("res://data/pastor_cards.json")
    hafez = _load("res://data/hafez.json")
    love = _load("res://data/love_msgs.json")

func _load(path: String):
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        push_error("missing data: " + path)
        return null
    var parsed = JSON.parse_string(f.get_as_text())
    return parsed

# --------------------------------------------------------- deck helpers
static func shuffled_indices(count: int) -> Array:
    var arr := []
    for i in range(count):
        arr.append(i)
    for i in range(count - 1, 0, -1):
        var j := randi_range(0, i)
        var tmp = arr[i]
        arr[i] = arr[j]
        arr[j] = tmp
    return arr

# --------------------------------------------------------- tarot
func tarot_draw(count: int) -> Array:
    var picks := []
    var majors := shuffled_indices(tarot_major.size())
    var minors := shuffled_indices(56)
    var take_major := count
    if count >= 6:
        take_major = 4   # hexagram spread mixes majors & minors
    for i in range(min(take_major, majors.size())):
        picks.append(major_card(majors[i]))
    for i in range(count - picks.size()):
        picks.append(minor_card(minors[i]))
    return picks

func major_card(idx: int) -> Dictionary:
    var d: Dictionary = tarot_major[idx % tarot_major.size()]
    return {"kind": "major", "id": d.id, "num": d.n, "name": d.name, "glyph": d.g,
            "keywords": d.kw, "meaning": d.m, "yn": d.yn}

func minor_card(flat_idx: int) -> Dictionary:
    var suit_keys: Array = tarot_minor_cfg.suits.keys()
    var rank_keys: Array = tarot_minor_cfg.ranks.keys()
    var suit: String = suit_keys[flat_idx / rank_keys.size()]
    var rank: String = rank_keys[flat_idx % rank_keys.size()]
    var s: Dictionary = tarot_minor_cfg.suits[suit]
    var r: Dictionary = tarot_minor_cfg.ranks[rank]
    var name_fa: String = r.fa + " " + s.fa
    var meaning: String = r.verb + " زمینهٔ " + s.theme + " است: " + s.tone + "ت را درگیر می‌کند."
    var yn := "بله"
    if suit == "swords" and rank in ["five", "seven", "nine", "ten", "S"]:
        yn = "خیر"
    elif suit == "cups" and rank in ["five", "three"]:
        yn = "نامشخص"
    return {"kind": "minor", "id": suit + "_" + rank, "num": "", "name": name_fa, "glyph": s.g,
            "keywords": s.theme, "meaning": meaning, "yn": yn}

func yesno_from_cards(cards: Array) -> String:
    var score := 0
    for c in cards:
        if c.yn == "بله":
            score += 1
        elif c.yn == "خیر":
            score -= 1
    if score > 0:
        return "بله"
    elif score < 0:
        return "خیر"
    return "نامشخص"

# --------------------------------------------------------- coffee
func coffee_draw(count: int = 3) -> Array:
    var idxs := shuffled_indices(coffee_symbols.size())
    var out := []
    for i in range(min(count, coffee_symbols.size())):
        out.append(coffee_symbols[idxs[i]])
    return out

# --------------------------------------------------------- candle
func candle_draw() -> Dictionary:
    var pool: Array = []
    if randf() < 0.55:
        pool = candle.good
    elif randf() < 0.72:
        pool = candle.mid
    else:
        pool = candle.bad
    return pool[randi_range(0, pool.size() - 1)]

# --------------------------------------------------------- pastor (52 cards)
const SUITS_52 := [
    {"k":"H","fa":"دل","g":"♥"},
    {"k":"D","fa":"خشت","g":"♦"},
    {"k":"C","fa":"گشنیز","g":"♣"},
    {"k":"S","fa":"پیک","g":"♠"}
]
const RANKS_52 := [
    {"k":"A","fa":"تک"}, {"k":"2","fa":"دو"}, {"k":"3","fa":"سه"}, {"k":"4","fa":"چهار"},
    {"k":"5","fa":"پنج"}, {"k":"6","fa":"شش"}, {"k":"7","fa":"هفت"}, {"k":"8","fa":"هشت"},
    {"k":"9","fa":"نه"}, {"k":"10","fa":"ده"},
    {"k":"J","fa":"سرباز"}, {"k":"Q","fa":"بی‌بی"}, {"k":"K","fa":"شاه"}
]

func pastor_draw(count: int = 3) -> Array:
    var idxs := shuffled_indices(52)
    var out := []
    for i in range(count):
        var flat: int = idxs[i]
        var suit = SUITS_52[flat / 13]
        var rank = RANKS_52[flat % 13]
        var tone: Dictionary = pastor.suit_tones[suit.k]
        var meaning: String = pastor.rank_meanings[rank.k]
        out.append({"rank": rank.fa, "suit": suit.fa, "glyph": suit.g, "title": rank.fa + " " + suit.fa,
                    "meaning": meaning, "tone": tone.tone, "yn": tone.yn})
    return out

# --------------------------------------------------------- hafez
func hafez_draw() -> Dictionary:
    return hafez[randi_range(0, hafez.size() - 1)]

# --------------------------------------------------------- love
func love_compat() -> int:
    return randi_range(62, 98)

func love_msg() -> Dictionary:
    var r := randf()
    var key := "msg_mid"
    if r < 0.38:
        key = "msg_high"
    elif r > 0.72:
        key = "msg_low"
    var arr: Array = love[key]
    var poem: String = love.poems[randi_range(0, love.poems.size() - 1)]
    return {"compat": love_compat(), "msg": arr[randi_range(0, arr.size() - 1)], "poem": poem}

# ------------------------------------------------- overall reading (تفسیر کلی)
## Each generator weaves the drawn pieces into one closing paragraph so the
## user gets a single, easy-to-understand takeaway at the end of every fortune.

static func _first_clause(text: String) -> String:
    var s := str(text).strip_edges()
    for sep in ["؛", ".", "!", "؟", "\n"]:
        var i := s.find(sep)
        if i > 8:
            s = s.substr(0, i)
            break
    return s.strip_edges()

static func _pick(arr: Array) -> String:
    return str(arr[randi_range(0, arr.size() - 1)])

const _CLOSE_GOOD := [
    "در مجموع، مسیرت روشن است؛ با همین انرژی جلو برو و دست از تصمیمت برندار.",
    "جمع‌بندی: باد از سمتِ خیر می‌وزد؛ ریسک‌های حساب‌شده تو را جلو می‌برد.",
    "نتیجهٔ کلی: نیتت با شرایط فعلی هم‌راه است؛ فقط عجله نکن و قدم‌هایت را محکم بردار."
]
const _CLOSE_MID := [
    "جمع‌بندی: روزهای تو آمیزه‌ای از فرصت و آزمون است؛ صبورتر از همیشه باش.",
    "نتیجهٔ کلی: هیچ‌چیز قطعی نیست، اما دستِ تو کاری می‌کند؛ مشورت را فراموش نکن.",
    "در مجموع، راه باز است ولی پر از پیچ؛ قلب‌ات را آرام نگه دار و یکی‌یکی تصمیم بگیر."
]
const _CLOSE_BAD := [
    "جمع‌بندی: این چیدمان هشدار است، نه حکم؛ عجله را کنار بگذار و صبر را سلاح کن.",
    "نتیجهٔ کلی: بهتر است این روزها کمتر حرف بزنی و بیشتر ببینی؛ بعد از این آرامش، مسیر خودش باز می‌شود.",
    "در مجموع: زمینه هنوز آماده نیست؛ کمی نگه‌داشت و دوباره‌سازی، بهترین حرکتِ توست."
]

static func _closing_by_score(score: int) -> String:
    if score >= 2:
        return _pick(_CLOSE_GOOD)
    elif score <= -2:
        return _pick(_CLOSE_BAD)
    return _pick(_CLOSE_MID)

func overall_yesno(cards: Array, answer: String) -> String:
    var c: Dictionary = cards[0]
    var head := ""
    if answer == "بله":
        head = _pick(["نیتِ تو با جوابِ روشن روبه‌روست؛ این «بله» یعنی زمینهٔ کار فراهم است.", "آسمان سرِ سبز است! این «بله» به تو دلگرمی می‌دهد، اما پشتِ آن یک شرط پنهان است: قدمِ اول را خودت بردار."])
    elif answer == "خیر":
        head = _pick(["این «خیر» ردِ تو نیست؛ یعنی زمان هنوز نرسیده. بعد از یک مکثِ کوتاه، دوباره امتحان کن.", "جواب منفی است اما نه به‌خاطر بی‌ارزشیِ خواسته‌ات؛ زمین هنوز آمادهٔ کاشتن نیست. کمی صبر."])
    else:
        head = _pick(["جواب روشن نیست؛ نشانه‌ها دوپاره‌اند. خودت با یک انتخابِ کوچکِ امروزی، جواب را کامل کن.", "هیچ‌چیز هنوز شکل نگرفته؛ این وسط‌بودن یعنی تصمیم با توست، نه با تقدیر."])
    var line2 := "کارتِ " + str(c.name) + " کنارِ نیتت نشسته: " + _first_clause(str(c.meaning)) + "."
    return head + " " + line2 + " " + _closing_by_score(1 if answer == "بله" else (-1 if answer == "خیر" else 0))

func overall_tarot(cards: Array, roles: Array) -> String:
    var parts := []
    var score := 0
    for i in range(cards.size()):
        var c: Dictionary = cards[i]
        var role: String = str(roles[i]) if i < roles.size() else ""
        if c.yn == "بله":
            score += 1
        elif c.yn == "خیر":
            score -= 1
        parts.append("«" + role + "» با کارتِ " + str(c.name) + " معنا می‌گیرد: " + _first_clause(str(c.meaning)))
    var open := ""
    if score >= 2:
        open = _pick(["این چیدمان عمومی‌اش گرم و همراه است؛ کارت‌ها بیشتر از فرصت حرف می‌زنند تا مانع.", "بیشترِ کارت‌ها رو به روشنی‌اند؛ بسترِ ماجرا به نفعِ توست."])
    elif score <= -2:
        open = _pick(["این چیدمان هشدار می‌دهد اما راهِ خروج را هم نشان می‌دهد؛ نترس، فقط هوشیار باش.", "کارت‌ها سنگین‌اند، ولی سنگینیِ پیام یعنی اهمیتِ لحظه؛ تو در یک نقطهٔ عطف ایستاده‌ای."])
    else:
        open = _pick(["چیدمانت آمیزه‌ای از روشنایی و سایه است؛ مثلِ خودِ زندگی.", "کارت‌ها هم فرصت نشان می‌دهند هم احتیاط؛ تعادل، کلیدِ این فال است."])
    var body := " ".join(PackedStringArray(parts))
    return open + " " + body + ". " + _closing_by_score(score)

func overall_pastor(cards: Array) -> String:
    var parts := []
    var score := 0
    for c in cards:
        var yn: String = str(c.get("yn", ""))
        if yn == "بله":
            score += 1
        elif yn == "خیر":
            score -= 1
        parts.append(str(c.title) + " می‌گوید: " + _first_clause(str(c.meaning)))
    var open := ""
    if score >= 2:
        open = _pick(["ورق‌ها به نفعِ تو افتادند؛ هوا با بادبانِ تو هم‌جهت است.", "سه ورقِ تو دستِ گرم را نشان می‌دهد؛ خبرهای خوش از راهِ نزدیک‌ترند."])
    elif score <= -2:
        open = _pick(["ورق‌ها سنگین افتادند؛ این هفته احتیاط را پیشه کن.", "رنگِ ورق‌ها سرد است؛ عجله نکن، زمانه با عجله تو خوب نمی‌شود."])
    else:
        open = _pick(["ورق‌ها دو رنگ‌اند؛ نیمی از ماجرا دستِ توست و نیمی دستِ روزگار.", "افتِ ورق متعادل است؛ نه جای خوش‌خیالی است، نه جای نگرانی."])
    var body := " ".join(PackedStringArray(parts))
    return open + " " + body + ". " + _closing_by_score(score)

func overall_coffee(symbols: Array) -> String:
    var names := []
    var parts := []
    for s in symbols:
        names.append(str(s.name))
        parts.append(str(s.name) + ": " + _first_clause(str(s.meaning)))
    var head := "فنجانِ تو " + UiKit.fa(symbols.size()) + " نشان دارد: " + "، ".join(PackedStringArray(names)) + "."
    var tail := _pick([
        "در مجموع، فنجان می‌گوید نگاهت را از جزئیات بردار و به قصدِ اصلی‌ات برگرد؛ آن‌جا جواب است.",
        "جمع‌بندیِ فنجان: نشانه‌ها هم‌سوی یک پیام‌اند — دلت را شلوغ نکن، یک قدمِ کوچکِ امروز بهتر از هزار فکرِ فردا است.",
        "در کل، ته‌فنجانت از آینده نمی‌ترساند؛ فقط یادآوری می‌کند که قلبِ صبور، چشمِ تیزبین‌تری دارد."
    ])
    return head + " " + " ".join(PackedStringArray(parts)) + ". " + tail

func overall_candle(interp: Dictionary, polarity: String) -> String:
    var head := ""
    if polarity == "good":
        head = _pick(["شعله‌ات از خانوادهٔ روشن‌هاست؛ نیتت در مسیرِ پذیرش است.", "شمع به نیتِ تو سلام داد؛ نشانه‌ها از جنسِ خیرند."])
    elif polarity == "bad":
        head = _pick(["شعله‌ات پیامِ احتیاط دارد؛ این یعنی بازنگری، نه شکست.", "شمع لرزید تا بگوید: جایی از مسیر، باد مانع است — آن را پیدا کن."])
    else:
        head = _pick(["شعله‌ات میانه است؛ نه وعدهٔ فوری، نه ردِ قطعی.", "پیامِ شمع، صبر است؛ حاجت در راه است ولی هنوز به مقصد نرسیده."])
    return head + " " + _first_clause(str(interp.m)) + ". " + _closing_by_score(2 if polarity == "good" else (-2 if polarity == "bad" else 0))

func overall_hafez(poem: Dictionary) -> String:
    var beyt := str(poem.b).split("|")
    var m1 := str(beyt[0]).strip_edges() if beyt.size() > 0 else ""
    var tail := _pick([
        "جمع‌بندیِ فال: حافظ با تو مهربان است؛ همین که دلت را صاف نگه داشته‌ای، نصفِ راه است.",
        "نتیجهٔ کلی: این غزل می‌گوید دست‌به‌دامنِ تقدیر نباش؛ تو خودت کلیدِ گره‌ای.",
        "در مجموع، فالِ تو فالِ امید است؛ حافظ هیچ‌گاه از بن‌بست حرف نمی‌زند، از انحنا حرف می‌زند."
    ])
    return "هزارتوی این غزل در یک خط: «" + m1 + "». " + _first_clause(str(poem.t)) + ". " + tail

func overall_love(data: Dictionary) -> String:
    var pct := int(data.compat)
    var head := ""
    if pct >= 85:
        head = _pick(["عددها بالاست، ولی یادت باشد این عدد روزِ امروز است، نه حکمِ همیشگی.", "سازگاری‌تان در نقطهٔ خوبی ایستاده؛ چیزِ ارزشمند را با تکرارِ محبت حفظ کن."])
    elif pct >= 72:
        head = _pick(["عددِ میانه یعنی رابطه‌تان زنده و در حالِ ساختن است؛ تصمیم‌های کوچکِ روزانه تفاوت را می‌سازند.", "میانهٔ راه‌اید؛ نه جای نگرانی است، نه جای واپس‌زدن."])
    else:
        head = _pick(["عدد پایین است اما این یعنی «نیازمندِ گفت‌وگو»، نه پایانِ راه.", "این عدد سفیرِ یک گفت‌وگوی معوق است؛ حرفی را که نگفته‌ای، امشب بزن."])
    return head + " " + _closing_by_score(2 if pct >= 85 else (0 if pct >= 72 else -2))
