#!/usr/bin/env python3
"""Validate both catalogs and execute the real Luau UI with a mocked Noctalia host.

Run from the repository root: python tests/check_i18n.py [--luau /path/to/luau]
The checks do not access the network or change the live shell configuration.
"""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import tomllib


def lua(value):
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, dict):
        return "{" + ",".join(f"[{lua(k)}]={lua(v)}" for k, v in value.items()) + "}"
    raise TypeError(type(value))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", default=shutil.which("luau"))
    args = parser.parse_args()
    if not args.luau:
        parser.error("Install Luau or pass --luau /path/to/luau")
    catalogs = {lang: json.loads(Path(f"translations/{lang}.json").read_text()) for lang in ["en", "gl-ES"]}
    en, gl = catalogs["en"], catalogs["gl-ES"]
    assert en.keys() == gl.keys(), "English and Galician catalog keys differ"
    for key, value in en.items():
        assert isinstance(value, str) and isinstance(gl[key], str)
        assert re.findall(r"%[-\d.]*[sdif]", value) == re.findall(r"%[-\d.]*[sdif]", gl[key]), key
    manifest = tomllib.loads(Path("plugin.toml").read_text())
    for setting in manifest["setting"]:
        for key in [setting["label_key"], setting.get("description_key")]:
            if key:
                assert key in en, key
        for option in setting.get("options", []):
            assert option["label_key"] in en, option
    sources = {name: Path(name + ".luau").read_text() for name in ["i18n", "forecast", "shared", "concellos", "stations", "bar", "panel", "service"]}
    for name, source in sources.items():
        for key in re.findall(r'(?:\btr|i18n\.format)\("([^"\n]+)"\s*[,)]', source):
            assert key in en, f"{name}: {key}"
    prelude = "local SOURCES=" + lua(sources) + "\nlocal CATALOGS=" + lua(catalogs) + "\n"
    with tempfile.TemporaryDirectory(prefix="meteogalicia-i18n-test-") as directory:
        script = Path(directory) / "test.luau"
        script.write_text(prelude + Path("tests/i18n_test.luau").read_text())
        subprocess.run([args.luau, str(script)], check=True, env={**os.environ, "TZ": "Europe/Madrid"}, timeout=60)
    print(f"catalogs: {len(en)} matching English/Galician keys; settings and formatting placeholders verified")


if __name__ == "__main__":
    main()
