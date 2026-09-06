class_name PixelUITheme
extends RefCounted

## Program-only UI language: square corners, stepped borders and a restrained
## indigo/steel palette matching the delivered refrigerator pixel art.

const INK := Color(0.018, 0.027, 0.055, 0.96)
const INK_LIGHT := Color(0.045, 0.066, 0.105, 0.96)
const STEEL := Color(0.25, 0.34, 0.48, 1.0)
const VIOLET := Color(0.58, 0.31, 0.82, 1.0)
const TEXT := Color(0.88, 0.92, 1.0, 1.0)
const FONT_PATH := "res://assets/fonts/NotoSerifSC-VF.ttf"

static var _font_cache: Font


static func get_font() -> Font:
	if is_instance_valid(_font_cache):
		return _font_cache
	if ResourceLoader.exists(FONT_PATH):
		_font_cache = load(FONT_PATH) as Font
	return _font_cache


static func panel_style(fill: Color = INK, border: Color = STEEL, border_width: int = 4, shadow: bool = true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	if shadow:
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.62)
		style.shadow_size = 4
		style.shadow_offset = Vector2(4, 4)
	return style


static func apply_panel(panel: Control, fill: Color = INK, border: Color = STEEL, border_width: int = 4) -> void:
	panel.add_theme_stylebox_override("panel", panel_style(fill, border, border_width))
	var font := get_font()
	if font != null:
		panel.add_theme_font_override("font", font)


static func apply_button(button: Button, accent: Color = VIOLET) -> void:
	button.add_theme_stylebox_override("normal", panel_style(Color(0.035, 0.050, 0.082, 0.98), Color(accent, 0.62), 2, false))
	button.add_theme_stylebox_override("hover", panel_style(Color(0.070, 0.080, 0.130, 1.0), accent, 3, false))
	button.add_theme_stylebox_override("pressed", panel_style(Color(0.11, 0.055, 0.15, 1.0), accent.lightened(0.18), 3, false))
	button.add_theme_stylebox_override("focus", panel_style(Color(0.055, 0.065, 0.11, 1.0), Color(0.92, 0.76, 1.0), 2, false))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.88, 0.52))
	button.add_theme_font_size_override("font_size", 15)
	var font := get_font()
	if font != null:
		button.add_theme_font_override("font", font)


static func apply_progress(bar: ProgressBar, accent: Color = Color(0.92, 0.72, 0.24)) -> void:
	bar.add_theme_stylebox_override("background", panel_style(Color(0.018, 0.025, 0.045, 1.0), Color(0.20, 0.28, 0.40), 2, false))
	bar.add_theme_stylebox_override("fill", panel_style(accent.darkened(0.12), accent.lightened(0.18), 2, false))


static func apply_title(label: Label, color: Color = Color(0.82, 0.64, 1.0)) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.015, 0.03, 1.0))
	label.add_theme_constant_override("outline_size", 3)
	var font := get_font()
	if font != null:
		label.add_theme_font_override("font", font)
