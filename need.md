# 《破晓之种》团队协作需求清单

> 用途：程序、美术、音频、文案、测试与最终提交的统一资产清单。  
> 当前推荐技术方案：Godot 4.7.2 Standard、GDScript、Compatibility 渲染器、Windows x86_64 首发。  
> 优先级：`P0` = 必须立即完成；`P1` = 核心内容完成后制作；`P2` = 时间充足再做或候选方案。  
> 状态建议：每项可在行尾追加 `[负责人 / 未开始、制作中、待验收、已完成]`。
> 清单格式：`中文名称 -- 规范文件名 -- 格式/要求 -- 优先级 -- 描述`。下列英文文件名视为交付接口；同一素材的状态或帧使用 `_01`、`_02`、`_intact`、`_broken` 等后缀。当前阶段只接收可直接导入游戏的运行时文件，不要求提交 `.psd`、`.kra` 等可编辑源文件。
> 素材状态：`C0` = 缺失，`C1` = 已有且可直接使用，`C2` = 已有但需要裁剪/补状态，`PG` = 已改为程序像素绘制，不再需要美术交付对应文件。

## 更新日志（本次地图形态改版）

- `2026-09-05`：最终地图美术规范从“中心向外的圆形程序化冰箱背板”改回“25600×25600 自底向上的垂直程序化冰箱地图”，补充七个生态层的上下坐标、层高、横向作图区、画布安全边距和切片交付规格。
- `2026-09-05`：明确七个生态层之间不制作实体横向边界墙；美术只需提供可连续拼装的层带材质、纵向/横向搁架和上下过渡，不需要为每个层绘制一整条不可穿越的墙体。
- `2026-09-05`：本日志只记录本次需求清单改动；程序侧已同步取消原圆形环间碰撞，改为自底向上地图的四条世界外边界，仍需完成本轮运行回归验收。
- `2026-09-05`：完成 `program/image` 图片盘点并为美术资产条目加状态标记：`C0` 完全缺失、`C1` 文件组齐全无需继续裁剪、`C2` 已有部分但仍缺少状态/变体/裁剪文件；本次共标记 `C0=11`、`C1=81`、`C2=63`。
- `2026-09-05`：根据制作时间限制，取消所有 `.psd`、`.kra` 和“必须保留分层源文件”的交付要求；美术只需提交最终运行时 `.png`，同一物体的不同状态继续使用独立文件名区分。
- `2026-09-05`：取消结局母版、角色立绘和结局覆盖层的拼装方案；十二个正式结局改为各自一张完整的 `1920×1080` 结局插画，结局画面只叠加程序生成的标题、文案和按钮。
- `2026-09-05`：玩家状态覆盖层、冰棺覆盖层等非结局覆盖素材统一标记为 `C0`，首版由程序颜色、粒子和几何绘制提供反馈，不再等待单独覆盖层图片。
- `2026-09-06`：UI、美术粒子贴图和屏幕/玩家覆盖层全部改为程序像素绘制并标记为 `PG`；已有 `ui_`、`vfx_` 图片不再参与运行时表现，只保留在素材目录供参考。
- `2026-09-06`：六张冰箱垂直背板已确认齐全并改为 `C1`；程序按生态层循环使用 `env_fridge_backplate_tile_01.png` 至 `06.png`，生态颜色仅作为半透明色调，不再遮住背板。
- `2026-09-06`：再次核对 `program/image` 与 `program/audio`：运行时现有 282 张 PNG（含 8 个规范别名）、88 个分类音频（不含试听总集）；十二张完整结局图与三类正式音频均已同步到 `source/assets`。
- `2026-09-06`：为 8 个交付命名/编号错误建立了不破坏原文件的规范别名（ROOT 断开节点、菜薹复苏、温控第七格、永冻之心空壳、灯开关两态、发芽警告残片、保鲜膜裂纹第 02 帧）。
- `2026-09-06`：补齐 `env_rotten_cucumber_intact.png` 并同步到运行时；腐烂黄瓜完整态现在作为第一处黑水区域的环境主体显示。运行时仍缺门封冷/暖两态，继续使用程序暖光框回退；宣传图不属于本轮运行时素材。

## 0. 开工前必须统一的规范

- 十二结局范围冻结表 -- `ending_scope.md` + `ending_scope.csv` -- `.md` + `.csv` -- `[P0]` 以当前《ending.md》为唯一结局规范，正式结局固定为：01《生长成功，食用失败》、02《万芽之主》、03《奶龙降生》、04《真正的破晓》、05《保鲜层自治森林》、06《无限增长有限公司》、07《永冬胚种》、08《ROOT 权限》、09《紫冠的新芽》、10《不见天日的丰收》、11《今天不长》、12《垃圾大陆之王》；此前文档中的三结局制和附加结局不再作为制作目标。每个结局还必须固定 `ending_id`、所需道具、禁止条件、行为阈值、出口、优先级和结算文案。
- 资产总表 -- `asset_manifest.xlsx` + `asset_manifest.csv` -- `.csv` 或 `.xlsx`，另导出 `.csv` -- `[P0]` 字段至少包含 `asset_id`、中文名称、英文文件名、类型、优先级、负责人、尺寸、是否透明、关联场景、关联结局、授权来源、当前状态；程序只按固定英文文件名接入。
- 文件命名规范 -- `file_naming_spec.md` -- `.md` -- `[P0]` Godot 工程内文件名只使用小写英文、数字和下划线，例如 `item_milk_drop.png`；禁止空格、中文文件名、`最终版2_真的最终版` 等命名；同一素材修改时覆盖原文件或使用版本控制，不改变程序引用路径。
- 美术交付规范 -- `art_delivery_spec.md` -- `.md` -- `[P0]` 运行时图片统一导出为 sRGB PNG；透明物体必须带 Alpha 通道；不要求提交 PSD/KRA 等可编辑源文件；透明边缘不得出现白边；同组物品保持统一透视、描边粗细和光源方向。
- 音频交付规范 -- `audio_delivery_spec.md` -- `.md` -- `[P0]` 短音效使用 48 kHz WAV，环境与音乐循环使用 48 kHz OGG；需循环的文件必须无明显接缝；注明单声道或立体声、是否循环、推荐音量和触发位置。
- 授权登记表 -- `asset_license_register.csv` + `asset_license_register.md` -- `.csv` + `.md` -- `[P0]` 所有字体、音频、图片、纹理和参考素材记录作者、原始链接、许可证、是否允许修改和商用；AI 生成内容也要记录生成工具、日期、用途和是否经过人工修改，便于 GGJ 页面填写 AI 使用环节。
- 游戏规格锁定文档 -- `game_spec.md` -- `.md` -- `[P0]` 固定目标分辨率 1280×720、目标平台 Windows x86_64、控制方式、单局时长、必做结局、音量标准、字体和色板；所有成员以该文档为准。

## 1. 程序工程文件

- Godot 项目入口 -- `project.godot` -- `[P0]` 保存项目名称、1280×720 窗口、Compatibility 渲染器、输入动作和主场景；由程序维护，不由其他成员手工编辑。
- Git 忽略规则 -- `.gitignore` -- `[P0]` 忽略 `.godot/`、`builds/`、临时文件和本机缓存；源代码、场景、导入素材和 `export_presets.cfg` 需要提交。
- 主场景 -- `main.tscn` + `main.gd` -- `[P0]` 负责装载关卡、UI、暂停、重新开始和场景切换；不得堆放道具具体逻辑。
- 冰箱主关卡 -- `fridge_level.tscn` + `fridge_level.gd` -- `[P0]` 最终版为 `25600×25600` 自底向上的垂直程序化关卡，出生点在底部中央，七个生态层向上推进，包含腐土、虚空之茧、泰坦巨柱与霜毒、顶部外壳出口；所有结局复用该关卡。
- 玩家嫩芽场景 -- `sprout.tscn` + `sprout.gd` -- `[P0]` 包含可碰撞芽尖、移动、Line2D 生长轨迹、局部光源、相机和交互检测；首版只让芽尖参与实体碰撞。
- 玩家外观控制器 -- `sprout_visual.gd` -- `[P1]` 根据奶化、旧神、共生、吞噬、霜化、带电等状态切换颜色、眼纹、小角、叶片、尖刺和粒子，不负责结局判断。
- 通用道具场景 -- `pickup.tscn` + `pickup.gd` -- `[P0]` 通过 Inspector 配置 `item_id`、神话名称、现实名称、状态效果、拾取音效和提示文本；所有隐藏道具尽量复用。
- 通用观察与吸收交互 -- `interactable.tscn` + `interactable.gd` -- `[P0]` 支持短按观察、长按吸收或帮助，并向 GameState 报告行为；活物需要能区分“共生”和“吞噬”。
- 蓄力障碍场景 -- `charge_barrier.tscn` + `charge_barrier.gd` -- `[P0]` 供保鲜膜和终局盒盖复用；包含进入检测、蓄力、松开衰减、破裂、关闭碰撞、动画和音效事件。
- 黏液区域场景 -- `sticky_area.tscn` + `sticky_area.gd` -- `[P0]` 进入后减速并改变移动声音，离开后恢复；用于腐烂黄瓜黑水和软烂食物。
- 冰霜区域场景 -- `frost_area.tscn` + `frost_area.gd` -- `[P0]` 进入后短暂减速、滑动或冻结；吸收霜晶时通知 GameState。
- 剧情触发器 -- `narrative_trigger.tscn` + `narrative_trigger.gd` -- `[P0]` 进入区域后发送文本请求，每条文本只能按配置触发一次；支持普通文本、条件文本和二周目现实文本。
- 仪式检查点 -- `ritual_checkpoint.tscn` + `ritual_tracker.gd` -- `[P1]` 用四个不可见区域判断顺时针或逆时针绕柱，不做精确 360 度数学判定；正确步骤要发光或升调，错误顺序自动重置。
- 出口触发器 -- `ending_entrance.tscn` + `ending_entrance.gd` -- `[P0]` 用于正上方盒盖、门缝、电线、冷冻凹槽、返回出生点、向下根系和灯开关等结局出口；不满足条件时显示缺失提示。
- 全局本局状态 -- `game_state.gd` -- `[P0]` Autoload，记录 `devour_count`、`nurture_count`、`noise_count`、`milk_count`、`frost_count`、道具字典、仪式字典和最终出口；重开时清空本局数据。
- 结局解锁状态 -- `progress_state.gd` 或合并到 `game_state.gd` -- `[P1]` 保存已解锁结局、是否完成首周目、是否开启现实标签；重开本局时不能清除。
- 结局判定器 -- `ending_resolver.gd` -- `[P0]` 所有结局条件集中在一个脚本；优先级固定为“精确配方彩蛋 > 特殊仪式 > 指定出口 > 行为倾向 > 默认土豆”，禁止将判断散落到各道具脚本。
- 文本播放系统 -- `narrative_manager.gd` + `dialogue_box.tscn` -- `[P0]` 负责文本队列、打字机效果、立即显示全文、自动淡出和演出期间输入锁定；不能因连续触发而覆盖上一段文字。
- 音频管理系统 -- `audio_manager.gd` -- `[P0]` 管理 Music、Ambience、SFX、UI 四个总线，负责环境循环、一次性音效和结局音乐切换；不在每个脚本里重复加载音频。
- 通用结局画面 -- `ending_screen.tscn` + `ending_screen.gd` -- `[P0]` 加载对应结局的一张完整插画，再叠加标题、副标题、结局编号、重开按钮和退出按钮；不再加载背景、角色立绘或覆盖层组合。
- 结局图鉴 -- `ending_gallery.tscn` + `ending_gallery.gd` -- `[P1]` 显示已解锁图标和未解锁剪影；未解锁项只显示一句谜语，首版至少显示“已发现结局 X/N”。
- 主菜单 -- `main_menu.gd` + `ui_logo.png` + `ui_main_menu_background.png` -- `[P0]` 已由程序动态创建，包含开始游戏、新手教程和退出；直接使用 Logo 与主菜单背景图片，首周目后仍可显示再次发芽语义。
- 新手教程 -- `tutorial_overlay.gd` -- `[PG]` 六步程序 UI，覆盖移动、疾跑、E 交互、Space 蓄力、背包/地图和探索目标；首次开始游戏自动显示，也可从主菜单重复打开并支持跳过。
- 暂停菜单 -- `pause_menu.tscn` + `pause_menu.gd` -- `[P1]` 包含继续、重新开始、主菜单、音量和退出；结局演出期间不能打开。
- 物品栏 / 背包 -- `inventory_panel.tscn` + `inventory_panel.gd` -- `[P1]` 按 I 或 Tab 查看本局已获得道具、分类、数量和双重名称；只读取 GameState，不另存库存。
- 垂直地图生成器 -- `procedural_map_generator.gd` + `map_generation_rules.tres` -- `[P0]` 按 `run_seed` 生成七个自底向上生态层、横向扇区、上下路线、侧室、区域与道具，并验证连通性、关键物品顺序、碰撞重叠和仪式净空。
- 存档配置 -- `save_data.cfg`，运行时生成 -- `[P1]` 只保存已解锁结局、总游戏次数和首周目状态，不保存复杂场景位置；不得随源代码提交真实运行存档。
- Windows 导出预设 -- `export_presets.cfg` -- `[P0]` 配置 Windows Desktop x86_64 Release 导出；不得提交 `.godot/export_credentials.cfg`。
- 程序调试说明 -- `docs/debug_guide.md` -- `[P1]` 记录常见错误、输入、强制触发某结局的方法和测试快捷键，方便队友自行验证素材。

## 2. 基础美术资产

### 2.1 玩家与状态外观

- [C1] 中性芽尖 -- `sprout_head_neutral.png` -- 运行时 `.png` 透明背景，建议不小于 256×256 -- `[P0]` 玩家头部默认造型；轮廓在深色背景和小光圈中仍需清晰，朝向最好可通过旋转节点完成。
- [C1] 中性芽体纹理 -- `sprout_trail_neutral.png` -- `.png` 透明背景，可平铺 -- `[P0]` 用作 Line2D 的纹理；左右边缘能够无缝衔接，中心较亮、边缘较暗，不绘制固定方向阴影。
- [C1] 母薯本体 -- `env_mother_potato.png` -- `.png` 透明背景 -- `[P0]` 出生点的干瘪土豆，需包含皱皮、芽眼和少量泥土；前期只被局部光照看到，终局能与现实土豆对应。
- [PG] 旧神眼纹覆盖层 -- `sprout_eldritch_eye_closed.png`、`sprout_eldritch_eye_half.png`、`sprout_eldritch_eye_open.png` -- 程序像素几何 -- `[P0]` 收集三件旧神遗物后的反馈由程序眼睛、逆向粒子和紫色脉冲表现，不读取覆盖图片。
- [PG] 奶化颜色覆盖层 -- `sprout_milk_stage_01.png`、`sprout_milk_stage_02.png`、`sprout_milk_stage_03.png` -- 程序颜色与像素粒子 -- `[P0]` 每吸收一滴牛奶由程序切换白色、淡黄、金黄三阶段颜色，不读取覆盖图片。
- [C1] 奶香幼龙小角 -- `sprout_dragon_horn_left.png` + `sprout_dragon_horn_right.png` -- 两张独立 `.png` 透明图片 -- `[P0]` 第二滴奶后出现的小角；造型必须原创，不直接复刻已有商业角色。
- [PG] 共生绿叶覆盖层 -- `sprout_symbiosis_leaf_01.png` 至 `sprout_symbiosis_leaf_03.png` -- 程序像素几何 -- `[P1]` 每帮助一名蔬菜同伴由程序增加叶片与绿色脉冲，不读取覆盖图片。
- [PG] 吞噬尖刺覆盖层 -- `sprout_devour_spike_01.png` + `sprout_devour_spike_02.png` -- 程序像素几何 -- `[P1]` 高吞噬值时由程序改变轮廓、颜色与尖刺，不读取覆盖图片。
- [PG] 霜化结晶覆盖层 -- `sprout_frost_stage_01.png` 至 `sprout_frost_stage_03.png` -- 程序像素几何 -- `[P1]` 轻、中、重霜化由程序冷色、结晶与方形粒子表现，不读取覆盖图片。
- [PG] ROOT 电流覆盖层 -- `sprout_root_electric.png` -- 程序像素线条 -- `[P1]` 接通线路后由程序绘制电弧、金边与扫描噪点，不读取覆盖图片。
- [C1] 被剪断的健康芽眼 -- `sprout_healthy_eye_cut.png` -- `.png` 透明背景 -- `[P2]` 《今天不长》结局最终留下的小芽眼，与腐化芽体形成视觉对照。

### 2.2 主关卡环境

- [C1] 冰箱垂直模块背景组 -- `env_fridge_backplate_tile_01.png` 至 `env_fridge_backplate_tile_06.png` -- 6 张 `1024×1024` sRGB `.png`；四边可无缝平铺 -- `[P0]` 六张文件已接入；程序按七个生态层循环拼装，生态色只以低透明度叠加，确保背板、搁架、污渍与冷凝水保持可见。

#### 自底向上程序化地图尺寸交付表

地图逻辑画布固定为 `25600×25600 px`，左上角为 `(0, 0)`，出生点约为 `(12800, 23600)`，主要探索方向为向上。有效内容区的横向范围约为 `x=900–24700`，上下范围约为 `y=1200–24400`；四边剩余区域是世界安全边距和外壳收束，不要求铺满高密度装饰。

| 层编号 | 自底向上范围 | 层高 | 横向作图区 | 主要用途 | 美术重点 |
|---|---|---:|---|---|---|
| 层 01（底部核心） | `y=22600–24400` | `1800 px` | `x=900–24700` | 母薯出生区、基础教学、返回安全区 | 腐土、母薯、低密度冷凝水；出生点周围约 `360 px` 半径保持低装饰安全区 |
| 层 02 | `y=19300–22200` | `2900 px` | `x=900–24700` | 腐土与现实线索 | 皱皮、日期贴纸、黑水边缘、破裂抽屉；上下过渡使用颜色和材质渐变 |
| 层 03 | `y=15700–18900` | `3200 px` | `x=900–24700` | 保鲜膜、黄瓜与早期分支 | 保鲜膜接缝、黄瓜残骸、包装角；保留多条垂直和侧向视觉引导 |
| 层 04 | `y=12100–15300` | `3200 px` | `x=900–24700` | 同伴、养分与根网 | 根须温床、花盆碎片、绿色脉冲；大面积重复不能出现明显棋盘格 |
| 层 05 | `y=8500–11700` | `3200 px` | `x=900–24700` | 泰坦赤柱、冰霜与遗物 | 辣酱瓶/赤柱周边、冰霜带、遗物冷光；赤柱本体单独交付，不嵌入背景瓦片 |
| 层 06 | `y=4800–8100` | `3300 px` | `x=900–24700` | 温控、终端与基础设施 | 线路、条形码、压缩机和控制面板；冷蓝色金属材质，避免大面积纯黑 |
| 层 07（顶部外壳） | `y=1200–4400` | `3200 px` | `x=900–24700` | 外壳、盒盖、门缝与特殊出口 | 冰箱内壁、盒盖、门封和暖光缝；顶部边缘须有收束高光，但不画成横向碰撞墙 |

补充交付约束：

- 以上七层是逻辑分区和美术语言，不是七堵连续实体墙；层与层之间必须保留开放上下通行带，不能用深色实线或不可穿越厚边表示边界。
- `tile_01` 至 `tile_06` 是材质模块，不要求一张图对应一个层；程序会按层主题、扇区和随机种子重复拼装。每张图四边必须能与自身及其他瓦片衔接，建议边缘色值和噪声强度做 64 px 的可混合过渡。
- 纵向搁架、塑料膜接缝和冷凝水轨迹应提供少量方向性版本；若只交付一张，程序会旋转使用，但不能依赖固定“上方”光源。
- 层 05 的赤柱、层 07 的盒盖和门缝属于独立可碰撞道具/结构，分别使用环境物体文件，不把它们烘焙进背景瓦片。
- [C1] 腐烂黄瓜主体 -- `env_rotten_cucumber_intact.png` + `env_rotten_cucumber_broken.png` -- `.png` 透明背景，完整、破损两版 -- `[P0]` 完整态与破损态均已提供；完整态接入第一处黑水区域，破损态保留给后续腐败/结局状态。
- [C1] 腐败黑水与黏液块 -- `env_slime_pool_01.png` 至 `env_slime_pool_05.png` -- `.png` 透明背景，3-5 种轮廓 -- `[P0]` 黏性减速区域；边缘需能平铺或自由缩放。
- [PG] 腐败气味薄雾 -- `vfx_rot_mist.png` -- 程序像素粒子 -- `[P1]` 使用稀疏半透明方块和漂移参数提示“甜腐气味”，不读取粒子贴图且不可遮挡移动。
- [C1] 完整保鲜膜 -- `env_plastic_film_intact.png` -- `.png` 透明背景 -- `[P0]` 第二阶段“虚空之茧”；透明度适中，黑暗中靠高光边缘辨认。
- [C1] 拉伸保鲜膜 -- `env_plastic_film_stretch_01.png` + `env_plastic_film_stretch_02.png` -- `.png` 透明背景，至少 2 帧 -- `[P0]` 玩家蓄力时逐步变形。
- [C1] 裂纹保鲜膜 -- `env_plastic_film_crack_01.png` + `env_plastic_film_crack_02.png` -- `.png` 透明背景，至少 2 帧 -- `[P0]` 第 02 帧已由交付的第 03 帧建立规范别名，蓄力时按完整、拉伸、裂纹状态播放。
- [PG] 破裂保鲜膜碎片 -- `vfx_plastic_film_shard_01.png` 至 `vfx_plastic_film_shard_08.png` -- 程序像素碎片 -- `[P0]` 破膜瞬间由程序生成方形/菱形碎片，颜色从完整薄膜状态取得，不读取粒子图片。
- [C1] 辣酱玻璃瓶主体 -- `env_hot_sauce_bottle.png` -- `.png` 透明背景 -- `[P0]` 第三阶段“泰坦巨柱”；瓶身、瓶盖、标签和瓶底红油应在一张图中清晰可辨，仪式反馈由程序处理。
- [C1] 辣酱瓶普通标签 -- `env_hot_sauce_label.png` -- `.png` 透明背景 -- `[P0]` 显示残缺“开封后请冷藏”等现实文字；不得直接使用真实品牌完整商标，可做原创仿制包装。
- [C1] 冰霜障碍组 -- `env_frost_spike_01.png` 至 `env_frost_spike_03.png`、`env_frost_chunk_01.png` 至 `env_frost_chunk_03.png`、`env_frost_sheet_01.png` 至 `env_frost_sheet_03.png` -- `.png` 透明背景，尖刺、碎块、薄层至少各 3 种 -- `[P0]` 第三阶段霜毒障碍；需要清楚区分可吸收小霜晶和不可穿过的大冰块。
- [C1] 硬质包装块 -- `env_hard_package_01.png` 至 `env_hard_package_05.png` -- `.png` 透明背景，3-5 种 -- `[P0]` 作为一般硬障碍，包括饭盒边、包装纸角和塑料托盘。
- [C1] 冰箱玻璃搁板 -- `env_glass_shelf.png` -- `.png` 透明背景，可横向拉伸 -- `[P0]` 作为关卡结构与平台边界；透明高光不能和保鲜膜混淆。
- [C1] 外卖盒主体 -- `env_takeout_box.png` -- `.png` 透明背景 -- `[P0]` 出生容器或终局容器；盒身、盒盖、卡扣、污渍和标签需在一张图中清晰可辨。
- [C1] 最终盒盖完整态 -- `env_final_lid_intact.png` -- `.png` 透明背景 -- `[P0]` “最后苍穹”，需要明确的受力中心和冷白边缘。
- [C1] 最终盒盖受力态 -- `env_final_lid_strain_01.png` 至 `env_final_lid_strain_03.png` -- `.png` 透明背景，至少 3 帧 -- `[P0]` 长按蓄力时下陷、抖动和开裂。
- [C1] 最终盒盖开启态 -- `env_final_lid_open.png` -- `.png` 透明背景 -- `[P0]` 配合“咔哒”、全屏白光和结局切换。
- [C1] 冰箱顶灯 -- `env_fridge_light_off.png` + `env_fridge_light_on.png` -- `.png` 透明背景，关闭和点亮两版 -- `[P0]` 默认反转中的“神圣天光”，也服务《万芽之主》的伪太阳机关。
- [C1] 冰箱门灯开关顶杆 -- `env_light_switch_released.png` + `env_light_switch_pressed.png` -- `.png` 透明背景，按下和弹起两版 -- `[P1]` 终点侧面的隐藏交互机关；按住可熄灭伪太阳，关联《万芽之主》。
- [C0] 冰箱门封与暖光缝 -- `env_door_seal_cold.png` + `env_door_seal_warm.png` -- `.png` 透明背景，冷暗和暖亮两版 -- `[P1]` 两张规范文件仍未找到；《真正的破晓》侧面出口暂用程序暖光框表示。
- [C1] 冷冻室凹槽 -- `env_freezer_recess.png` -- `.png` 透明背景 -- `[P1]` 《永冬胚种》的最终休眠位置，需要能容纳玩家盘成种子形状。
- [C1] 温控器与线路区域 -- `env_thermostat_circuit.png` -- `.png` 透明背景 -- `[P1]` 《ROOT 权限》的隐藏路径，需在一张图中清楚表现温度探针、断线、触点和四拍指示灯。
- [C1] 塑料垃圾袋 -- `env_trash_bag_open.png`、`env_trash_bag_wrapped.png`、`env_trash_bag_dropped.png` -- `.png` 透明背景，打开、包裹、落地 3 态 -- `[P1]` 《垃圾大陆之王》的现实清理演出使用。
- [C1] 已取消的阳台结局背景拆分素材 -- `ending_balcony_window.png` -- 不再单独制作 -- `[P1]` 原拆分方案已取消；暖色窗台、花盆和土豆芽统一交付为 `ending_04_full.png`。
- [C1] 已取消的填埋场结局背景拆分素材 -- `ending_landfill_silhouette.png` -- 不再单独制作 -- `[P2]` 原拆分方案已取消；垃圾袋、雨夜和紫色芽眼统一交付为 `ending_12_full.png`。

## 3. 全部隐藏道具与现实线索美术

> 本节列出当前十二个正式结局会使用或提示的隐藏道具。`P2` 仅表示制作优先级，不代表附加结局；未被这十二个结局使用的旧候选不再制作。相同物体若只需换色或改文字，应尽量复用同一主素材。

### 3.1 默认反转与基础现实线索

- [C1] 褪色日期贴纸 -- `clue_expiry_label_clean.png` + `clue_expiry_label_stained.png` -- `.png` 透明背景 -- `[P0]` 第一幕现实线索，表层像古代数字石片，细看可读“第三个月”或具体过期日期；需要完整态和被污渍遮挡态。
- [C1] 发芽土豆警告残片 -- `clue_sprouted_potato_warning_full.png` -- `.png` 透明背景 -- `[P0]` 默认结局核心提示。
- [C1] 超市特价标签 -- `clue_supermarket_sale_tag.png` -- `.png` 透明背景 -- `[P0]` 保鲜膜破裂时闪过“特价蔬菜、买一赠一”，既是现实线索，也是 KPI 结局的价签素材。
- [C1] 保鲜膜指纹 -- `clue_plastic_film_fingerprint.png` -- `.png` 透明背景，浅灰高光 -- `[P0]` 藏在薄膜褶皱上，近看像巨大古老纹路，现实含义是手指捏过的痕迹。
- [C1] “开封后请冷藏”标签残片 -- `clue_refrigerate_after_opening.png` -- `.png` 透明背景 -- `[P0]` 位于辣酱瓶边缘，作为现实层的重要文本线索；字体需在局部光圈内仍可辨认。
- [C1] 冻坏的葱段 -- `clue_frozen_scallion_normal.png` + `clue_frozen_scallion_frosted.png` -- `.png` 透明背景，普通和结霜两版 -- `[P0]` “绿色亡魂”线索，也可升级为共生对象或霜化警告。
- [C1] 皱皮土豆外壳碎片 -- `clue_wrinkled_potato_skin.png` -- `.png` 透明背景 -- `[P0]` 靠近终点时照见主角真实身体，用于暗示自身已经发皱老化。
- [C1] 购物小票主条 -- `clue_receipt_front.png` + `clue_receipt_back.png` -- `.png` 透明背景，正反面两版 -- `[P1]` 一面是普通购物记录，一面可写花盆计划、隐藏配方或命运清单；也是多路线共用的线索载体。
- [C1] “周日清冰箱”便签 -- `clue_sunday_fridge_cleanup_note.png` -- `.png` 透明背景 -- `[P1]` 预告高噪音后会被主人提前清理，也关联《垃圾大陆之王》。
- [C1] 外卖订单标签 -- `clue_takeout_order_label.png` -- `.png` 透明背景 -- `[P1]` 带订单号和日期，用于强化冰箱现实与社畜生活感，不单独构成结局条件。
- [C1] 干燥剂或除味包 -- `clue_deodorizer_packet.png` -- `.png` 透明背景，原创包装 -- `[P2]` 作为普通环境红鲱鱼，包装上有“请勿食用”；不绑定任何独立结局。

### 3.2 克苏鲁真结局道具

- [C1] 腐败之眼 -- `item_eye_of_decay_dormant.png` + `item_eye_of_decay_glow.png` -- `.png` 透明背景，休眠和发光两版 -- `[P0]` 藏在腐烂黄瓜黑水中的第一件旧神遗物；现实可解释为黑色孢核或腐败斑点，吸收后玩家获得第一枚眼纹。
- [C1] 猩红圣膏 -- `item_scarlet_ointment_still.png` + `item_scarlet_ointment_flow.png` -- `.png` 透明背景，静止和流动两版 -- `[P0]` 辣酱瓶底的一滴红油，第二件旧神遗物；必须区别于场景中的普通红色污渍和玻璃反光，可使用更深的核心高光。
- [C1] 永冻之心 -- `item_heart_of_eternal_frost.png` + `item_heart_of_eternal_frost_empty.png` -- `.png` 透明背景，完整和吸收后空壳两版 -- `[P0]` 冷冻层核心冰晶，第三件旧神遗物；中心含眼形裂纹，吸收后玩家获得第三枚眼纹。
- [PG] 三枚遗物空槽 -- `ui_relic_slots_00.png` 至 `ui_relic_slots_03.png` -- 程序像素 UI -- `[P0]` 由程序绘制空槽、亮起数量和状态文字，不读取 UI 图片。
- [C1] 黑色终局圆环 -- `env_eldritch_final_ring_closed.png` + `env_eldritch_final_ring_open.png` -- `.png` 透明背景，关闭和开启两版 -- `[P0]` 三遗物集齐后显现的真结局入口，外观同时像召唤阵、盒盖污渍和土豆芽眼。
- [C1] 逆时针仪式刻痕 -- `env_ritual_marks_counterclockwise.png` -- `.png` 透明背景 -- `[P1]` 辣酱瓶周围的四段残缺箭头，提示玩家逆时针盘柱；不要画成过于明显的游戏 UI。
- [C1] 黑白残缺经文三片 -- `clue_eldritch_script_01.png` 至 `clue_eldritch_script_03.png` -- `.png` 透明背景，3 张独立素材 -- `[P1]` 三张文件已齐全，分别提示“三腐星归位、逆行盘赤柱、第三次呼吸扼伪日”。

### 3.3 奶香幼龙彩蛋道具

- [C1] 牛奶滴 -- `item_milk_drop_01.png` 至 `item_milk_drop_03.png` -- `.png` 透明背景，1 张主图加 2 种轮廓变化 -- `[P0]` 地图中放置三滴，实际复用同一素材；每收集一滴依次触发 Do、Re、Mi，并推进玩家白、黄、金三阶段。
- [C1] 奶酪黄边 -- `item_golden_cheese_rind.png` -- `.png` 透明背景 -- `[P0]` “日之金鳞”，已确定为奶龙配方唯一黄色素材；外观是弯曲的黄色奶酪边，需要与洪山菜薹花瓣和红色污渍明确区分。
- [C1] 黄色牛奶瓶盖 -- `env_yellow_milk_cap_front.png` + `env_yellow_milk_cap_side.png` -- `.png` 透明背景，正面和侧面两版 -- `[P0]` “黄金卵壳”，玩家需要围绕它完成蛋形仪式；尺寸要足够让玩家绕行。
- [C1] 奶龙酸奶杯图案 -- `env_dragon_yogurt_art.png` -- `.png` 透明背景 -- `[P0]` 奶龙最终仪式地点；图案可参考奶娃，尾巴或视线可以暗示瓶盖方向。
- [C1] 原创奶龙冰箱贴 -- `clue_original_chubby_dragon_magnet.png` -- `.png` 透明背景 -- `[P1]` 奶龙路线的提前视觉提示；可将尾巴设计成箭头，但不要直接出现“喝三滴奶”的明文。
- [C1] 乳白配方童谣标签 -- `clue_milk_dragon_rhyme_label.png` -- `.png` 透明背景 -- `[P1]` 显示“三滴白母泪、一片日之鳞、蜷于旧像前”等线索；表面看像儿童食品说明。

### 3.4 《真正的破晓》道具

- [C1] 干净冷凝水滴 -- `item_clean_condensation_01.png` 至 `item_clean_condensation_03.png` -- `.png` 透明背景，2-3 种轮廓 -- `[P1]` 与牛奶滴使用不同色温和音效；路线需要至少两滴，用于净化芽体和帮助其他生命。
- [C1] 门缝泥土颗粒 -- `item_door_soil_01.png` 至 `item_door_soil_05.png` -- `.png` 透明背景，3-5 个颗粒组合 -- `[P1]` 暗示侧面门缝连接真实世界和花盆，是《真正的破晓》的必要道具。
- [C1] 花盆计划小票背面 -- `clue_flowerpot_plan_receipt.png` -- `.png` 透明背景 -- `[P1]` 写有“周末给阳台花盆添土”或简笔花盆；与购物小票正面组成翻面线索。

### 3.5 《保鲜层自治森林》共生道具

- [C1] 洋葱同伴 -- `npc_onion_sleep.png`、`npc_onion_glow.png`、`npc_onion_sprout.png` -- `.png` 透明背景，沉睡、发光、发芽三态 -- `[P1]` “千眼先知”，短触可唤醒、长按可吞噬；需要明显的生命脉冲部位。
- [C1] 蒜头同伴 -- `npc_garlic_sleep.png`、`npc_garlic_glow.png`、`npc_garlic_sprout.png` -- `.png` 透明背景，沉睡、发光、发芽三态 -- `[P1]` “白齿隐士”，共生路线第二名同伴，轮廓与洋葱要明显不同。
- [C1] 老姜同伴 -- `npc_ginger_sleep.png`、`npc_ginger_glow.png`、`npc_ginger_sprout.png` -- `.png` 透明背景，沉睡、发光、发芽三态 -- `[P1]` “盘根贤者”，共生路线第三名同伴；也可改为葱根，但最终只保留一个版本。
- [C1] 共生水滴标记 -- `env_symbiosis_water_empty.png` + `env_symbiosis_water_filled.png` -- `.png` 透明背景，空、注水两态 -- `[P1]` 每名同伴旁的自然容器，用来表现玩家已送水，避免玩家忘记完成状态。
- [C1] 根系连接节点 -- `env_root_node_disconnected.png` + `env_root_node_connected.png` -- `.png` 透明背景，未连接和连接两态 -- `[P1]` 三个区域完成连接时点亮，最终组合成发光网络。

### 3.6 《无限增长有限公司》道具

- [C1] 促销价签 A -- `item_sale_tag_a.png` -- `.png` 透明背景 -- `[P1]` 第一张可扫描价签，带上升箭头和折扣数字，收集时播放收银提示音。
- [C1] 促销价签 B -- `item_sale_tag_b.png` -- `.png` 透明背景 -- `[P1]` 第二张可扫描价签，构图与 A 不同但属于同一套包装。
- [C1] 促销价签 C -- `item_sale_tag_c.png` -- `.png` 透明背景 -- `[P1]` 第三张可扫描价签，集齐后允许触发 KPI 结局。
- [C1] 条形码经文碎片 -- `item_barcode_fragment_01.png` 至 `item_barcode_fragment_04.png` -- `.png` 透明背景，至少 4 片 -- `[P1]` 条形码既是现实包装，也是“黑白经文”；可与三张价签合并制作，减少独立素材量。
- [C1] 普通养分团块 -- `item_nutrient_clump_01.png` 至 `item_nutrient_clump_05.png` -- `.png` 透明背景，3-5 种轮廓 -- `[P1]` 高吞噬路线的可选资源；吃掉后增加长度和吞噬值，留下干瘪空壳。
- [C1] 干瘪养分空壳 -- `env_nutrient_husk_01.png` 至 `env_nutrient_husk_03.png` -- `.png` 透明背景，3 种 -- `[P1]` 玩家吸收后替换原物，明确表现世界被榨干，而不是道具凭空消失。
- [C1] 红色增长箭头贴纸 -- `clue_growth_arrow_red.png` -- `.png` 透明背景 -- `[P2]` 旁白转变为公司语言后的环境反馈，也可用于结局季度报告 UI。

### 3.7 《永冬胚种》道具

- [C1] 可收集霜晶 -- `item_frost_crystal_01.png` 至 `item_frost_crystal_04.png` -- `.png` 透明背景，4 种形状 -- `[P1]` 地图放置四枚，每枚中心亮度略有差异；必须和普通伤害冰刺明显区分。
- [C1] 冻豌豆袋 -- `env_frozen_pea_bag.png` -- `.png` 透明背景 -- `[P1]` “十二座透明棺椁”或沉眠区域，袋内需要能藏眠石。
- [C1] 眠石 -- `item_sleeping_stone_dormant.png` + `item_sleeping_stone_glow.png` -- `.png` 透明背景，沉睡和发光两版 -- `[P1]` 沉睡和发光两态已齐全，用于冻豌豆深处的休眠遗物。
- [C1] 温控旋钮 1-7 -- `env_thermostat_dial_01.png` 至 `env_thermostat_dial_07.png` -- `.png` 透明背景，旋钮与刻度清晰可辨 -- `[P1]` “七重寒冷封印”，玩家将其拨到第七格才能进入永冬路线；也参与洪山路线的禁止条件。
- [PG] 透明冰棺覆盖层 -- `env_ice_coffin_overlay.png` -- 程序像素覆盖 -- `[P1]` 玩家盘成种子后的封存效果由程序绘制阶梯冰框、边缘冰晶和结霜动画，不读取覆盖图片。

### 3.8 《ROOT 权限》道具

- [C1] 铝箔碎片 -- `item_aluminum_foil_01.png` 至 `item_aluminum_foil_03.png` -- `.png` 透明背景，2-3 种反光状态 -- `[P1]` “雷引”，用于连接线路；反光需在小光圈中清晰但不能像冰晶。
- [C1] 冰箱贴磁芯 -- `item_magnet_core_intact.png` + `item_magnet_core_broken.png` -- `.png` 透明背景，完整和破裂两版 -- `[P1]` “方向之核”，从普通冰箱贴背面取出；靠近电线时可表现轻微吸引。
- [C1] 导电冷凝水 -- `item_conductive_condensation.png` -- `.png` 透明背景 -- `[P1]` “流动之镜”，直接使用单张道具图，导电状态由程序颜色、闪烁和粒子表现，不再追加电光覆盖层图片。
- [C1] 断裂温控线 -- `env_thermostat_wire_broken.png` + `env_thermostat_wire_connected.png` -- `.png` 透明背景，断开和接通两版 -- `[P1]` ROOT 路线的主要交互对象，两个触点位置要与碰撞区域一致。
- [C1] 三个电气节点 -- `env_electric_node_dark.png`、`env_electric_node_lit.png`、`env_electric_node_error.png` -- `.png` 透明背景，暗、亮、错误闪红三态 -- `[P1]` 按“亮、亮、停、亮”节奏操作的节点，负责给玩家明确反馈。

### 3.9 洪山元素路线道具

- [C1] 洪山菜薹残破标签 -- `clue_hongshan_caitai_label_front.png` + `clue_hongshan_caitai_label_damaged.png` -- `.png` 透明背景，正面和污损两版 -- `[P1]` 《紫冠的新芽》核心身份线索；使用原创版式，文字可包含“洪山菜薹”，同时保留紫茎黄花视觉标识。
- [C1] 洪山菜薹防伪码 -- `clue_hongshan_caitai_security_mark.png` -- `.png` 透明背景，使用不可扫描的原创图案 -- `[P1]` 初看像克苏鲁召唤阵，现实模式下看出是防伪标签；不要复制真实企业二维码。
- [C1] 金黄色菜薹花瓣 -- `item_caitai_petals_01.png` 至 `item_caitai_petals_03.png` -- `.png` 透明背景，2-3 种轮廓 -- `[P1]` “黄冠碎片”，路线必要道具，与奶酪金边通过植物纹理和色相区分。
- [C1] 紫色菜薹根 -- `npc_caitai_root_sleep.png`、`npc_caitai_root_dry.png`、`npc_caitai_root_revived.png` -- `.png` 透明背景，沉睡、缺水、复苏三态 -- `[P1]` 被塑料袋压住的隐藏生命；玩家需要送水而非吞噬。
- [C1] 九岭十八凹图案残片 -- `clue_jiuling_shibao_pattern.png` -- `.png` 透明背景 -- `[P2]` 将本地地貌抽象成根系纹样，用于提示暖光方向和文化背景，避免直接变成长篇说明文字。

### 3.10 繁殖、反抗和向下路线道具

- [C1] 芽眼结节 A -- `item_sprout_nodule_a.png` -- `.png` 透明背景 -- `[P2]` 《不见天日的丰收》第一颗繁殖道具，形状偏圆。
- [C1] 芽眼结节 B -- `item_sprout_nodule_b.png` -- `.png` 透明背景 -- `[P2]` 第二颗繁殖道具，形状偏长，颜色与 A 同系列。
- [C1] 芽眼结节 C -- `item_sprout_nodule_c.png` -- `.png` 透明背景 -- `[P2]` 第三颗繁殖道具，中心有微小新芽；三者集齐后允许返回出生点播种。
- [C1] 干净腐殖团 -- `env_clean_compost_empty.png` + `env_clean_compost_planted.png` -- `.png` 透明背景，普通和已播种两版 -- `[P2]` 埋入芽眼结节的柔软土壤，不增加腐败或吞噬值。
- [C1] 被剪断的旧芽 -- `clue_old_sprout_withered.png` + `clue_old_sprout_glow.png` -- `.png` 透明背景，枯萎和微光两版 -- `[P2]` 《今天不长》的可观察线索，提示“它曾经也相信上方就是答案”。
- [C1] 隐藏向下箭头 -- `clue_hidden_down_arrow_dim.png` + `clue_hidden_down_arrow_revealed.png` -- `.png` 透明背景，暗淡和显现两版 -- `[P2]` 教学文字消失后短暂出现，提示拒绝向上；不能使用普通 UI 风格，要像包装划痕或根纹。
- [C1] “根部浸水可再生”说明片 -- `clue_root_regrow_instruction.png` -- `.png` 透明背景 -- `[P2]` 同时提示繁殖、共生和真正破晓路线，可复用葱根标签设计。

### 3.11 垃圾大陆结局辅助道具

- [C1] 可堆肥标签 -- `clue_compostable_label_intact.png` + `clue_compostable_label_torn.png` -- `.png` 透明背景，完整和撕裂两版 -- `[P1]` 《垃圾大陆之王》的关键提示；读到标签后垃圾堆可继续生长并进入二段结算，未读到则停在垃圾袋现实结算。
- [C1] 垃圾袋封口扎带 -- `env_trash_bag_tie_loose.png` + `env_trash_bag_tie_tight.png` -- `.png` 透明背景，松开和扎紧两版 -- `[P1]` 表现玩家反复撞击、撕裂和堆叠垃圾袋的破坏反馈；结局演出时用于确认垃圾大陆已经形成。
- [C1] 填埋场紫色芽眼 -- `ending_landfill_sprout_single.png` + `ending_landfill_sprout_cluster.png` -- `.png` 透明背景，单颗和群集两版 -- `[P2]` 读到可堆肥标签后的二段结局远景，不单独触发结局。

## 4. UI 与字体（程序像素绘制，主菜单保留指定图片）

> 除主菜单明确指定的 Logo 与背景外，运行时 UI 不读取 `ui_` 图片；面板、按钮、槽位、进度条、键帽、闪屏、晕影和终端均由 Godot Control/CanvasItem 程序绘制。

- [C1] 游戏标题 Logo -- `ui_logo.png` -- `.png`，透明背景，建议保留原始像素边缘 -- `[P0]` 主菜单直接显示；程序叠加冷紫色暗角和按钮，不再重绘 Logo 主体。
- [C1] 主菜单背景 -- `ui_main_menu_background.png` -- `.png`，建议 1280×720 或可裁切宽画面 -- `[P0]` 主菜单直接使用，程序叠加暗角和面板；不参与关卡背景拼装。
- [PG] 对话框底板 -- `ui_dialogue_panel.png` -- 程序 StyleBox -- `[P0]` 方角、4 px 边框、像素阴影和低透明深蓝底板。
- [C1] 中文史诗字体 -- `NotoSerifSC-VF.ttf` -- `.ttf`，需覆盖简体中文字符，保留原字体许可证 -- `[P0]` 已接入程序全局 Theme；正文使用高可读衬线字形，标题通过字号、描边和冷紫色强化神秘感。
- [PG] 标题字体 -- `font_title_zh.ttf` + `font_title_zh_license.txt` -- Godot 默认字体与程序描边 -- `[P1]` 若后续提供专用标题字体，可替换 `NotoSerifSC-VF.ttf`；当前不阻塞运行。
- [PG] 键位图标组 -- `ui_key_w.png`、`ui_key_a.png`、`ui_key_s.png`、`ui_key_d.png`、`ui_key_arrows.png`、`ui_key_e.png`、`ui_key_space.png`、`ui_key_r.png`、`ui_key_esc.png`、`ui_key_i.png`、`ui_key_tab.png` -- 程序键帽 -- `[P0]` 统一使用方角 StyleBox 和文字生成键帽，不读取图片。
- [PG] 交互提示底板 -- `ui_interaction_prompt_panel.png` -- 程序 StyleBox -- `[P0]` 紫黑底、5 px 阶梯边框和文字描边，由程序响应窗口缩放。
- [PG] 蓄力进度条 -- `ui_charge_bar_empty.png`、`ui_charge_bar_fill.png`、`ui_charge_bar_flash.png` -- 程序 ProgressBar -- `[P0]` 底槽、填充、满蓄颜色与闪烁均由 StyleBox/Tween 生成。
- [PG] 道具获得提示图标框 -- `ui_item_acquired_frame.png` -- 程序 StyleBox -- `[P1]` 方形像素边框、神话名和提示文字由程序组合。
- [PG] 物品栏底板与槽位 -- `ui_inventory_panel.png` + `ui_inventory_slot.png` + `ui_inventory_category_icons.png` -- 程序 Control -- `[P1]` 背包面板、分类和槽位全部由方角 StyleBox 与动态文本生成。
- [PG] 三遗物槽 UI -- `ui_relic_slots_00.png` 至 `ui_relic_slots_03.png` -- 程序像素槽位 -- `[P1]` 由程序根据持有数量绘制空槽与亮起状态。
- [PG] 结局图鉴种子剪影 -- `ui_ending_seed_01.png` 至 `ui_ending_seed_12.png` -- 程序像素剪影 -- `[P1]` 未解锁/已解锁状态使用程序几何与结局配色。
- [PG] 结局编号牌 -- `ui_ending_number_plate.png` -- 程序 StyleBox -- `[P1]` 编号、总数和批次标签感由程序排版生成。
- [PG] 暂停菜单底板 -- `ui_pause_menu_panel.png` -- 程序 StyleBox -- `[P1]` 深蓝方角面板、紫色边框和像素阴影，不读取图片。
- [PG] 白光闪屏 -- `ui_white_flash.png` -- 程序 CanvasItem/Tween -- `[P0]` 全屏颜色与透明度由程序控制。
- [PG] 黑暗晕影 -- `ui_dark_vignette.png` -- 程序阶梯边框 -- `[P0]` 使用多层矩形边缘压暗和稀疏扫描线，不读取晕影图片。
- [PG] 圆形柔光纹理 -- `light_soft_circle.png` -- 程序 ImageTexture -- `[P0]` 启动时生成径向 Alpha 纹理供 PointLight2D 使用。
- [PG] 垂直进度与生态层指示 -- `ui_vertical_progress.png` + `ui_layer_indicator.png` -- 程序 HUD -- `[P1]` 当前高度、生态层、方向与疾跑条由程序实时排版。
- [PG] KPI 报表 UI -- `ui_kpi_report.png` -- 程序 Control -- `[P1]` 动态数字、上升箭头和状态语句由程序生成。
- [PG] ROOT 终端 UI -- `ui_root_terminal.png` -- 程序文本与扫描线 -- `[P1]` 终端命令、错误和授权状态使用程序文字与像素故障线。

## 5. 结局完整插画（不再使用覆盖层拼装）

> 十二个正式结局各交付一张完整的 `1920×1080` sRGB `.png`。画面须把背景、角色、道具、光效和结局状态直接合成在同一张图中，不需要透明通道、PSD/KRA、角色立绘、母版或额外覆盖层；标题、副标题、编号和按钮由程序叠加。

- [C1] 结局 01《生长成功，食用失败》完整插画 -- `ending_01_full.png` -- `1920×1080` 不透明 `.png` -- `[P0]` 半米长紫黑芽顶开外卖盒，保留冰箱现实反转和喜剧感；作为宣传截图的核心视觉。
- [C1] 结局 02《万芽之主》完整插画 -- `ending_02_full.png` -- `1920×1080` 不透明 `.png` -- `[P0]` 黑色圆环、旧神眼睛、触手和城市冰箱巨眼合并为一张完整画面，不能依赖后续叠层。
- [C1] 结局 03《奶龙降生》完整插画 -- `ending_03_full.png` -- `1920×1080` 不透明 `.png` -- `[P0]` 原创圆滚滚幼龙、黄色蛋壳、牛奶和吸管在同一画面中完成，避免拆分角色姿势。
- [C1] 结局 04《真正的破晓》完整插画 -- `ending_04_full.png` -- `1920×1080` 不透明 `.png` -- `[P1]` 暖色窗台、花盆、土豆芽和厨房窗框直接合成，表现已经种下并长出新叶的结果。
- [C1] 结局 05《保鲜层自治森林》完整插画 -- `ending_05_full.png` -- `1920×1080` 不透明 `.png` -- `[P1]` 根系、叶片、菌落、水滴与三名蔬菜同伴组成完整的保鲜层森林。
- [C1] 结局 06《无限增长有限公司》完整插画 -- `ending_06_full.png` -- `1920×1080` 不透明 `.png` -- `[P1]` 无限上升的芽群、增长箭头和荒诞 KPI 视觉直接合成，不要求单独枝条端点。
- [C1] 结局 07《永冬胚种》完整插画 -- `ending_07_full.png` -- `1920×1080` 不透明 `.png` -- `[P1]` 冰棺、边缘结霜、中心芽眼和永冬环境构成完整封存画面。
- [C1] 结局 08《ROOT 权限》完整插画 -- `ending_08_full.png` -- `1920×1080` 不透明 `.png` -- `[P1]` 温控线路、发光节点、ROOT 终端和接通后的芽体在同一画面中清楚可辨。
- [C1] 结局 09《紫冠的新芽》完整插画 -- `ending_09_full.png` -- `1920×1080` 不透明 `.png` -- `[P1]` 洪山菜薹的紫茎、黄花、根系和复苏芽体直接组成完整结算画面。
- [C1] 结局 10《不见天日的丰收》完整插画 -- `ending_10_full.png` -- `1920×1080` 不透明 `.png` -- `[P2]` 外卖盒内部的小土豆繁殖群和密集芽眼直接合成，不再要求五张可复用小土豆图。
- [C1] 结局 11《今天不长》完整插画 -- `ending_11_full.png` -- `1920×1080` 不透明 `.png` -- `[P2]` 主动脱落的紫黑芽、留下的健康芽眼和安静的黑暗环境合并为一张完整画面。
- [C1] 结局 12《垃圾大陆之王》完整插画 -- `ending_12_full.png` -- `1920×1080` 不透明 `.png` -- `[P2]` 垃圾袋、填埋场雨夜和群集紫色芽眼直接合成，覆盖现实清理与二段结局的最终状态。

## 6. VFX 与动画（全部程序像素绘制）

- [PG] 芽尖移动微光 -- `vfx_sprout_move_glow.png` -- 程序方形粒子 -- `[P0]` 玩家移动和状态变化时生成稀疏像素粒子，不读取贴图。
- [PG] 生长轨迹脉冲 -- `vfx_trail_pulse.gdshader` + `vfx_trail_gradient.png` -- 程序 Line2D -- `[P1]` 通过轨迹颜色和宽度参数表现生命脉冲，不读取渐变图片。
- [PG] 黏液气泡 -- `vfx_slime_bubble.png` -- 程序像素粒子 -- `[P1]` 使用低频小方块和菱形气泡，不读取贴图。
- [PG] 保鲜膜受力抖动 -- `anim_plastic_film_strain.tres` -- 程序 Tween -- `[P0]` 形变、颜色和抖动由代码参数驱动。
- [PG] 冰晶碎裂粒子 -- `vfx_ice_shard.png` -- 程序像素多边形 -- `[P0]` 使用白蓝色三角/方块碎片，不读取贴图。
- [PG] 黑色孢子粒子 -- `vfx_black_spore.png` -- 程序方形粒子 -- `[P0]` 缓慢逆向漂向玩家，数量和透明度由代码限制。
- [PG] 牛奶飞溅粒子 -- `vfx_milk_splash.png` -- 程序像素粒子 -- `[P1]` 使用乳白和金黄色方块/菱形，保持卡通化。
- [PG] 共生绿色脉冲 -- `vfx_symbiosis_pulse.png` -- 程序几何脉冲 -- `[P1]` 帮助同伴和连接根系时扩散像素环与方块。
- [PG] ROOT 电弧 -- `vfx_root_arc.png` + `vfx_root_arc.gdshader` -- 程序折线与故障条 -- `[P1]` 连接电路和终局时绘制低频闪烁折线，不读取图片/Shader。
- [PG] 全屏白光 Tween -- `anim_fullscreen_white_flash.tres` -- 程序 CanvasItem/Tween -- `[P0]` 从黑暗快速爆白并切换色调。
- [PG] 屏幕震动参数 -- `camera_shake_profiles.tres` -- 程序参数 -- `[P1]` 瓶子碰撞、盒盖突破、冰箱门开启使用三档可配置强度。
- [PG] 结霜屏幕覆盖动画 -- `vfx_screen_frost.png` + `vfx_screen_frost.gdshader` -- 程序阶梯冰晶 -- `[P1]` 屏幕边缘绘制像素冰晶和淡蓝扫描线，不读取图片/Shader。

## 7. 音频素材

### 7.1 环境与音乐

- [C1] 冰箱压缩机基础循环 -- `amb_fridge_compressor_loop.ogg` -- `.ogg`，48 kHz，立体声，无缝循环 15-30 秒 -- `[P0]` 全流程核心环境声，也是克苏鲁路线“巨兽呼吸”和第三次启动判定的听觉基础。
- [C1] 压缩机启动声 -- `sfx_compressor_start.wav` -- `.wav`，48 kHz -- `[P0]` 每次循环起始的低沉震动，需要有清楚但不突兀的节拍标记。
- [C1] 冰箱风道冷风循环 -- `amb_fridge_cold_air_loop.ogg` -- `.ogg`，48 kHz，无缝循环 -- `[P0]` 第二、三阶段使用，增加寒冷与空旷感。
- [C1] 前期史诗氛围音乐 -- `music_mythic_ambience_loop.ogg` -- `.ogg`，48 kHz，立体声，无缝循环 -- `[P0]` 低频、稀疏、克制，不能盖住文本提示和压缩机节奏。
- [C1] 第三阶段危险音乐层 -- `music_titan_danger_layer.ogg` -- `.ogg`，48 kHz，无缝循环 -- `[P1]` 可与基础音乐叠加，在泰坦巨柱与霜毒阶段增加紧张感。
- [C1] 默认结局庄严短和弦 -- `music_ending_solemn_sting.wav` -- `.wav` 或短 `.ogg` -- `[P0]` 白光出现时先制造升格感，随后突然停止形成笑点。
- [C1] 奶龙结局结算音乐 -- `music_ending_nailong.ogg` -- `.ogg` 或 `.wav` -- `[P0]` 奶龙大笑音频，奶龙彩蛋结局使用，10秒。
- [C1] 克苏鲁真结局音乐 -- `music_ending_eldritch.ogg` -- `.ogg`，48 kHz -- `[P0]` 普通反转后重新进入低频合唱和不协和声，时长约 10-20 秒。
- [C1] 窗台暖色环境音乐 -- `music_ending_balcony_warm.ogg` -- `.ogg`，48 kHz -- `[P1]` 《真正的破晓》使用，生活化、克制，不做过度煽情钢琴。
- [C1] 共生和声层 -- `music_symbiosis_layer_01.ogg` 至 `music_symbiosis_layer_03.ogg` -- `.ogg` 或三个可叠加 `.wav` -- `[P1]` 每帮助一名同伴增加一个音层，全部唤醒后构成完整和弦。
- [C1] 永冬低速心跳 -- `amb_eternal_frost_heartbeat.ogg` -- `.ogg` 或 `.wav` -- `[P1]` 随霜化加深逐渐变慢，最后只剩很长间隔的单次心跳。
- [C1] ROOT 电子脉冲循环 -- `music_root_pulse_loop.ogg` -- `.ogg`，48 kHz，无缝循环 -- `[P1]` 四拍结构必须清楚，供电路谜题使用。
- [C1] 片尾制作人员音乐 -- `music_credits_loop.ogg` -- `.ogg`，48 kHz -- `[P1]` 普通片尾与十二结局图鉴共用；结算界面可循环播放。

### 7.2 玩家、环境和交互音效

- [C1] 嫩芽移动摩擦循环 -- `sfx_sprout_move_loop.ogg` -- `.ogg` 或短循环 `.wav` -- `[P0]` 柔软植物与塑料表面摩擦，不应像脚步声。
- [C1] 嫩芽停止移动声 -- `sfx_sprout_move_stop.wav` -- `.wav` -- `[P1]` 从移动循环自然收尾，避免声音突然截断。
- [C1] 黏液进入声 -- `sfx_slime_enter_01.wav` 至 `sfx_slime_enter_03.wav` -- `.wav`，2-3 个变体 -- `[P0]` 玩家进入腐败区域时使用。
- [C1] 黏液脱离声 -- `sfx_slime_exit_01.wav` + `sfx_slime_exit_02.wav` -- `.wav`，2 个变体 -- `[P0]` 离开黏液时拉扯感明显。
- [C1] 保鲜膜拉伸循环 -- `sfx_plastic_film_stretch_loop.ogg` -- `.ogg` 或可循环 `.wav` -- `[P0]` 蓄力期间持续播放，音高可随进度提升。
- [C1] 保鲜膜破裂声 -- `sfx_plastic_film_break_01.wav` + `sfx_plastic_film_break_02.wav` -- `.wav`，2 个变体 -- `[P0]` 第二阶段核心力量反馈。
- [C1] 玻璃瓶轻碰声 -- `sfx_glass_tap_01.wav` 至 `sfx_glass_tap_03.wav` -- `.wav`，3 个变体 -- `[P0]` 普通接触使用，避免每次碰撞完全相同。
- [C1] 玻璃瓶重撞声 -- `sfx_glass_impact_01.wav` + `sfx_glass_impact_02.wav` -- `.wav`，2 个变体 -- `[P0]` 增加噪音值并触发外部脚步提示。
- [C1] 冰霜接触声 -- `sfx_frost_touch_01.wav` 至 `sfx_frost_touch_03.wav` -- `.wav`，2-3 个变体 -- `[P0]` 轻微结冰与减速反馈。
- [C1] 冰晶吸收声 -- `sfx_frost_absorb_01.wav` 至 `sfx_frost_absorb_04.wav` -- `.wav`，4 个音高变体或可程序变调 -- `[P1]` 收集霜晶时使用，提示累计数量。
- [C1] 通用道具发现声 -- `sfx_item_discover.wav` -- `.wav` -- `[P0]` 靠近隐藏道具时极轻提示，不等同于拾取完成。
- [C1] 通用道具吸收声 -- `sfx_item_absorb.wav` -- `.wav` -- `[P0]` 长按完成时使用，之后再叠加路线专属声音。
- [C1] 牛奶 Do 音 -- `sfx_milk_do.wav` -- `.wav` -- `[P0]` 第一滴牛奶确认。
- [C1] 牛奶 Re 音 -- `sfx_milk_re.wav` -- `.wav` -- `[P0]` 第二滴牛奶确认。
- [C1] 牛奶 Mi 音 -- `sfx_milk_mi.wav` -- `.wav` -- `[P0]` 第三滴牛奶确认。
- [C1] 幼龙稚嫩叫声 -- `sfx_dragon_chirp_01.wav` 至 `sfx_dragon_chirp_03.wav` -- `.wav`，2-3 个变体 -- `[P0]` 奶龙外观变化与结局演出使用，保持原创声音。
- [C1] 旧神眼睛睁开声 -- `sfx_eldritch_eye_open_01.wav` 至 `sfx_eldritch_eye_open_03.wav` -- `.wav`，3 个强度或程序变调 -- `[P0]` 每吸收一件旧神遗物确认一次。
- [C1] 绕柱仪式确认音 -- `sfx_ritual_step_01.wav` 至 `sfx_ritual_step_04.wav` -- `.wav`，4 个递升音高 -- `[P1]` 每经过正确检查点播放一个，顺序错误另用低沉失败音。
- [C1] 仪式顺序错误声 -- `sfx_ritual_error.wav` -- `.wav` -- `[P1]` 轻微提示重置，不能像死亡失败一样惩罚。
- [C1] 冷凝水拾取声 -- `sfx_condensation_pickup_01.wav` + `sfx_condensation_pickup_02.wav` -- `.wav`，2 个变体 -- `[P1]` 清澈水滴，与牛奶音阶明显区分。
- [C1] 同伴唤醒音 A -- `sfx_companion_onion_wake.wav` -- `.wav` -- `[P1]` 洋葱对应音符。
- [C1] 同伴唤醒音 B -- `sfx_companion_garlic_wake.wav` -- `.wav` -- `[P1]` 蒜头对应音符。
- [C1] 同伴唤醒音 C -- `sfx_companion_ginger_wake.wav` -- `.wav` -- `[P1]` 老姜或葱根对应音符；三者叠加应和谐。
- [C1] 条形码扫描声 -- `sfx_barcode_scan_01.wav` + `sfx_barcode_scan_02.wav` -- `.wav`，2 个变体 -- `[P1]` 价签收集与 KPI 结局使用。
- [C1] 电气节点正确声 -- `sfx_electric_node_ok_01.wav` 至 `sfx_electric_node_ok_03.wav` -- `.wav`，至少 3 个音高 -- `[P1]` ROOT 谜题正确步骤反馈。
- [C1] 电气节点错误声 -- `sfx_electric_node_error.wav` -- `.wav` -- `[P1]` 短促低音，不使用刺耳报警。
- [C1] 接通电路声 -- `sfx_circuit_connected.wav` -- `.wav` -- `[P1]` ROOT 路线条件完成时播放。
- [C1] 温控旋钮咔哒声 -- `sfx_thermostat_click.wav` -- `.wav` -- `[P1]` 每移动一格播放，进入第七格时叠加低频确认。
- [C1] 冰箱门外脚步声 -- `sfx_owner_step_far.wav`、`sfx_owner_step_mid.wav`、`sfx_owner_step_near.wav` -- `.wav`，远、中、近三版 -- `[P1]` 随噪音值升高逐渐靠近，提醒玩家行为后果。
- [C1] 冰箱门震动声 -- `sfx_fridge_door_rumble_01.wav` + `sfx_fridge_door_rumble_02.wav` -- `.wav`，2 个变体 -- `[P0]` 关门或外部动作在神话层表现为泰坦脚步。
- [C1] 冰箱门磁吸开启声 -- `sfx_fridge_door_open.wav` -- `.wav` -- `[P0]` 终局现实反转的关键声，保持清晰、少混响。
- [C1] 外卖盒卡扣“咔哒” -- `sfx_takeout_lid_click.wav` -- `.wav`，干声 -- `[P0]` 最终盒盖被顶开的关键笑点，不能带史诗混响。
- [C1] 灯开关按下声 -- `sfx_light_switch_press.wav` -- `.wav` -- `[P1]` 克苏鲁真结局中长按冰箱门灯开关时使用。
- [C1] 垃圾袋摩擦声 -- `sfx_trash_bag_rustle_01.wav` 至 `sfx_trash_bag_rustle_03.wav` -- `.wav`，2-3 个变体 -- `[P0]` 垃圾大陆之王结局中拖拽、撕裂和堆叠垃圾袋时使用。
- [C1] 垃圾袋落地声 -- `sfx_trash_bag_drop.wav` -- `.wav` -- `[P0]` 黑屏后一击式现实笑点。
- [C1] 雨夜填埋场环境声 -- `amb_landfill_rain_loop.ogg` -- `.ogg`，无缝循环 -- `[P2]` 垃圾大陆二段结局使用。
- [C1] 窗外风声与鸟声 -- `amb_balcony_wind_birds_loop.ogg` -- `.ogg`，无缝循环 -- `[P1]` 真正破晓结局使用，音量低于结算文字。
- [C1] 收银或报表完成声 -- `sfx_kpi_report_complete.wav` -- `.wav` -- `[P1]` 无限增长结局最终 KPI 弹出。
- [C1] 系统 ROOT 成功声 -- `sfx_root_access_granted.wav` -- `.wav` -- `[P1]` 机器神结局使用，像操作系统提示但必须原创。

## 8. 文案与数据文件

- 开场预言终稿 -- `opening_prophecy.md` + `opening_prophecy.csv` -- `.md` + 程序使用的 `.csv` 或 Inspector 文本 -- `[P0]` 4-6 行短句，保持严肃，不提前出现冰箱和土豆字样。
- 四阶段剧情文本终稿 -- `narrative_text.md` + `narrative_text.csv` -- `.md` + `.csv` -- `[P0]` 序章、腐土、保鲜膜、泰坦与霜毒、终局各 1-3 组；每组标注 `text_id`、触发位置、是否只显示一次和预计停留时间。
- 操作教学文案 -- `tutorial_text.md` + `tutorial_text.csv` -- `.md` + `.csv` -- `[P0]` 移动、观察、吸收、帮助、蓄力、重开和跳过文本；文字必须短到玩家移动时也能读完。
- 隐藏道具双重名称表 -- `item_text.csv` -- `.csv` -- `[P0]` 每件道具包含 `item_id`、神话名称、现实名称、首周目描述、现实模式描述和关联结局；禁止程序员自行临时起名。
- 结局条件表 -- `ending_conditions.csv` -- `.csv` -- `[P0]` 每个结局列出所需道具、禁止道具、行为阈值、仪式、出口、优先级、失败时提示和测试方法。
- 结局文案终稿 -- `ending_text.md` + `ending_text.csv` -- `.md` + `.csv` -- `[P0]` 十二个正式结局全部需要标题、两到四行正文、社畜对白、结局编号和重开提示；48 小时内可按批次先完成前三个，再补齐其余九个。
- 结局图鉴谜语 -- `gallery_hints.csv` -- `.csv` -- `[P1]` 每个未解锁结局提供一句可以推理但不直接公布配方的提示。
- 旁白行为变化文本 -- `behavior_narrative.csv` -- `.csv` -- `[P1]` 吞噬、共生、高噪音、奶化、霜化和旧神状态各准备 2-3 句反应，让玩家知道行为正在改变角色。
- 奶龙童谣 -- `milk_dragon_rhyme.md` + `milk_dragon_rhyme.csv` -- `.md` + `.csv` -- `[P0]` 固定“三滴奶、金鳞、旧像、蜷缩”等配方信息；必须与最终程序条件完全一致。
- 克苏鲁三段经文 -- `eldritch_scriptures.md` + `eldritch_scriptures.csv` -- `.md` + `.csv` -- `[P0]` 固定三遗物、逆时针、第三次压缩机、压住灯开关等仪式线索；做对一步后有确认文本。
- 洪山路线文本 -- `hongshan_route_text.md` + `hongshan_route_text.csv` -- `.md` + `.csv` -- `[P1]` 包含紫茎黄花、冷凉但非永冬、地域来源和最终移栽；应尊重本地文化并核对事实。
- KPI 公司话术 -- `kpi_dialogue.md` + `kpi_dialogue.csv` -- `.md` + `.csv` -- `[P1]` 从史诗语言逐步转为增长率、目标和报表，控制在 4-6 句。
- ROOT 终端文本 -- `root_terminal_text.csv` -- `.txt` 或 `.csv`，UTF-8 -- `[P1]` 包含访问拒绝、缺失组件、节点成功和最终管理员权限；确保导出时被包含。
- 制作人员名单 -- `credits.md` + `credits.csv` -- `.md` + 游戏内 `.csv` / Inspector 文本 -- `[P0]` 全员姓名或昵称、分工、素材来源和特殊感谢；页面署名与 GGJ 成员信息保持一致。
- 操作说明 -- `controls.txt` + `controls.md` -- `.txt` + `.md` -- `[P0]` 用于游戏内和 release README，包含 WASD/方向键、E、Space、R、Esc。
- 测试用结局清单 -- `ending_test_routes.md` + `ending_test_routes.csv` -- `.md` 或 `.csv` -- `[P0]` 每条路线写成可重复步骤，至少由一名未写代码的队友按表独立触发一次。

## 9. 宣传、展示与提交素材

- [C0] GGJ Featured Image -- `press_featured_image.png` -- `.png` 或高质量 `.jpg`，建议 1920×1080 -- `[P0]` 当前目录未找到；官网列表代表图，不剧透完整冰箱反转。
- [C0] 游戏内主截图 -- `press_gameplay_01.png` -- `.png`，至少 1920×1080 -- `[P0]` 当前目录未找到；应展示黑暗环境、局部光照、芽体轨迹和有辨识度的障碍。
- [C0] 终局反转截图 -- `press_ending_reveal_01.png` -- `.png`，至少 1920×1080 -- `[P0]` 当前目录未找到；用于 press 文件夹和宣传。
- [C0] 多结局拼图 -- `press_endings_collage.png` -- `.png`，建议 1920×1080 -- `[P1]` 当前目录未找到；展示多个结局剪影。
- [C0] 游戏 Logo 横版 -- `press_logo_horizontal.png` -- `.png` 透明背景 -- `[P0]` 当前目录未找到；官网、README 和宣传图使用。
- [C0] 团队 Logo 或团队名图 -- `press_team_logo.png` -- `.png` 透明背景 -- `[P1]` 当前目录未找到；没有 Logo 时可只用排版文字。
- [C0] 宣传短视频 -- `press_trailer.mp4` -- `.mp4`，H.264，1080p，15-45 秒 -- `[P2]` 非必交；展示移动、破膜、白光和一两个不完全剧透的结局片段。
- 游戏介绍文案 -- `game_description.md` + `game_description.txt` -- `.md` + `.txt` -- `[P0]` 包含一句话介绍、100 字短简介、300 字长简介、平台、语言、使用工具和 AI 使用说明。
- 团队介绍 -- `TEAM.md` + `TEAM.txt` -- `.md` + `.txt` -- `[P0]` 全部成员、职责、联系方式和贡献，放入 `other/` 并同步到 GGJ 页面。
- 游戏许可证 -- `LICENSE.txt` -- `[P0]` 按赛事要求准备项目授权文本；第三方素材许可证另行保留，不得用项目许可证覆盖第三方限制。
- 第三方授权汇总 -- `THIRD_PARTY_LICENSES.md` -- `[P0]` 列出字体、音频、图片和代码的许可证及来源。
- 源码编译说明 -- `source/README.md` -- `[P0]` 写明 Godot 4.7.2 Standard、如何打开 `project.godot`、如何运行和如何导出 Windows 版本。
- 运行说明 -- `release/README.txt` -- `[P0]` 写明解压方式、Windows 版本、启动 exe、操作按键、退出方式和已知问题。
- Windows 可执行程序 -- `dawn_of_the_sprout.exe` + `dawn_of_the_sprout.pck` -- `.exe` + `.pck` -- `[P0]` 使用 Godot 4.7.2 Windows Desktop x86_64 Release 导出；在未安装 Godot 的另一台电脑完整通关测试。
- 完整项目压缩包 -- `dawn_of_the_sprout_submission.zip` -- `.zip` -- `[P0]` 根目录含授权文件以及 `source/`、`release/`、`press/`、`other/`；不得只提交 GitHub 链接或外部下载链接。

## 10. 建议的实际制作批次

- 第一批程序灰盒 -- `batch_01_graybox_manifest.md` -- `.tscn` + `.gd` + 占位 `.png` -- `[P0]` 先完成移动、Line2D、摄像机、墙体、黏液、保鲜膜、文本触发和默认结局；任何正式美术未完成都不得阻塞灰盒。
- 第一批美术包 -- `batch_01_art_manifest.md` -- `.png` -- `[P0]` 中性芽、母薯、黄瓜黑水、保鲜膜三态、辣酱瓶、冰霜、外卖盒三态、柔光、基础 UI 和可直接使用的完整结局插画。
- 第一批隐藏道具包 -- `batch_01_item_manifest.md` -- `.png` -- `[P0]` 发芽警告残片、日期贴纸、腐败之眼、猩红圣膏、永冻之心、三滴牛奶共用图、奶酪黄边、黄色瓶盖和原创小龙图案。
- 第一批音频包 -- `batch_01_audio_manifest.md` -- `.wav` + `.ogg` -- `[P0]` 压缩机、冷风、移动、黏液、薄膜、玻璃、冰霜、牛奶三音、旧神眼、盒盖咔哒、冰箱门、垃圾袋、基础 BGM 和 8-bit 结算。
- 第二批核心多结局包 -- `batch_02_endings_manifest.md` -- `.png` + `.wav` / `.ogg` + 文案 `.csv` -- `[P1]` 真正破晓、自治森林、无限增长、永冬和 ROOT；必须等默认、克苏鲁和奶香幼龙三条路线均能稳定触发后再接入。
- 第三批后置正式结局包 -- `batch_03_endings_manifest.md` -- `ending_09_full.png` 至 `ending_12_full.png` -- `[P2]` 紫冠的新芽、不见天日的丰收、今天不长、垃圾大陆之王完整插画；它们仍属于正式十二结局，只是可在核心五结局完成后补齐。

## 11. 每项素材的验收规则

- 图片验收 -- `.png` -- 文件名正确、尺寸足够、光源与透视一致、缩小到实际游戏尺寸仍可辨认；透明素材不得有白边，并在 Godot Compatibility 渲染器中检查一次；不验收 PSD/KRA 等源文件。
- 音频验收 -- `.wav` 或 `.ogg` -- 无爆音、无明显底噪、响度不过载、循环无接缝、文件用途和音量已标注，并在游戏而不是播放器中试听。
- 文案验收 -- UTF-8 `.md` / `.csv` / `.txt` -- 无错别字、引号和换行不会破坏 CSV、两行内可读完、神话名与现实名一致、触发条件与程序表一致。
- 程序验收 -- `.gd` + `.tscn` -- 无红色报错、重新开始后本局状态正确清空、结局图鉴不丢失、同一道具不重复计数、结局优先级无冲突。
- 结局验收 -- 测试记录 `.md` 或 `.csv` -- 每个保留结局至少完成一次正向触发、一次缺条件测试、一次与其他结局冲突测试，并保存对应截图。
- 导出验收 -- `.exe` + `.pck` + `README.txt` -- 在没有安装 Godot 的 Windows x86_64 电脑上解压运行，字体、中文、图片、音频、重开和退出全部正常。
