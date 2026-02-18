import numpy as np
import wave, os, subprocess, tempfile

SR = 44100

def lowpass(x, cutoff_hz, sr):
    rc = 1.0 / (2*np.pi*cutoff_hz)
    dt = 1.0 / sr
    alpha = dt / (rc + dt)
    y = np.zeros_like(x)
    y[0] = x[0]
    for i in range(1, len(x)):
        y[i] = y[i-1] + alpha * (x[i] - y[i-1])
    return y

def highpass(x, cutoff_hz, sr):
    return x - lowpass(x, cutoff_hz, sr)

def bandpass(x, lo_hz, hi_hz, sr):
    return lowpass(highpass(x, lo_hz, sr), hi_hz, sr)

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

def exp_env(t, a):
    return np.exp(-a*t)

def cookoff_burst(rng, t, start_s, dur_s, strength=1.0):
    """Single 'ammo pop' burst: bright crack + short mid body + tiny thump."""
    n = t.size
    env = np.zeros(n, dtype=np.float32)
    mask = (t >= start_s) & (t < start_s + dur_s)
    tt = (t[mask] - start_s)

    # Very fast attack, then decay
    a = 700.0
    d = 35.0
    env_seg = (1 - np.exp(-a*tt)) * np.exp(-d*tt)
    env[mask] = env_seg.astype(np.float32)

    white = rng.standard_normal(n).astype(np.float32)
    crack = highpass(white, 2500, SR) * env * (0.9*strength)

    mid = bandpass(rng.standard_normal(n).astype(np.float32), 250, 2200, SR)
    mid *= env * (0.55*strength)

    # tiny thump (sub pulse)
    freq = 90.0
    phase = 2*np.pi*freq*(t-start_s)
    th = np.sin(phase).astype(np.float32) * env * (0.25*strength)
    th = lowpass(th, 180, SR)

    return crack + mid + th

def synth_tank_cookoff(duration=3.2, seed=23):
    rng = np.random.default_rng(seed)
    n = int(SR * duration)
    t = np.arange(n) / SR

    # === Main catastrophic blast at t=0 ===
    # Shock crack
    crack = highpass(rng.standard_normal(n).astype(np.float32), 2800, SR)
    crack *= exp_env(t, 180.0).astype(np.float32) * 0.65

    # Body blast (band-limited noise, fast attack, medium decay)
    body = bandpass(rng.standard_normal(n).astype(np.float32), 70, 2400, SR)
    attack = (1.0 - np.exp(-t*160.0))
    decay = np.exp(-t*2.6)
    body *= (attack*decay).astype(np.float32) * 1.15

    # Heavy sub thump
    freq = 68 - 26*(1 - np.exp(-t*9.0))
    phase = 2*np.pi*np.cumsum(freq)/SR
    thump = np.sin(phase).astype(np.float32) * exp_env(t, 9.5).astype(np.float32)
    thump *= (t < 0.5).astype(np.float32) * 0.95
    thump = lowpass(thump, 140, SR)

    # === Fire/pressure roar tail ===
    roar = lowpass(rng.standard_normal(n).astype(np.float32), 900, SR)
    roar = highpass(roar, 60, SR)
    roar_env = (1 - np.exp(-t*18.0)) * np.exp(-t*0.9)
    roar *= roar_env.astype(np.float32) * 0.55

    # === Metallic debris "tinks" (short resonant pings) ===
    pings = np.zeros(n, dtype=np.float32)
    ping_times = rng.uniform(0.08, duration*0.95, size=45)
    for st in ping_times:
        idx = int(st*SR)
        if idx >= n: 
            continue
        L = int(SR * rng.uniform(0.03, 0.12))
        end = min(n, idx+L)
        tt = np.arange(end-idx)/SR
        f0 = rng.uniform(900, 4200)
        sig = np.sin(2*np.pi*f0*tt) * np.exp(-tt*rng.uniform(20, 60))
        sig *= rng.uniform(0.03, 0.10)
        pings[idx:end] += sig.astype(np.float32)

    pings = bandpass(pings, 600, 6500, SR)

    # === Ammo cook-off chain bursts after the initial blast ===
    chain = np.zeros(n, dtype=np.float32)
    # clustered early pops + some later ones
    times = np.concatenate([
        rng.uniform(0.10, 0.90, size=10),
        rng.uniform(0.90, 2.40, size=8),
        rng.uniform(2.40, duration*0.92, size=4),
    ])
    times.sort()
    for st in times:
        dur = rng.uniform(0.06, 0.16)
        strength = rng.uniform(0.6, 1.1) * (0.85 if st > 1.6 else 1.0)
        chain += cookoff_burst(rng, t, float(st), float(dur), float(strength))

    # === Early reflections / space (short feedback delay) ===
    x = crack + body + thump + roar + chain + pings

    delay_ms = 62
    d = int(SR * delay_ms / 1000)
    y = np.copy(x)
    fb = 0.30
    for i in range(d, n):
        y[i] += fb * y[i - d]
    y = lowpass(y, 7000, SR)

    return normalize(y)

if __name__ == "__main__":
    audio = synth_tank_cookoff(duration=3.2, seed=23)
    with tempfile.TemporaryDirectory() as td:
        wav_path = os.path.join(td, "explosion.wav")
        ogg_path = os.path.abspath("explosion.ogg")
        write_wav(wav_path, audio)
        wav_to_ogg(wav_path, ogg_path)
    print("Wrote:", ogg_path)
