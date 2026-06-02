extends OneShotFx
## 坦克殉爆特效：一次性粒子播放完自动销毁
## 新增：播放爆炸音效（命中爆炸/死亡殉爆共用该特效）

@export var auto_free_delay: float = 1.2

@export_group("Audio")
@export var explosion_sfx: AudioStream = preload("res://assets/audio/sfx/explosion.wav")


func _on_before_play() -> void:
    AudioManager.play_sfx_2d(self, explosion_sfx)
