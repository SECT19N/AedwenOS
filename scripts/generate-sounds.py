#!/usr/bin/env python3
"""
Synthesize the AedwenOS system sound set from the exact tone recipes in the
AedwenOS System Surfaces design's play() function (Web Audio oscillator +
gain-envelope calls), then package them as a freedesktop sound theme.

Pure-stdlib WAV synthesis (no numpy) piped through ffmpeg for the final
Ogg Vorbis files, matching each event's oscillator type, frequency (with
optional exponential glide to a second frequency), start offset, duration
and gain envelope (12ms exponential attack, exponential decay to the tail).

Usage:
    scripts/generate-sounds.py [--out DIR]

Requires ffmpeg on PATH.
"""

import argparse
import math
import os
import struct
import subprocess
import wave

SAMPLE_RATE = 44100

NOTES = {
    "C5": 523.25,
    "E5": 659.25,
    "G5": 783.99,
    "A5": 880,
    "C6": 1046.5,
    "E6": 1318.5,
    "G4": 392,
    "E4": 329.6,
    "C4": 261.6,
    "A4": 440,
}


def osc(t, freq, kind):
    phase = 2 * math.pi * freq * t
    if kind == "sine":
        return math.sin(phase)
    if kind == "triangle":
        x = (freq * t) % 1.0
        return 4 * abs(x - 0.5) - 1
    if kind == "square":
        return 1.0 if (freq * t) % 1.0 < 0.5 else -1.0
    raise ValueError(kind)


def gain_envelope(t, dur):
    """12ms exponential attack to 1.0, then exponential decay to ~0 by `dur`."""
    attack = 0.012
    floor = 0.0001
    if t < attack:
        # exponential ramp from floor to 1.0
        frac = t / attack
        return floor * (1.0 / floor) ** frac
    frac = (t - attack) / max(dur - attack, 0.001)
    frac = min(frac, 1.0)
    return 1.0 * (floor / 1.0) ** frac


def render_tone(buf, f, start_s, dur, kind="sine", gain=0.16, f2=None):
    n0 = int(start_s * SAMPLE_RATE)
    n1 = int((start_s + dur + 0.05) * SAMPLE_RATE)
    for n in range(n0, min(n1, len(buf))):
        t = (n - n0) / SAMPLE_RATE
        if t < 0:
            continue
        if f2 is not None:
            frac = min(t / dur, 1.0)
            freq = f * (f2 / f) ** frac
        else:
            freq = f
        env = gain_envelope(t, dur)
        buf[n] += osc(t, freq, kind) * env * gain


def new_buffer(total_dur):
    return [0.0] * int(total_dur * SAMPLE_RATE)


def write_wav(path, buf):
    peak = max(0.001, max(abs(s) for s in buf))
    scale = min(1.0, 0.98 / peak)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        frames = struct.pack(
            "<%dh" % len(buf),
            *(max(-32768, min(32767, int(s * scale * 32767))) for s in buf),
        )
        w.writeframes(frames)


N = NOTES


def build(kind):
    if kind == "login":
        buf = new_buffer(0.9)
        for i, n in enumerate(["C5", "E5", "G5", "C6"]):
            render_tone(buf, N[n], i * 0.08, 0.5, "sine", 0.13)
        return buf
    if kind == "logout":
        buf = new_buffer(0.85)
        for i, n in enumerate(["C6", "G5", "E5", "C5"]):
            render_tone(buf, N[n], i * 0.08, 0.45, "sine", 0.12)
        return buf
    if kind == "notify":
        buf = new_buffer(0.5)
        render_tone(buf, N["E6"], 0, 0.25, "triangle", 0.12)
        render_tone(buf, N["A5"] * 1.5, 0.09, 0.35, "triangle", 0.1)
        return buf
    if kind == "critical":
        buf = new_buffer(0.55)
        render_tone(buf, N["A4"], 0, 0.18, "triangle", 0.18)
        render_tone(buf, N["E4"], 0.16, 0.3, "triangle", 0.18)
        return buf
    if kind == "error":
        buf = new_buffer(0.35)
        render_tone(buf, 220, 0, 0.12, "square", 0.05)
        render_tone(buf, 196, 0.13, 0.16, "square", 0.05)
        return buf
    if kind == "volume":
        buf = new_buffer(0.15)
        render_tone(buf, 1600, 0, 0.05, "sine", 0.14)
        return buf
    if kind == "plug":
        buf = new_buffer(0.4)
        render_tone(buf, N["G4"], 0, 0.3, "sine", 0.16, N["G5"])
        return buf
    if kind == "unplug":
        buf = new_buffer(0.4)
        render_tone(buf, N["G5"], 0, 0.3, "sine", 0.16, N["G4"])
        return buf
    if kind == "shot":
        buf = new_buffer(0.15)
        render_tone(buf, 2400, 0, 0.04, "square", 0.03)
        render_tone(buf, 1800, 0.06, 0.05, "square", 0.03)
        return buf
    if kind == "trash":
        buf = new_buffer(0.45)
        render_tone(buf, 900, 0, 0.35, "triangle", 0.1, 180)
        return buf
    if kind == "battery":
        buf = new_buffer(0.75)
        render_tone(buf, N["E5"], 0, 0.18, "sine", 0.14)
        render_tone(buf, N["C5"], 0.18, 0.18, "sine", 0.14)
        render_tone(buf, N["G4"], 0.36, 0.3, "sine", 0.14)
        return buf
    raise ValueError(kind)


# freedesktop sound-theme-spec event id each maps onto
FREEDESKTOP_NAMES = {
    "login": "desktop-login",
    "logout": "desktop-logout",
    "notify": "message-new-instant",
    "critical": "dialog-warning",
    "error": "dialog-error",
    "volume": "audio-volume-change",
    "plug": "device-added",
    "unplug": "device-removed",
    "shot": "screen-capture",
    "trash": "trash-empty",
    "battery": "battery-low",
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="iso/airootfs/usr/share/sounds/AedwenOS")
    args = ap.parse_args()

    stereo_dir = os.path.join(args.out, "stereo")
    os.makedirs(stereo_dir, exist_ok=True)

    for kind, fd_name in FREEDESKTOP_NAMES.items():
        buf = build(kind)
        wav_path = os.path.join(stereo_dir, f"{fd_name}.wav")
        ogg_path = os.path.join(stereo_dir, f"{fd_name}.oga")
        write_wav(wav_path, buf)
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-loglevel",
                "error",
                "-i",
                wav_path,
                "-c:a",
                "libvorbis",
                "-q:a",
                "4",
                ogg_path,
            ],
            check=True,
        )
        os.remove(wav_path)
        print(f"  {kind:10s} -> {ogg_path}")

    with open(os.path.join(args.out, "index.theme"), "w") as f:
        f.write("""[Sound Theme]
Name=AedwenOS
Comment=Soft sine/triangle tones in one key, generated from the AedwenOS System Surfaces design
Inherits=freedesktop
Directories=stereo

[stereo]
OutputProfile=stereo
""")

    print(f"Wrote sound theme to {args.out}")


if __name__ == "__main__":
    main()
