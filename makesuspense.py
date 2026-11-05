import math, struct, wave

sample_rate = 44100
duration = 2.4  # Seamless loop duration
num_samples = int(sample_rate * duration)
freqs = [220.0, 277.18, 329.63, 440.0, 659.25, 880.0]  # A-major magical shimmer chord

with wave.open("DuoGacha/chest_suspense.wav", "w") as wav:
    wav.setnchannels(1)
    wav.setsampwidth(2)
    wav.setframerate(sample_rate)
    for i in range(num_samples):
        t = i / sample_rate
        # Slow pulsing LFO for the Fortnite-style treasure shimmer
        lfo = 0.65 + 0.35 * math.sin(2 * math.pi * (t / duration) * 2)
        sample = sum(math.sin(2 * math.pi * f * t) / len(freqs) for f in freqs)
        # Add subtle high-frequency sparkle
        sparkle = 0.15 * math.sin(2 * math.pi * 1760.0 * t) * (0.5 + 0.5 * math.sin(2 * math.pi * 5 * t))
        val = max(-1.0, min(1.0, (sample * lfo + sparkle) * 0.45))
        wav.writeframesraw(struct.pack("<h", int(val * 32767)))

print("Created DuoGacha/chest_suspense.wav")