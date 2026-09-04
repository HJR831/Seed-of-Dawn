# 《破晓之种》程序开发执行方案

> 面向第一次接触游戏开发的程序负责人。本文不是概念建议，而是可以逐项执行和验收的开发清单。  
> 技术基线：Godot 4.7.2 Standard、GDScript、Compatibility 渲染器、Windows x86_64、1280×720。  
> 内容基线：关卡流程参考《破晓之种_剧情与玩法策划.md》，结局数量和条件以 `ending.md` 中十二个正式结局为准；旧文档里的“三结局按线索数量划分”不再进入程序实现。  
> 目标：先做出一条可从开场玩到默认结局的完整竖切，再用同一套系统接入另外十一个结局。

---

## 1. 程序工作能否主要交给 Agent

可以。只要 Godot 工程和素材位于当前共享工作文件夹中，Agent 可以承担绝大多数可落到文件或命令行的工作：

- 创建 Godot 项目、目录、场景、脚本、资源和导出配置。
- 编写玩家移动、芽体轨迹、相机、碰撞、障碍、交互、文本、音频和存档系统。
- 实现十二结局的状态记录、条件判定、演出入口和结局图鉴。
- 生成占位素材和调试界面，使程序不必等待正式美术。
- 读取 Godot 报错、修复脚本、运行无界面检查和自动化测试。
- 整理 Git 提交、`.gitignore`、构建脚本、发布目录和编译说明。
- 在素材到位后批量替换引用、检查缺失文件和重复资源。

你仍然需要亲自负责或最终确认以下事项：

- 第一次在本机打开工程，并在 Godot 编辑器中确认字体、画面、音量和手感是否符合预期。
- 告诉 Agent Godot 可执行文件的绝对路径，或把 Godot 加入系统 `PATH`，否则 Agent 不能直接通过命令行运行工程。
- 登录 Git 托管平台、Game Jam 官网及其他外部账号，处理验证码、权限邀请和最终提交。
- 与队友确认玩法取舍、正式素材版本、著作权和第三方许可证。
- 用真实玩家完成试玩。自动测试能检查逻辑，但无法代替“是否好玩、提示是否看得懂”的判断。
- 在比赛截止前亲自确认最终 ZIP 可以下载、解压和运行。

最适合的合作方式是：Agent 连续完成一个阶段并提交可运行版本，你只需打开游戏试玩 3–10 分钟，反馈“哪里不好玩或看不懂”，Agent 再继续调整。

---

## 2. 你还需要准备什么

### 2.1 必须准备

- **Godot 版本统一**：全队使用完全相同的 Godot 4.7.2 Standard。不要有人使用 Mono/C# 版、有人使用 Standard 版，也不要比赛中途升级引擎。
- **Godot 路径**：已定位并验证 `D:\App\Godot\Godot_v4.7.2-stable_win64.exe`。它暂未加入 Windows `PATH`，但 Agent 可以直接使用绝对路径运行检查；加入 `PATH` 只是方便操作，不再是阻塞项。
- **Git 身份**：执行一次 `git config --global user.name "你的昵称"` 和 `git config --global user.email "你的邮箱"`。邮箱可以使用 GitHub 提供的隐私邮箱。
- **远程仓库**：在 GitHub、Gitee 或 GitLab 建立团队仓库，将其他成员设为协作者。比赛中本机文件不是备份，至少要有一个远程副本。
- **素材交付约定**：让美术和音频按 `need.md` 的英文文件名、格式和透明通道要求交付。程序引用路径一旦确定，后续不要随意改文件名。
- **中文字体及许可证**：至少准备一套可再分发的中文 `.ttf` 或 `.otf`，并保留许可证文件，否则导出后其他电脑可能显示方框。
- **测试电脑**：至少准备另一台没有安装 Godot 的 Windows 电脑，在截止前测试最终导出包。

### 2.2 推荐准备

- **代码编辑器**：Godot 内置编辑器已经够用；也可以安装 VS Code 和 Godot Tools 扩展，但不是必需条件。
- **Git 图形客户端**：小白可使用 GitHub Desktop 查看改动和解决简单冲突；命令行仍由 Agent 处理即可。
- **耳机和普通扬声器**：两种设备都要试听，避免低频冰箱声在普通电脑上完全听不见。
- **手柄**：本届版本不必强制支持。键盘玩法稳定后还有时间再加。
- **Git LFS**：只有在仓库中提交大量 `.psd`、`.kra`、高质量 `.wav` 时才需要。若未安装 LFS，尽量不要把数百 MB 的源文件反复提交。
- **录屏工具**：Windows 截图或 OBS 均可，用于记录 Bug 和制作宣传短视频；不是程序开发的前置条件。

### 2.3 不需要准备

- 不需要购买 Godot 插件或商业框架。
- 不需要数据库、服务器或联网后端。
- 不需要 Blender、复杂骨骼动画工具或物理插件。
- 不需要先学完 GDScript。代码由 Agent 编写，你只要会运行场景、查看报错和描述体验问题。

---

## 3. 技术方案总览

### 3.1 为什么选择 Godot + GDScript

- 项目是小型 2D 游戏，Godot 的场景、碰撞、动画、音频和 UI 已经足够。
- GDScript 语法短，修改后启动速度快，适合 48 小时迭代。
- Standard 版无需配置 .NET SDK，可减少环境问题。
- Compatibility 渲染器对旧电脑和比赛现场设备更稳。
- 所有十二结局复用一张关卡和一套交互系统，不需要十二套独立关卡。

### 3.2 核心结构

```text
输入
  ↓
玩家芽尖移动 ──→ 身体轨迹与局部光照
  ↓
碰撞 / 短按 / 长按 / 绕行 / 静止
  ↓
通用交互对象发送事件
  ↓
GameState 记录本局行为与道具
  ↓
指定结局入口请求判定
  ↓
EndingResolver 检查条件
  ↓
EndingScreen 播放对应演出并写入 ProgressState
```

设计原则：道具只负责报告“发生了什么”，不自行决定结局；所有结局条件集中在 `ending_resolver.gd` 中。这样修改条件时只改一个地方。

### 3.3 项目目录

比赛最终 ZIP 需要 `source`、`release`、`press`、`other` 四个目录，因此从一开始就按下面组织：

```text
GameJam/
├─ source/                         # 完整 Godot 工程
│  ├─ project.godot
│  ├─ icon.svg
│  ├─ autoload/
│  │  ├─ game_state.gd
│  │  ├─ progress_state.gd
│  │  ├─ audio_manager.gd
│  │  └─ narrative_manager.gd
│  ├─ scenes/
│  │  ├─ main/
│  │  │  ├─ main.tscn
│  │  │  └─ main.gd
│  │  ├─ levels/
│  │  │  ├─ fridge_level.tscn
│  │  │  └─ fridge_level.gd
│  │  ├─ player/
│  │  │  ├─ sprout.tscn
│  │  │  ├─ sprout.gd
│  │  │  └─ sprout_visual.gd
│  │  ├─ gameplay/
│  │  │  ├─ pickup.tscn
│  │  │  ├─ pickup.gd
│  │  │  ├─ interactable.tscn
│  │  │  ├─ interactable.gd
│  │  │  ├─ sticky_area.tscn
│  │  │  ├─ frost_area.tscn
│  │  │  ├─ charge_barrier.tscn
│  │  │  ├─ charge_barrier.gd
│  │  │  ├─ ritual_checkpoint.tscn
│  │  │  ├─ ritual_tracker.gd
│  │  │  ├─ narrative_trigger.tscn
│  │  │  └─ ending_entrance.tscn
│  │  └─ ui/
│  │     ├─ main_menu.tscn
│  │     ├─ pause_menu.tscn
│  │     ├─ dialogue_box.tscn
│  │     ├─ ending_screen.tscn
│  │     ├─ ending_screen.gd
│  │     ├─ ending_gallery.tscn
│  │     ├─ ending_gallery.gd
│  │     └─ debug_panel.tscn
│  ├─ systems/
│  │  ├─ ending_resolver.gd
│  │  ├─ ending_ids.gd
│  │  └─ save_service.gd
│  ├─ data/
│  │  ├─ ending_text.csv
│  │  ├─ narrative_text.csv
│  │  ├─ item_text.csv
│  │  └─ gallery_hints.csv
│  ├─ assets/
│  │  ├─ art/
│  │  ├─ audio/
│  │  ├─ fonts/
│  │  └─ licenses/
│  ├─ tests/
│  │  ├─ ending_resolver_test.gd
│  │  ├─ save_roundtrip_test.gd
│  │  └─ smoke_test.gd
│  └─ docs/
│     └─ debug_guide.md
├─ release/                        # 导出的 exe、pck、README
├─ press/                          # 大于 1024×768 的截图
├─ other/                          # 授权、团队介绍、AI 使用说明
├─ need.md
├─ ending.md
└─ programming.md
```

禁止把 Godot 自动生成的 `.godot/` 目录提交到 Git。`release/` 可以在最终阶段生成，不必每次提交二进制。

---

## 4. Godot 项目初始配置

### 4.1 创建项目

1. 打开 Godot Project Manager。
2. 点击 **Create**。
3. Project Name 填 `Dawn of the Sprout`。
4. Project Path 选择当前目录下的 `GameJam/source`。
5. Renderer 选择 **Compatibility**。
6. Version Control Metadata 选择 **Git**。
7. 创建并打开项目。

如果由 Agent 创建工程，你只需要在 Project Manager 中点击 **Import**，选择 `source/project.godot`。

### 4.2 显示与窗口

在 Project Settings 中设置：

```text
Display > Window > Size > Viewport Width  = 1280
Display > Window > Size > Viewport Height = 720
Display > Window > Stretch > Mode         = canvas_items
Display > Window > Stretch > Aspect       = keep
Rendering > Renderer > Rendering Method   = gl_compatibility
```

开发时允许拖动窗口；正式导出默认窗口模式，不强制全屏。UI 锚点按 1280×720 设计，但必须在 16:9 的常见尺寸下保持可读。

### 4.3 输入动作

在 `Project Settings > Input Map` 创建：

| Action | 默认按键 | 用途 |
| --- | --- | --- |
| `move_up` | W、↑ | 向上生长 |
| `move_down` | S、↓ | 向下生长、反抗结局 |
| `move_left` | A、← | 向左移动 |
| `move_right` | D、→ | 向右移动 |
| `interact` | E | 短按观察/帮助，长按吸收 |
| `charge` | Space | 顶开保鲜膜或盒盖 |
| `restart_run` | R | 结局后重新开始 |
| `pause` | Esc | 暂停菜单 |
| `skip_text` | Enter、Space | 二周目快速显示文本 |
| `debug_toggle` | F3 | 仅 Debug 构建显示状态面板 |

同一个 `Space` 在普通游玩中负责蓄力，在文本显示时只负责立即显示全文；输入锁要避免一次按键同时触发两个功能。

### 4.4 Autoload

在 `Project Settings > Globals > Autoload` 注册：

```text
GameState        res://autoload/game_state.gd
ProgressState    res://autoload/progress_state.gd
AudioManager     res://autoload/audio_manager.gd
NarrativeManager res://autoload/narrative_manager.gd
```

`GameState` 只保存本局数据；`ProgressState` 保存跨局数据。重新开始时只能清空前者。

### 4.5 碰撞层

统一使用固定层，禁止每个人临时乱选：

| Layer | 名称 | 内容 |
| ---: | --- | --- |
| 1 | `world_solid` | 玻璃、包装、墙体、不可穿越冰块 |
| 2 | `player_head` | 玩家芽尖 |
| 3 | `hazard_area` | 黏液、霜毒、腐败区域 |
| 4 | `interactable` | 道具、同伴、机关 |
| 5 | `trigger` | 文本、仪式检查点、结局入口 |
| 6 | `player_body` | 需要检测身体绕行时使用，默认不参与实体碰撞 |

首版只让芽尖发生实体碰撞，Line2D 身体仅负责显示；这能避免长身体卡在复杂地形中的高风险 Bug。

---

## 5. 程序模块设计

### 5.1 `main.tscn`：游戏总入口

职责：

- 启动主菜单。
- 创建或卸载关卡。
- 接收暂停、重新开始和返回菜单请求。
- 在关卡与结局画面之间切换。
- 捕获无法恢复的错误并回到菜单。

不要把玩家移动、道具计数或具体结局判断写入 `main.gd`。

建议节点：

```text
Main (Node)
├─ SceneContainer (Node)
├─ UIContainer (CanvasLayer)
├─ FadeLayer (CanvasLayer)
│  └─ ColorRect
└─ TransitionPlayer (AnimationPlayer)
```

### 5.2 `sprout.tscn`：玩家嫩芽

建议节点：

```text
Sprout (CharacterBody2D)
├─ HeadSprite (Sprite2D)
├─ HeadCollision (CollisionShape2D)
├─ InteractionDetector (Area2D)
│  └─ CollisionShape2D
├─ Trail (Line2D)
├─ PointLight2D
├─ GPUParticles2D
├─ Camera2D
├─ HoldTimer (Timer)
└─ IdleTimer (Timer)
```

移动采用 `CharacterBody2D.move_and_slide()`，不要使用刚体模拟。建议首版参数：

```text
max_speed        = 180 px/s
acceleration     = 900 px/s²
deceleration     = 1200 px/s²
sticky_multiplier = 0.45
frost_multiplier  = 0.65
trail_point_gap   = 8 px
max_trail_points  = 700
```

每帧读取四向输入并归一化，避免斜向速度更快。只有当头部与上一个轨迹点距离超过 `trail_point_gap` 时才向 Line2D 添加点，避免每帧增加一个点造成内存和绘制压力。

必须提供这些公开方法，其他模块不能直接修改玩家内部节点：

```gdscript
set_input_enabled(enabled: bool)
apply_status(status_id: StringName, amount: float)
set_visual_stage(route_id: StringName, stage: int)
add_temporary_speed_modifier(source: StringName, multiplier: float)
remove_speed_modifier(source: StringName)
get_head_position() -> Vector2
get_trail_points() -> PackedVector2Array
```

### 5.3 交互系统

`interactable.gd` 统一处理短按与长按：

- E 按下并在约 0.35 秒内松开：`observe_or_help`。
- E 持续约 0.8 秒：`absorb`。
- 长按进度要显示圆环或进度条；完成前离开范围则取消。
- 一个物体只允许成功一次，成功后关闭碰撞和提示。
- 活物短按增加 `nurture`，长按增加 `devour`；死物按配置执行，不用特殊脚本硬编码。

每个实例只配置数据：

```text
item_id
display_name_myth
display_name_real
interaction_type
short_action
hold_action
state_delta
narrative_text_id
required_item
consumed_after_use
```

### 5.4 障碍系统

- `sticky_area`：进入时添加减速来源，退出时移除；不要直接写死玩家速度。
- `frost_area`：添加霜化状态、短暂减速和视觉结晶；可收集霜晶必须是独立 `pickup`，不能与伤害冰刺使用同一个 ID。
- `charge_barrier`：保鲜膜和盒盖复用。记录蓄力进度，松开时缓慢回退；达到 100% 后播放动画、关闭碰撞并报告破坏行为。
- 玻璃瓶：使用静态碰撞；重撞速度超过阈值才增加 `noise` 和 `bottle_hit_count`，普通擦碰只播放轻声。

建议蓄力值：保鲜膜 0.8–1.2 秒，终局盒盖 1.5–2.0 秒。不要让玩家无反馈地按住超过三秒。

### 5.5 叙事系统

`narrative_trigger` 只发送 `text_id`，`NarrativeManager` 从 `narrative_text.csv` 获取实际文字。它负责：

- 文本排队，不覆盖正在显示的上一条。
- 打字机效果、立即显示全文、自动淡出。
- 同一 `text_id` 默认本局只播放一次。
- 支持条件：首周目、已发现某结局、持有道具、行为阈值。
- 结局演出期间清空普通文本队列并锁定玩家输入。

CSV 建议字段：

```text
text_id,chapter,speaker,zh_cn,duration,once_per_run,condition_tag
```

中文文本可能包含逗号和换行，必须使用正确 CSV 引号；如果队友不熟悉 CSV，可先在 `.md` 中写作，由程序负责人统一转入 CSV。

### 5.6 `GameState`：本局状态

使用明确 API 更新状态，不允许其他脚本随意执行 `GameState.noise += 1`。这样可以统一触发视觉和声音反馈。

建议数据：

```gdscript
var devour: int = 0
var nurture: int = 0
var noise: int = 0
var destruction: int = 0
var corruption: int = 0

var items: Dictionary[StringName, bool] = {}
var counters: Dictionary[StringName, int] = {}
var flags: Dictionary[StringName, bool] = {}
var rituals: Dictionary[StringName, bool] = {}

var last_exit: StringName = &"none"
var run_seconds: float = 0.0
var input_distance: float = 0.0
var optional_nutrients_total: int = 0
var optional_nutrients_eaten: int = 0
```

建议 API：

```gdscript
reset_run()
add_stat(stat_id: StringName, amount: int)
collect_item(item_id: StringName)
has_item(item_id: StringName) -> bool
set_flag(flag_id: StringName, value: bool = true)
has_flag(flag_id: StringName) -> bool
complete_ritual(ritual_id: StringName)
increment_counter(counter_id: StringName, amount: int = 1)
make_snapshot() -> Dictionary
```

所有变化发出信号，例如 `stat_changed`、`item_collected`、`flag_changed`。玩家外观、音频和 UI 监听信号，不轮询状态。

### 5.7 `ProgressState` 与存档

跨局只保存：

```text
save_version
unlocked_ending_ids
run_count
first_ending_seen
text_skip_unlocked
master/music/sfx 音量
```

存档路径使用 Godot 的 `user://save_data.cfg`。不要保存完整关卡坐标和几十个节点状态，48 小时内不做中途存档。

读取失败时：记录警告、备份损坏文件并创建新存档，不能让游戏无法启动。Debug 菜单需要提供“清空图鉴”按钮，但 Release 构建不显示。

### 5.8 音频系统

建立四条 Audio Bus：

```text
Master
├─ Music
├─ Ambience
├─ SFX
└─ UI
```

`AudioManager` 提供 `play_sfx(id)`、`play_music(id, fade_seconds)`、`set_ambience_layer(id, weight)`。所有资源可通过字典预加载，避免场景脚本各自写路径。

克苏鲁路线依赖“第三次压缩机启动”，因此压缩机循环不能只是一段无法知道节拍的长音频。应由 Timer 或 AudioStreamPlayer 的明确重启事件增加 `compressor_start_count`，音频只是表现，程序计时才是判定依据。

### 5.9 仪式与绕圈判定

不要计算玩家是否画了完美圆形。围绕目标放置四个 `Area2D` 检查点：上、左、下、右。

- 逆时针顺序：上 → 左 → 下 → 右 → 上。
- 顺时针顺序：上 → 右 → 下 → 左 → 上。
- 正确经过一个点时播放升调音并点亮刻痕。
- 走错顺序只重置当前进度，不惩罚玩家。
- 离开目标过远或超过 8 秒未到下一点则重置。

同一套 `ritual_tracker.gd` 通过 Inspector 配置顺序，用于辣酱瓶、黄色瓶盖、自身成环和根系连接。

---

## 6. 十二结局的程序判定

### 6.1 不要每帧自动判定

结局只在明确的“结局请求点”判断。例如玩家顶开盒盖、进入门缝、完成根网、钻入探针、主动剪断或触发外部清理时，调用：

```gdscript
EndingResolver.request_ending(trigger_id, GameState.make_snapshot())
```

这比把十二个条件每帧互相比较更稳定，也能减少多个结局同时满足的冲突。

若某个特殊入口条件不足，只显示“还缺少什么”的模糊提示，不应自动切到默认结局。只有顶开普通盒盖时，才允许回退到结局 01。

### 6.2 统一结局 ID

```text
ending_01_food_failure
ending_02_lord_of_sprouts
ending_03_milk_dragon
ending_04_true_dawn
ending_05_autonomous_forest
ending_06_infinite_growth_inc
ending_07_eternal_winter_seed
ending_08_root_access
ending_09_purple_crown
ending_10_dark_harvest
ending_11_not_growing_today
ending_12_landfill_king
```

这些 ID 一旦进入存档就不再改名。显示名称放在 CSV 中，可以随时修改而不破坏图鉴。

### 6.3 条件表

| 结局 | 触发点 `trigger_id` | 必要条件 | 禁止或排除条件 | 条件不足时提示 |
| --- | --- | --- | --- | --- |
| 01 生长成功，食用失败 | `top_lid` | 顶开最终盒盖 | 没有其他特殊入口已经成功 | “破晓就在上方。” |
| 02 万芽之主 | `light_switch_hold` | 三遗物、逆时针瓶仪式、压缩机启动至少三次、持续按灯 7 秒 | 无 | 根据缺项提示“仍有腐星未归位”等 |
| 03 奶龙降生 | `dragon_shrine_idle` | 三滴奶、日之金鳞、绕黄色瓶盖、在小龙图案前静止 3 秒 | 未吸收腐败黑水和辣油 | “白母仍少一滴泪”或“日鳞尚缺” |
| 04 真正的破晓 | `warm_door_gap` | 两滴干净水、门缝泥土、小票背面、瓶子杠杆完成、对伸手不攻击 | 不吸收腐液/霉菌/辣油，尽量不撕膜 | “真正的出口会带来风。” |
| 05 保鲜层自治森林 | `root_network_complete` | 三名同伴均短触唤醒、分别送水、三地根系连接、返回下层 | 不能吞噬任一同伴 | “还有一位沉睡者没有回应。” |
| 06 无限增长有限公司 | `barcode_terminal` | 三张价签、所有可选养分被吸收、终点解锁后曾回头、长度/枝条达标 | `nurture == 0` | “本纪元增长目标尚未完成。” |
| 07 永冬胚种 | `freezer_alcove` | 四霜晶、眠石、温控第七格、静止一整个压缩机周期、自身成环 | 无 | “第七格不是死亡，而是等待。” |
| 08 ROOT 权限 | `temperature_probe` | 铝箔、导电冷凝水、磁芯、节点节奏正确 | 无 | 终端显示缺失组件或 `ACCESS DENIED` |
| 09 紫冠的新芽 | `hongsan_root_link` | 菜薹标签、黄花瓣、干净水、紫色菜薹根已帮助、听到钟声、向暖光、完成连接 | 温控不能在第七格；不能吞噬菜薹根 | “她喜冷凉，却不属于永冬。” |
| 10 不见天日的丰收 | `mother_soil` | 三芽眼结节、干净养分、返回母薯、三处播种完成、持续向下 | 盒盖未打开 | “还有一扇门没有被种下。” |
| 11 今天不长 | `self_prune` | 教学后返回起点、零养分吸收、零攻击、多次响应旁白命令时保持静止、长按向下剪芽 | `devour == 0`、`destruction == 0` | 旁白逐级焦躁，不直接显示配方 |
| 12 垃圾大陆之王 | `forced_cleanup` | 高噪音、高破坏、高腐化、瓶子重撞至少三次、所有保鲜膜撕裂、吸干黑水、反复撞盒盖 | `nurture == 0` | 脚步声和“噪音投诉 +1”预告；读过可堆肥标签则播放二段 |

表中“高”“所有”“多次”等词必须在调试完成后冻结为整数。第一版建议：

```text
noise >= 6
destruction >= 5
corruption >= 3
bottle_hit_count >= 3
lid_hit_count >= 3
narrator_refusal_count >= 3
milk_count == 3
frost_count == 4
barcode_count == 3
```

### 6.4 冲突处理

优先使用唯一触发点解决冲突，而不是依赖一个很长的全局优先级列表。若同一触发点仍可能匹配多个规则，使用：

```text
精确配方彩蛋
> 特殊仪式
> 指定物理出口
> 行为倾向
> 默认结局
```

每次判定在 Debug 控制台打印：触发点、满足规则、失败规则及首个缺失条件。Release 构建不显示这些调试信息。

### 6.5 结局数据与演出

`ending_text.csv` 建议字段：

```text
ending_id,index,title,category,line_1,line_2,line_3,subtitle,art_path,music_id,post_delay,next_action
```

十二结局复用同一个 `ending_screen.tscn`：

1. 锁定玩家输入。
2. 停止普通文本和危险音效。
3. 淡出或白闪。
4. 加载共用终局背景与对应覆盖层。
5. 播放对应音乐和短演出。
6. 显示标题、编号和正文。
7. 写入 `ProgressState`。
8. 显示“再次发芽 / 结局图鉴 / 返回菜单”。

结局 12 如果读过可堆肥标签，在第一次结算八秒后继续播放填埋场二段；它仍然是同一个 `ending_id`，不能在图鉴中占两个格子。

---

## 7. 关卡与镜头实现

### 7.1 一张纵向主关卡

使用一张约 1280×3600 至 1280×5000 的纵向关卡：

```text
y = 4200–5000  出生点 / 腐土深渊
y = 3000–4200  黄瓜、黏液、现实线索
y = 1900–3000  保鲜膜与共生对象
y = 700–1900   辣酱瓶、冰霜、温控线路
y = 0–700      盒盖、灯开关、门缝及特殊出口
```

数字只是灰盒参考，美术到位后再调。所有隐藏路线在同一张地图中通过侧向小空间、返回下层和特殊交互实现，不制作十二张地图。

### 7.2 Camera2D

- 相机跟随芽尖，Position Smoothing 开启。
- 水平范围限制在冰箱内，纵向限制在关卡范围。
- 普通碰撞轻微震动，只有重撞和终局使用明显震动。
- 结局演出时相机从玩家身上解绑，由 AnimationPlayer 控制。
- 提供“降低屏幕震动”选项，默认 100%，允许调整到 0%。

### 7.3 黑暗与局部光照

首选低风险方案：深色背景 + 玩家圆形柔光 Sprite/PointLight2D + CanvasModulate。不要在 48 小时项目里依赖复杂全屏 Shader。

- 玩家附近半径约 180–260 px 可见。
- 重要道具自身有非常弱的轮廓光，但不能直接暴露完整位置。
- UI 位于独立 CanvasLayer，不受黑暗影响。
- 终局用白色 ColorRect Tween 爆白，随后关闭 CanvasModulate。

---

## 8. Debug 工具与自动测试

### 8.1 Debug 面板

F3 打开，仅 Debug 构建可用。显示：

```text
devour / nurture / noise / destruction / corruption
milk / frost / barcode / relic mask
compressor count / bottle hits / lid hits
items / flags / rituals
当前附近的 ending trigger
上一次判定失败原因
```

按钮：

- 传送到四个关卡阶段。
- 添加指定道具。
- 设置行为值。
- 完成指定仪式。
- 强制请求十二个结局入口。
- 重置本局。
- 清空永久图鉴。

没有这个面板，十二结局会导致大量重复跑图，严重浪费比赛时间。

### 8.2 自动测试

不依赖第三方测试插件，使用可被 `--headless --script` 调用的 GDScript 测试脚本即可。至少覆盖：

- 十二条正向条件各能返回正确 `ending_id`。
- 每条特殊结局分别缺一个关键条件时不能触发。
- 奶龙碰过腐败黑水后不能触发。
- 共生路线吞噬一个同伴后不能触发。
- 洪山路线温控拨到七后不能触发。
- 结局 12 是否播放二段只受可堆肥标签控制，图鉴 ID 不变化。
- 顶开普通盒盖始终有默认结局，不会卡死。
- 重新开局会清空 GameState，但不会清空已解锁结局。
- 损坏或空存档不会让游戏崩溃。

### 8.3 手工测试表

每个结局至少执行：

1. 一次完整正向触发。
2. 一次缺少最后条件的失败测试。
3. 一次与相似路线的冲突测试。
4. 一次结局后重新开始。
5. 一次关闭游戏再打开，检查图鉴仍在。

测试人员记录：Godot 版本、构建编号、操作步骤、预期结果、实际结果、截图或录屏、是否阻塞提交。

Bug 优先级：

```text
P0：崩溃、无法通关、导出不能运行、存档损坏、结局错误
P1：明显卡住、提示缺失、音频持续播放、UI 无法操作
P2：轻微穿模、动画不顺、错别字、装饰问题
```

截止前只允许 P0 阻塞发布；P1 尽量修，P2 记录到已知问题。

---

## 9. 48 小时具体执行顺序

十二个结局都保留在设计和数据中，但程序必须按批次完成。每个阶段结束都要产生一个可玩的版本。

### 第 0–2 小时：冻结规则与建仓

- [ ] 全队确认 Godot 精确版本、1280×720、Windows、键位和文件命名。
- [ ] 确认 `ending.md` 是结局唯一规范；旧三结局逻辑不实现。
- [ ] 建立远程 Git 仓库，添加队友，完成第一次推送。
- [ ] 建立 `source/release/press/other` 目录和 `.gitignore`。
- [ ] 创建 Godot 工程、Input Map、Autoload、Audio Bus 和主场景。
- [ ] 将十二个结局 ID 写入 `ending_ids.gd`，从此不改 ID。

验收：空工程能运行到主菜单，无报错，另一名队友能拉取并打开。

### 第 2–7 小时：最小可玩竖切

- [ ] 完成芽尖四向移动、加减速和碰撞。
- [ ] 完成 Line2D 身体轨迹、相机和局部光照。
- [ ] 使用矩形/圆形占位图搭建一条从底到顶的灰盒关卡。
- [ ] 完成终局盒盖蓄力、白闪和默认结局 01。
- [ ] 完成 R 重新开始和 Esc 暂停。

验收：没有正式素材也能在 2–3 分钟内从出生点到结局 01，再按 R 重开。

### 第 7–13 小时：基础系统

- [ ] 完成黏液、保鲜膜、硬障碍、冰霜四种反馈。
- [ ] 完成通用短按/长按交互与道具拾取。
- [ ] 完成 GameState、信号和 Debug 面板。
- [ ] 完成文本 CSV、文本队列和四阶段叙事触发。
- [ ] 完成 AudioManager、压缩机事件和基础音效。

验收：不同材质反馈清楚；道具不会重复计数；文本不会互相覆盖。

### 第 13–20 小时：首批三结局

- [ ] 结局 01 默认土豆。
- [ ] 结局 02 三遗物、逆时针仪式、第三次压缩机、灯开关长按。
- [ ] 结局 03 三滴奶、金鳞、黄色瓶盖仪式、小龙图案静止。
- [ ] 完成通用 EndingScreen 和结局解锁存档。
- [ ] 为三结局各做一次正向、缺条件和冲突测试。

验收：前三结局从同一关卡稳定触发，重开后图鉴显示 3/12。

### 第 20–32 小时：第二批五结局

- [ ] 04 真正的破晓：水、泥、小票、杠杆、暖门缝。
- [ ] 05 自治森林：三同伴、送水、根网。
- [ ] 06 无限增长：养分统计、回头标记、条形码终端。
- [ ] 07 永冬胚种：霜晶、眠石、温控、完整压缩机周期。
- [ ] 08 ROOT 权限：三材料、节点节拍、温控探针。

验收：结局 04–08 可通过 Debug 面板快速验证，至少各完整手玩一次。

### 第 32–39 小时：第三批四结局

- [ ] 09 紫冠的新芽：菜薹标签、花瓣、送水、钟声、暖光连接。
- [ ] 10 不见天日的丰收：三结节、返回母薯、三处播种。
- [ ] 11 今天不长：零吸收/零攻击、拒绝计数、主动剪芽。
- [ ] 12 垃圾大陆之王：噪音/破坏/腐化阈值、提前清理、可堆肥二段。

验收：十二条自动条件测试通过；图鉴为 12 格；不存在旧附加结局 ID。

### 第 39–44 小时：素材接入与手感

- [ ] 用正式 PNG、字体、WAV、OGG 替换占位资源。
- [ ] 修正碰撞形状，不直接照图片透明边缘自动生成复杂多边形。
- [ ] 调整速度、蓄力时长、暗度、音量和文本停留时间。
- [ ] 检查 1280×720、1920×1080 和较小窗口。
- [ ] 让至少一名没看过答案的人试玩，记录他在哪里迷路。

验收：首次玩家能触发默认结局，并能看懂至少两条隐藏路线的提示。

### 第 44–47 小时：导出与回归测试

- [ ] 冻结新功能，只修 P0/P1 Bug。
- [ ] 创建 Windows Desktop x86_64 Release 导出预设。
- [ ] 导出到 `release/`，填写 `release/README.txt`。
- [ ] 在无 Godot 的电脑上完整运行一次。
- [ ] 完成至少一张大于 1024×768 的截图放入 `press/`。
- [ ] 检查 `source/` 包含完整工程和编译说明。
- [ ] 检查 `other/` 包含团队介绍、许可证和第三方授权。

验收：从最终目录重新压缩、解压、运行，中文、音频、存档和退出正常。

### 第 47–48 小时：提交缓冲

- [ ] 生成最终 ZIP，不再改高风险代码。
- [ ] 核对 ZIP 内不是多套一层无意义目录，根目录直接看到四个规定文件夹。
- [ ] 上传完整 ZIP；GitHub 链接只能补充，不能替代 ZIP。
- [ ] 队长检查项目页面成员、简介、平台、工具和截图。
- [ ] 保留本地 ZIP、远程仓库和另一处备份。

最后一小时禁止临时升级 Godot、重写玩家控制或加入新结局。

---

## 10. 时间不够时的降级方案

“十二结局写入设计”不等于必须为每个结局做完全不同的地图、动画和音乐。按以下顺序降级：

1. 保留十二个判定和图鉴格子。
2. 每个结局至少有独立标题、文字、颜色和一个覆盖层。
3. 结局 01、02、03 保留完整演出。
4. 结局 04–08 可以复用终局母版，只换覆盖层、滤镜、音乐和文字。
5. 结局 09–12 可以使用静帧、程序生成文字和现有芽体复制。
6. 删除装饰性粒子和次要动画，不删除结局条件反馈。
7. 最后仍无法稳定时，用项目内 `feature_flags.gd` 暂时隐藏未完成入口，但不要留下可进入后卡死的半成品。

任何时候都优先保证：能启动、能移动、默认结局可完成、能重开、能导出。

---

## 11. 美术和音频接入合同

### 11.1 美术

- 运行时统一 `.png`，透明物体必须有 Alpha。
- 可编辑源文件保留 `.psd` 或 `.kra`，但 Godot 只引用导出的 PNG。
- 同一个物体的状态使用统一尺寸和锚点，例如 `film_intact.png`、`film_stretched.png`、`film_broken.png` 画布完全一致。
- 光源方向、像素密度和描边粗细在美术规范中固定。
- 程序碰撞形状单独制作，不依赖贴图透明度。
- 不直接使用真实品牌 Logo；老干妈等只作为内部描述，正式图使用原创辣酱标签。

### 11.2 音频

- 短音效：48 kHz `.wav`。
- BGM 和环境循环：48 kHz `.ogg`，首尾无接缝。
- 文件名只使用小写英文、数字、下划线。
- 每个文件注明是否循环、推荐音量、单声道/立体声和触发位置。
- 程序保留总线音量，不通过直接修改源文件来反复调大小。

### 11.3 文案

- 文案人员修改 `.md` 源稿，程序负责人统一同步到 CSV。
- 每条文本有唯一 `text_id`，修改文字不能改 ID。
- 单次屏幕最多 1–2 行，避免玩家移动时阅读长段落。
- 结局名与 `ending.md` 完全一致。

---

## 12. Git 协作步骤

### 12.1 分支规则

小团队 48 小时内使用简单规则：

```text
main                 始终保持可运行
feature/player       玩家移动和轨迹
feature/endings      结局系统
feature/ui           UI 和文案
asset/art-batch-01   美术批次
asset/audio-batch-01 音频批次
```

每个功能完成并在本机运行后再合并到 `main`。避免多人同时编辑同一个 `.tscn`；场景冲突比脚本冲突更难处理。

### 12.2 每次工作循环

```powershell
git pull --rebase
git switch -c feature/功能名
# 修改并测试
git status
git add 明确的文件路径
git commit -m "feat: 完成某功能"
git push -u origin feature/功能名
```

不要使用 `git add .` 无脑提交缓存、导出包和私人临时文件。Agent 在提交前应展示 `git status` 和变更摘要。

### 12.3 场景冲突预防

- 一个人负责 `fridge_level.tscn` 的摆放。
- 一个人负责 `ending_screen.tscn`。
- 其他人交付素材，不直接打开并保存这些场景。
- 通用对象各自独立成 `.tscn`，主关卡只实例化它们。
- 合并前关闭 Godot，确保场景已保存且 `.godot/` 未被跟踪。

---

## 13. 导出与最终提交

### 13.1 编辑器导出

1. 打开 `Project > Export`。
2. 添加 `Windows Desktop` 预设。
3. Architecture 选择 `x86_64`。
4. Export Mode 选择全部项目资源，排除测试截图和未使用大源文件。
5. 导出路径设为 `../release/dawn_of_the_sprout.exe`。
6. 关闭“Export With Debug”。
7. 导出后检查 `.exe` 和 `.pck` 均存在。

若 Godot 已加入 PATH，Agent 可以执行等价命令：

```powershell
godot --headless --path source --editor --quit
godot --headless --path source --export-release "Windows Desktop" ../release/dawn_of_the_sprout.exe
```

第一条用于检查工程能否正常导入，第二条用于生成 Release。实际命令可能需要使用 Godot exe 的完整路径。

### 13.2 最终目录验收

```text
最终ZIP/
├─ source/
│  ├─ project.godot
│  ├─ 完整脚本、场景、素材
│  └─ README.md              # 如何用 Godot 4.7.2 打开和导出
├─ release/
│  ├─ dawn_of_the_sprout.exe
│  ├─ dawn_of_the_sprout.pck
│  └─ README.txt             # 解压、启动、按键、退出、已知问题
├─ press/
│  └─ screenshot_01.png      # 至少一张，大于 1024×768
└─ other/
   ├─ TEAM.md
   ├─ LICENSE.txt
   ├─ THIRD_PARTY_LICENSES.md
   └─ AI_USAGE.md
```

完整 ZIP 必须直接上传到比赛项目页面。GitHub 仓库、Release、视频或网页版只能作为补充链接。

---

## 14. 完成定义

程序完成不是“代码写完”，而是同时满足：

- [ ] Godot 编辑器打开工程无红色错误。
- [ ] 新玩家能完成移动教学并在 3–5 分钟触发默认结局。
- [ ] 十二个正式结局均有固定 ID、入口、条件、缺失提示、文本和图鉴位置。
- [ ] 十二条正向判定测试和关键冲突测试通过。
- [ ] 本局重开后行为状态清空，永久图鉴保留。
- [ ] 文本不会重叠，结局演出期间输入被锁定。
- [ ] 音乐、环境声和音效可分别调节。
- [ ] 不依赖编辑器专有状态，Windows Release 在另一台电脑可运行。
- [ ] `source/release/press/other` 齐全，许可证和编译说明完整。
- [ ] 最终 ZIP 已实际解压验证，不只是确认文件存在。

---

## 15. 你现在最先做的五件事

1. 在 Godot Project Manager 中导入 `source/project.godot`，按 F5 试玩已完成的第 0–7 小时灰盒。
2. 确认全队都使用 Godot 4.7.2 Standard，不再更换版本。
3. 为已经初始化的本地 Git 仓库创建远程仓库、邀请队友并设置用户名和邮箱；当前尚未替你提交或推送文件。
4. 奶龙道具已经冻结为“奶酪黄边（日之金鳞）”，程序和美术统一使用这一名称及唯一物品 ID，不再制作蛋黄碎屑候补。
5. 完成人工试玩并反馈移动速度、光照范围、地图长度和蓄力时长；确认手感后再执行第 7–13 小时阶段。

之后你可以直接这样下达任务：

> 请按照 programming.md 的第 0–7 小时阶段创建 Godot 工程。使用占位素材完成玩家移动、芽体 Line2D、局部光照、灰盒关卡、盒盖蓄力、默认结局和重新开始。完成后运行检查并告诉我如何在 Godot 中试玩。

这会比一次性要求“把整个游戏做完”更容易验证，也便于发现方向错误后及时调整。
