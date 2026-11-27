Scriptname OBF_Detect Hidden
{OStim Beast Form 1.1.1 - detection, duty claims, kind lookup and the child check. That Guy (Coronerra).
Global functions only: no records, no polling, no saved script state. Duty settings and claims live in StorageUtil (PapyrusUtil),
the same place OBF_Log keeps its switch. Everything here degrades to "ours" or "not detected" when a plugin is missing.
Duties: key, timer, load, size, prompt, combat (and femalebody, which is informational only).}

; ---------- plugin detection (names already used by 1.0.5 or listed in the 1.1 plan; nothing guessed) ----------
; 1.1.1: OCreatures is detected by its base plugin. A plain OCreatures install and OCreatures Reforged both ship OCreatures.esp, so both count.
; Fallback: a load order that has only the Reforged Menu plugin still counts. Plugin names only, no DLL checks.
; The name stays OCRActive so existing call sites and other mods that read it keep working.
bool Function OCRActive() global
	return OBF_Log.Loaded("OCreatures.esp") || OBF_Log.Loaded("OCreatures Reforged - Menu.esp")
EndFunction

; Reforged only (its Menu plugin). Used for the custom-body check, which reads the Reforged ini. A plain OCreatures install does not have that ini.
bool Function ReforgedActive() global
	return OBF_Log.Loaded("OCreatures Reforged - Menu.esp")
EndFunction

; kept for old callers (no call sites in 1.1.0 or 1.1.1): OCreatures.esp without the Reforged Menu plugin
bool Function OriginalOCreatures() global
	return OBF_Log.Loaded("OCreatures.esp") && !ReforgedActive()
EndFunction

bool Function TwoActive() global
	return OBF_Log.Loaded("Werewolves.esp")
EndFunction

bool Function GrowlActive() global
	return OBF_Log.Loaded("Growl - Werebeasts of Skyrim.esp")
EndFunction

bool Function SkyrimNetActive() global
	return OBF_Log.Loaded("SkyrimNet.esp")
EndFunction

; read only; Beast Form never modifies OStimNet
bool Function OStimNetActive() global
	return OBF_Log.Loaded("TT_OStimNet.esp") || SKSE.GetPluginVersion("OStimNet") > 0
EndFunction

bool Function NiOverrideReady() global
	return SKSE.GetPluginVersion("NiOverride") > 0
EndFunction

; ---------- duties ----------
int Function DutyIndex(string duty) global
	if duty == "key"
		return 0
	elseif duty == "timer"
		return 1
	elseif duty == "load"
		return 2
	elseif duty == "size"
		return 3
	elseif duty == "prompt"
		return 4
	elseif duty == "combat"
		return 5
	elseif duty == "femalebody"
		return 6
	endif
	return -1
EndFunction

string Function DutyName(int i) global
	if i == 0
		return "key"
	elseif i == 1
		return "timer"
	elseif i == 2
		return "load"
	elseif i == 3
		return "size"
	elseif i == 4
		return "prompt"
	elseif i == 5
		return "combat"
	endif
	return "femalebody"
EndFunction

; override set in the MCM: 0 Auto, 1 Always ours, 2 Never ours
int Function ModeOf(string duty) global
	if !OBF_Log.HasPapyrusUtil()
		return 0
	endif
	return StorageUtil.GetIntValue(None, "OBF_Mode_" + duty, 0)
EndFunction

Function SetMode(string duty, int mode) global
	if !OBF_Log.HasPapyrusUtil()
		return
	endif
	StorageUtil.SetIntValue(None, "OBF_Mode_" + duty, mode)
	OBF_Log.Line("OBF", "duty override " + duty + " = " + ModeText(mode))
	OBF_Hooks.Fire("OBF_StateChanged", "mask", ClaimMask() as float, None)
EndFunction

string Function ModeText(int mode) global
	if mode == 1
		return "Always ours"
	elseif mode == 2
		return "Never ours"
	endif
	return "Auto"
EndFunction

; claim bitmask from other mods (ModEvent OBF_Claim). Rebuilt every load: OBF_Main.Maintenance clears it, then fires OBF_Ready so claimers re-send.
int Function ClaimMask() global
	if !OBF_Log.HasPapyrusUtil()
		return 0
	endif
	return StorageUtil.GetIntValue(None, "OBF_ClaimMask", 0)
EndFunction

Function ClearClaims() global
	if OBF_Log.HasPapyrusUtil()
		StorageUtil.SetIntValue(None, "OBF_ClaimMask", 0)
	endif
EndFunction

Function SetClaim(string duty, bool claim) global
	int i = DutyIndex(duty)
	if i < 0 || !OBF_Log.HasPapyrusUtil()
		return
	endif
	int bit = Math.LeftShift(1, i)
	int mask = StorageUtil.GetIntValue(None, "OBF_ClaimMask", 0)
	if claim
		mask = Math.LogicalOr(mask, bit)
	else
		mask = Math.LogicalAnd(mask, Math.LogicalNot(bit))
	endif
	StorageUtil.SetIntValue(None, "OBF_ClaimMask", mask)
	OBF_Log.Line("OBF", "claim " + duty + " " + OBF_Log.YesNo(claim) + " (mask " + mask + ")")
	OBF_Hooks.Fire("OBF_StateChanged", "mask", mask as float, None)
EndFunction

bool Function Claimed(string duty) global
	int i = DutyIndex(duty)
	if i < 0
		return false
	endif
	return Math.LogicalAnd(ClaimMask(), Math.LeftShift(1, i)) != 0
EndFunction

; true when Beast Form should do this duty itself
bool Function Ours(string duty) global
	int m = ModeOf(duty)
	if m == 1
		return true
	elseif m == 2
		return false
	endif
	if Claimed(duty)
		return false
	endif
	if OCRActive() && duty != "femalebody"
		return false
	endif
	return true
EndFunction

; short text for the MCM Interop page: who owns the duty right now
string Function OwnerText(string duty) global
	int m = ModeOf(duty)
	if m == 2
		return "off (Never ours)"
	elseif m == 1
		if OCRActive() || Claimed(duty)
			return "ours (forced; another system also does this)"
		endif
		return "ours (forced)"
	endif
	if Claimed(duty)
		return "another mod (claimed)"
	endif
	if OCRActive()
		return "OCreatures"
	endif
	return "ours"
EndFunction

; ---------- kinds: werewolf / werebear / vampirelord / none ----------
; Built-in races, then extra races from StorageUtilData/OStimBeastForm/kinds.json (plugin name + decimal FormID lists, never name substrings).
string Function KindOfRace(Race r) global
	if !r
		return "none"
	endif
	Race ww = Game.GetFormFromFile(0x000CDD84, "Skyrim.esm") as Race
	Race wb = Game.GetFormFromFile(0x0001E17B, "Dragonborn.esm") as Race
	Race vl = Game.GetFormFromFile(0x0000283A, "Dawnguard.esm") as Race
	if ww && r == ww
		return "werewolf"
	elseif wb && r == wb
		return "werebear"
	elseif vl && r == vl
		return "vampirelord"
	endif
	if OBF_Log.HasPapyrusUtil() && JsonUtil.JsonExists("OStimBeastForm/kinds")
		if ExtraKind(r, "werewolf")
			return "werewolf"
		elseif ExtraKind(r, "werebear")
			return "werebear"
		elseif ExtraKind(r, "vampirelord")
			return "vampirelord"
		endif
	endif
	return "none"
EndFunction

bool Function ExtraKind(Race r, string kind) global
	string f = "OStimBeastForm/kinds"
	int n = JsonUtil.StringListCount(f, kind + "_plugins")
	int i = 0
	while i < n && i < 16
		string p = JsonUtil.StringListGet(f, kind + "_plugins", i)
		int id = JsonUtil.IntListGet(f, kind + "_ids", i)
		if p != "" && id > 0 && OBF_Log.Loaded(p)
			Form x = Game.GetFormFromFile(id, p)
			if x && x == r
				return true
			endif
		endif
		i += 1
	endwhile
	return false
EndFunction

string Function KindOf(Actor a) global
	if !a
		return "none"
	endif
	return KindOfRace(a.GetRace())
EndFunction

; ---------- child exclusion (hard rule) ----------
; Vanilla flag, OStim's own check, and the race name. Used on every path that picks or adds an actor for a scene.
bool Function IsMinor(Actor a) global
	if !a
		return true
	endif
	if a.IsChild() || OUtils.IsChild(a)
		return true
	endif
	Race r = a.GetRace()
	if r
		string rn = r.GetName()
		if StringUtil.Find(rn, "child") >= 0 || StringUtil.Find(rn, "Child") >= 0
			return true
		endif
	endif
	return false
EndFunction

; last sweep over an actor list: true if anyone in it is (or might be) a minor, or the entry is empty
bool Function AnyMinor(Actor[] list) global
	if !list
		return true
	endif
	int i = 0
	while i < list.Length
		if IsMinor(list[i])
			return true
		endif
		i += 1
	endwhile
	return false
EndFunction
