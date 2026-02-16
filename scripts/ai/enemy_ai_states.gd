extends RefCounted
class_name EnemyAIStates

enum State {
    DREAM = 0,      # 梦游：随机游走，不追不打
    CHASE = 1,      # 追逐：只追不打
    STANDBY = 2,    # 待命：随机游走；仅射程内攻击；不追
    MADNESS = 3     # 疯狂：追击并攻击
}

const WEIGHTS: Dictionary = {
    State.DREAM: 70.0,
    State.CHASE: 20.0,
    State.STANDBY: 5.0,
    State.MADNESS: 5.0
}

static func pick_state(rng: RandomNumberGenerator, weights: Dictionary = WEIGHTS) -> int:
    var total: float = 0.0
    for w in weights.values():
        total += float(w)

    if total <= 0.0:
        return State.DREAM

    var roll: float = rng.randf() * total
    var acc: float = 0.0

    for s in weights.keys():
        acc += float(weights[s])
        if roll <= acc:
            return int(s)

    return State.DREAM
