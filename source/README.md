# 《破晓之种》Godot 灰盒工程

当前已完成 `programming.md` 的第 0–47 小时程序阶段，改动暂未提交或推送。

## 已完成

- 25600×25600 的自底向上地图；出生点位于底部中央，每局按 Seed 生成七个垂直生态层、12–16 个主题扇区、三条独立上下路线、区域、道具和入口。
- 1280 px 逻辑分块管理远处装饰；不生成环墙，只保留四条世界外边界碰撞，地图重建流程仍由固定 Seed 验证。
- 四向移动、Line2D 芽体轨迹、局部光照、材质反馈、碰撞、暂停和重新开始。
- I / Tab 本局背包，显示道具分类、神话名称、数量信息及解锁后的现实名称。
- 道具效果由 `ItemEffectDirector` 统一管理；背包显示效果与来源，危险区域和疾跑状态通过环境与交互反馈表达。
- 左上角知识小地图；按 M 打开完整地图，包含战争迷雾、已发现地标和方向/扇区/估计/准确四级剧情标记。
- 数据驱动动态提示、中央神谕、“启示”重读页，以及三遗物顺序和乱序兼容。
- 结局 01–03：默认土豆、万芽之主和奶龙降生。
- 结局 04–08：真正的破晓、保鲜层自治森林、无限增长有限公司、永冬胚种和 ROOT 权限。
- 结局 09–12：紫冠的新芽、不见天日的丰收、今天不长和垃圾大陆之王。
- 结局集中判定、通用结局画面、12/12 图鉴兼容和 `user://save_data.cfg` 永久存档。
- 100 个固定种子的复现、三路线、分块、关键顺序、区域/碰撞重叠和仪式净空回归测试。
- `assets/image` 扁平图片库与 `assets/audio` 三类音频库已接入；结局插画等缺失文件自动使用程序占位，素材替换不影响启动。
- UI、粒子和所有状态/屏幕覆盖层已统一改为程序像素绘制；右上角玩家键位提示直接使用 `ui_key_*.png`，角色、场景、道具和结局插画仍由 `AssetLibrary` 接入。
- 玩家移动使用七套生态层配色的程序像素尾粒；疾跑提高粒子数量和拖尾距离，道具状态色会与层级色混合。
- 层间 400px 过渡缝使用混合色和背板纹理实体填充，不再露出黑色底图；移动尾粒使用更大的高亮阶梯像素，保证在游戏缩放下可见。
- 拾取物会显示图文详情卡，背包条目可点击打开相同详情；首次启动进入主菜单，开始游戏后提供可跳过的六步新手教程。
- 主菜单直接接入 `ui_logo.png`、`ui_main_menu_background.png`；全局中文 UI 使用 `NotoSerifSC-VF.ttf` 史诗感衬线字体。
- 拾取和交互已统一消除 E 键时长死区；重复获得的唯一道具会让世界副本自动退场，不再留下不可拾取的假目标。

## 在 Godot 中运行

1. 使用 Godot 4.7.2 Standard 导入本目录中的 `project.godot`。
2. 确认 Renderer 为 Compatibility。
3. 点击运行按钮或按 F6/F5。

## 操作

- WASD / 方向键：移动芽尖。
- 按住 Shift：短时疾跑；仪式、入口长按和剧情锁定期间自动禁用。
- E：观察、帮助、操作仪器或按入口提示长按。
- Space：保鲜膜和盒盖蓄力；文本显示时用于跳字。
- I / Tab：打开或关闭本局背包；背包打开时 Esc 优先关闭背包。
- M：打开或关闭完整地图；地图与背包互斥。
- Esc：暂停或继续。
- R：结局后重新开始。
- U：打开或关闭右上角完整键位提示；右下角会持续显示疾跑耐力槽。
- F3：输入开发者 UID `wutiaowu831` 后打开 Godot 调试测试面板（仅 Debug 运行可用）。

开场氛围音乐结束后，背景音乐按玩家所在生态层自动切换到 `background/01`–`07`，并与独立的拾取、交互和环境音效同时播放。

最终大地图、动态提示、四个新结局和快速验收步骤见 `docs/phase_32_39_test_guide.md`。

Windows x86_64 Release 导出预设位于 `export_presets.cfg`；导出文件和运行说明见
上一级 `release/`，完整工程包可直接在 Godot 4.7.2 Standard 中导入本目录。

## 命令行检查

在 `source` 目录执行：

```powershell
godot --headless --path . --script res://tests/smoke_test.gd
godot --headless --path . --scene res://tests/basic_systems_test.tscn
godot --headless --path . --script res://tests/procedural_map_test.gd
godot --headless --path . --script res://tests/ending_resolver_test.gd
godot --headless --path . --scene res://tests/phase_13_20_test.tscn
godot --headless --path . --scene res://tests/phase_20_32_test.tscn
godot --headless --path . --scene res://tests/phase_20_endings_flow_test.tscn
godot --headless --path . --scene res://tests/phase_32_39_test.tscn
godot --headless --path . --scene res://tests/phase_32_endings_flow_test.tscn
godot --headless --path . --scene res://tests/ending_screen_test.tscn
godot --headless --path . --scene res://tests/save_roundtrip_test.tscn
godot --headless --path . --scene res://tests/gameplay_flow_test.tscn
godot --headless --path . --scene res://tests/interaction_audit_test.tscn
godot --headless --path . --scene res://tests/front_end_test.tscn
```

若 Godot 没有加入 PATH，请使用 `D:\App\Godot\Godot_v4.7.2-stable_win64.exe`。
