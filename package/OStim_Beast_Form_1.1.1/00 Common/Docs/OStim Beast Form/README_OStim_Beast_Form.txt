OStim Beast Form 1.1.1 (Skyrim SE / AE) - FINAL RELEASE
by That Guy (Coronerra)
Technical readme and source: https://github.com/Coronerra/OStim-Beast-Form
For adults only (18+).

## ⚠️ ABANDONED: Final Release

OStim Beast Form is abandoned as of this release. Lirael's animation pack, which this mod was built around, has been shut down. Beast Form ships no animations of its own, so without that pack it does basically nothing. If her animations are still up anywhere, you can check [dwemermods.com](https://dwemermods.com).

![Lirael's Patreon post, now under review by Patreon Trust and Safety](docs/lirael_patreon_under_review.png)

This is a bittersweet one for me. My mod died after a month of hard work. On the other hand, in my view she can't keep collecting money off LoversLab modders' work anymore. From what I saw, she fed other people's mods to her AIs, had them rebuilt her way, and used DLLs that keep people paying to stay in her ecosystem, all without crediting the original mod authors. It's my belief that this mod was used, uncredited, as the basis for OCreatures 1.75 and later. If she comes back, I don't think anyone's mods are safe, so expect her to return with a vengeance.

From here on, it belongs to the community. Build your own animations, make patches, fork it, and do whatever you want with it. If you want to make patches or mods of your own, I suggest:

- [Ultimate Grok Claude Modder Assistant v1.2](https://github.com/Coronerra/Ultimate-Grok-Claude-Modder-Assistant/releases/tag/v1.2)
- [Grok Modders Kit for Skyrim](https://github.com/JezebelGraves/Grok-Modders-Kit-for-Skyrim)

That's what I used to make this mod in the first place, and now I can finally focus on more important things.

Play nice with one another, give credit where it's due and...

**Happy Modding.**

— That Guy (Coronerra)

## Permissions

Anyone may modify, reupload, or build on this mod. Keep the existing permission credits (Billyy, Frosferes, and any other credited authors) in place. This mod is provided as-is, with no further support from the original author.

=====================================================================
WHAT THIS IS
=====================================================================
OStim Beast Form is an enabling framework for werewolves, werebears and
Vampire Lords in OStim. It ships no bodies, and anyone can make bodies for
it. It starts OStim scenes while you are in beast form, keeps your beast
form from running out mid-scene, and works with vanilla, Growl and Total
Werewolf Overhaul (TWO).

It points every body, aroused swap and add-on at the stock vanilla file
paths, so any body set drops straight in. Documented hooks (ModEvents,
JSON files, path contracts) are for other authors; see
Docs\OStim Beast Form\Extension_Guide.txt. If OCreatures (the original or
OCreatures Reforged) is installed, overlapping features step aside quietly,
with MCM overrides.

=====================================================================
THE SHORT VERSION
=====================================================================
1. Install with MO2 and read every installer page.
2. Page 1, pick the ONE setup you use:
   - Vanilla / FSMP (no TWO, no Growl)
   - TWO 4.1, no Growl
   - Growl (the Nolvus default)
   - Growl + TWO 4.1
3. Page 2, tick the extras you want: Beast couples (optional; the buttons
   only animate if you still have a couple animation pack that plays
   them), icons for the Werewolf and Vampire Lord scene packs, and (only
   shown when OCreatures Reforged is active) "Use Riotguard/custom bodies
   even with OCR".
4. Page 3 appears only if OCum is active: pick your OCum script variant.
5. Page 4: read and tick the acknowledgement.
6. Copy the files listed in the PUT_..._FILES_HERE.txt notes (see below).
7. Run Pandora (or your behavior engine) again, then start the game.
Enable your OCreatures plugin (if you use one) BEFORE installing: the
installer decides some files from the plugins that are active at that
moment. Reinstall if you add one later.

=====================================================================
BODY SETS: THIS MOD SHIPS NO BODY MESHES
=====================================================================
Beast Form is a framework. It uses the stock vanilla paths:
  meshes\actors\werewolfbeast\character assets\   (werewolves)
  meshes\actors\dlc02\werebear\                    (werebears)
  meshes\actors\vampirelord\character assets\body\ (vampire lords)
Whatever body mod sits at those paths is the body you get. Without a body
set, the same paths use TWO's, Growl's or vanilla bodies, so nothing goes
missing.

The Riotguard body pack (a separate download) is the first body set built
on this framework: male and female werewolf and werebear bodies. It is
not required, and it is not the only one. Other authors are welcome to
make their own sets, patches and hubs; Docs\OStim Beast Form\
Extension_Guide.txt is the contract. If you use a body pack, put it BELOW
Beast Form, Growl, TWO and Monster Lipsync in the MO2 left pane so its
meshes win at the stock paths.

Vampire Lords: Beast Form ships no vampire lord body either. The female
vampire lord keeps the vanilla body (or the one your vampire lord body
mod provides) at the vanilla Dawnguard path. The male-only aroused
vampire lord and werebear swaps never apply to female actors: the swap
script checks the actor's sex first.

Female werewolves, werebears and vampire lords: two-breasted bodies only.
Breast physics need a body that carries them. Beast Form cannot turn
physics on by itself (the body mesh names its own physics file); the MCM
Body page reads the actor and tells you whether the breast bones exist.
Reference configuration and the contract are in Docs\OStim Beast Form\
Physics\.

=====================================================================
WHY SOME FOLDERS ONLY HAVE A PUT_..._FILES_HERE.txt
=====================================================================
This mod only ships files I made or changed myself. Files made by other
authors that I didn't change aren't included. Each spot where one of those
files goes has a PUT_..._FILES_HERE.txt that says which file goes there
and where it comes from. You can leave them alone if the mod named in the
note is already installed, because it puts its files in the same place.

  PUT_TWO_FILES_HERE.txt          TWO 4.1 male body, skeleton, head parts,
                                  textures (cores A and C without TWO)
  PUT_VAMPIRE_LORD_FILES_HERE.txt Monster Facial Animation's headless
                                  Vampire Lord bodies and heads, and the
                                  aroused Vampire Lord mesh
  PUT_WEREBEAR_FILES_HERE.txt     werebear meshes (Growl core only)

Werebear paths (Growl core): exploration form uses the vanilla Dragonborn
paths (meshes\actors\dlc02\werebear\); Growl ships no werebear meshes of
its own and uses them. The aroused / scene body is
meshes\MoreNastyCritters\werebear\werebearHard.nif (a shared path, not a
path of this mod). This mod does not ship any werebear mesh or texture.

=====================================================================
WHAT YOU GET
=====================================================================
- Start-scene hotkey while you're a werewolf or werebear, out of combat:
  aim at an adult NPC and press it. Default: Up Arrow (new games; an
  existing save keeps whatever key it had, including "none"). Remap or
  unbind it in the MCM. The beast timer pauses during scenes.
- Gesture start key (MCM > Key, OFF by default): tap to start, hold the key
  and press an arrow key to start from that category, double tap to also
  bring the nearest eligible follower. Use a start key that is not an
  arrow key. Movement controls are never disabled.
- Climax feeds the beast timer (MCM > Feeding): a few minutes per climax,
  capped, only while the timer is paused for your scene.
- Combat pause (MCM > Combat, OFF by default): fighters who are attacking
  the people in your scene stand down, then resume when it ends.
- Anatomy size menu (MCM > Size, OFF by default): XS to XXL, global or per
  kind, optional variation. VISUAL SIZE ONLY: it scales the male beast's
  genital bones during a scene. Whether PPA follows that size was not
  verified in game. Needs RaceMenu's NiOverride.
- Icons for the Werewolf and Vampire Lord scene packs: 33 icons in this
  mod's own folder (used by this mod's own scenes), plus an optional set
  at the shared icon paths that werewolf and Vampire Lord OStim scene
  packs point at (installer page 2).
- Beast Aware / SkyrimNet: NPCs are told when someone transforms, while
  they're transformed, and when they turn back, with the beast's size,
  arousal band and climax count when known. Vampire Lords can be sex
  partners when the NPC wants it (SkyrimNet / OStimNet).
- Werewolves and Vampire Lords are their own OStim actor types (male and
  female), so every pack with werewolf or vampire lord scenes shows up.
  Couples scenes (two werewolves, two vampire lords) need no other mod
  except a couple animation pack for the animations (this mod ships none).
- This mod's own start poses and menus. They never replace files from
  OCreatures Reforged or any animation pack.
- Big loads and Beast Pie (OCum, MCM): werewolves and werebears get big
  loads; the creampie holds through beast form.
- Growl core: werebears. MCM "Werebears use werewolf scenes".
- A log for bug reports: Data\SKSE\Plugins\OStimBeastForm.log.

=====================================================================
WITH OCREATURES (ORIGINAL OR REFORGED)
=====================================================================
If OCreatures is installed (its base plugin OCreatures.esp; OCreatures
Reforged uses it too), overlapping features step aside automatically: the
start key, the beast timer, the beast cum load, the SkyrimNet state note,
the size menu and the combat pause. MCM > Interop shows who does what and
lets you override each one (Auto / Always ours / Never ours). Scenes,
icons for shared paths, gender roles and couples keep working either way.
OCreatures is never required: Beast Form works without it.

Custom bodies with OCreatures Reforged (this part is Reforged only): if
you want the bodies at the stock paths (a body pack, TWO, or your own)
instead of OCR's female werewolf body, tick "Use Riotguard/custom bodies
even with OCR" on installer page 2 (it is only shown when OCreatures
Reforged is active), or pick "Custom bodies" in MCM > Interop. Then, in
OCR's own ini file (SKSE\Plugins\OCreaturesReforged.ini), set:  bBody=0
Beast Form never edits that file. It reads it once per game load and tells
you if it still says bBody=1. Run the game once to confirm the result.
Whether every OCR piece steps aside for custom bodies was not tested in
game; if it does not, that combination is not supported.

=====================================================================
REQUIREMENTS
=====================================================================
Everyone: OStim Standalone, OCum Ascended, SKSE, Address Library, SkyUI,
PapyrusUtil, powerofthree's Papyrus Extender, XPMSSE, FSMP, Pandora, and
a werewolf / Vampire Lord OStim animation pack (or community-made scenes)
for sex scenes: this mod ships none. Vampire Lords: Monster Facial
Animation (its meshes).
Vanilla core: the TWO 4.1 files listed in PUT_TWO_FILES_HERE.txt (the TWO
   plugin itself is NOT needed).
TWO core: TWO 4.1 Core and Monster Facial Animation (MonsterLipSync1.esp).
Growl core: Growl, JS Emissive Eyes SE, Monster Facial Animation (its
   head meshes). Growl + TWO: also TWO 4.1 Core with its Growl patch.
Optional: RaceMenu (NiOverride) for the size menu; SkyrimNet and OStimNet
   for the NPC side.
NOT needed: HDT Werewolves (keep it off, its plugin is also called
Werewolves.esp), ABC, Creature Framework, HCOS, SOS, SexLab.

OCum users: installer page 3 installs the OCum script variant for Tull
Animated Creampie / Liquid Pack (https://dwemermods.com/mods/5304) and/or
GT Softbody, or nothing (OCum's own script).

=====================================================================
BODYSLIDE AND OBODY
=====================================================================
See Docs\OStim Beast Form\BodySlide_OBody.txt.

=====================================================================
TROUBLESHOOTING / LOG FILES
=====================================================================
The mod writes its own log, so you don't need Papyrus logging:
  Data\SKSE\Plugins\OStimBeastForm.log
  (MO2: overwrite\SKSE\Plugins\OStimBeastForm.log)
Every game load adds a header and a startup block: what was found, which
duties are ours, race and scene checks, the MCM settings. Then one line
per event: beast scenes, start-key attempts, timer pause and resume,
climax feeding, combat pause, size changes, body checks, loads.
MCM > OStim Beast Form > "Write log file" (ON by default). The file
starts over after 10 game loads; at most 2000 lines per game load.
Bug reports: attach OStimBeastForm.log. If the game crashed, copy it
BEFORE you load again. (The mod is no longer supported by its author; the
log is for whoever carries it on.)

Animations do not play? Run Pandora (or Nemesis) once and reload. The
game shows a one-time reminder after installing or updating.

=====================================================================
UPDATING
=====================================================================
From 1.1.0: install 1.1.1 over it (same plugin names and FormIDs; saves
keep working; settings are kept).
From 1.0.5: install 1.1.1 over it (your 1.0.5 settings are kept and the
new options start at their defaults). Going back to 1.0.5 is not
supported: keep a 1.0.5 save.
From 1.0.4 or older: remove the old version first, then install 1.1.1.

=====================================================================
CREDITS
=====================================================================
That Guy (Coronerra): this mod.
Frosferes: TWO - Total Werewolf Overhaul (the TWO body and cock standard
this mod points at).
Billyy: the animations this mod ships for its start poses (with
permission). See Docs\OStim Beast Form\Lite_animation_attribution.txt.
Lirael Atelier: Werewolf and Vampire Lord OStim (historical credit: the
optional Beast couples start poses were written to play her couple
animations; not shipped, and the pack is no longer available).
The authors of Growl - Werebeasts of Skyrim, Monster Facial Animation,
OStim, OCum, SkyrimNet and OStimNet: the mods this one builds on.
