# 《破晓之种》Godot 灰盒工程

当前完成 `programming.md` 的第 0–7 小时阶段：

- 四向平滑移动，支持 WASD 和方向键。
- 由 Line2D 生成的芽体轨迹。
- 玩家周围局部紫色光照。
- 一张纵向冰箱灰盒关卡与四段高度提示。
- 中途保鲜膜和顶部盒盖的 Space 蓄力交互。
- 默认结局《生长成功，食用失败》。
- 结局后点击按钮或按 R 重新开始。
- Esc 暂停与继续。

## 在 Godot 中运行

1. 打开 Godot Project Manager。
2. 点击 **Import**。
3. 选择本目录中的 `project.godot`。
4. 确认 Renderer 为 Compatibility。
5. 点击右上角运行按钮或按 F6/F5。

## 操作

- WASD / 方向键：移动芽尖。
- Space：靠近半透明横向障碍时长按蓄力。
- Esc：暂停或继续。
- R：进入结局后重新开始。

沿通道持续向上，在第二幕长按 Space 撕开保鲜膜；到达顶部后再次长按 Space 顶开盒盖，即可进入默认结局。

## 命令行检查

Godot 加入 PATH 后，在 `program` 目录执行：

```powershell
godot --headless --path source --editor --quit
godot --headless --path source --script res://tests/smoke_test.gd
godot --headless --path source --scene res://tests/gameplay_flow_test.tscn
```

若 Godot 没有加入 PATH，请将 `godot` 替换为实际 exe 的完整路径。
