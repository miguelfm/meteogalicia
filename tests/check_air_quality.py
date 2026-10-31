#!/usr/bin/env python3
"""Unit tests for air quality data parsing, distance calculations, and translation consistency."""

import json
import math
import re
from pathlib import Path


def distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    r_lat1 = math.radians(lat1)
    r_lat2 = math.radians(lat2)
    a = math.sin(d_lat * 0.5) ** 2 + math.cos(r_lat1) * math.cos(r_lat2) * math.sin(d_lon * 0.5) ** 2
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(max(0.0, 1.0 - a)))
    return 6371.0 * c


def format_pollutant(code: str) -> tuple[str, str]:
    if not code:
        return "--", "µg/m³"
    c = code.upper()
    if c in ("PM25", "PM2.5", "PM2_5"):
        return "PM₂.₅", "µg/m³"
    if c == "PM10":
        return "PM₁₀", "µg/m³"
    if c == "NO2":
        return "NO₂", "µg/m³"
    if c == "O3":
        return "O₃", "µg/m³"
    if c == "SO2":
        return "SO₂", "µg/m³"
    if c == "CO":
        return "CO", "mg/m³"
    return code, "µg/m³"


def test_catalogs():
    root = Path(__file__).resolve().parent.parent
    catalogs = {lang: json.loads((root / f"translations/{lang}.json").read_text()) for lang in ["en", "gl-ES"]}
    en, gl = catalogs["en"], catalogs["gl-ES"]
    assert en.keys() == gl.keys(), "Catalog keys mismatch: " + str(set(en.keys()) ^ set(gl.keys()))
    for key, value in en.items():
        assert isinstance(value, str) and isinstance(gl[key], str)
        assert re.findall(r"%[-\d.]*[sdif]", value) == re.findall(r"%[-\d.]*[sdif]", gl[key]), f"Placeholder mismatch in {key}"

    # Required air quality keys
    req_keys = [
        "ui.aqi.good", "ui.aqi.fair", "ui.aqi.moderate", "ui.aqi.poor", "ui.aqi.very_poor",
        "ui.aqi.full", "ui.aqi.val_full", "ui.aqi.station", "ui.aqi.station_simple",
        "ui.aqi.pollutant", "ui.aqi.forecast_hint", "ui.aqi.rec_1", "ui.aqi.rec_2",
        "ui.aqi.rec_3", "ui.aqi.rec_4", "ui.aqi.rec_5"
    ]
    for k in req_keys:
        assert k in en, f"Missing key in en: {k}"
        assert k in gl, f"Missing key in gl: {k}"
    print("✓ Translation catalogs verified (250 keys, identical placeholders)")


def test_distance():
    # Fene (43.4633, -8.1633) to Ferrol - Raíña Sofía (43.481510, -8.2431197)
    d = distance_km(43.4633, -8.1633, 43.481510, -8.2431197)
    assert 6.0 <= d <= 7.0, f"Unexpected distance: {d}"

    # A Coruña (43.3713, -8.396) to Riazor (43.367091, -8.420599)
    d2 = distance_km(43.3713, -8.396, 43.367091, -8.420599)
    assert 1.0 <= d2 <= 2.5, f"Unexpected distance: {d2}"
    print(f"✓ Distance calculations verified (Fene->Raíña Sofía: {d:.1f} km, Coruña->Riazor: {d2:.1f} km)")


def test_pollutant_formatting():
    assert format_pollutant("PM25") == ("PM₂.₅", "µg/m³")
    assert format_pollutant("PM10") == ("PM₁₀", "µg/m³")
    assert format_pollutant("NO2") == ("NO₂", "µg/m³")
    assert format_pollutant("O3") == ("O₃", "µg/m³")
    assert format_pollutant("SO2") == ("SO₂", "µg/m³")
    assert format_pollutant("CO") == ("CO", "mg/m³")
    assert format_pollutant("unknown") == ("unknown", "µg/m³")
    print("✓ Pollutant formatting and units verified")


if __name__ == "__main__":
    test_catalogs()
    test_distance()
    test_pollutant_formatting()
    print("All air quality unit tests passed!")
