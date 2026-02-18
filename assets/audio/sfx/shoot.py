import numpy as np
import wave, os, subprocess, tempfile

SR = 44100

def env_exp(t, a=30.0):
    # fast decay envelope
    return np.exp(-a * t)

def lowpass(x, cutoff_hz, sr):
    # one-pole lowpass
    rc = 1.0 / (2*np.pi*cutoff_hz)
    dt = 1.0 / sr
    alpha = dt / (rc + dt)
    y = np.zeros_like(x)
    y[0] = x[0]
    for i in range(1, len(x)):
        y[i] = y[i-1] + alpha * (x[i] - y[i-1])
    return y

def highpass(x, cutoff_hz, sr):
    # one-pole highpass via lowpass subtraction
    return x - lowpass(x, cutoff_hz, sr)

def normalize(x, peak=0.98):
    m = np.max(np.abs(x)) + 1e-9
    return x * (peak / m)

def synth_tank_cannon(duration=1.6):
    n = int(SR * duration)
    t = np.arange(n) / SR

    # Shock transient: very short low-frequency thump + click
    thump = np.sin(2*np.pi*(55 + 25*np.exp(-t*18))*t) * env_exp(t, a=18)
    thump *= (t < 0.25).astype(np.float32)

    click = (np.random.randn(n) * env_exp(t, a=180)) * (t < 0.04)

    # Blast body: band-limited noise with fast attack, slower decay
    noise = np.random.randn(n)
    body = lowpass(noise, 1800, SR)
    body = highpass(body, 60, SR)
    body_env = (1 - np.exp(-t*180)) * np.exp(-t*3.2)
    body *= body_env

    # Tail: darker rumble with longer decay
    tail = lowpass(np.random.randn(n), 380, SR)
    tail_env = (1 - np.exp(-t*40)) * np.exp(-t*1.4)
    tail *= tail_env * 0.7

    x = 1.2*thump + 0.6*click + 1.0*body + 0.9*tail

    # Simple "space": feedback delay (very small, subtle)
    delay_ms = 42
    d = int(SR * delay_ms / 1000)
    y = np.copy(x)
    fb = 0.35
    for i in range(d, n):
        y[i] += fb * y[i - d]
    y = lowpass(y, 6000, SR)

    return normalize(y)

def write_wav(path, x):
    x16 = np.int16(np.clip(x, -1, 1) * 32767)
    with wave.open(path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(x16.tobytes())

def wav_to_ogg(wav_path, ogg_path):
    # Requires ffmpeg in PATH
    cmd = [
        "ffmpeg", "-y",
        "-i", wav_path,
        "-c:a", "libvorbis",
        "-q:a", "5",
        ogg_path
    ]
    subprocess.check_call(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

if __name__ == "__main__":
    x = synth_tank_cannon()
    with tempfile.TemporaryDirectory() as td:
        wav_path = os.path.join(td, "shoot.wav")
        ogg_path = os.path.abspath("shoot.ogg")
        write_wav(wav_path, x)
        wav_to_ogg(wav_path, ogg_path)
    print("Wrote:", ogg_path)
