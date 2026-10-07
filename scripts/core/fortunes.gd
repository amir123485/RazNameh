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
