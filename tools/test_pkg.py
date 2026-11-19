# Step 1/6 checks: JSON lint, path collisions vs animation packs, scene id clashes, navigation targets.
import os, json, zipfile, sys, re
PKG = sys.argv[1] if len(sys.argv) > 1 else "/workspace/skyrim/bf10/pkg_main"
ROOTS = ('meshes', 'textures', 'skse', 'scripts', 'interface', 'sound', 'seq')
def norm(p):
    parts = p.replace('\\', '/').lower().split('/')
    for i, x in enumerate(parts):
        if x in ROOTS: return '/'.join(parts[i:])
    if parts[-1].endswith(('.esp', '.esm', '.esl', '.bsa')): return parts[-1]
    return None
packs = {
  'OCR 1.9': ['/workspace/skyrim/lirael_patches/src/OCreatures Reforged v1.9.zip', '/workspace/skyrim/ocr/x'],
  "Lirael WVL 0.2.3": ['/workspace/skyrim/lirael023/src'],
  'Billyy (OCR pack 2.1.2)': ['/workspace/skyrim/lirael_patches/src/OCreatures - Billyy Animation Pack COMPLETE v2.1.2.zip'],
  'Billyy merged 4.1': ['/workspace/skyrim/billyy/BillyyMerged_4.1_plus_LiraelComplete_2.0.2.zip'],
  'Baka': ['/workspace/skyrim/lirael_patches/src/OCreatures - Baka Animation Pack v0.1-dev.zip'],
  'FunnyBiz': ['/workspace/skyrim/wwvl_src/FunnyBiz OStim - Creatures v0.2.3.zip'],
  'FlufyFox': ['/workspace/skyrim/lirael_patches/src/FlufyFox OStim - Creatures v0.5.2.zip'],
}
def listing(src):
    out = set()
    if src.endswith('.zip'):
        with zipfile.ZipFile(src) as z:
            for n in z.namelist():
                if not n.endswith('/'):
                    k = norm(n)
                    if k: out.add(k)
    else:
        for d, _, fs in os.walk(src):
            for f in fs:
                k = norm(os.path.join(d, f))
                if k: out.add(k)
    return out
pack_files = {k: set().union(*[listing(s) for s in v if os.path.exists(s)]) for k, v in packs.items()}
for k, v in pack_files.items(): print(f"  {k}: {len(v)} files indexed")
ok = True
# JSON lint + our files
ours = {}
bad_json = []
for folder in sorted(os.listdir(PKG)):
    if folder == 'fomod': continue
    for d, _, fs in os.walk(os.path.join(PKG, folder)):
        for f in fs:
            full = os.path.join(d, f)
            if f.lower().endswith('.json'):
                try: json.load(open(full, encoding='utf-8'))
                except Exception as e: bad_json.append((full, str(e)))
            k = norm(os.path.relpath(full, os.path.join(PKG, folder)))
            if k: ours.setdefault(k, []).append(folder)
print(('PASS' if not bad_json else 'FAIL'), f"JSON lint: {sum(1 for k in ours if k.endswith('.json'))} JSON files", bad_json[:3]); ok &= not bad_json
for pack, files in pack_files.items():
    hits = sorted((k, ours[k]) for k in ours if k in files)
    allowed = [h for h in hits if all(f == '40 OCR standins' for f in h[1]) and pack.startswith('OCR')]
    real = [h for h in hits if h not in allowed]
    print(('PASS' if not real else 'FAIL'), f"no shared paths with {pack}" + (f" ({len(allowed)} OCR stand-ins share OCR's paths; installed only when OCR is NOT installed)" if allowed else ''), real[:8])
    ok &= not real
# scene IDs
def scene_ids(files_iter):
    return {os.path.basename(k)[:-5].lower() for k in files_iter if '/ostim/scenes/' in k and k.endswith('.json')}
our_ids = {}
for k, fl in ours.items():
    if '/ostim/scenes/' in k and k.endswith('.json'):
        our_ids.setdefault(os.path.basename(k)[:-5].lower(), set()).update(fl)
for pack, files in pack_files.items():
    clash = sorted(i for i in scene_ids(files) & set(our_ids) if not (our_ids[i] == {'40 OCR standins'} and pack.startswith('OCR')))
    print(('PASS' if not clash else 'FAIL'), f"no scene-id clash with {pack}", clash[:8]); ok &= not clash
# navigation targets
all_ids = set(our_ids)
for f in pack_files.values(): all_ids |= scene_ids(f)
missing = []
for folder in sorted(os.listdir(PKG)):
    for d, _, fs in os.walk(os.path.join(PKG, folder)):
        for f in fs:
            if f.endswith('.json') and '/OStim/scenes/' in d.replace('\\', '/') + '/':
                j = json.load(open(os.path.join(d, f)))
                for n in j.get('navigations', []):
                    for key in ('destination', 'origin'):
                        t = n.get(key)
                        if t and t.lower() not in all_ids: missing.append((f, key, t))
print(('PASS' if not missing else 'FAIL'), "every navigation origin/destination exists (ours, OCR, Lirael or packs)", missing[:8]); ok &= not missing
print('ALL OK' if ok else 'SOME FAILED')
