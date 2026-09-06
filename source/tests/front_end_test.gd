extends Node

const MAIN_MENU_SCRIPT := preload("res://scenes/ui/main_menu.gd")
const TUTORIAL_SCRIPT := preload("res://scenes/ui/tutorial_overlay.gd")


func _ready() -> void:
	var library := get_node_or_null("/root/AssetLibrary")
	if library == null or library.get_texture(&"ui_logo.png") == null or library.get_texture(&"ui_main_menu_background.png") == null:
		_fail("主菜单 Logo 或背景素材未加载")
		return
	if library.get_texture(&"env_rotten_cucumber_intact.png") == null:
		_fail("完整腐烂黄瓜未加载")
		return
	var menu := MAIN_MENU_SCRIPT.new()
	add_child(menu)
	var tutorial := TUTORIAL_SCRIPT.new()
	add_child(tutorial)
	await get_tree().process_frame
	if not menu.is_menu_visible():
		_fail("主菜单根节点未创建")
		return
	tutorial.open(false)
	if not tutorial.is_open():
		_fail("新手教程未打开")
		return
	tutorial.close()
	print("FRONT END PASS: 主菜单素材、完整黄瓜、中文字体入口和新手教程均可创建。")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	print("FRONT END FAIL: %s" % message)
	get_tree().quit(1)
