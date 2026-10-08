@tool
extends EditorPlugin
## Godot EditorExportPlugin packaging for the IrServices Android plugin
## (Godot 4.4+ replaced .gdap files with this mechanism).

var export_plugin: AndroidExportPlugin


func _enter_tree() -> void:
    export_plugin = AndroidExportPlugin.new()
    add_export_plugin(export_plugin)


func _exit_tree() -> void:
    remove_export_plugin(export_plugin)
    export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
    var _plugin_name := "IrServices"

    func _get_name() -> String:
        return _plugin_name

    func _supports_platform(platform) -> bool:
        if platform is EditorExportPlatformAndroid:
            return true
        return false

    func _get_android_libraries(platform, debug: bool) -> PackedStringArray:
        return PackedStringArray(["IrServices/IrServicesPlugin.aar"])

    ## Tapsell Mediation SDK (rewarded video) — resolved by the gradle
    ## build from Maven Central so all transitive libs are included.
    func _get_android_dependencies(platform, debug: bool) -> PackedStringArray:
        return PackedStringArray(["ir.tapsell:tapsell:1.3.0"])
