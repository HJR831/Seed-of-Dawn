extends Node

signal text_requested(text_id: StringName)

# 灰盒阶段仅保留统一入口；正式文本队列在下一阶段实现。
func request_text(text_id: StringName) -> void:
	text_requested.emit(text_id)

