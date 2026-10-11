#!/bin/bash
# Gathers the logs needed for a bug report into one text file, with personal
# details masked: IPv4 and IPv6 addresses, MAC addresses, UUIDs and other long
# IDs, device serials, Steam IDs, email addresses, the PC names and addresses
# Moonlight XR has stored, this machine's hostname, saved Wi-Fi network names
# and your home folder name.
# Usage: steam-frame/collect-logs.sh [appid]
# Without an appid it uses the newest Lepton log that mentions Moonlight XR.
# Read the output before you share it. The masking is pattern based.
set -e
LOGS=$HOME/.local/share/Steam/logs
PKG=com.gilleece.moonlightxr
APPID=$1
if [ -z "$APPID" ]; then
    NEWEST=$(ls -t "$LOGS"/lepton-steamlaunch-*.log 2>/dev/null | grep -v '\.prev\.log$' \
        | while read -r f; do grep -q "$PKG" "$f" && { echo "$f"; break; }; done)
    [ -n "$NEWEST" ] || { echo "no Lepton log mentions Moonlight XR yet; launch it once, or pass the appid the installer printed"; exit 1; }
    APPID=$(basename "$NEWEST" .log); APPID=${APPID#lepton-steamlaunch-}
fi
OUTDIR=$HOME/Games/MoonlightXR/logs
mkdir -p "$OUTDIR"
OUT=$OUTDIR/moonlightxr-logs-$(date +%Y%m%d-%H%M%S).txt

# Words to mask besides the patterns: saved Wi-Fi names and this hostname
EXTRA=$(mktemp); trap 'rm -f "$EXTRA"' EXIT
command -v nmcli >/dev/null && nmcli -t -f NAME,TYPE connection show 2>/dev/null \
    | sed -n 's/:802-11-wireless$//p' >> "$EXTRA" || true
hostname >> "$EXTRA" 2>/dev/null || true

python3 -I - "$OUT" "$APPID" "$PKG" "$EXTRA" <<'PY'
import glob, json, os, re, sqlite3, sys, time
out, appid, pkg, extra = sys.argv[1:5]
home = os.path.expanduser('~')
logs = os.path.join(home, '.local/share/Steam/logs')

names = set()
for line in open(extra, encoding='utf-8', errors='replace'):
    w = line.strip()
    # Skip generic hostnames, which would mask ordinary words in the logs
    if len(w) >= 3 and w.lower() not in ('steamdeck', 'steamos', 'localhost', 'frame', 'steam'):
        names.add(w)
db = os.path.join(home, '.local/share/Steam/steamapps/compatdata', appid, 'internal', pkg,
                  'databases/computers4.db')
if os.path.exists(db):
    try:
        con = sqlite3.connect('file:' + db + '?mode=ro&immutable=1', uri=True)
        for name, addrs, mac in con.execute('SELECT ComputerName, Addresses, MacAddress FROM Computers'):
            if name: names.add(name)
            if mac: names.add(mac)
            try:
                for a in json.loads(addrs or '{}').values():
                    if isinstance(a, dict) and a.get('address'): names.add(a['address'])
            except ValueError:
                pass
    except sqlite3.Error:
        pass

rules = [
    (re.compile(r'\x1b\[[0-9;]*m'), ''),
    (re.compile(r'(?<![/\w.%+-])[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,24}\b'), '<email>'),
    (re.compile(r'(?i)\b([0-9a-f]{2}[:-]){5}[0-9a-f]{2}\b'), '<mac>'),
    (re.compile(r'(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b'), '<uuid>'),
    (re.compile(r'\b7656119\d{10}\b'), '<steamid>'),
    (re.compile(r'(?i)((?:ro\.)?serial(?:no|number)?|android_id)(["\'\]\s:=]+)([^\s,;"\'\]]+)'), r'\1\2<serial>'),
    (re.compile(r'\b(?!127\.0\.0\.1\b)(?!0\.0\.0\.0\b)(?:\d{1,3}\.){3}\d{1,3}\b'), '<ip>'),
    (re.compile(r'(?i)(?<![\w:])(?=[0-9a-f:]*[a-f][0-9a-f:]*)(?:[0-9a-f]{0,4}:){2,7}[0-9a-f]{1,4}(?![\w:])'), '<ipv6>'),
    (re.compile(r'\b(?=[0-9A-F]*[A-F])(?=[0-9A-F]*[0-9])[0-9A-F]{16}\b'), '<id>'),
    (re.compile(re.escape(home) + r'\b'), '/home/<user>'),
]
for n in sorted(names, key=len, reverse=True):
    rules.append((re.compile(r'(?<![\w.-])' + re.escape(n) + r'(?![\w-])', re.I), '<name>'))

def mask(text):
    for rx, rep in rules:
        text = rx.sub(rep, text)
    return text

parts = [('launch wrapper', '/tmp/moonlightxr-launch.log'),
         ('Lepton', os.path.join(logs, 'lepton-steamlaunch-%s.log' % appid))]
dumps = [f for f in glob.glob(os.path.join(logs, 'lepton-logcats', '*')) if os.path.isfile(f)]
dumps.sort(key=os.path.getmtime, reverse=True)
for f in dumps[:5]:
    if pkg in open(f, encoding='utf-8', errors='replace').read():
        parts.append(('logcat dump', f))
        if len([p for p in parts if p[0] == 'logcat dump']) == 2:
            break

with open(out, 'w', encoding='utf-8') as o:
    o.write('Moonlight XR on the Steam Frame, logs collected %s, appid %s\n' % (time.strftime('%Y-%m-%d %H:%M'), appid))
    for label, f in parts:
        o.write('\n===== %s: %s =====\n' % (label, mask(f)))
        if not os.path.exists(f):
            o.write('(missing)\n')
            continue
        with open(f, encoding='utf-8', errors='replace') as src:
            for line in src:
                o.write(mask(line))
os.chmod(out, 0o600)
print(out)
PY
echo "Read it before you share it. Anything personal the patterns missed is yours to remove."
