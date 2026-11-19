#!/usr/bin/env python3
"""Build WVL_0.3.1_Patch_0.2.zip

Combines:
  (a) Icon Patch 0.1 icon work (WVLIcons + icon-only scene JSON edits)
  (b) Human-first (male human, female werewolf) copies of every 0.3.1
      Female Werewolf scene, using OStim animationIndex to keep the
      original animation events (name_0 / name_1).

Ships a FOMOD that mirrors 0.3.1's module / animator / male-partner
choices so a patched scene is only installed when that 0.3.1 module is
selected. Human-first copies live in the Female Werewolf MNC / HCOS
modules their animations come from.

Contains no animation files, plugins, or behavior graphs.
"""
from __future__ import annotations

import copy
import glob
import hashlib
import json
import os
import shutil
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
WVL_ROOT = '/workspace/skyrim/wvl031/x'
ICON_PATCH = '/workspace/skyrim/wvl_icon_patch'
ICON_DDS = os.path.join(ICON_PATCH, 'stage', 'interface')
STAGE = os.path.join(HERE, 'stage')
ZIP_PATH = os.path.join(HERE, 'WVL_0.3.1_Patch_0.2.zip')
REPORT = os.path.join(HERE, 'build_report.txt')

sys.path.insert(0, ICON_PATCH)
from build_patch import (  # noqa: E402
    FOMOD_PACK_ORDER,
    map_icon,
    is_hub_entry,
    actor_counts,
)

COMMON = '00 Common'

# Pack name -> (module flag, source flag, male_partner)
def pack_flags(pack: str):
    name = pack.replace('Werewolf and Vampire Lord - ', '')
    male = '(male partner)' in name
    if name.startswith('Female Werewolf'):
        module = 'Module_FemaleWerewolf'
    elif name.startswith('Beast Couples'):
        module = 'Module_BeastCouples'
    elif name.startswith('Vampire Lord'):
        module = 'Module_VampireLord'
    elif name.startswith('Werewolf'):
        module = 'Module_Werewolf'
    elif name.startswith('Anim Objects'):
        return None
    else:
        return None
    animator = name.split(' - ')[-1]
    src = {
        'Billyy': 'Source_BILLYY',
        'Anub': 'Source_ANUB',
        'FlufyFox': 'Source_FLUFY',
        'Baka': 'Source_BAKA',
        'MNC': 'Source_MNC',
        'HCOS': 'Source_HCOS',
        'FunnyBiz': 'Source_FUNNYBIZ',
    }.get(animator)
    if not src:
        return None
    return module, src, male


FEMALE_WW_PACKS = {
    'Werewolf and Vampire Lord - Female Werewolf - MNC': 'WVL_MNCWerewolfMissionaryTest_S1',
    'Werewolf and Vampire Lord - Female Werewolf - HCOS': 'WVL_mmgfemwerenpcstand_S1',
}

HUB_OLD = 'WVLFWWWerewolfHubFMC1'
HUB_NEW = 'WVLP_FWWWerewolfHubMH'
IDLE_NEW = 'WVLP_WerewolfIdleMH'

ACTION_IDX_KEYS = ('actor', 'target', 'performer')


def rel_under(path: str, root: str) -> str:
    return os.path.relpath(path, root).replace('\\', '/')


def make_mh_id(old: str) -> str:
    if old == HUB_OLD:
        return HUB_NEW
    if not old.startswith('WVL'):
        raise ValueError(f'unexpected scene id: {old}')
    rest = old[3:]
    if '-' in rest:
        base, stage = rest.rsplit('-', 1)
        if stage.isdigit():
            return f'WVLP_{base}MH-{stage}'
    return f'WVLP_{rest}MH'


def apply_icons(data: dict, is_hub_scene: bool) -> int:
    """Apply Icon Patch 0.1 mapping in place. Returns number of navs changed."""
    changed = 0
    scene_id_guess = ''
    actors = data.get('actors')
    tags = data.get('tags')
    actions = data.get('actions')
    navs = data.get('navigations') or []
    # series name: first origin-bearing nav dest/self; map_icon only uses it for reports
    series = ''
    for nav in navs:
        origin = nav.get('origin') or ''
        desc = nav.get('description') or ''
        icon = nav.get('icon') or ''
        new = map_icon(origin, desc, icon, actors, tags, actions, series, is_hub_scene)
        if new and new != icon:
            nav['icon'] = new
            changed += 1
    return changed


def swap_to_mh(data: dict, id_map: dict) -> dict:
    d = copy.deepcopy(data)
    actors = d.get('actors') or []
    if len(actors) != 2:
        raise ValueError(f'expected 2 actors, got {len(actors)} in {d.get("name")}')
    new_actors = []
    for orig_i, a in enumerate(actors):
        a = copy.deepcopy(a)
        if 'animationIndex' not in a:
            a['animationIndex'] = orig_i
        new_actors.append(a)
    d['actors'] = list(reversed(new_actors))
    for ac in d.get('actions') or []:
        for k in ACTION_IDX_KEYS:
            if k in ac and isinstance(ac[k], int):
                ac[k] = 1 - ac[k] if ac[k] in (0, 1) else ac[k]
    for nav in d.get('navigations') or []:
        for k in ('origin', 'destination'):
            if k in nav and nav[k] in id_map:
                nav[k] = id_map[nav[k]]
    name = d.get('name') or ''
    if '[male-first order]' not in name.lower():
        d['name'] = (name + ' [male-first order]').strip()
    tags = list(d.get('tags') or [])
    if not any(t.lower() == 'malefirst' for t in tags):
        tags.append('malefirst')
    d['tags'] = tags
    return d


def write_json(path: str, data: dict) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
        f.write('\n')


def collect_fnis_events():
    events = set()
    for p in glob.glob(WVL_ROOT + '/**/FNIS_*.txt', recursive=True):
        for line in open(p, encoding='utf-8', errors='replace'):
            parts = line.split()
            # FNIS: b -Tn[,flags] EventName file.hkx
            if len(parts) >= 3 and parts[0] in ('b', 'o', 's', 't+'):
                # event is the first token that is not a flag starting with - or AV
                for tok in parts[1:]:
                    if tok.startswith('-') or tok.startswith('AV'):
                        continue
                    events.add(tok)
                    break
    return events


def pick_unique_detect_file(pack: str, files: list[str]) -> str | None:
    """Return a Data-relative path unique to this pack, for FOMOD fileDependency."""
    # Prefer a unique OStim scene JSON (not a shared hub).
    preferred = []
    hubs = []
    for rel in files:
        if not rel.startswith('SKSE/'):
            continue
        base = os.path.basename(rel).lower()
        if 'hub' in base or 'idle' in base:
            hubs.append(rel)
        else:
            preferred.append(rel)
    return (preferred or hubs or [None])[0]


def xml_escape(s: str) -> str:
    return (s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
             .replace('"', '&quot;'))


def build_fomod(detect: dict, packs_with_files: set[str]) -> tuple[str, str]:
    """detect: pack -> data-relative file path (forward slashes)."""
    info = '''<?xml version="1.0" encoding="UTF-8"?>
<fomod>
    <Name>Werewolf and Vampire Lord OStim 0.3.1 Patch</Name>
    <Author>That Guy (Coronerra)</Author>
    <Description>Icon and male-first scene patch for Werewolf and Vampire Lord OStim 0.3.1 by Lirael. Contains no animations. Install 0.3.1 first, then this, and choose the same packs and animators.</Description>
    <Version>0.2</Version>
    <Website></Website>
</fomod>
'''

    def dep_file(rel: str) -> str:
        return xml_escape(rel.replace('/', '\\'))

    def recommend_if(file_rel: str, default='Optional', if_present='Recommended') -> str:
        if not file_rel:
            return f'                            <typeDescriptor>\n                                <type name="{default}" />\n                            </typeDescriptor>'
        return f'''                            <typeDescriptor>
                                <dependencyType>
                                    <defaultType name="{default}" />
                                    <patterns>
                                        <pattern>
                                            <dependencies operator="And">
                                                <fileDependency file="{dep_file(file_rel)}" state="Active" />
                                            </dependencies>
                                            <type name="{if_present}" />
                                        </pattern>
                                    </patterns>
                                </dependencyType>
                            </typeDescriptor>'''

    # Module detection: any file from any pack in that module
    module_detect = {}
    source_detect = {}  # may be multiple; we'll Or them
    source_detect_files = {k: [] for k in (
        'Source_BILLYY', 'Source_ANUB', 'Source_FLUFY', 'Source_BAKA',
        'Source_MNC', 'Source_HCOS', 'Source_FUNNYBIZ')}
    male_detect = []
    for pack, rel in detect.items():
        flags = pack_flags(pack)
        if not flags or not rel:
            continue
        module, src, male = flags
        module_detect.setdefault(module, []).append(rel)
        source_detect_files[src].append(rel)
        if male:
            male_detect.append(rel)

    def recommend_if_any(files: list[str], default='Optional', if_present='Recommended') -> str:
        files = [f for f in files if f]
        if not files:
            return f'                            <typeDescriptor>\n                                <type name="{default}" />\n                            </typeDescriptor>'
        deps = '\n'.join(
            f'                                                <fileDependency file="{dep_file(f)}" state="Active" />'
            for f in files)
        op = 'Or' if len(files) > 1 else 'And'
        return f'''                            <typeDescriptor>
                                <dependencyType>
                                    <defaultType name="{default}" />
                                    <patterns>
                                        <pattern>
                                            <dependencies operator="{op}">
{deps}
                                            </dependencies>
                                            <type name="{if_present}" />
                                        </pattern>
                                    </patterns>
                                </dependencyType>
                            </typeDescriptor>'''

    # Male partner Yes/No: if any male-partner file present, recommend Yes
    no_male_td = recommend_if_any(male_detect, default='Recommended', if_present='Optional')
    yes_male_td = recommend_if_any(male_detect, default='Optional', if_present='Recommended')

    cfg = f'''<?xml version="1.0" encoding="UTF-8"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://qconsulting.ca/fo3/ModConfig5.0.xsd">
    <moduleName>Werewolf and Vampire Lord OStim 0.3.1 Patch</moduleName>
    <requiredInstallFiles>
        <folder source="{COMMON}\\interface" destination="interface" priority="0" />
        <file source="README.txt" destination="README.txt" priority="0" />
    </requiredInstallFiles>
    <installSteps order="Explicit">
        <installStep name="Animation packs">
            <optionalFileGroups order="Explicit">
                <group name="Animation packs (tick the same ones you chose in 0.3.1)" type="SelectAny">
                    <plugins order="Explicit">
                        <plugin name="Werewolf">
                            <description>Icon edits for the male werewolf packs you installed from 0.3.1. If 0.3.1 is already installed, this should pre-tick when those files are found. Tick it only if you installed the Werewolf pack.</description>
                            <conditionFlags>
                                <flag name="Module_Werewolf">On</flag>
                            </conditionFlags>
{recommend_if_any(module_detect.get('Module_Werewolf') or [])}
                        </plugin>
                        <plugin name="Female Werewolf">
                            <description>Icon edits plus human-first (male human, female werewolf) scene copies for the Female Werewolf pack. Tick this if you installed Female Werewolf in 0.3.1. This is the fix for "no valid animations" when a man starts a scene with a female werewolf.</description>
                            <conditionFlags>
                                <flag name="Module_FemaleWerewolf">On</flag>
                            </conditionFlags>
{recommend_if_any(module_detect.get('Module_FemaleWerewolf') or [])}
                        </plugin>
                        <plugin name="Vampire Lord">
                            <description>Icon edits for the Vampire Lord packs you installed from 0.3.1. Tick this only if you installed the Vampire Lord pack.</description>
                            <conditionFlags>
                                <flag name="Module_VampireLord">On</flag>
                            </conditionFlags>
{recommend_if_any(module_detect.get('Module_VampireLord') or [])}
                        </plugin>
                        <plugin name="Beast Couples">
                            <description>Icon edits for the Beast Couples pack from 0.3.1. Tick this only if you installed Beast Couples.</description>
                            <conditionFlags>
                                <flag name="Module_BeastCouples">On</flag>
                            </conditionFlags>
{recommend_if_any(module_detect.get('Module_BeastCouples') or [])}
                        </plugin>
                    </plugins>
                </group>
            </optionalFileGroups>
        </installStep>
        <installStep name="Animators">
            <optionalFileGroups order="Explicit">
                <group name="Animators (tick the same ones you chose in 0.3.1)" type="SelectAny">
                    <plugins order="Explicit">
                        <plugin name="Billyy">
                            <description>Patch files for Billyy's 0.3.1 scenes only. Tick this only if you installed Billyy in 0.3.1. The installer pre-ticks it when those files are already in your game.</description>
                            <conditionFlags>
                                <flag name="Source_BILLYY">On</flag>
                            </conditionFlags>
{recommend_if_any(source_detect_files['Source_BILLYY'])}
                        </plugin>
                        <plugin name="Anub">
                            <description>Patch files for Anub's 0.3.1 scenes only. Tick this only if you installed Anub in 0.3.1.</description>
                            <conditionFlags>
                                <flag name="Source_ANUB">On</flag>
                            </conditionFlags>
{recommend_if_any(source_detect_files['Source_ANUB'])}
                        </plugin>
                        <plugin name="FlufyFox">
                            <description>Patch files for FlufyFox's 0.3.1 scenes only. Leave this unticked if you did not install FlufyFox in 0.3.1 — otherwise OStim will load orphan scenes that point at missing stages.</description>
                            <conditionFlags>
                                <flag name="Source_FLUFY">On</flag>
                            </conditionFlags>
{recommend_if_any(source_detect_files['Source_FLUFY'])}
                        </plugin>
                        <plugin name="Baka">
                            <description>Patch files for Baka's 0.3.1 scenes only. Tick this only if you installed Baka in 0.3.1.</description>
                            <conditionFlags>
                                <flag name="Source_BAKA">On</flag>
                            </conditionFlags>
{recommend_if_any(source_detect_files['Source_BAKA'])}
                        </plugin>
                        <plugin name="MNC">
                            <description>Patch files for MNC's 0.3.1 scenes only, including human-first Female Werewolf copies when that pack is ticked. Tick this only if you installed MNC in 0.3.1.</description>
                            <conditionFlags>
                                <flag name="Source_MNC">On</flag>
                            </conditionFlags>
{recommend_if_any(source_detect_files['Source_MNC'])}
                        </plugin>
                        <plugin name="HCOS">
                            <description>Patch files for HCOS's 0.3.1 scenes only, including human-first Female Werewolf copies when that pack is ticked. Tick this only if you installed HCOS in 0.3.1.</description>
                            <conditionFlags>
                                <flag name="Source_HCOS">On</flag>
                            </conditionFlags>
{recommend_if_any(source_detect_files['Source_HCOS'])}
                        </plugin>
                        <plugin name="FunnyBiz">
                            <description>Patch files for FunnyBiz's 0.3.1 scenes only. Tick this only if you installed FunnyBiz in 0.3.1.</description>
                            <conditionFlags>
                                <flag name="Source_FUNNYBIZ">On</flag>
                            </conditionFlags>
{recommend_if_any(source_detect_files['Source_FUNNYBIZ'])}
                        </plugin>
                    </plugins>
                </group>
            </optionalFileGroups>
        </installStep>
        <installStep name="Male partner">
            <optionalFileGroups order="Explicit">
                <group name="Scenes with a male partner" type="SelectExactlyOne">
                    <plugins order="Explicit">
                        <plugin name="No">
                            <description>Do not install male-partner icon edits. Choose this if you did not add male partner scenes in 0.3.1.</description>
                            <conditionFlags>
                                <flag name="MalePartner">Off</flag>
                            </conditionFlags>
{no_male_td}
                        </plugin>
                        <plugin name="Yes, add male partner scenes">
                            <description>Install icon edits for the 0.3.1 male-partner scenes. Choose this only if you added male partner scenes in 0.3.1, and only for the packs and animators you ticked above.</description>
                            <conditionFlags>
                                <flag name="MalePartner">On</flag>
                            </conditionFlags>
{yes_male_td}
                        </plugin>
                    </plugins>
                </group>
            </optionalFileGroups>
        </installStep>
    </installSteps>
    <conditionalFileInstalls>
        <patterns>
'''

    # One pattern per pack that actually has patch files, same flag combos as 0.3.1
    patterns = []
    for pack in FOMOD_PACK_ORDER:
        if pack not in packs_with_files:
            continue
        flags = pack_flags(pack)
        if not flags:
            continue
        module, src, male = flags
        deps = [
            f'                    <flagDependency flag="{module}" value="On" />',
            f'                    <flagDependency flag="{src}" value="On" />',
        ]
        if male:
            deps.append('                    <flagDependency flag="MalePartner" value="On" />')
        patterns.append(f'''            <pattern>
                <dependencies operator="And">
{chr(10).join(deps)}
                </dependencies>
                <files>
                    <folder source="{xml_escape(pack)}\\SKSE" destination="SKSE" priority="0" />
                </files>
            </pattern>
''')
    cfg += ''.join(patterns)
    cfg += '''        </patterns>
    </conditionalFileInstalls>
</config>
'''
    return info, cfg


README = r'''Werewolf and Vampire Lord OStim 0.3.1 Patch 0.2
Author: That Guy (Coronerra)

A FOMOD patch for Werewolf and Vampire Lord OStim v0.3.1 by Lirael
(Lirael Atelier). This patch contains no animations, no plugins, and no
behavior files. It does not change or redistribute any animation from the
0.3.1 pack.

Animations in 0.3.1 are by Billyy, Anub, FlufyFox, Baka (BakaFactory),
FunnyBizness, the More Nasty Critters team (Dayelyte, Panicforever) and
MadMansGun (Horny Creatures of Skyrim). All animation work is theirs.

Requires Werewolf and Vampire Lord OStim v0.3.1 exactly. Install 0.3.1
first, run its installer, then install this patch after (below) it in Mod
Organizer 2. In this patch's FOMOD, tick the same animation packs, animators
and male-partner option you chose for 0.3.1. If 0.3.1 is already installed
and enabled, the installer tries to pre-tick what it finds; check those ticks
before you continue. Restart the game after installing. You do not need to
run Pandora or Nemesis.

This supersedes WVL 0.3.1 Icon Patch 0.1. If you have 0.1 installed, remove
it and use this instead. 0.1 was a flat set of scene files and could add
scenes for 0.3.1 modules you never installed (for example FlufyFox), which
led to OStim warnings about missing navigation targets. 0.2 ships a FOMOD
that matches 0.3.1's modules, so a patched scene is only installed when that
module is selected.

What it does
------------
1. Icons. 0.3.1 ships no icons of its own and reuses shared OCreatures and
   OStim icons. This patch adds icons under:

     interface/OStim/icons/WVLIcons/

   and, for the modules you tick, copies of those 0.3.1 scene files with
   only the navigation icon fields pointed at the new paths. Shared
   OCreatures and OStim icon files are not overwritten. OStim's return,
   next and climax icons are left untouched.

2. Human-first Female Werewolf scenes. OStim (and OStimNet) put the male
   partner first when it builds a cast, but 0.3.1's Female Werewolf sex
   scenes are all [female werewolf, human male]. Starting a scene as a man
   with a female werewolf then fails with "no valid animations" / "no
   starting animation found".

   For each Female Werewolf module you tick, this patch adds a second copy
   of that module's scenes with new ids (WVLP_...MH), the two actors swapped
   ([human male, female werewolf]), and OStim's animationIndex set so each
   actor still plays the original animation event already registered by
   0.3.1 (the event name is the speed animation plus "_" plus that index:
   WVL_..._S1_0 on the werewolf, WVL_..._S1_1 on the human). Tags, actions
   (with actor, target and performer indices swapped), speeds and the same
   random-start eligibility as the originals are kept. Navigations stay
   inside the new copies.

   A human-first idle (WVLP_WerewolfIdleMH) and hub (WVLP_FWWWerewolfHubMH)
   are included in each Female Werewolf module you tick, so the menu works
   without depending on a particular OCreatures Reforged version or on any
   other animation pack. The idle uses a stage-1 animation from that
   module (HCOS: standing embrace; MNC: missionary) so the animation
   already exists if that module is installed. Tick both MNC and HCOS if
   you installed both; the hub then lists every series you have.

The original 0.3.1 scene files are not removed. Female-werewolf-first
scenes stay in place for casts that still use that order.
'''


def main():
    if os.path.exists(STAGE):
        shutil.rmtree(STAGE)
    os.makedirs(STAGE, exist_ok=True)

    # --- icons (always installed) ---
    dest_icons = os.path.join(STAGE, COMMON, 'interface')
    shutil.copytree(ICON_DDS, dest_icons)
    dds = list(glob.glob(dest_icons + '/**/*.dds', recursive=True))
    if len(dds) != 33:
        raise SystemExit(f'expected 33 dds icons, found {len(dds)}')

    # --- existing scene IDs for collision check ---
    existing_ids = set()
    for p in glob.glob('/workspace/skyrim/**/SKSE/Plugins/OStim/scenes/**/*.json', recursive=True):
        existing_ids.add(os.path.splitext(os.path.basename(p))[0])

    fnis_events = collect_fnis_events()

    packs_with_files = set()
    detect = {}
    icon_json_count = 0
    icon_nav_count = 0
    mh_scene_count = 0
    mh_ids = []
    auto_start_mh = 0
    per_pack = []
    issues = []
    used_anims = set()

    # unique-file search across packs
    all_pack_files = {}
    for pack in FOMOD_PACK_ORDER:
        proot = os.path.join(WVL_ROOT, pack)
        if not os.path.isdir(proot):
            continue
        rels = []
        for p in glob.glob(proot + '/**/*', recursive=True):
            if os.path.isfile(p):
                rels.append(rel_under(p, proot))
        all_pack_files[pack] = rels

    # files that appear in more than one pack (shared hubs etc.)
    rel_owners = {}
    for pack, rels in all_pack_files.items():
        for rel in rels:
            rel_owners.setdefault(rel, []).append(pack)

    for pack in FOMOD_PACK_ORDER:
        proot = os.path.join(WVL_ROOT, pack)
        if not os.path.isdir(proot):
            continue
        # unique detect file (scene json preferred)
        unique_scenes = [r for r in all_pack_files[pack]
                         if r.startswith('SKSE/Plugins/OStim/scenes/')
                         and r.endswith('.json')
                         and len(rel_owners.get(r, [])) == 1]
        unique_any = [r for r in all_pack_files[pack] if len(rel_owners.get(r, [])) == 1]
        detect_rel = (unique_scenes or unique_any or [None])[0]
        if detect_rel:
            detect[pack] = detect_rel

        scenes = sorted(glob.glob(proot + '/**/SKSE/Plugins/OStim/scenes/**/*.json', recursive=True))
        icon_changed_here = 0
        mh_here = 0

        # Icon-patch each scene from THIS pack's own source (keep pack-specific hubs)
        patched_by_id = {}
        for src in scenes:
            rel = rel_under(src, proot)
            with open(src, encoding='utf-8') as f:
                data = json.load(f)
            sid = os.path.splitext(os.path.basename(src))[0]
            is_hub = bool(data.get('noRandomSelection')) and not data.get('actions')
            # also treat files with Hub in the id or name as hubs for icon mapping
            if 'hub' in sid.lower() or 'hub' in (data.get('name') or '').lower():
                is_hub = True
            n = apply_icons(data, is_hub)
            patched_by_id[sid] = data
            if n:
                dest = os.path.join(STAGE, pack, rel)
                write_json(dest, data)
                icon_changed_here += 1
                icon_json_count += 1
                icon_nav_count += n
                packs_with_files.add(pack)

        # Human-first copies for Female Werewolf modules
        if pack in FEMALE_WW_PACKS:
            pack_ids = [os.path.splitext(os.path.basename(s))[0] for s in scenes]
            id_map = {i: make_mh_id(i) for i in pack_ids}
            # also map the shared hub id even if... it's in pack_ids
            id_map[HUB_OLD] = HUB_NEW
            # do not map OCr or anything else

            for sid, new in id_map.items():
                if new in existing_ids:
                    issues.append(f'ID collision with existing scene: {new} (from {sid})')
                if new in mh_ids:
                    # hub id is shared across MNC and HCOS — allowed if identical purpose
                    if new not in (HUB_NEW, IDLE_NEW):
                        issues.append(f'duplicate new id {new}')

            for src in scenes:
                rel = rel_under(src, proot)
                sid = os.path.splitext(os.path.basename(src))[0]
                if sid == HUB_OLD:
                    continue  # replaced by new hub+idle
                data = patched_by_id[sid]
                mh = swap_to_mh(data, id_map)
                new_id = id_map[sid]
                # place under werewolf/mf-c1/<series>/<id>.json
                series = new_id.rsplit('-', 1)[0] if '-' in new_id and new_id.rsplit('-', 1)[-1].isdigit() else new_id
                dest_rel = f'SKSE/Plugins/OStim/scenes/WerewolfVampireLordOStim/werewolf/mf-c1/{series}/{new_id}.json'
                write_json(os.path.join(STAGE, pack, dest_rel), mh)
                mh_ids.append(new_id)
                mh_here += 1
                mh_scene_count += 1
                if mh.get('actions') and not mh.get('noRandomSelection'):
                    auto_start_mh += 1
                for sp in mh.get('speeds') or []:
                    anim = sp.get('animation')
                    if anim:
                        used_anims.add(anim)
                        for idx in (0, 1):
                            ev = f'{anim}_{idx}'
                            if ev not in fnis_events:
                                issues.append(f'missing FNIS event {ev} (pack {pack}, scene {new_id})')

            # idle + hub, pack-specific animation
            idle_anim = FEMALE_WW_PACKS[pack]
            used_anims.add(idle_anim)
            for idx in (0, 1):
                ev = f'{idle_anim}_{idx}'
                if ev not in fnis_events:
                    issues.append(f'missing FNIS event {ev} for idle/hub in {pack}')

            actors_mh = [
                {'intendedSex': 'male', 'tags': ['standing'], 'animationIndex': 1},
                {'type': 'Werewolf', 'intendedSex': 'female', 'tags': ['standing'], 'animationIndex': 0},
            ]
            idle = {
                'name': 'Female Werewolf Idle [male-first order]',
                'modpack': 'WerewolfVampireLordOStim',
                'length': 2,
                'navigations': [],
                'speeds': [{'animation': idle_anim}],
                'actors': actors_mh,
                'tags': [
                    'idle', 'intro', 'creature', 'werewolf',
                    'packfemalewerewolf', 'malefirst',
                ],
            }
            hub = {
                'name': 'Female Werewolf Pack [male-first order]',
                'modpack': 'WerewolfVampireLordOStim',
                'length': 2,
                'navigations': [
                    {
                        'origin': IDLE_NEW,
                        'description': 'Female Werewolf Pack',
                        'icon': 'WVLIcons/werewolf/FemaleWerewolfHub',
                        'priority': -100,
                    },
                    {
                        'destination': IDLE_NEW,
                        'description': 'Return',
                        'icon': 'OStim/symbols/return',
                        'priority': -1000,
                    },
                ],
                'speeds': [{'animation': idle_anim}],
                'actors': actors_mh,
                'tags': [
                    'idle', 'intro', 'hub', 'creature', 'werewolf',
                    'packfemalewerewolf', 'malefirst',
                ],
                'noRandomSelection': True,
            }
            base = 'SKSE/Plugins/OStim/scenes/WerewolfVampireLordOStim/werewolf/mf-c1'
            write_json(os.path.join(STAGE, pack, base, f'{IDLE_NEW}.json'), idle)
            write_json(os.path.join(STAGE, pack, base, f'{HUB_NEW}.json'), hub)
            mh_ids.extend([IDLE_NEW, HUB_NEW])
            mh_here += 2
            mh_scene_count += 2
            packs_with_files.add(pack)

        per_pack.append((pack, icon_changed_here, mh_here, detect_rel))

    # collision: new ids vs existing (allow HUB/IDLE repeats)
    unique_mh = []
    seen = set()
    for i in mh_ids:
        if i not in seen:
            unique_mh.append(i)
            seen.add(i)
    for i in unique_mh:
        if i in existing_ids:
            issues.append(f'ID collision with existing scene: {i}')

    # validate all staged JSON
    staged_json = list(glob.glob(STAGE + '/**/*.json', recursive=True))
    nav_missing = []
    staged_ids_by_pack = {}
    all_staged_ids = set()
    for p in staged_json:
        with open(p, encoding='utf-8') as f:
            try:
                data = json.load(f)
            except Exception as e:
                issues.append(f'invalid JSON {p}: {e}')
                continue
        sid = os.path.splitext(os.path.basename(p))[0]
        all_staged_ids.add(sid)
        # pack folder is first component after STAGE
        rel = rel_under(p, STAGE)
        pack = rel.split('/')[0]
        staged_ids_by_pack.setdefault(pack, set()).add(sid)
        for nav in data.get('navigations') or []:
            for k in ('origin', 'destination'):
                dest = nav.get(k)
                if dest and dest.startswith('WVLP_'):
                    # must exist in this pack (or be IDLE/HUB in this pack)
                    if dest not in staged_ids_by_pack.get(pack, set()) and dest not in (IDLE_NEW, HUB_NEW):
                        # may not have been recorded yet if walk order is wrong; check later
                        nav_missing.append((pack, sid, dest))

    # recheck navs now that all ids are known
    nav_missing_final = []
    for pack, sid, dest in nav_missing:
        if dest not in staged_ids_by_pack.get(pack, set()):
            nav_missing_final.append((pack, sid, dest))
    # second pass properly
    nav_missing_final = []
    for p in staged_json:
        rel = rel_under(p, STAGE)
        pack = rel.split('/')[0]
        if pack in ('00 Common', 'fomod') or not rel.endswith('.json'):
            continue
        sid = os.path.splitext(os.path.basename(p))[0]
        data = json.load(open(p, encoding='utf-8'))
        for nav in data.get('navigations') or []:
            for k in ('origin', 'destination'):
                dest = nav.get(k)
                if dest and dest.startswith('WVLP_') and dest not in staged_ids_by_pack.get(pack, set()):
                    nav_missing_final.append((pack, sid, dest))
    for row in nav_missing_final:
        issues.append(f'missing nav target {row[2]} from {row[1]} in {row[0]}')

    # README + FOMOD
    open(os.path.join(STAGE, 'README.txt'), 'w', encoding='utf-8', newline='\n').write(README)
    info, cfg = build_fomod(detect, packs_with_files)
    os.makedirs(os.path.join(STAGE, 'fomod'), exist_ok=True)
    open(os.path.join(STAGE, 'fomod', 'info.xml'), 'w', encoding='utf-8', newline='\n').write(info)
    open(os.path.join(STAGE, 'fomod', 'ModuleConfig.xml'), 'w', encoding='utf-8', newline='\n').write(cfg)

    # zip
    if os.path.exists(ZIP_PATH):
        os.remove(ZIP_PATH)
    with zipfile.ZipFile(ZIP_PATH, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for dp, ds, fs in os.walk(STAGE):
            ds.sort()
            for fn in sorted(fs):
                p = os.path.join(dp, fn)
                z.write(p, rel_under(p, STAGE))

    md5 = hashlib.md5(open(ZIP_PATH, 'rb').read()).hexdigest()
    size = os.path.getsize(ZIP_PATH)

    lines = []
    lines.append(f'ZIP {ZIP_PATH}')
    lines.append(f'SIZE {size}')
    lines.append(f'MD5 {md5}')
    lines.append(f'DDS_ICONS {len(dds)}')
    lines.append(f'ICON_JSON {icon_json_count}')
    lines.append(f'ICON_NAVS {icon_nav_count}')
    lines.append(f'MH_SCENES {mh_scene_count} (includes idle+hub in each Female WW pack)')
    lines.append(f'MH_UNIQUE_IDS {len(unique_mh)}')
    lines.append(f'MH_AUTO_START {auto_start_mh}')
    lines.append(f'PACKS_WITH_FILES {len(packs_with_files)}')
    lines.append('')
    lines.append('--- Per pack (icon-patched overwrites, new MH scenes, detect file) ---')
    for pack, ic, mh, det in per_pack:
        mark = 'INSTALL' if pack in packs_with_files else 'empty'
        lines.append(f'  [{mark}] {pack}: icon_json={ic} mh={mh}')
        lines.append(f'         detect={det}')
    lines.append('')
    lines.append('--- New MH ids ---')
    for i in unique_mh:
        lines.append(f'  {i}')
    lines.append('')
    lines.append(f'ISSUES {len(issues)}')
    for i in issues:
        lines.append(f'  {i}')
    text = '\n'.join(lines) + '\n'
    open(REPORT, 'w', encoding='utf-8').write(text)
    print(text)
    if issues:
        raise SystemExit('build finished with issues')


if __name__ == '__main__':
    main()
