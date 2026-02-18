import numpy as np
import wave, os, subprocess, tempfile

SR = 44100

def normalize(x, peak=0.98):
    m = np.max(np.abs(x)) + 1e-12
    return x * (peak / m)

def write_wav(path, x):
    x16 = np.int16(np.clip(x, -1, 1) * 32767)
    with wave.open(path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(x16.tobytes())

def wav_to_ogg(wav_path, ogg_path):
    cmd = ["ffmpeg", "-y", "-i", wav_path, "-c:a", "libvorbis", "-q:a", "5", ogg_path]
    subprocess.check_call(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def tone(t, f):
    return np.sin(2*np.pi*f*t)

def adsr(n, a, d, s, r):
    # a,d,r in samples; s level 0..1
    env = np.zeros(n, dtype=np.float32)
    a = int(a); d = int(d); r = int(r)
    sus = max(0, n - a - d - r)
    if a > 0:
        env[:a] = np.linspace(0, 1, a, endpoint=False)
    if d > 0:
        env[a:a+d] = np.linspace(1, s, d, endpoint=False)
    if sus > 0:
        env[a+d:a+d+sus] = s
    if r > 0:
        env[a+d+sus:] = np.linspace(s, 0, r, endpoint=True)
    return env

def beep(duration_s, f=1800, f2=None, level=0.25):
    n = int(SR * duration_s)
    t = np.arange(n) / SR
    x = tone(t, f)
    if f2 is not None:
        x = 0.6*x + 0.4*tone(t, f2)
    # snappy envelope for cockpit-like beep
    env = adsr(n, a=0.004*SR, d=0.010*SR, s=0.55, r=0.020*SR)
    x = (x * env * level).astype(np.float32)
    return x

def silence(duration_s):
    return np.zeros(int(SR*duration_s), dtype=np.float32)

def make_search_to_lock():
    # Beeps accelerate, then lock confirmation (dual-tone)
    parts = []
    # accelerating beeps
    intervals = [0.34, 0.28, 0.23, 0.19, 0.16, 0.13, 0.11, 0.10]
    freqs =     [1400, 1450, 1500, 1550, 1600, 1680, 1760, 1840]
    for iv, f in zip(intervals, freqs):
        parts.append(beep(0.055, f=f, level=0.22))
        parts.append(silence(max(0.0, iv-0.055)))
    # lock confirm: two quick chirps + a longer dual tone
    parts.append(beep(0.06, f=2100, level=0.22))
    parts.append(silence(0.05))
    parts.append(beep(0.06, f=2100, level=0.22))
    parts.append(silence(0.08))
    parts.append(beep(0.35, f=1900, f2=2400, level=0.26))
    return np.concatenate(parts)

def make_sustained_lock(duration_s=2.0):
    # steady lock tone pattern
    parts = []
    t = 0.0
    while t < duration_s:
        parts.append(beep(0.045, f=1850, level=0.20))
        parts.append(silence(0.085))
        t += 0.13
    return np.concatenate(parts)

if __name__ == "__main__":
    # Choose style: search_to_lock OR sustained_lock
    x = make_search_to_lock()
    # x = make_sustained_lock(2.4)

    x = normalize(x, peak=0.98)

    with tempfile.TemporaryDirectory() as td:
        wav_path = os.path.join(td, "radar.wav")
        ogg_path = os.path.abspath("radar.ogg")
        write_wav(wav_path, x)
        wav_to_ogg(wav_path, ogg_path)

    print("Wrote:", ogg_path)
