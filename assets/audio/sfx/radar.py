import math, struct, subprocess, shutil, sys

SR = 48000

OUT_OGG = "radar.ogg"   # 按你的文件名要求
DUR = 4.0               # 总长度（秒）
BEEP_HZ = 1000.0        # “滴”的音高
BEEP_LEN = 0.055        # 每次“滴”的时长（秒）
BEEP_RATE = 2.0         # 每秒多少次“滴”（2.0=每0.5秒一次，均匀）
GAIN = 0.85             # 总音量（0..1）

def clamp(x, lo=-1.0, hi=1.0):
    return lo if x < lo else hi if x > hi else x

def envelope(t, attack=0.004, release=0.012, hold=0.0, total=0.05):
    # 简单的 A-H-R 包络，避免点击爆音
    if t < 0 or t >= total:
        return 0.0
    if t < attack:
        return t / max(1e-9, attack)
    if t < attack + hold:
        return 1.0
    tr = t - (attack + hold)
    rel = max(1e-9, total - (attack + hold))
    # 指数/平方衰减让“滴”更利落
    x = 1.0 - (tr / rel)
    return max(0.0, x * x)

def synth_pcm_s16le():
    n = int(SR * DUR)
    step = 1.0 / BEEP_RATE  # 每次滴的间隔
    beep_total = BEEP_LEN

    pcm = bytearray()
    for i in range(n):
        t = i / SR

        # 本次“滴”的相位：把时间折叠到每个 step 周期内
        p = t % step  # 0..step
        env = envelope(p, attack=0.004, release=0.014, hold=0.0, total=beep_total)

        # 纯净正弦 + 少量二次谐波，像电子告警
        s = math.sin(2 * math.pi * BEEP_HZ * t)
        s2 = 0.18 * math.sin(2 * math.pi * (2 * BEEP_HZ) * t)

        x = GAIN * env * (s + s2)

        # 限幅并写入16-bit little-endian
        v = int(clamp(x) * 32767)
        pcm += struct.pack("<h", v)

    return bytes(pcm)

def encode_ogg_from_pcm(pcm_bytes):
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise RuntimeError("未找到 ffmpeg。请先安装并确保可运行 `ffmpeg -version`。")

    # 从 stdin 读入原始 PCM，输出 OGG(Vorbis)
    cmd = [
        ffmpeg, "-y",
        "-f", "s16le",
        "-ar", str(SR),
        "-ac", "1",
        "-i", "pipe:0",
        "-c:a", "libvorbis",
        "-q:a", "6",
        OUT_OGG
    ]

    p = subprocess.run(cmd, input=pcm_bytes, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        raise RuntimeError("ffmpeg 编码失败：\n" + p.stderr.decode("utf-8", errors="replace"))

def main():
    pcm = synth_pcm_s16le()
    encode_ogg_from_pcm(pcm)
    print(f"Done: {OUT_OGG}  (DUR={DUR}s, {BEEP_RATE} beeps/sec, {BEEP_HZ}Hz)")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print("ERROR:", e, file=sys.stderr)
        sys.exit(1)
