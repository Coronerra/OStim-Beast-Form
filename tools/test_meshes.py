import os, re, subprocess, sys
PKG = sys.argv[1] if len(sys.argv) > 1 else "/workspace/skyrim/bf10/pkg_main"
ok = True
shipped = {}
for d, _, fs in os.walk(PKG):
    for f in fs:
        rel = os.path.relpath(os.path.join(d, f), PKG).split(os.sep, 1)
        if len(rel) == 2: shipped.setdefault(rel[1].replace('\\', '/').lower(), []).append(os.path.join(d, f))
for k, paths in sorted(shipped.items()):
    if not k.endswith('.nif') or '/animations/' in k: continue
    data = open(paths[0], 'rb').read()
    strs = set(re.findall(rb'[ -~]{6,}', data))
    xmls = [s.decode() for s in strs if s.lower().endswith(b'.xml')]
    tris = [s.decode() for s in strs if s.lower().endswith(b'.tri')]
    shapes = [l.split(' verts=')[0] for l in subprocess.run(['/workspace/tools/nifly/chk', paths[0]], capture_output=True, text=True).stdout.splitlines() if ' verts=' in l]
    for x in xmls:
        xk = x.replace('\\', '/').lower()
        found = xk in shipped
        print(('PASS' if found else 'FAIL'), f"{k}: SMP XML {x} shipped"); ok &= found
        if found:
            xt = open(shipped[xk][0], encoding='utf-8', errors='ignore').read()
            names = re.findall(r'<per-(?:vertex|triangle)-shape name="([^"]+)"', xt)
            miss = [n for n in names if n not in shapes]
            # an XML shared by two meshes may list shapes of the other one; report only
            print(('PASS' if not miss else 'NOTE'), f"   XML shapes present in this nif: {len(names)-len(miss)}/{len(names)}", miss)
    for t in tris:
        tk = ('meshes/' + t.replace('\\', '/')).lower()
        found = tk in shipped
        print(('PASS' if found else 'FAIL'), f"{k}: BODYTRI {t} shipped"); ok &= found
print('ALL OK' if ok else 'SOME FAILED')
