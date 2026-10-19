"""Small original machine sound loop and chimes. Standard Python; no downloaded audio."""
from pathlib import Path
import math
import random
import struct
import wave

out = Path(__file__).resolve().parents[1] / "assets" / "audio"
out.mkdir(parents=True, exist_ok=True)
rate = 22050
random.seed(84)
for name in ("diesel",):
    frames = bytearray()
    noise = 0.0
    for i in range(rate * 2):
        t = i / rate
        noise = noise * .94 + random.uniform(-1, 1) * .06
        pulse = .65 + .35 * math.sin(2 * math.pi * 14 * t)
        value = pulse * (.28 * math.sin(2 * math.pi * 56 * t) + .17 * math.sin(2 * math.pi * 112 * t) + .08 * math.sin(2 * math.pi * 168 * t)) + .24 * noise
        frames.extend(struct.pack('<h', int(max(-1, min(1, value)) * 32767)))
    with wave.open(str(out / f"{name}.wav"), 'wb') as f:
        f.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        f.writeframes(frames)

# Short, gentle toy sounds. Envelopes eliminate clicks at either end.
for name, notes in {
    'scoop': [(392, .10), (523.25, .14)],
    'plop': [(180, .13)],
    'star': [(523.25, .12), (659.25, .12), (783.99, .24)],
}.items():
    frames = bytearray()
    for frequency, duration in notes:
        for i in range(int(rate * duration)):
            t = i / rate
            envelope = min(1, t / .012) * max(0, 1 - t / duration)**1.5
            value = .38 * envelope * (math.sin(2 * math.pi * frequency * t) + .13 * math.sin(2 * math.pi * frequency * 2 * t))
            frames.extend(struct.pack('<h', int(value * 32767)))
    with wave.open(str(out / f'{name}.wav'), 'wb') as f:
        f.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        f.writeframes(frames)
