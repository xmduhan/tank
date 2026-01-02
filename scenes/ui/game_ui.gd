# res://scripts/GameUI.gd
extends Control

# UI脚本，负责处理玩家输入和显示分数。
# 挂在 ui/GameUI.tscn 的根节点 Control 上。

signal answer_submitted(answer: int)

@onready var answer_input = $VBoxContainer/HBoxContainer/AnswerInput
@onready var score_label = $VBoxContainer/ScoreLabel

var score = 0

func _ready():
	# 连接按钮和回车键信号
	$VBoxContainer/HBoxContainer/SubmitButton.pressed.connect(_on_submit_button_pressed)
	answer_input.text_submitted.connect(_on_answer_submitted)

func _on_submit_button_pressed():
	submit_answer()

func _on_answer_submitted(_text):
	submit_answer()

# 提交答案的核心逻辑
func submit_answer():
	var answer_text = answer_input.text.strip_edges()
	if answer_text.is_valid_int():
		var answer = answer_text.to_int()
		answer_submitted.emit(answer) # 发射信号给Main
		answer_input.clear()
	else:
		# 输入无效，清空并提示
		answer_input.text = ""
		answer_input.placeholder_text = "请输入数字！"
		# 1秒后恢复原提示文本
		await get_tree().create_timer(1.0).timeout
		answer_input.placeholder_text = "输入答案"

# 更新分数显示
func update_score(points: int):
	score += points
	score_label.text = "得分: " + str(score)