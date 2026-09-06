# 素材接入目录

运行时素材从项目外的 `program/image` 和 `program/audio` 同步到这里，Godot 只从 `res://assets/` 读取：

- `image/`：扁平目录中的运行时 PNG，不再按 C1/C2 建子目录。
- `audio/ambience/`：环境循环 OGG。
- `audio/music/`：音乐 OGG/WAV。
- `audio/background/`：七层生态背景音乐（01–07），按玩家所在层循环切换。
- `audio/sfx/`：短音效 WAV/OGG。
- `fonts/`：运行时中文字体及许可证说明；当前使用 `NotoSerifSC-VF.ttf`。

`autoload/asset_library.gd` 负责角色、环境、道具、主菜单 Logo/背景和结局插画的图片缓存与查找；`autoload/audio_manager.gd` 会自动扫描音频目录并按文件名注册。UI、粒子、柔光与状态/屏幕覆盖层全部由程序像素绘制，主菜单只读取明确接入的 `ui_logo.png` 与 `ui_main_menu_background.png`；其他 `ui_`、`vfx_` 图片仅作为历史参考保留。其他素材缺失时继续使用程序占位，不会阻止启动。
