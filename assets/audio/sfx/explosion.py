import math, random, struct, subprocess, shutil, sys

SR = 48000
DUR = 3.0
N = int(SR * DUR)

OUT_OGG = "explosion.ogg"

# Loudness / tone
PREGAIN_DB = 6.0
SAT_DRIVE = 2.0
POST_GAIN = 0.98

# Explosion sequence controls (compressed into 3s)
NUM_BLASTS = 5
MIN_GAP, MAX_GAP = 0.22, 0.55
SEED = 23

def db_to_lin(db):
    return 10 ** (db / 20.0)

def clamp(x, lo=-1.0, hi=1.0):
    return lo if x < lo else hi if x > hi else x

def exp_env(t, tau):
    return math.exp(-t / max(1e-9, tau)) if t >= 0 else 0.0

def soft_limiter(x, drive=2.0):
    return math.tanh(drive * x) / math.tanh(drive)

def schedule_blasts():
    random.seed(SEED)
    blasts = []
    t = 0.15  # allow immediate action
    for k in range(NUM_BLASTS):
        t += random.uniform(MIN_GAP, MAX_GAP)
        if t > DUR - 0.60:
            break
        strength = random.uniform(0.80, 1.20) * (1.12 if k == 0 else 1.0)
        color = random.uniform(0.85, 1.25)
        blasts.append((t, strength, color))
    return blasts

BLASTS = schedule_blasts()

def synth_pcm_s16le():
    pregain = db_to_lin(PREGAIN_DB)
    pcm = bytearray()

    for i in range(N):
        t = i / SR

        # Shorter continuous bed so it doesn't extend past 3s too much
        rnd_bed = random.Random((i * 1103515245) ^ 0xA5A5A5A5)
        bed_noise = rnd_bed.uniform(-1, 1)
        bed = 0.06 * bed_noise * exp_env(max(0.0, t - 0.05), 1.8)

        x = bed

        for (t0, strength, color) in BLASTS:
            u = t - t0
            if u < -0.02 or u > 1.35:
                continue

            rnd = random.Random((i * 1315423911) ^ int(t0 * 1000) ^ 0x9E3779B9)

            # Shock
            shock = 0.0
            if 0.0 <= u < 0.028:
                e = exp_env(u, 0.0065)
                shock = e * (0.95 * rnd.uniform(-1, 1) + 0.55 * math.sin(2 * math.pi * (1700 * color) * u))

            # Blast noise body (compressed)
            wn = rnd.uniform(-1, 1)
            low = wn * 0.8
            mid = wn * 0.55
            high = wn * 0.40

            blast_fast = exp_env(u, 0.18)
            blast_slow = exp_env(u, 0.65)

            blast = (1.15 * low * blast_slow + 0.78 * mid * blast_fast + 0.22 * high * blast_fast)

            # Thump
            thump = math.sin(2 * math.pi * (55.0 + 8.0 * (color - 1.0)) * u) * exp_env(u, 0.30)

            # Debris (short)
            debris = 0.0
            if 0.01 < u < 0.45:
                p = 0.030 * exp_env(u - 0.01, 0.16) * (0.8 + 0.5 * color)
                if rnd.random() < p:
                    f = rnd.choice([1200, 1600, 2400, 3200, 4200]) * (0.9 + 0.3 * color)
                    debris += math.sin(2 * math.pi * f * u) * exp_env(u, 0.045) + 0.25 * rnd.uniform(-1, 1)

            event = (0.75 * shock + 1.00 * blast + 0.55 * thump + 0.35 * debris)
            x += strength * event

        # Master loudness
        x *= pregain
        x = soft_limiter(x, drive=SAT_DRIVE)
        x *= POST_GAIN

        v = int(clamp(x) * 32767)
        pcm += struct.pack("<h", v)

    return bytes(pcm)

def encode_ogg_from_pcm(pcm_bytes, q=6):
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise RuntimeError("未找到 ffmpeg。请先安装并确保可运行 `ffmpeg -version`。")

    cmd = [
        ffmpeg, "-y",
        "-f", "s16le",
        "-ar", str(SR),
        "-ac", "1",
        "-i", "pipe:0",
        "-af", "loudnorm=I=-12:TP=-1.0:LRA=7",
        "-c:a", "libvorbis",
        "-q:a", str(q),
        OUT_OGG
    ]
    p = subprocess.run(cmd, input=pcm_bytes, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        raise RuntimeError("ffmpeg 编码失败：\n" + p.stderr.decode("utf-8", errors="replace"))

def main():
    print("Blast schedule (s):", [round(t0, 2) for (t0, _, _) in BLASTS])
    pcm = synth_pcm_s16le()
    encode_ogg_from_pcm(pcm, q=6)
    print(f"Done: {OUT_OGG} (DUR={DUR}s)")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print("ERROR:", e, file=sys.stderr)
        sys.exit(1)
