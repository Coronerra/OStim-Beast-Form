<div align="center">

# 🐺🌕 OStim Beast Form 🌕🐺

### *When the moon rises, the romance doesn't have to stop.*

**Start OStim scenes as the player while in werewolf beast form — Skyrim SE/AE.**

`v0.1` · tiny light plugin (ESL-flagged ESP) · no world edits · no race edits

</div>

---

> 🔞 **Adult mod.** For adults 18+ only. All characters are adults. The mod refuses to start scenes with child actors.

## 🩸 What it does

Vanilla beast form switches off NPC activation: no crosshair prompt, no "E", and OStim's start key has nobody to target. Your follower may be *very* interested in the big furry Dragonborn, but you can't do anything about it.

**OStim Beast Form** fixes that:

- 🎯 **Its own hotkey** starts an OStim scene with the NPC you're facing while you're a werewolf.
- ⏳ **Beast-form timer guard**: the transformation timer is paused during the scene and your remaining time is given back afterward, so you don't turn back mid-animation.
- 🗣️ Works alongside **OStimNet / SkyrimNet**, so NPC-initiated scenes in beast form are guarded too.

## ✅ Status

**v0.1, tested in-game by the author:**
- ✔️ NPC-initiated scenes (via OStimNet/SkyrimNet) in beast form work
- ✔️ Hotkey start in beast form works

### 🧪 Tested on

Developed and tested in-game on a **modified Nolvus 6.0.21** build (Skyrim SE 1.5.97) with a werewolf overhaul and creature body mod installed:

- 🐺 **[Growl - Werebeasts of Skyrim](https://www.nexusmods.com/skyrimspecialedition/mods/31245)**
- 🍆 **[BakaFactory Animated Beasts Cocks (ABC)](https://www.loverslab.com/files/file/7556-animated-beasts-cocksabc-for-users-le-se/)**, with the **Furry Works** option selected in ABC's installer

**Nolvus players, you're welcome here.** The mod works on the beast-form *race*, not the body mesh, so werewolf body replacers and overhauls like these are fine.

## ⚙️ How it works

1. **Custom hotkey.** Beast form disables NPC activation and the crosshair prompt, so the mod listens for its own key instead of OStim's.
2. **Target pick.** It uses the crosshair target if there is one. Otherwise it picks the nearest valid NPC *in front of you* within the search radius.
3. **Safety checks.** It refuses child actors, dead actors, actors in combat (and you in combat, unless "Try StopCombat" is on and works), and other invalid targets.
4. **Scene start.** It calls `OLibrary.GetRandomScene` with you and your partner, then starts it with `OThreadBuilder`, with **the player as the dominant actor**. Any installed OStim scene that fits a werewolf + your partner can be chosen, from any pack.
5. **Werewolf typing.** **OCreatures Reforged** tells OStim that `WerewolfBeastRace` is a werewolf, which is how OStim matches you to werewolf scenes.
6. **Timer guard.** On scene start it stores and pauses the game's `PlayerWerewolfShiftBackTime`, and on scene end it restores your remaining beast-form time.

## 🎛️ MCM: "OStim Beast Form"

| Setting | Default | What it does |
|---|---|---|
| **Start scene hotkey** | unbound | The key that starts a scene in beast form. **Set this first.** Don't use OStim's own key. |
| **Fallback search radius** | 200 units | How far in front of you to look when nothing is under the crosshair. |
| **Try StopCombat before starting** | off | Attempts to end combat so a scene can start. |
| **Pause beast timer for ANY OStim scene** | on | Also guards scenes started some other way (OStim key, OStimNet/SkyrimNet) while you're a werewolf. Hotkey scenes are always guarded. |
| **Debug notifications** | off | Shows on-screen messages explaining what happened (or why nothing did). |

## 📦 Installation

1. Download `OStim_Beast_Form_v0.1.zip` from [Releases](../../releases).
2. Install with **Mod Organizer 2** or **Vortex** like any other mod (the zip root is the `Data` folder).
3. Load a save and give **SkyUI** a minute to register the MCM (or save and reload).
4. Open **OStim Beast Form** in the MCM and set the **Start scene hotkey**.
5. Turn into a werewolf, get out of combat, face your partner up close, and press the hotkey. 🌕

## 📋 Requirements

| Mod | Notes |
|---|---|
| Skyrim **SE / AE** | |
| **SKSE64** | |
| **SkyUI** | for the MCM |
| **OStim Standalone** | 7.5.1c tested |
| **PapyrusUtil** | OStim dependency |
| **OCreatures Reforged** by **Lirael** | **Required.** Gives OStim its werewolf race typing. |
| An OStim creature pack **with werewolf scenes** | e.g. Lirael's OCreatures Billyy animation pack |

**Optional:**
- **OStimNet** + **SkyrimNet**: lets NPCs start scenes with you themselves.
- [`patches/`](patches/): an optional OStimNet source patch so NPCs list the werewolf player even with **"Nearby actors humanoid only"** on. It must be **compiled on Windows**. See [patches/README.md](patches/README.md).

## 💜 Support Lirael

This mod stands on **OCreatures Reforged** and Lirael's creature animation packs. If you enjoy it, please support her work:

👉 **[Lirael on Patreon](https://www.patreon.com/LiraelAtelier)**

## ⚠️ Known limits

- Werewolf scenes are **male werewolf + female partner** only (that's what the packs provide).
- Works with the standard werewolf beast-form race (`WerewolfBeastRace`), which overhauls like Growl and body/mesh replacers like ABC keep using. Werebear form and mods that add a *brand-new* transformation race aren't handled yet.
- Player-only werewolf skin/body mods may be affected by OStim's undressing.
- Scenes **can't start in combat**.

## 🛠️ Building from source

Sources are in [`Data/Scripts/Source/`](Data/Scripts/Source/):
- `OBF_Main.psc`: hotkey, targeting, scene start, timer guard
- `OBF_MCM.psc`: SkyUI MCM
- `OBF_PlayerAlias.psc`: game-load hook

Compile with the Papyrus Compiler (Creation Kit) or [Caprica](https://github.com/Orvid/Caprica) (`-g skyrim`), with imports for vanilla + SKSE, SkyUI SDK, OStim Standalone and PapyrusUtil script sources.

The plugin is generated by [`tools/mkesp.py`](tools/mkesp.py) (Python 3, no dependencies). Run it from the `Data` folder to write `OStim_Beast_Form.esp`: one quest with a player alias and the three scripts attached.

## 🙏 Credits

- **coronerra**: author
- **Lirael**: OCreatures Reforged and creature animation packs
- **OStim team**: OStim Standalone
- **tetherball88**: OStimNet

## 📜 License

[MIT](LICENSE) © coronerra
