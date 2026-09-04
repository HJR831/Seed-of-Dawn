# 《破晓之种》Godot 灰盒工程

当前已完成 `programming.md` 的第 0–13 小时阶段。

## 已完成

- 四向平滑移动、Line2D 芽体轨迹、局部光照和纵向相机。
- 从出生点通往盒盖的纵向灰盒关卡、保鲜膜蓄力和默认结局 01。
- 黏液来源化减速、冰霜减速与霜化变色、硬障碍重撞反馈。
- 通用 E 短按/长按交互和进入范围自动拾取；对象均保证只成功一次。
- `GameState` 本局行为值、道具、计数器、旗标、仪式、信号与快照 API。
- CSV 驱动的四阶段叙事触发、串行文本队列、打字机显示和跳字。
- Music、Ambience、SFX、UI 四条音频总线；程序占位音与明确的压缩机启动计数。
- 仅 Debug 构建可用的 F3 状态面板、四阶段传送和快速修改按钮。
- Esc 暂停、结局后 R 重开；重开会清空本局状态。

## 在 Godot 中运行

1. 使用 Godot 4.7.2 Standard 导入本目录中的 `project.godot`。
2. 确认 Renderer 为 Compatibility。
3. 点击运行按钮或按 F6/F5。

## 操作

- WASD / 方向键：移动芽尖。
- E：在生命体附近轻按帮助，长按约 0.8 秒吸收。
- Space：靠近半透明障碍时蓄力；文本显示时立即显示全文/继续。
- F3：打开调试面板，可传送并检查本局状态。
- Esc：暂停或继续。
- R：进入结局后重新开始。

试玩基础系统时，可在第一幕寻找黄色日期石片、绿色沉睡者和大片黏液；第三幕右侧有冰霜区。沿通道向上仍可在 2–3 分钟内触发默认结局。

## 命令行检查

在 `source` 目录执行：

```powershell
godot --headless --path . --script res://tests/smoke_test.gd
godot --headless --path . --scene res://tests/basic_systems_test.tscn
godot --headless --path . --scene res://tests/gameplay_flow_test.tscn
```

若 Godot 没有加入 PATH，请使用 `D:\App\Godot\Godot_v4.7.2-stable_win64.exe`。
