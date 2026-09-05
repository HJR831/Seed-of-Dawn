# 第 20–32 小时版本测试指南

## 本阶段内容

- 8192×8192 中心向外圆形地图；每局生成 8–12 个扇区、三层生态环墙、两条以上环门通路。
- `RUN SEED` 决定地图、区域、道具和入口位置；F3 可用同一 Seed 重开复现，也可生成新 Seed。
- I 或 Tab 打开本局背包，Esc 优先关闭背包。
- 保留结局 01–03，并加入结局 04–08。

## 快速验证五个新结局

按 F3 打开调试面板。每条路线先点击“给予……配方”，再点击对应“到 0X ……入口”。关闭 F3 后按入口提示操作。

1. 04《真正的破晓》：给予真正破晓配方 → 到 04 暖门缝 → 长按 E。
2. 05《保鲜层自治森林》：给予自治森林配方 → 到 05 根网出口 → 长按 E。
3. 06《无限增长有限公司》：给予无限增长配方 → 到 06 条码终端 → 长按 E。
4. 07《永冬胚种》：给予永冬配方 → 到 07 冷冻凹槽 → 松开移动键并静止。
5. 08《ROOT 权限》：给予 ROOT 配方 → 到 08 温控探针 → 长按 E。

每个结局出现后按 R 重开。永久结局图鉴应从 3/12 逐步增加到 8/12，本局背包和行为数据应清空。

## 自然路线检查重点

- 出生点位于地图中心，向外穿过三道有缺口的生态环墙；不再按“从底走到顶”探索。
- 同一个 Seed 重开时，道具、区域和入口位置应完全一致；新 Seed 重开时应明显变化。
- 所有彩色菱形道具都应在墙体外侧可接近，不应压在墙、危险区或仪式标记里。
- 赤柱、黄色瓶盖、根网与自身成环仪式的四个标记都应可进入。
- 温控旋钮轻按 E 七次；ROOT 三节点按 I、II、II、III 的顺序分别按 E。
- 冷冻胚种区域需要静止约 12 秒完成一次压缩机周期。
- 先到外环再返回内环会记录“终点解锁后回头”，用于无限增长路线。

## 自动测试

在 `source` 目录运行：

```powershell
godot --headless --path . --script res://tests/procedural_map_test.gd
godot --headless --path . --scene res://tests/phase_20_32_test.tscn
godot --headless --path . --scene res://tests/phase_20_endings_flow_test.tscn
godot --headless --path . --script res://tests/ending_resolver_test.gd
godot --headless --path . --scene res://tests/ending_screen_test.tscn
godot --headless --path . --scene res://tests/gameplay_flow_test.tscn
```

若遇到地图或道具问题，请同时记录 HUD 上的 `RUN SEED`。
