# Downloads 2 (Softbody / Tullius patches) and 3 (Herm patch). That Guy (Coronerra).
import os, shutil
from xml.sax.saxutils import escape as e
from lxml import etree
R = "/workspace/skyrim/bf10"; S = "/workspace/skyrim/bf081/pkg"
def cp(a, b): os.makedirs(os.path.dirname(b), exist_ok=True); shutil.copy2(a, b)
def put(p, t): os.makedirs(os.path.dirname(p), exist_ok=True); open(p, 'w', newline='\r\n').write(t.strip() + "\n")
def info(p, name, desc):
    put(f"{p}/fomod/info.xml", f'''<?xml version="1.0" encoding="UTF-8"?>
<fomod>
	<Name>{e(name)}</Name>
	<Author>That Guy (Coronerra)</Author>
	<Version>1.0</Version>
	<Description>{e(desc)}</Description>
	<Website>https://github.com/Coronerra/OStim-Beast-Form-Merged</Website>
	<Groups><element>Creatures</element></Groups>
</fomod>''')
def plugin(name, desc, flags, typ="Optional", dep=None):
    fl = "".join(f'<flag name="{k}">{v}</flag>' for k, v in flags)
    if dep:
        td = '<typeDescriptor><dependencyType><defaultType name="%s" /><patterns><pattern><dependencies operator="%s">%s</dependencies><type name="Recommended" /></pattern></patterns></dependencyType></typeDescriptor>' % (typ, dep[0], "".join(f'<fileDependency file="{f}" state="Active" />' for f in dep[1]))
    else:
        td = f'<typeDescriptor><type name="{typ}" /></typeDescriptor>'
    return f'<plugin name="{e(name)}"><description>{e(desc)}</description><conditionFlags>{fl}</conditionFlags>{td}</plugin>'
def step(name, group, gtype, plugins):
    return f'<installStep name="{e(name)}"><optionalFileGroups order="Explicit"><group name="{e(group)}" type="{gtype}"><plugins order="Explicit">{"".join(plugins)}</plugins></group></optionalFileGroups></installStep>'
def write_cfg(p, modname, steps, pats, required=None):
    req = f'<requiredInstallFiles><folder source="{required}" destination="" priority="0" /></requiredInstallFiles>' if required else ''
    pt = ""
    for deps, folders in pats:
        d = "".join(f'<flagDependency flag="{k}" value="{v}" />' for k, v in deps)
        f = "".join(f'<folder source="{x}" destination="" priority="0" />' for x in folders)
        pt += f'<pattern><dependencies operator="And">{d}</dependencies><files>{f}</files></pattern>'
    xml = f'<?xml version="1.0" encoding="UTF-8"?><config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://qconsulting.ca/fo3/ModConfig5.0.xsd"><moduleName>{e(modname)}</moduleName>{req}<installSteps order="Explicit">{"".join(steps)}</installSteps><conditionalFileInstalls><patterns>{pt}</patterns></conditionalFileInstalls></config>'
    os.makedirs(f"{p}/fomod", exist_ok=True)
    open(f"{p}/fomod/ModuleConfig.xml", "wb").write(etree.tostring(etree.fromstring(xml.encode()), xml_declaration=True, encoding="UTF-8", pretty_print=True))

# ---------------- Download 2 ----------------
P = f"{R}/pkg_softbody"; shutil.rmtree(P, ignore_errors=True)
put(f"{P}/00 Docs/Docs/OStim Beast Form/README_Softbody_Tullius_Patches.txt", """
Beast Form Softbody / Tullius Patches 1.0 (optional, for OStim Beast Form 1.0)
by That Guy (Coronerra)

What it is: ONE file, Scripts\\OCumMaleScript.pex, picked for your setup.
OCum, GT Softbody's OCum patch, the OCum Tull/Liquid add-on and this patch
all ship that same file, so only one can win. This installer gives you
the one that matches what you use.

The converted female werewolf body and cock are already in the main file
for everyone (they work with or without GT Softbody), so this download
has no meshes.

Choices:
- GT Softbody (with or without Tull / Liquid Pack): my OCum + Tull/Liquid
  + GT Softbody merged script (same as OCum-Tull-Liquid-Softbody-Patch
  v1.0). It adds GT Softbody's two OCum fixes and Tull Animated Creampie /
  Liquid Pack v2 support with the Scene Change Fix. Without Tull or Liquid
  Pack it falls back to OCum's own creampie meshes.
- Tull / Liquid Pack, no GT Softbody: the same script, but OCum's own
  urethra (cum origin) adjustment is kept, because that's only removed for
  GT Softbody's collision.
- Neither: nothing to install; you don't need this download.

Load order (MO2 left pane): put this mod BELOW GT - Softbody, the OCum
Tull/Liquid add-on and its Scene Change Fix, and OCum Ascended, so this
script wins. If you already use the separate OCum-Tull-Liquid-Softbody
patch, disable it (same script).

Links:
GT - Softbody: https://www.nexusmods.com/skyrimspecialedition/mods/152103
OCum Ascended - Tull and Liquid Pack Meshes: https://dwemermods.com/mods/5304
""")
cp(f"{S}/30 Softbody/Scripts/OCumMaleScript.pex", f"{P}/20 Script GT Softbody/Scripts/OCumMaleScript.pex")
cp(f"{R}/src/ocum_gt/OCumMaleScript.psc", f"{P}/20 Script GT Softbody/Scripts/Source/OCumMaleScript.psc")
cp(f"{R}/build/ocum_tull/OCumMaleScript.pex", f"{P}/21 Script Tullius no Softbody/Scripts/OCumMaleScript.pex")
cp(f"{R}/src/ocum_tull/OCumMaleScript.psc", f"{P}/21 Script Tullius no Softbody/Scripts/Source/OCumMaleScript.psc")
steps = [
  step("Tullius / Liquid Pack", "Do you use Tull Animated Creampie and/or Liquid Pack v2 with OCum (dwemermods 5304)?", "SelectExactlyOne", [
    plugin("Yes", "You use the OCum Tull/Liquid add-on (https://dwemermods.com/mods/5304) with Tull Animated Creampie and/or [Predator] Liquid Pack v2.", [("tull", "yes")], dep=("Or", ["TullAnimatedCreampie.esp", "[Predator] Liquid Pack v2.esp"])),
    plugin("No", "You don't use Tull Animated Creampie or Liquid Pack v2.", [("tull", "no")])]),
  step("GT Softbody", "Do you use GT - Softbody (Nexus 152103)?", "SelectExactlyOne", [
    plugin("Yes", "GT - Softbody by Goutou is installed and working (https://www.nexusmods.com/skyrimspecialedition/mods/152103). Installs the merged OCum + Tull/Liquid + GT Softbody script.", [("gt", "yes")]),
    plugin("No", "You don't use GT - Softbody.", [("gt", "no")])]),
]
write_cfg(P, "Beast Form Softbody / Tullius Patches 1.0", steps,
          [([("gt", "yes")], ["20 Script GT Softbody"]), ([("gt", "no"), ("tull", "yes")], ["21 Script Tullius no Softbody"])], required="00 Docs")
info(P, "Beast Form Softbody / Tullius Patches", "Optional OCum script for OStim Beast Form 1.0: GT Softbody and/or Tull Animated Creampie + Liquid Pack users. Credit: That Guy (Coronerra).")

# ---------------- Download 3 ----------------
H = f"{R}/pkg_herm"; shutil.rmtree(H, ignore_errors=True)
h = f"{H}/10 Herm"
for rel in ("OStim_Beast_Form_TWO_Herm_Patch.esp", "SKSE/Plugins/OStim/actor properties/OBLWerewolfHerm.json", "Scripts/OBFHerm_Main.pex", "Scripts/OBFHerm_PlayerAlias.pex", "Scripts/Source/OBFHerm_Main.psc", "Scripts/Source/OBFHerm_PlayerAlias.psc"):
    cp(f"{S}/40 Herm/{rel}", f"{h}/{rel}")
put(f"{h}/Docs/OStim Beast Form/README_Herm_Patch.txt", """
Beast Form Herm Patch 1.0 (optional, for OStim Beast Form 1.0) - A.K.A. Fruta
by That Guy (Coronerra)

Only for TWO Extras' herm / urta PLAYER werewolf (TWO Extras' "Toggle Herm
Werewolf" spell). OStim then treats your herm or urta werewolf as having a
penis as well as a vagina and breasts, and it gets the aroused cock and the
Beast Load climax.

Works with: the main file's TWO core (B), or the Growl core with
"Growl + TWO 4.1" picked. It does NOT work with the vanilla core (A),
because TWO Extras needs TWO's plugin.
Needs: TWO Extras (WerewolvesExtras.esp), plus TWO's
WerewolvesExtrasGrowl.esp if you use Growl. Leave OStim's "Futas use male
role" on.

Same plugin and scripts as the 0.8.1 Hermaphrodite option, so saves keep
working.

I am not going to test this myself. If you use TWO's herm or urta werewolf,
please test it and report any problems in the support section of the OStim
Beast Form page.
""")
steps = [step("Herm patch", "Read before installing", "SelectAll", [
    plugin("I use TWO Extras' herm / urta werewolf", "Needs TWO Extras (WerewolvesExtras.esp), and WerewolvesExtrasGrowl.esp if you use Growl. Works with the main file's TWO core, or the Growl core with \"Growl + TWO 4.1\". Not with the vanilla core.\nI am not going to test this myself. If you use TWO's herm or urta werewolf, please test it and report any problems in the support section of the OStim Beast Form page.", [("herm", "on")], typ="Required")])]
write_cfg(H, "Beast Form Herm Patch 1.0", steps, [([("herm", "on")], ["10 Herm"])])
info(H, "Beast Form Herm Patch", "Optional herm / urta (Fruta) patch for OStim Beast Form 1.0, for TWO Extras users. Credit: That Guy (Coronerra).")
print("ok")
