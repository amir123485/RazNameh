class_name UiKit
extends RefCounted
## Static theme + widget builders for RazNameh (dark mystic, gold accents).

const BG := Color("120f20")
const PANEL := Color("1c1730")
const PANEL2 := Color("241d3d")
const GOLD := Color("d4af6a")
const PURPLE := Color("8a6bc1")
const INK := Color("efe9da")
const DIM := Color("9a91ad")
const GOOD := Color("7fc98f")
const BAD := Color("c97f7f")
const LINE := Color("3a3160")

## Global UI scale (user feedback: everything was too small → +30%).
const SCALE := 1.3

static func fs(size: int) -> int:
    return int(round(size * SCALE))

static func font(bold: bool = false, size: int = 22) -> FontFile:
    var path := "res://assets/fonts/vazir/Vazirmatn-Bold.ttf" if bold else "res://assets/fonts/vazir/Vazirmatn-Regular.ttf"
    if not ResourceLoader.exists(path):
        path = "res://assets/fonts/DejaVuSans.ttf"
    var f: FontFile = load(path)
    if f != null and f.fallbacks.is_empty():
        var dv: FontFile = load("res://assets/fonts/DejaVuSans.ttf")
        if dv != null:
            f.fallbacks = [dv]
    return f

static func label(text: String, size: int = 22, color: Color = INK, bold: bool = false, wrap: bool = false) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_override("font", font(bold))
    l.add_theme_font_size_override("font_size", fs(size))
    l.add_theme_color_override("font_color", color)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    if wrap:
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l.custom_minimum_size = Vector2(0, 0)
    return l

static func panel_style(bg: Color = PANEL, radius: int = 18, border: Color = LINE) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.set_corner_radius_all(radius)
    sb.border_width_left = 1
    sb.border_width_right = 1
    sb.border_width_top = 1
    sb.border_width_bottom = 1
    sb.border_color = border
    sb.content_margin_left = 18
    sb.content_margin_right = 18
    sb.content_margin_top = 13
    sb.content_margin_bottom = 13
    return sb

static func button(text: String, size: int = 22, accent: Color = GOLD, dark_text: bool = false) -> Button:
    var b := Button.new()
    b.text = text
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_override("font", font(true))
    b.add_theme_font_size_override("font_size", fs(size))
    var fg := BG if dark_text else INK
    b.add_theme_color_override("font_color", fg)
    b.add_theme_color_override("font_pressed_color", fg)
    b.add_theme_color_override("font_hover_color", fg)
    b.add_theme_color_override("font_disabled_color", DIM)
    var sb := panel_style(accent, 16, accent)
    sb.content_margin_top = 16
    sb.content_margin_bottom = 16
    var sb2 := panel_style(accent.lightened(0.12), 16, accent)
    sb2.content_margin_top = 16
    sb2.content_margin_bottom = 16
    var sb3 := panel_style(PANEL2, 16, LINE)
    sb3.content_margin_top = 16
    sb3.content_margin_bottom = 16
    b.add_theme_stylebox_override("normal", sb)
    b.add_theme_stylebox_override("hover", sb2)
    b.add_theme_stylebox_override("pressed", sb2)
    b.add_theme_stylebox_override("disabled", sb3)
    b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    return b

static func ghost_button(text: String, size: int = 20) -> Button:
    var b := button(text, size, PANEL2)
    return b

static func panel(bg: Color = PANEL) -> PanelContainer:
    var p := PanelContainer.new()
    p.add_theme_stylebox_override("panel", panel_style(bg))
    return p

static func hspacer() -> Control:
    var c := Control.new()
    c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    c.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return c

## Make touch-drag scroll work from anywhere inside a ScrollContainer.
## Godot gives the touch to the topmost STOP control (panels!) which then
## eats the drag, so the page only scrolled via the scrollbar thumb.
## Everything non-interactive becomes MOUSE_FILTER_IGNORE so the drag
## falls through to the ScrollContainer itself. Buttons / LineEdits /
## sliders keep working (they stay interactive).
static func scroll_friendly(root: Node) -> void:
    for c in root.get_children():
        if c is Control:
            var interactive := (c is Button) or (c is LineEdit) \
                or (c is Slider) or (c is ScrollBar)
            if not interactive:
                c.mouse_filter = Control.MOUSE_FILTER_IGNORE
        scroll_friendly(c)

static func fa(n) -> String:
    return Rates.fa_num(n)

static func price_tag(price: int) -> String:
    if price <= 0:
        return "رایگان"
    return "🪙 " + fa(price)
