extends RefCounted
class_name AudioConfig

## 可选音频配置集中管理（当前项目主要由 Main.gd 在运行时设置 AudioManager）。
## 若后续想把音量/总线等参数配置化，可在此扩展并在 AudioManager.ensure() 后应用。

const DEFAULT_SFX_VOLUME_DB: float = -6.0
const DEFAULT_LOOP_VOLUME_DB: float = -12.0
const BUS_SFX: StringName = &"Master"
const BUS_MUSIC: StringName = &"Master"