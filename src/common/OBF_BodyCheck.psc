Scriptname OBF_BodyCheck Hidden
{OStim Beast Form 1.1.1 - read-only female-body / physics-bone diagnostic. That Guy (Coronerra).
Which body draws is decided by ordinary armor-addon data (male or female slot by the actor's sex) at the stock paths, so no runtime body swap exists.
This only LOOKS: one NetImmerse.HasNode pass on one actor, at the first beast scene after a load and when the player finishes a race switch.
Result goes to the log, to StorageUtil (shown on the MCM Body page) and to the ModEvent OBF_BodyReport. No world scan, no loop, nothing written to the actor.}

string Function YN(bool b) global
	return OBF_Log.YesNo(b)
EndFunction

Function Run(Actor a, string why) global
	if !a || !a.Is3DLoaded()
		return
	endif
	string kind = OBF_Detect.KindOf(a)
	if kind == "none"
		return
	endif
	bool female = a.GetLeveledActorBase().GetSex() == 1
	bool breast = NetImmerse.HasNode(a, "NPC L Breast", false) && NetImmerse.HasNode(a, "NPC R Breast", false)
	bool genital = false
	string flags = kind
	if female
		genital = NetImmerse.HasNode(a, "VaginaB1", false)
		flags += ",female"
		if breast
			flags += ",breastbones"
		endif
		if genital
			flags += ",genitalbones"
		endif
	else
		genital = NetImmerse.HasNode(a, "WWD 2", false) || NetImmerse.HasNode(a, "NPC Genitals01", false)
		flags += ",male"
		if genital
			flags += ",genitalbones"
		endif
	endif
	if OBF_Log.HasPapyrusUtil()
		StorageUtil.SetStringValue(None, "OBF_Body_Who", a.GetDisplayName() + " (" + kind + ")")
		StorageUtil.SetIntValue(None, "OBF_Body_Female", female as int)
		StorageUtil.SetIntValue(None, "OBF_Body_Breast", breast as int)
		StorageUtil.SetIntValue(None, "OBF_Body_Genital", genital as int)
		StorageUtil.SetIntValue(None, "OBF_Body_Seen", 1)
	endif
	OBF_Log.Line("OBF", "body check (" + why + ") " + OBF_Log.Who(a) + ": female " + YN(female) + " | breast bones " + YN(breast) + " | genital bones " + YN(genital))
	OBF_Hooks.Fire("OBF_BodyReport", flags, 0.0, a)
	if female && !breast && StorageUtil.GetIntValue(None, "OBF_Body_Warned", 0) == 0
		StorageUtil.SetIntValue(None, "OBF_Body_Warned", 1)
		Debug.Notification("Beast Form: this female beast body has no breast bones, so breast physics will not run. See the README (Body sets).")
	endif
EndFunction

; once per game load (OBF_Main clears the warning flag in Maintenance)
Function NewLoad() global
	if OBF_Log.HasPapyrusUtil()
		StorageUtil.SetIntValue(None, "OBF_Body_Warned", 0)
		StorageUtil.SetIntValue(None, "OBF_Body_Seen", 0)
	endif
EndFunction

string Function Summary() global
	if !OBF_Log.HasPapyrusUtil() || StorageUtil.GetIntValue(None, "OBF_Body_Seen", 0) == 0
		return "not checked yet this session (starts at your first beast scene or beast-form shift)"
	endif
	return StorageUtil.GetStringValue(None, "OBF_Body_Who", "") + ": female body " + YN(StorageUtil.GetIntValue(None, "OBF_Body_Female", 0) == 1) + ", breast bones " + YN(StorageUtil.GetIntValue(None, "OBF_Body_Breast", 0) == 1) + ", genital bones " + YN(StorageUtil.GetIntValue(None, "OBF_Body_Genital", 0) == 1)
EndFunction

; Body priority with OCR (custom bodies): one read-only look at the ini text. Never writes it. Returns "" when nothing to say.
; 1.1.1: this is the one OCreatures check that stays Reforged-specific, because only OCreatures Reforged has this ini.
string Function OcrIniNote() global
	if !OBF_Detect.ReforgedActive() || StorageUtil.GetIntValue(None, "OBF_BodyCustom", 0) == 0 || !OBF_Log.HasPapyrusUtil()
		return ""
	endif
	string p = "Data/SKSE/Plugins/OCreaturesReforged.ini"
	if !MiscUtil.FileExists(p)
		return "OCR's ini was not found where Beast Form looked, so its female werewolf body setting could not be checked. In that ini set bBody=0 to use custom bodies."
	endif
	string txt = MiscUtil.ReadFromFile(p)
	if txt == ""
		return ""
	endif
	int at = StringUtil.Find(txt, "bBody=1")
	if at < 0
		at = StringUtil.Find(txt, "bBody = 1")
	endif
	if at >= 0
		return "OCR is still set to replace female werewolf bodies; set bBody=0 in its ini to use your custom bodies."
	endif
	return ""
EndFunction
