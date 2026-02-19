extends RefCounted
class_name GameBalance

## 敌方 AI 的整体节奏倍率：越小越慢（0.5 = 慢一半）
const ENEMY_TIME_SCALE: float = 0.45

## 敌方移动速度倍率（<1 更慢）
const ENEMY_MOVE_SPEED_MULT: float = 0.65

## 敌方开火/攻击冷却倍率（>1 更慢）
const ENEMY_FIRE_COOLDOWN_MULT: float = 1.75

## 敌人开局强制“梦游”时长（秒）
const ENEMY_INITIAL_DREAM_SECONDS: float = 10.0

## 敌人履带循环音效开关（关闭可避免多个敌人叠加太吵）
const ENEMY_TRACKS_SFX_ENABLED: bool = false

## 射击口算题：倍数题基数 n（题目形如：n × k）
const MULTIPLE_BASE: int = 9

## 玩家射击是否需要输入“射击诸元”（口算题）：
## - true：按空格会弹出答题框，答对才命中；答错/取消/超时打空
## - false：按空格直接发射命中（不弹窗、不暂停）
const SHOOT_MATH_GATE_ENABLED: bool = false
