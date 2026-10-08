extends Node
## Notif: daily local notifications (2×/day) via the IrServices Android plugin.
## Messages cycle through a shuffled pool so the user doesn't see repeats.
## On desktop/headless this is a no-op.

const MSGS_PATH := "res://data/notify_msgs.json"
const HOUR_1 := 11   # 11:00
const MIN_1 := 0
const HOUR_2 := 21   # 21:00
const MIN_2 := 0

var plugin = null

func _ready() -> void:
    if OS.has_feature("android") and Engine.has_singleton("IrServices"):
        plugin = Engine.get_singleton("IrServices")
        if plugin.has_method("ensure_notif_channel"):
            plugin.ensure_notif_channel()
        apply()

## Re-apply current setting: schedule when on, cancel when off.
func apply() -> void:
    if plugin == null:
        return
    if Save.notif_on:
        var msgs := load_msgs()
        if msgs.is_empty():
            return
        if plugin.has_method("request_notif_permission"):
            plugin.request_notif_permission()
        if plugin.has_method("schedule_daily_notifs"):
            var joined := "\u0001".join(msgs)
            plugin.schedule_daily_notifs(HOUR_1, MIN_1, HOUR_2, MIN_2, joined)
    else:
        if plugin.has_method("cancel_notifs"):
            plugin.cancel_notifs()

func load_msgs() -> PackedStringArray:
    var out := PackedStringArray()
    var f := FileAccess.open(MSGS_PATH, FileAccess.READ)
    if f == null:
        return out
    var parsed = JSON.parse_string(f.get_as_text())
    if parsed is Dictionary and parsed.has("msgs") and parsed.msgs is Array:
        for m in parsed.msgs:
            var s := str(m).strip_edges()
            if s != "":
                out.append(s)
    return out
