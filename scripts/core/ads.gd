extends Node
## Ads: rewarded video for coins. Backends:
##  - "test": simulated countdown ad (sandbox/personal build)
##  - store builds: Tapsell rewarded via IrServices plugin; graceful
##    simulated fallback if the plugin or key is missing.

signal ad_reward(coins: int)
signal ad_failed(reason: String)

var plugin = null
var busy := false

func _ready() -> void:
    if OS.has_feature("android") and Engine.has_singleton("IrServices"):
        plugin = Engine.get_singleton("IrServices")
        if plugin.has_signal("ad_rewarded"):
            plugin.ad_rewarded.connect(_on_rewarded)
        if plugin.has_signal("ad_failed"):
            plugin.ad_failed.connect(_on_ad_failed)

func plugin_ready() -> bool:
    var key: String = str(Rates.rate("tapsell_app_key"))
    return plugin != null and key != "" and plugin.has_method("show_rewarded_ad")

func cooldown_active() -> bool:
    return Time.get_ticks_msec() < Save.ad_cooldown_until

func can_show() -> bool:
    return not busy and not cooldown_active()

## Shows a rewarded ad; grants Rates.ad_reward coins on completion.
func show_rewarded() -> void:
    if busy:
        return
    busy = true
    var reward := int(Rates.rate("ad_reward"))
    if plugin_ready():
        plugin.show_rewarded_ad(str(Rates.rate("tapsell_app_key")), str(Rates.rate("tapsell_ad_unit")))
    else:
        _simulate(reward)

func _finish(reward: int) -> void:
    busy = false
    Save.ad_cooldown_until = Time.get_ticks_msec() + int(Rates.rate("ad_cooldown_sec")) * 1000
    Save.save_all()
    Save.add_coins(reward)
    ad_reward.emit(reward)

func _on_rewarded(coins: int) -> void:
    _finish(coins if coins > 0 else int(Rates.rate("ad_reward")))

func _on_ad_failed(reason: String) -> void:
    busy = false
    ad_failed.emit(reason)

## Simulated ad screen: 5s countdown then reward (used in test build and
## as graceful fallback when Tapsell key/plugin is not configured yet).
func _simulate(reward: int) -> void:
    var layer := preload("res://scripts/ui/sim_ad_screen.gd").new()
    get_tree().root.add_child(layer)
    var done: int = await layer.run()
    layer.queue_free()
    if done == 1:
        _finish(reward)
    else:
        busy = false
        ad_failed.emit("تبلیغ بسته شد")
