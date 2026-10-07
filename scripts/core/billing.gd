extends Node
## Billing: coin-pack purchases. Backends:
##  - "test": simulated gateway dialog (works everywhere, no plugin needed)
##  - "bazaar"/"myket": In-App Billing v3 via the IrServices Android plugin
##    (binds to the store's billing service by package name).

signal purchase_ok(pack_key: String)
signal purchase_fail(reason: String)

var plugin = null          # IrServices JavaPlugin singleton (Android only)
var vendor := "test"

const VENDOR_PKGS := {
    "bazaar": "com.farsitel.bazaar",
    "myket": "ir.mservices.market"
}
const PACK_SKUS := {   # SKU id created in the store console
    "pack_1": "coin_50",
    "pack_2": "coin_150",
    "pack_3": "coin_300"
}

func _ready() -> void:
    vendor = Rates.vendor()
    if OS.has_feature("android"):
        if Engine.has_singleton("IrServices"):
            plugin = Engine.get_singleton("IrServices")
            var pkg: String = VENDOR_PKGS.get(vendor, "")
            if pkg != "" and plugin.has_method("initialize"):
                plugin.initialize(pkg)
            if plugin.has_signal("purchase_done"):
                plugin.purchase_done.connect(_on_plugin_purchase)
        elif Rates.is_store_build():
            push_warning("IrServices plugin missing; billing falls back to test mode")

func plugin_ready() -> bool:
    return plugin != null and Rates.is_store_build()

## pack_key: "pack_1" | "pack_2" | "pack_3"; on_ok() / on_fail(why) callables.
func start_purchase(pack_key: String, coins: int, price_toman: int, on_ok: Callable, on_fail: Callable) -> void:
    if not plugin_ready() or vendor == "test":
        _simulate_gateway(pack_key, coins, price_toman, on_ok, on_fail)
    else:
        _pending_ok = on_ok
        _pending_fail = on_fail
        _pending_pack = pack_key
        var sku: String = PACK_SKUS.get(pack_key, pack_key)
        plugin.purchase(sku)

var _pending_ok: Callable
var _pending_fail: Callable
var _pending_pack := ""

func _on_plugin_purchase(result_json: String) -> void:
    var data = JSON.parse_string(result_json)
    var ok := false
    var why := "پرداخت انجام نشد"
    if data != null and data is Dictionary:
        if int(data.get("code", -1)) == 0 and str(data.get("token", "")) != "":
            ok = true
        else:
            why = str(data.get("msg", why))
    if ok:
        purchase_ok.emit(_pending_pack)
        if _pending_ok.is_valid():
            _pending_ok.call()
    else:
        purchase_fail.emit(why)
        if _pending_fail.is_valid():
            _pending_fail.call(why)
    _pending_pack = ""

## Test-mode gateway: a small awaitable simulated flow (sandbox builds only).
func _simulate_gateway(pack_key: String, coins: int, price_toman: int, on_ok: Callable, on_fail: Callable) -> void:
    var dialog := preload("res://scripts/ui/billing_dialog.gd").new(coins, price_toman)
    get_tree().root.add_child(dialog)
    var result: int = await dialog.run()
    dialog.queue_free()
    if result == 1:
        purchase_ok.emit(pack_key)
        if on_ok.is_valid():
            on_ok.call()
    else:
        purchase_fail.emit("پرداخت لغو شد")
        if on_fail.is_valid():
            on_fail.call("پرداخت لغو شد")
