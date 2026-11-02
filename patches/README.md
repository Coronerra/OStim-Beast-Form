# Optional OStimNet patch

`OStimNet_PassesFilters_player_beastform.patch` is **optional**. It modifies OStimNet's SKSE plugin source (`SKSE_Source/src/ActorUtils.h`) so that, with **"Nearby actors humanoid only"** left ON, the *player* in vanilla werewolf beast form (`WerewolfBeastRace`, `Skyrim.esm` 0x000CDD84) is still listed as a nearby actor, so SkyrimNet NPCs can choose you, while real creatures stay filtered out.

- It is a source patch, **not** a binary. Apply it to OStimNet's source and **compile the SKSE plugin on Windows** (MSVC + CommonLibSSE toolchain used by OStimNet).
- Untested. Without it, you can instead temporarily turn off "Nearby actors humanoid only" in OStimNet's settings (this also lets NPCs pick creatures).
- OStimNet is by tetherball88; this patch is offered to its author/users and contains none of OStimNet's other files.
