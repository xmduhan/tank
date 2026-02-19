extends Node
class_name Settings

signal changed

const CONFIG_PATH: String = "user://settings.cfg"
const SECTION: String = "game"

const KEY_ENEMY_DESIRED: String = "enemy_desired_count"
const KEY_ENEMY_TOTAL: String = "enemy_total_count"

const DEFAULT_ENEMY_DESIRED: int = 4
const DEFAULT_ENEMY_TOTAL: int = 20

const MIN_ENEMY_DESIRED: int = 0
const MAX_ENEMY_DESIRED: int = 64

const MIN_ENEMY_TOTAL: int = 0
const MAX_ENEMY_TOTAL: int = 9999

var enemy_desired_count: int = DEFAULT_ENEMY_DESIRED:
    set(value):
        var v: int = clampi(value, MIN_ENEMY_DESIRED, MAX_ENEMY_DESIRED)
        if v == enemy_desired_count:
            return
        enemy_desired_count = v
        changed.emit()

var enemy_total_count: int = DEFAULT_ENEMY_TOTAL:
    set(value):
        var v: int = clampi(value, MIN_ENEMY_TOTAL, MAX_ENEMY_TOTAL)
        if v == enemy_total_count:
            return
        enemy_total_count = v
        changed.emit()


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    load_from_disk()


func load_from_disk() -> void:
    var cfg: ConfigFile = ConfigFile.new()
    var err: Error = cfg.load(CONFIG_PATH)
    if err != OK:
        _apply_defaults()
        save_to_disk()
        return

    enemy_desired_count = int(cfg.get_value(SECTION, KEY_ENEMY_DESIRED, DEFAULT_ENEMY_DESIRED))
    enemy_total_count = int(cfg.get_value(SECTION, KEY_ENEMY_TOTAL, DEFAULT_ENEMY_TOTAL))

    enemy_desired_count = clampi(enemy_desired_count, MIN_ENEMY_DESIRED, MAX_ENEMY_DESIRED)
    enemy_total_count = clampi(enemy_total_count, MIN_ENEMY_TOTAL, MAX_ENEMY_TOTAL)


func save_to_disk() -> void:
    var cfg: ConfigFile = ConfigFile.new()
    cfg.set_value(SECTION, KEY_ENEMY_DESIRED, enemy_desired_count)
    cfg.set_value(SECTION, KEY_ENEMY_TOTAL, enemy_total_count)

    var dir_err: Error = DirAccess.make_dir_recursive_absolute("user://")
    if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
        push_warning("Settings: cannot ensure user:// dir: %s" % dir_err)

    var err: Error = cfg.save(CONFIG_PATH)
    if err != OK:
        push_warning("Settings: save failed: %s" % err)


func apply_and_save(desired: int, total: int) -> void:
    enemy_desired_count = desired
    enemy_total_count = total
    save_to_disk()


func _apply_defaults() -> void:
    enemy_desired_count = DEFAULT_ENEMY_DESIRED
    enemy_total_count = DEFAULT_ENEMY_TOTAL