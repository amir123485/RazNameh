extends Node
## Sfx: sounds + vibration (respects user's sound/vibe toggles).

var _streams: Dictionary = {}
var _ambient_player: AudioStreamPlayer = null

const SOUNDS := [
    "click", "flip", "coin", "chime", "whoosh", "flame", "reward", "page", "heart"
]

func _ready() -> void:
    for s in SOUNDS:
        var path := "res://assets/audio/%s.wav" % s
        if ResourceLoader.exists(path):
            _streams[s] = load(path)

func play(name: String, volume_db: float = -6.0) -> void:
    if not Save.sound_on or not _streams.has(name):
        return
    var p := AudioStreamPlayer.new()
    p.stream = _streams[name]
    p.volume_db = volume_db
    p.bus = "Master"
    add_child(p)
    p.finished.connect(p.queue_free)
    p.play()

func ambient_on() -> void:
    if not Save.sound_on or _ambient_player != null:
        return
    var path := "res://assets/audio/ambient_loop.wav"
    if not ResourceLoader.exists(path):
        return
    _ambient_player = AudioStreamPlayer.new()
    var st: AudioStream = load(path)
    if st is AudioStreamWAV:
        st.loop_mode = AudioStreamWAV.LOOP_FORWARD
        st.loop_end = st.data.size() / 2   # 16-bit mono
    _ambient_player.stream = st
    _ambient_player.volume_db = -16.0
    add_child(_ambient_player)
    _ambient_player.play()

func ambient_off() -> void:
    if _ambient_player != null:
        _ambient_player.stop()
        _ambient_player.queue_free()
        _ambient_player = null

func vibe(ms: int = 25) -> void:
    if Save.vibe_on and OS.has_feature("android"):
        Input.vibrate_handheld(ms)
