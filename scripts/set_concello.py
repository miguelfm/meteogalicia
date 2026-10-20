#!/usr/bin/env python3
import sys, re, os

if len(sys.argv) < 3:
    sys.exit(1)

cid = str(sys.argv[1]).strip()
cname = str(sys.argv[2]).strip()

path = os.path.expanduser("~/.local/state/noctalia/settings.toml")
if not os.path.exists(path):
    sys.exit(0)

try:
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    header = '[plugin_settings."miguelfm/meteogalicia"]'
    if header in text:
        parts = text.split(header, 1)
        after = parts[1]
        match = re.search(r'\n\[[^\n]+\]', after)
        if match:
            sec = after[:match.start()]
            rest = after[match.start():]
        else:
            sec = after
            rest = ""
        if not sec.startswith("\n"):
            sec = "\n" + sec
        int_cid = int(cid)
        if re.search(r'^\s*concello_id\s*=', sec, re.M):
            sec = re.sub(r'^\s*concello_id\s*=.*$', f'concello_id = {int_cid}', sec, flags=re.M)
        else:
            sec = f'\nconcello_id = {int_cid}' + sec
        if re.search(r'^\s*concello_name\s*=', sec, re.M):
            sec = re.sub(r'^\s*concello_name\s*=.*$', f'concello_name = "{cname}"', sec, flags=re.M)
        else:
            sec = f'\nconcello_name = "{cname}"' + sec
        text = parts[0] + header + "\n" + sec.strip("\n") + "\n\n" + rest.lstrip("\n")
    else:
        text += f'\n\n{header}\nconcello_id = {int(cid)}\nconcello_name = "{cname}"\n'

    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
except Exception as e:
    sys.stderr.write(f"Error updating settings.toml: {e}\n")
    sys.exit(1)
