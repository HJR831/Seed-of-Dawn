extends Node

# 第 0–7 小时灰盒阶段尚未接入正式音频。
# 后续所有 BGM、环境声和音效都通过此节点播放，避免散落在关卡脚本中。

func stop_all() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()

