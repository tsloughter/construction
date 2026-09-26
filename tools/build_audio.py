"""Small original machine sound loops. Standard Python; no downloaded audio."""
from pathlib import Path
import math
import random
import struct
import wave

out = Path(__file__).resolve().parents[1] / "assets" / "audio"
out.mkdir(parents=True, exist_ok=True)
rate = 22050
random.seed(84)
for name in ("diesel", "hydraulics"):
    frames = bytearray()
    noise = 0.0
    for i in range(rate * 2):
        t = i / rate
        noise = noise * .94 + random.uniform(-1, 1) * .06
        if name == "diesel":
            pulse = .65 + .35 * math.sin(2 * math.pi * 14 * t)
            value = pulse * (.28 * math.sin(2 * math.pi * 56 * t) + .17 * math.sin(2 * math.pi * 112 * t) + .08 * math.sin(2 * math.pi * 168 * t)) + .24 * noise
        else:
            value = .13 * math.sin(2 * math.pi * 430 * t) + .08 * math.sin(2 * math.pi * 860 * t) + .4 * noise
        frames.extend(struct.pack('<h', int(max(-1, min(1, value)) * 32767)))
    with wave.open(str(out / f"{name}.wav"), 'wb') as f:
        f.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        f.writeframes(frames)
