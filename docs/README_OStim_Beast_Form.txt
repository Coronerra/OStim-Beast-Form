OStim Beast Form 1.0.1 (Skyrim SE / AE)
by That Guy (Coronerra)
Technical readme and source: https://github.com/Coronerra/OStim-Beast-Form-Merged

Play as a werewolf, werebear or Vampire Lord in OStim with your mind intact.

=====================================================================
THE SHORT VERSION
=====================================================================
1. Install with MO2 and read every installer page.
2. Page 1, pick the ONE setup you use:
   A. Vanilla / FSMP: no TWO, no Growl
   B. TWO 4.1 (Total Werewolf Overhaul)
   C. Growl (the Nolvus default). Growl + TWO users also tick
      "I also use TWO 4.1" on the next page.
3. The installer asks whether you use OCreatures Reforged. If you don't,
   it installs this mod's own werewolf and vampire lord start poses so
   other packs' buttons still show up.
4. Optional: "Beast couples" (two werewolves or two vampire lords), only
   if you have Lirael's Werewolf and Vampire Lord OStim.
5. Copy the files listed in the PUT_..._FILES_HERE.txt notes (see below).
6. Run Pandora (or your behavior engine) again, then start the game.

=====================================================================
WHY SOME FOLDERS ONLY HAVE A PUT_..._FILES_HERE.txt
=====================================================================
This mod only ships files I changed myself. Files made by other authors
that I didn't change aren't included. Each spot where one of those files
goes has a PUT_..._FILES_HERE.txt that says which file goes there and
where it comes from. You can leave them alone if the mod named in the note
is already installed, because it puts its files in the same place.

This mod uses the TWO body made by Frosferes, at the LoversLab community's
request. Frosferes is okay with patches but I will not repackage any files
he made that I did not have to patch. So non-softbody female bodies and
all Male bodies are still dependant on his TWO bodies. Anyone is free to
make their own patches, hubs and mods based on this one.

  PUT_TWO_FILES_HERE.txt          TWO 4.1 male body, skeleton, head parts,
                                  textures (cores A and C without TWO)
  PUT_VAMPIRE_LORD_FILES_HERE.txt Monster Facial Animation's headless
                                  Vampire Lord bodies and heads, and the
                                  aroused Vampire Lord mesh (MNC / OCR)
  PUT_WEREBEAR_FILES_HERE.txt     werebear meshes (Growl core only)

=====================================================================
WHAT YOU GET
=====================================================================
- Start-scene hotkey (MCM) while you're a werewolf or werebear, out of
  combat. The beast timer pauses during scenes.
- Werewolves and Vampire Lords are their own OStim actor types (male and
  female), so every pack with werewolf or vampire lord scenes shows up.
- This mod's own start poses and menus. They never replace files from
  OCreatures Reforged or any animation pack.
- Vampire Lords can be sex partners when the NPC wants it (SkyrimNet /
  OStimNet).
- SkyrimNet: NPCs are told when someone transforms, while they're
  transformed, and when they turn back. Vampire Lords: "their body grows
  and changes into a vampire lord form with wings".
- Big loads (OCum, MCM, on by default): werewolves and werebears only.
  Vaginal and anal finishes stay inside and never reach her face.
- Beast Pie keeps the OCum / Tull / Liquid creampie through beast form.
- Converted female werewolf body (SMP opening that reacts to TNG and SOS)
  and converted male cock (SMP collision with UNP / CBBE / UBE bodies).
- BFA expression morphs for werewolf and vampire lord heads.
- Growl core: werebears. MCM "Werebears use werewolf scenes" (on by
  default; werebears use the werewolf skeleton). Off makes them their own
  "Werebear" OStim type for future packs. No werebear scenes exist yet.

=====================================================================
REQUIREMENTS
=====================================================================
Everyone: OStim Standalone, OCum Ascended, SKSE, Address Library, SkyUI,
PapyrusUtil, powerofthree's Papyrus Extender, XPMSSE, FSMP, Pandora, and an
OStim pack with werewolf scenes. Vampire Lords: Monster Facial Animation
(its meshes). Recommended: Lirael Atelier's Werewolf and Vampire Lord
OStim 0.2.3.
A (vanilla): the TWO 4.1 files listed in PUT_TWO_FILES_HERE.txt (the TWO
   plugin itself is NOT needed).
B (TWO): TWO 4.1 Core and Monster Facial Animation (MonsterLipSync1.esp).
C (Growl): Growl, JS Emissive Eyes SE, Monster Facial Animation (its head
   meshes). Growl + TWO: also TWO 4.1 Core with its Growl patch.
NOT needed: HDT Werewolves (keep it off, its plugin is also called
Werewolves.esp), ABC, Creature Framework, HCOS, SOS, SexLab.

Optional downloads:
- Beast Form Softbody / Tullius Patches: the OCum script for GT Softbody
  and/or Tull Animated Creampie + Liquid Pack users.
- Beast Form Herm Patch: for TWO Extras' herm / urta player werewolf.

=====================================================================
BODYSLIDE AND OBODY
=====================================================================
See Docs\OStim Beast Form\BodySlide_OBody.txt.

=====================================================================
TROUBLESHOOTING / LOG FILES (new in 1.0.1)
=====================================================================
The mod writes its own log, so you don't need Papyrus logging:
  Data\SKSE\Plugins\OStimBeastForm.log
  (MO2: overwrite\SKSE\Plugins\OStimBeastForm.log)
Every game load adds a header (version, core, game time; each line has
the real date and time) and a startup block: SKSE, PapyrusUtil,
powerofthree, OStim, OCum, OCreatures Reforged, Growl, TWO, TWO Extras,
Monster Facial Animation, Lirael's pack, SkyrimNet, OStimNet, the Herm
patch; whether the werewolf / werebear / vampire lord races were found;
the OCR keywords on them; which of this mod's scenes OStim registered;
the MCM settings. Then one line per event: beast scenes and beast couple
scenes starting (scene and actors), start-key attempts and why one
failed, timer pause / resume, beast climaxes and loads (and why there
was no load), Beast Pie, aroused-body swaps, Beast Aware form changes
and SkyrimNet messages, and (with the patches) the Tull / Liquid pie and
the herm condition.
MCM > OStim Beast Form > "Write log file" (ON by default). The file
starts over after 10 game loads; at most 2000 lines per game load.
Needs PapyrusUtil (already required); without it nothing is written.
Bug reports: attach OStimBeastForm.log. If the game crashed, copy it
BEFORE you load again.

=====================================================================
UPDATING FROM 0.8.x
=====================================================================
From 1.0: install 1.0.1 over it (same choices). Scripts and docs only;
plugins, FormIDs and assets are unchanged.
Plugin names and FormIDs are the same, so saves keep working. Remove the
old version (MO2: install as "Replace"), then run the new installer.
Lirael's role-swap scenes and the menu edits for her pack are gone in 1.0:
this mod no longer edits any animation pack.

=====================================================================
CREDITS
=====================================================================
That Guy (Coronerra): this mod.
Frosferes: TWO - Total Werewolf Overhaul (body this mod's converted female
werewolf and cock are made from).
Billyy: the animations this mod ships for its start poses (with
permission). See Docs\OStim Beast Form\Lite_animation_attribution.txt.
Lirael Atelier: Werewolf and Vampire Lord OStim (her animations are used
by the optional Beast couples scenes, not shipped).
The authors of Growl - Werebeasts of Skyrim, Monster Facial Animation,
OStim, OCum, SkyrimNet and OStimNet: the mods this one builds on.
