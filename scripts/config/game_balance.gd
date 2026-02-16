extends RefCounted
class_name GameBalance

## 敌方 AI 的整体节奏倍率：越小越慢（0.5 = 慢一半）
const ENEMY_TIME_SCALE: float = 0.45

## 敌方移动速度倍率（<1 更慢）
const ENEMY_MOVE_SPEED_MULT: float = 0.65

## 敌方开火/攻击冷却倍率（>1 更慢）
const ENEMY_FIRE_COOLDOWN_MULT: float = 1.75
