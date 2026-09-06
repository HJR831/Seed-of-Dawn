《破晓之种 / Dawn of the Sprout》Windows x86_64 Release
===========================================================

文件：dawn_of_the_sprout.exe + dawn_of_the_sprout.pck
构建：Godot 4.7.2 Standard，Compatibility 渲染器，Windows Desktop x86_64

这是可直接运行的 Windows 版本；exe 与同目录的 pck 必须一起保留，测试电脑不需要安装 Godot。

运行
----
1. 将 `dawn_of_the_sprout.exe` 与 `dawn_of_the_sprout.pck` 解压到同一个可写目录。
2. 双击 `dawn_of_the_sprout.exe` 启动。首次运行会在 Windows 用户目录创建 `Dawn of the Sprout` 存档目录。
3. 若 Windows SmartScreen 提示未知发布者，请确认文件来自项目组后再选择运行。

操作
----
- WASD / 方向键：移动芽尖；Shift：疾跑。
- E：观察、帮助或操作；Space：蓄力 / 跳过对白。
- I / Tab：背包；M：完整地图；U：打开/关闭键位提示；Esc：暂停或关闭当前面板；R：结局后重开。
- F3：开发测试入口（仅 Debug 构建）；输入开发者 UID `wutiaowu831` 后打开调试面板。
- 调试面板可查看素材、给予配方、传送和复现 Seed；正式 Release 构建不会开放该入口。

音频
----
- 开场音乐结束后，按所在楼层循环播放 `audio/background/01`–`07` 对应音轨。
- 背景音乐、拾取音效和交互音效使用独立通道，可同时播放。

回归记录
--------
- 已通过烟雾、基础系统、100 Seed 程序地图、结局解析、阶段 13–20、20–32、32–39、
  结局流程 04–08/09–12、结局画面、存档往返、完整流程、交互审计和前端检查。
- 已用 Godot 4.7.2 导出模板生成并启动本文件；另见项目根目录的 `press/` 截图。
- 存档使用 `user://save_data.cfg`，不会写回安装目录。

如果需要在 Godot 中继续开发，请传输上一级的完整 `program` 工程包，并按
`source/README.md` 导入 `source/project.godot`。
