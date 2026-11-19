# XSD-validate a FOMOD and list installed files for every option combination.
import sys, os, itertools
from lxml import etree
P = sys.argv[1]
xsd = etree.XMLSchema(etree.parse("/workspace/skyrim/bf10/tools/xsd/ModConfig5.0.xsd"))
doc = etree.parse(f"{P}/fomod/ModuleConfig.xml")
ok = xsd.validate(doc)
print(('PASS' if ok else 'FAIL'), 'XSD validation', '' if ok else xsd.error_log)
etree.parse(f"{P}/fomod/info.xml"); print('PASS info.xml well-formed')
r = doc.getroot()
req = [f.get('source') for f in r.findall('requiredInstallFiles/*')]
steps = r.findall('installSteps/installStep')
def flags_vis(step, flags):
    v = step.find('visible/dependencies')
    if v is None: return True
    return all(flags.get(d.get('flag')) == d.get('value') for d in v.findall('flagDependency'))
# enumerate: for each step all legal selections
def choices(step):
    out = []
    for g in step.findall('optionalFileGroups/group'):
        pl = g.findall('plugins/plugin'); t = g.get('type')
        if t == 'SelectExactlyOne': out.append([[p] for p in pl])
        elif t == 'SelectAll': out.append([pl])
        elif t == 'SelectAny': out.append([list(c) for n in range(len(pl) + 1) for c in itertools.combinations(pl, n)])
        elif t == 'SelectAtLeastOne': out.append([list(c) for n in range(1, len(pl) + 1) for c in itertools.combinations(pl, n)])
    return out
results = []
def walk(i, flags, picks):
    if i == len(steps):
        files = list(req)
        for p in r.findall('conditionalFileInstalls/patterns/pattern'):
            if all(flags.get(d.get('flag')) == d.get('value') for d in p.findall('dependencies/flagDependency')):
                files += [f.get('source') for f in p.findall('files/*')]
        results.append((picks, files)); return
    st = steps[i]
    if not flags_vis(st, flags):
        walk(i + 1, flags, picks); return
    for combo in itertools.product(*choices(st)):
        f2 = dict(flags); names = []
        for sel in combo:
            for p in sel:
                names.append(p.get('name'))
                for fl in p.findall('conditionFlags/flag'): f2[fl.get('name')] = fl.text
        walk(i + 1, f2, picks + [' + '.join(names) or '(none)'])
walk(0, {}, [])
print(f"{len(results)} combinations")
allok = ok
for picks, files in results:
    missing = [f for f in files if not os.path.isdir(f"{P}/{f}")]
    n = sum(len(fs) for f in files if os.path.isdir(f"{P}/{f}") for _, _, fs in os.walk(f"{P}/{f}"))
    # destination collisions between folders in one install
    seen = {}; coll = []
    for f in files:
        for d, _, fs in os.walk(f"{P}/{f}"):
            for x in fs:
                k = os.path.relpath(os.path.join(d, x), f"{P}/{f}").lower()
                if k in seen and not k.endswith('.txt'): coll.append((k, seen[k], f))
                seen[k] = f
    status = 'PASS' if not missing and not coll else 'FAIL'
    allok &= status == 'PASS'
    print(f"{status} {' | '.join(p[:28] for p in picks)} -> {files} ({n} files){' MISSING '+str(missing) if missing else ''}{' COLLIDE '+str(coll[:3]) if coll else ''}")
print('ALL OK' if allok else 'SOME FAILED')
