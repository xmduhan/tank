import math, random, struct, subprocess, shutil, sys

SR = 48000
DUR = 1.6
N = int(SR * DUR)
OUT_OGG = "victory.ogg"

def clamp(x, lo=-1.0, hi=1.0):
    return lo if x < lo else hi if x > hi else x

def softsat(x, drive=1.6):
    return math.tanh(drive * x)

def hz(note):
    # A4=440, MIDI note number
    return 440.0 * (2 ** ((note - 69) / 12))

def adsr(t, a, d, s, r, gate):
    # simple ADSR: t in seconds, gate in seconds (note length before release)
    if t < 0: return 0.0
    if t < a: return t / max(1e-9, a)
    if t < a + d:
        x = (t - a) / max(1e-9, d)
        return 1.0 + (s - 1.0) * x
    if t < gate:
        return s
    # release
    tr = t - gate
    if tr >= r: return 0.0
    return s * (1.0 - tr / max(1e-9, r))

def tri(phase):
    # phase 0..1
    x = 2.0 * abs(2.0 * (phase - math.floor(phase + 0.5))) - 1.0
    return x

def synth():
    # Sequence: bright arpeggio + final chord
    # MIDI notes in C major-ish: C5 E5 G5 C6 then final C major chord
    events = []
    t = 0.0
    step = 0.14
    melody = [72, 76, 79, 84, 83, 84]  # C5 E5 G5 C6 B5 C6
    for n in melody:
        events.append(("mel", t, 0.16, n, 0.85))
        t += step

    # final chord hit
    chord_t = 0.78
    for n in [72, 76, 79, 84]:  # C5 E5 G5 C6
        events.append(("ch", chord_t, 0.55, n, 0.75))

    # little "sparkle" sweep (noise ping) at the end
    sparkle_t = 0.92

    pcm = bytearray()
    random.seed(5)

    for i in range(N):
        t = i / SR
        x = 0.0

        # melodic synth (triangle + sine for brightness)
        for kind, t0, dur, note, vel in events:
            u = t - t0
            if u < 0 or u > dur + 0.35:
                continue
            f = hz(note)
            gate = dur
            env = adsr(u, a=0.008, d=0.06, s=0.55, r=0.22, gate=gate)

            # slight vibrato for "gamey" feel
            vib = 0.0035 * math.sin(2 * math.pi * 6.0 * u)
            phase = (f * (u + vib)) % 1.0

            tone = 0.65 * math.sin(2 * math.pi * f * (u + vib)) + 0.35 * tri(phase)
            # chord a bit softer
            if kind == "ch":
                tone *= 0.85
            x += vel * env * tone

        # sparkle: short band-limited noise pings
        u = t - sparkle_t
        if 0.0 <= u <= 0.38:
            env = math.exp(-u / 0.12)
            # pseudo "shimmer": multiply noise by a fast sine
            n = random.uniform(-1, 1)
            shimmer = n * (0.6 + 0.4 * math.sin(2 * math.pi * 4200 * u))
            x += 0.18 * env * shimmer

        # simple "reverb-like" tail via extra decay (no background noise floor)
        tail = math.exp(-max(0.0, t - 0.8) / 0.55)
        x *= (0.75 + 0.25 * tail)

        # master
        x = softsat(x * 0.75, drive=1.4)
        v = int(clamp(x) * 32767)
        pcm += struct.pack("<h", v)

    return bytes(pcm)

def encode_ogg(pcm_bytes, q=6):
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise RuntimeError("未找到 ffmpeg。请先安装并确保可运行 `ffmpeg -version`。")

    cmd = [
        ffmpeg, "-y",
        "-f", "s16le",
        "-ar", str(SR),
        "-ac", "1",
        "-i", "pipe:0",
        "-c:a", "libvorbis",
        "-q:a", str(q),
        OUT_OGG
    ]
    p = subprocess.run(cmd, input=pcm_bytes, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        raise RuntimeError(p.stderr.decode("utf-8", errors="replace"))

def main():
    pcm = synth()
    encode_ogg(pcm, q=6)
    print(f"Done: {OUT_OGG} (DUR={DUR}s, SR={SR}Hz)")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print("ERROR:", e, file=sys.stderr)
        sys.exit(1)
