# Writes fomod/ModuleConfig.xml + info.xml for OStim Beast Form 1.0.2. That Guy (Coronerra).
import os
from xml.sax.saxutils import escape as e
import sys
P = sys.argv[1] if len(sys.argv) > 1 else "/workspace/skyrim/bf102/pkg_main"
ACK = """I have read every option in this installer and didn't just click through. If I picked the wrong options, the mod won't work.

This mod uses the TWO body made by Frosferes, at the LoversLab community's request. Frosferes is okay with patches but I will not repackage any files he made that I did not have to patch. So non-softbody female bodies and all Male bodies are still dependant on his TWO bodies. Anyone is free to make their own patches, hubs and mods based on this one.

Not included, and why: this mod only ships files I changed (the converted female werewolf body and cock, their SMP files, head expression files, plugins, scripts, scene files). Untouched TWO, Vampire Lord (Monster Facial Animation) and werebear files are not shipped. Folders where they go have a PUT_..._FILES_HERE.txt note that says what goes there and where to get it.

This mod doesn't change any animation pack (OCreatures Reforged, Lirael's Werewolf and Vampire Lord OStim, Billyy, Baka, FunnyBiz, FlufyFox). Their scenes show up through OStim's normal werewolf / vampire lord types.

After installing: run Pandora (or your behavior engine) again.

Known incompatibilities (as of this release):
- Diverse Werewolves Collection SE by opusGlass: the camera locks to the sides. Leave it off with this mod.
- HDT Werewolves: keep it off (its plugin is also called Werewolves.esp).

Credit: That Guy (Coronerra). Source code: https://github.com/Coronerra/OStim-Beast-Form"""

def plugin(name, desc, flags, typ="Optional", dep=None):
    fl = "".join(f'<flag name="{k}">{v}</flag>' for k, v in flags)
    if dep:
        f, state, t2 = dep
        td = f'<typeDescriptor><dependencyType><defaultType name="{typ}" /><patterns><pattern><dependencies operator="And"><fileDependency file="{f}" state="{state}" /></dependencies><type name="{t2}" /></pattern></patterns></dependencyType></typeDescriptor>'
    else:
        td = f'<typeDescriptor><type name="{typ}" /></typeDescriptor>'
    return f'<plugin name="{e(name)}"><description>{e(desc)}</description><conditionFlags>{fl}</conditionFlags>{td}</plugin>'

def step(name, group, gtype, plugins, visible=None):
    vis = f'<visible><dependencies operator="And">{visible}</dependencies></visible>' if visible else ''
    return f'<installStep name="{e(name)}">{vis}<optionalFileGroups order="Explicit"><group name="{e(group)}" type="{gtype}"><plugins order="Explicit">{"".join(plugins)}</plugins></group></optionalFileGroups></installStep>'

steps = []
steps.append(step("Which werewolf setup do you use?", "Pick the ONE setup you use", "SelectExactlyOne", [
    plugin("A. Vanilla / FSMP (no TWO, no Growl)",
           "Pick this if you use neither TWO nor Growl.\n\nInstalls OStim_Beast_Form_TWO.esp built WITHOUT TWO's plugin: no Werewolves.esp or MonsterLipSync1.esp needed. It brings its own head-part records and werewolf race head list.\n\nYou still need TWO 4.1's files (not its plugin): the male body, skeleton, head parts and textures. Copy them where the PUT_TWO_FILES_HERE.txt notes say. Vampire Lords need Monster Facial Animation's meshes (PUT_VAMPIRE_LORD_FILES_HERE.txt).\n\nTWO - Total Werewolf Overhaul: https://www.loverslab.com/topic/159911-two-total-werewolf-overhaul/",
           [("core", "a")]),
    plugin("B. TWO 4.1 user (no Growl)",
           "Pick this if you use TWO - Total Werewolf Overhaul 4.1 and do NOT use Growl.\n\nInstalls OStim_Beast_Form_TWO.esp (same plugin name and FormIDs as the TWO edition and 0.8.x, so saves keep working) and OStim_Beast_Form_TWO - BFA Heads.esp. The next page asks which female werewolf body you want (TWO's own body, so your BodySlide builds apply, or this mod's converted softbody body).\n\nNeeds: TWO 4.1 (Core), Monster Facial Animation (MonsterLipSync1.esp).\nTWO: https://www.loverslab.com/topic/159911-two-total-werewolf-overhaul/",
           [("core", "b")]),
    plugin("C. Growl user (recommended for Nolvus)",
           "Pick this if you use Growl - Werebeasts of Skyrim (Nolvus default).\n\nInstalls OStim_Beast_Form_Merged.esp (same plugin name and FormIDs as 0.8.x). Adds Growl werebears: MCM option \"Werebears use werewolf scenes\" (on by default).\n\nNeeds: Growl, JS Emissive Eyes SE, Monster Facial Animation (its head meshes). If you also use TWO 4.1, say so on the next page.\nGrowl: https://www.nexusmods.com/skyrimspecialedition/mods/31245",
           [("core", "c")], typ="Recommended"),
]))
steps.append(step("Growl + TWO?", "Do you also use TWO 4.1 together with Growl?", "SelectExactlyOne", [
    plugin("Growl only", "No TWO. Werewolves use Monster Facial Animation heads and this mod's converted female body. Copy TWO's male body and textures where the PUT_TWO_FILES_HERE.txt notes say, or keep the male body you already have.", [("ctwo", "off")]),
    plugin("Growl + TWO 4.1", "Also installs OStim_Beast_Form_Merged_TWO_Patch.esp and OStim_Beast_Form_Merged_TWO_Patch - BFA Heads.esp (same as 0.8.x): TWO's body and heads on Growl werewolves. The next page asks which female werewolf body you want.\nNeeds TWO 4.1 (Core) with its Growl patch, and Monster Facial Animation (MonsterLipSync1.esp).", [("ctwo", "on")], dep=("Werewolves.esp", "Active", "Recommended")),
], visible='<flagDependency flag="core" value="c" />'))
FB_VIS = '<flagDependency flag="core" value="b" />'
FB_VIS_C = '<flagDependency flag="core" value="c" /><flagDependency flag="ctwo" value="on" />'
steps.append(step("Female werewolf body", "Which female werewolf body do you want?", "SelectExactlyOne", [
    plugin("TWO's own female body (BodySlide works)",
           "Female werewolves use TWO 4.1's own female body and TWO's own aroused cock (CreatureFramework\\CanineRedHard.nif), the same as \"No softbody\" in 0.8.x.\n\nYour BodySlide builds of TWO's \"TWO Female Body\" project (and OBody presets for it) apply in game. Pick this if you don't use GT Softbody, or if you want your own BodySlide shape.",
           [("fbody", "two")], typ="Recommended"),
    plugin("Converted softbody female body (this mod's)",
           "Female werewolves use this mod's converted female body (SMP opening that reacts to TNG and SOS) and converted cock (SMP collision), the same as \"Yes, softbody\" in 0.8.x. Needs FSMP; made for GT Softbody setups.\n\nThis body is NOT part of TWO's BodySlide project, so BodySlide builds and TWO body presets do NOT change it (in-game morphs still work). Male werewolves always use TWO's own body.",
           [("fbody", "soft")]),
], visible=None))
steps[-1] = steps[-1].replace('<installStep name="Female werewolf body">', '<installStep name="Female werewolf body"><visible><dependencies operator="Or">' + FB_VIS + '<dependencies operator="And">' + FB_VIS_C + '</dependencies></dependencies></visible>', 1)
steps.append(step("OCreatures Reforged", "Do you use OCreatures Reforged (OCreatures.esp)?", "SelectExactlyOne", [
    plugin("Yes, I use OCreatures Reforged", "Nothing extra is installed. This mod's start poses lead to OCreatures Reforged's own werewolf and vampire lord menus, and OCR's files are never replaced.", [("ocr", "yes")], dep=("OCreatures.esp", "Active", "Recommended")),
    plugin("No", "Installs this mod's own werewolf and vampire lord start poses under the menu names other packs look for (OCrWerewolfIdle..., OCrVampireLordIdleFM), so packs that hang their buttons there (Billyy, Baka, FunnyBiz, FlufyFox, Lirael) still show up. Don't pick this if OCreatures Reforged is installed: these files would replace OCR's.", [("ocr", "no")], dep=("OCreatures.esp", "Missing", "Recommended")),
]))
steps.append(step("Beast couples (optional)", "Optional extras (tick or leave empty)", "SelectAny", [
    plugin("Beast couples (needs Lirael's Werewolf and Vampire Lord OStim)",
           "Start poses for two werewolves (male + female, female + male, two males) and two vampire lords (male + female, female + male), leading to Lirael's own couple menus, plus male-first copies of her male + female couple scenes so they also start from the male side.\n\nThese are this mod's own scene files that play HER animations. Nothing from her pack is copied or changed. Without her pack, the buttons don't animate.\nLirael's pack: https://www.patreon.com/LiraelAtelier/posts/werewolf-and-for-175434973",
           [("couples", "on")], dep=("WVLAnimObj.esp", "Active", "Recommended")),
]))
steps.append(step("Read and acknowledge", "Acknowledgement (required)", "SelectAll", [
    plugin("I have read and understand", ACK, [("ack", "on")], typ="Required")]))

def pat(deps, folders):
    d = "".join(f'<flagDependency flag="{k}" value="{v}" />' for k, v in deps)
    f = "".join(f'<folder source="{x}" destination="" priority="0" />' for x in folders)
    return f'<pattern><dependencies operator="And">{d}</dependencies><files>{f}</files></pattern>'
pats = [pat([("core", "a")], ["10 Core A Vanilla"]), pat([("core", "b")], ["20 Core B TWO"]), pat([("core", "c")], ["30 Core C Growl"]),
        pat([("core", "c"), ("ctwo", "on")], ["31 Core C TWO addon"]),
        pat([("core", "b"), ("fbody", "two")], ["22 Core B TWO body"]), pat([("core", "b"), ("fbody", "soft")], ["21 Core B Softbody body"]),
        pat([("core", "c"), ("ctwo", "on"), ("fbody", "two")], ["33 Core C TWO addon TWO body"]), pat([("core", "c"), ("ctwo", "on"), ("fbody", "soft")], ["32 Core C TWO addon Softbody body"]), pat([("ocr", "no")], ["40 OCR standins"]), pat([("couples", "on")], ["50 Beast couples"])]
xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://qconsulting.ca/fo3/ModConfig5.0.xsd">
<moduleName>OStim Beast Form 1.0.2</moduleName>
<requiredInstallFiles><folder source="00 Common" destination="" priority="0" /></requiredInstallFiles>
<installSteps order="Explicit">{"".join(steps)}</installSteps>
<conditionalFileInstalls><patterns>{"".join(pats)}</patterns></conditionalFileInstalls>
</config>'''
os.makedirs(f"{P}/fomod", exist_ok=True)
from lxml import etree
root = etree.fromstring(xml.encode())
open(f"{P}/fomod/ModuleConfig.xml", "wb").write(etree.tostring(root, xml_declaration=True, encoding="UTF-8", pretty_print=True))
open(f"{P}/fomod/info.xml", "w", encoding="utf-8").write('''<?xml version="1.0" encoding="UTF-8"?>
<fomod>
	<Name>OStim Beast Form</Name>
	<Author>That Guy (Coronerra)</Author>
	<Version>1.0.2</Version>
	<Description>Play as a werewolf, werebear or Vampire Lord in OStim with your mind intact. One installer, three setups: vanilla, TWO 4.1 or Growl. Credit: That Guy (Coronerra). Source: https://github.com/Coronerra/OStim-Beast-Form</Description>
	<Website>https://github.com/Coronerra/OStim-Beast-Form</Website>
	<Groups><element>Creatures</element></Groups>
</fomod>
''')
print("written")
