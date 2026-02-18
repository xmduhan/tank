import wave, struct, math, random, subprocess, shutil, sys

SR = 48000
DUR = 4.0                 # 秒：循环长度
N = int(SR * DUR)

WAV_PATH = "tracks_loop.wav"
OGG_PATH = "tracks_loop.ogg"

def clamp(x, lo=-1.0, hi=1.0):
    return lo if x < lo else hi if x > hi else x

def frac(x):
    return x - math.floor(x)

def env_percussive(p, attack=0.02, decay=0.20):
    # p: 0..1 within one hit
    if p < attack:
        return p / attack
    p2 = (p - attack) / max(1e-9, (1 - attack))
    return math.exp(-p2 / decay)

def one_pole_lp(x, state, cutoff_hz):
    a = math.exp(-2 * math.pi * cutoff_hz / SR)
    y = (1 - a) * x + a * state
    return y, y

def render_wav(path):
    random.seed(7)

    lp_state = 0.0
    rumble_lp_state = 0.0

    # Loop-safe wobble (integer multiples of 1/DUR)
    wobble_freqs = [1.0 / DUR * 1, 1.0 / DUR * 2, 1.0 / DUR * 3]
    wobble_phases = [0.3, 1.1, 2.0]
    wobble_amps = [0.35, 0.20, 0.12]

    base_rate = 14.0  # 履齿节奏 Hz
    rate_mod = 0.25

    clank_rate = 2.0  # events/sec
    grid = 1.0 / 24.0
    clank_slots = int(DUR / grid)
    clank_indices = set(random.sample(range(clank_slots), int(clank_rate * DUR)))

    samples = []

    for i in range(N):
        t = i / SR

        wob = 0.0
        for f, ph, a in zip(wobble_freqs, wobble_phases, wobble_amps):
            wob += a * math.sin(2 * math.pi * f * t + ph)
        wob = 0.5 + 0.5 * math.tanh(1.2 * wob)

        # loop-safe phase (integrated wobble)
        phase = t * base_rate + (rate_mod * base_rate) * (
            (wobble_amps[0] / (2 * math.pi * wobble_freqs[0])) * (-math.cos(2 * math.pi * wobble_freqs[0] * t + wobble_phases[0])) +
            (wobble_amps[1] / (2 * math.pi * wobble_freqs[1])) * (-math.cos(2 * math.pi * wobble_freqs[1] * t + wobble_phases[1])) +
            (wobble_amps[2] / (2 * math.pi * wobble_freqs[2])) * (-math.cos(2 * math.pi * wobble_freqs[2] * t + wobble_phases[2]))
        )
        p = frac(phase)

        click_env = env_percussive(p, attack=0.01, decay=0.10)
        noise = random.uniform(-1, 1)
        click = (0.7 * noise + 0.3 * math.sin(2 * math.pi * 2500 * t)) * click_env

        rumble_noise = random.uniform(-1, 1)
        rumble_lp, rumble_lp_state = one_pole_lp(rumble_noise, rumble_lp_state, cutoff_hz=120.0)
        rumble = 0.35 * rumble_lp + 0.12 * math.sin(2 * math.pi * 55 * t)

        gi = int((t / grid)) % clank_slots
        gp = frac(t / grid)
        clank = 0.0
        if gi in clank_indices:
            e = math.exp(-gp / 0.08)
            clank = e * (0.6 * random.uniform(-1, 1) + 0.4 * math.sin(2 * math.pi * (1800 + 400 * wob) * t))

        x = 0.55 * click + 0.55 * rumble + 0.35 * clank
        x, lp_state = one_pole_lp(x, lp_state, cutoff_hz=6500.0)
        x = math.tanh(1.6 * x)  # saturation

        samples.append(x)

    with wave.open(path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(b"".join(struct.pack("<h", int(clamp(x) * 32767)) for x in samples))

def wav_to_ogg_ffmpeg(wav_path, ogg_path, q=5):
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise RuntimeError(
            "未找到 ffmpeg。请先安装 ffmpeg，并确保命令行可直接运行 `ffmpeg -version`。"
        )

    # -q:a 0..10 (Vorbis quality). 5 is a decent default.
    cmd = [
        ffmpeg, "-y",
        "-i", wav_path,
        "-c:a", "libvorbis",
        "-q:a", str(q),
        ogg_path
    ]
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if p.returncode != 0:
        raise RuntimeError("ffmpeg 转换失败：\n" + p.stderr)

def main():
    print(f"Rendering {WAV_PATH} ...")
    render_wav(WAV_PATH)
    print(f"Converting to {OGG_PATH} via ffmpeg ...")
    wav_to_ogg_ffmpeg(WAV_PATH, OGG_PATH, q=5)
    print("Done.")
    print(f"- {WAV_PATH}")
    print(f"- {OGG_PATH}")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print("ERROR:", e, file=sys.stderr)
        sys.exit(1)
