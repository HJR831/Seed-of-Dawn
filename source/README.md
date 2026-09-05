# 《破晓之种》Godot 灰盒工程

当前已完成 `programming.md` 的第 0–32 小时阶段，暂未提交或推送。

## 已完成

- 8192×8192 的中心向外圆形地图；每局按 Seed 生成 8–12 个扇区、生态环通路、区域、道具和入口。
- 四向移动、Line2D 芽体轨迹、局部光照、材质反馈、碰撞、暂停和重新开始。
- I / Tab 本局背包，显示道具分类、神话名称、数量信息及解锁后的现实名称。
- 结局 01–03：默认土豆、万芽之主和奶龙降生。
- 结局 04–08：真正的破晓、保鲜层自治森林、无限增长有限公司、永冬胚种和 ROOT 权限。
- 结局集中判定、通用结局画面、8/12 图鉴兼容和 `user://save_data.cfg` 永久存档。
- 100 个固定种子的复现、关键顺序、区域/碰撞重叠和仪式净空回归测试。

## 在 Godot 中运行

1. 使用 Godot 4.7.2 Standard 导入本目录中的 `project.godot`。
2. 确认 Renderer 为 Compatibility。
3. 点击运行按钮或按 F6/F5。

## 操作

- WASD / 方向键：移动芽尖。
- E：观察、帮助、操作仪器或按入口提示长按。
- Space：保鲜膜和盒盖蓄力；文本显示时用于跳字。
- I / Tab：打开或关闭本局背包；背包打开时 Esc 优先关闭背包。
- F3：调试面板，可给予八条结局配方、传送入口、复现或更换 Seed。
- Esc：暂停或继续。
- R：结局后重新开始。

自然路线、五个新结局和快速验收步骤见 `docs/phase_20_32_test_guide.md`。

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
godot --headless --path . --scene res://tests/ending_screen_test.tscn
godot --headless --path . --scene res://tests/save_roundtrip_test.tscn
godot --headless --path . --scene res://tests/gameplay_flow_test.tscn
```

若 Godot 没有加入 PATH，请使用 `D:\App\Godot\Godot_v4.7.2-stable_win64.exe`。
