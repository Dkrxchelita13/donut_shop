#!/usr/bin/env python3

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path


SAMPLE_RATE: int = 22_050
AMPLITUDE: float = 0.28
FADE_SECONDS: float = 0.005
PROJECT_ROOT: Path = Path(__file__).resolve().parent.parent


def _frequency_at(name: str, elapsed: float, duration: float) -> float:
    if name != "sprinkles":
        frequencies: dict[str, float] = {
            "glaze_apply": 880.0,
            "topping_pop": 1046.5,
            "delivery": 523.25,
        }
        return frequencies[name]

    progress: float = elapsed / duration
    if progress < 1.0 / 3.0:
        return 1396.91
    if progress < 2.0 / 3.0:
        return 1760.0
    return 1174.66


def _generate_samples(name: str, duration: float) -> bytes:
    frame_count: int = round(SAMPLE_RATE * duration)
    fade_frames: int = max(1, round(SAMPLE_RATE * FADE_SECONDS))
    phase: float = 0.0
    frames: bytearray = bytearray()

    for index in range(frame_count):
        elapsed: float = index / SAMPLE_RATE
        frequency: float = _frequency_at(name, elapsed, duration)
        phase += math.tau * frequency / SAMPLE_RATE

        fade_in: float = min(1.0, index / fade_frames)
        fade_out: float = min(1.0, (frame_count - 1 - index) / fade_frames)
        envelope: float = max(0.0, min(fade_in, fade_out))
        sample: int = round(math.sin(phase) * AMPLITUDE * envelope * 32767.0)
        frames.extend(struct.pack("<h", sample))

    return bytes(frames)


def _write_wav(relative_path: str, name: str, duration: float) -> None:
    output_path: Path = PROJECT_ROOT / relative_path
    output_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        with wave.open(str(output_path), "wb") as wav_file:
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(SAMPLE_RATE)
            wav_file.writeframes(_generate_samples(name, duration))
    except (OSError, wave.Error) as error:
        raise RuntimeError(f"No se pudo escribir {output_path}: {error}") from error

    if not output_path.is_file() or output_path.stat().st_size <= 44:
        raise RuntimeError(f"WAV inválido o vacío: {output_path}")
    print(f"SFX placeholder generado: {output_path}")


def main() -> None:
    definitions: tuple[tuple[str, str, float], ...] = (
        ("assets/audio/sfx/decorating/glaze_apply.wav", "glaze_apply", 0.12),
        ("assets/audio/sfx/decorating/topping_pop.wav", "topping_pop", 0.08),
        ("assets/audio/sfx/decorating/sprinkles.wav", "sprinkles", 0.10),
        ("assets/audio/sfx/customers/delivery.wav", "delivery", 0.25),
    )
    for relative_path, name, duration in definitions:
        _write_wav(relative_path, name, duration)


if __name__ == "__main__":
    main()
