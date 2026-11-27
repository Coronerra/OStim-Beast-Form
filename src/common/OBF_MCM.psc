Scriptname OBF_MCM extends SKI_ConfigBase
{OStim Beast Form 1.1.1 MCM. One script for every core (the Growl-only werebear toggle shows only when the Growl core's plugin is loaded). That Guy (Coronerra).}

OBF_Main Property Main Auto

int oidKey
int oidGuardAll
int oidStopCombat
int oidRadius
int oidDebug
int oidLog
int oidBL
int oidHuge
int oidMesh
int oidShot
int oidStack
int oidRounds
int oidBearAsWolf
; 1.1.0
int oidGesture
int oidFights
int oidFeedHours
int oidFeedCap
int oidSizeOn
int oidSizeGlobal
int oidSizeWolf
int oidSizeBear
int oidSizeVamp
int oidSizeVar
int oidBodyPrio
int[] oidDuty

; Filled by the plugin (TWO edition). Growl edition leaves it empty and falls back to its own plugin name.
OCumBeastPie Property BeastPie Auto

OCumBeastPie Function BL()
	if !BeastPie && OBF_Log.Loaded("OStim_Beast_Form_Merged.esp")
		BeastPie = Game.GetFormFromFile(0x822, "OStim_Beast_Form_Merged.esp") As OCumBeastPie
	endif
	return BeastPie
EndFunction

GlobalVariable Function BearAsWolf()
	; Core C (Growl): MCM switch read by the werebear actor property perks
	if OBF_Log.Loaded("OStim_Beast_Form_Merged.esp")
		return Game.GetFormFromFile(0x839, "OStim_Beast_Form_Merged.esp") As GlobalVariable
	endif
	return None
EndFunction

int Function GetVersion()
	return 110 ; unchanged in 1.1.1 (no page changes): SkyUI keeps the page list of 1.1.0 saves
EndFunction

Event OnVersionUpdate(int newVersion)
	OnConfigInit()
EndEvent

Event OnConfigInit()
	ModName = "OStim Beast Form"
	Pages = new string[7]
	Pages[0] = "Settings"
	Pages[1] = "Key"
	Pages[2] = "Combat"
	Pages[3] = "Feeding"
	Pages[4] = "Size"
	Pages[5] = "Interop"
	Pages[6] = "Body"
EndEvent

OBF_Main Function M()
	if !Main
		Main = (Self as Quest) as OBF_Main
	endif
	return Main
EndFunction

Event OnPageReset(string page)
	SetCursorFillMode(TOP_TO_BOTTOM)
	if page == "Key"
		PageKey()
	elseif page == "Combat"
		PageCombat()
	elseif page == "Feeding"
		PageFeeding()
	elseif page == "Size"
		PageSize()
	elseif page == "Interop"
		PageInterop()
	elseif page == "Body"
		PageBody()
	else
		PageSettings()
	endif
EndEvent

Function PageSettings()
	oidBearAsWolf = -1
	AddHeaderOption("Beast form scenes")
	oidKey = AddKeyMapOption("Start scene hotkey", M().StartKey, OPTION_FLAG_WITH_UNMAP)
	oidRadius = AddSliderOption("Fallback search radius", M().SearchRadius, "{0} units")
	oidStopCombat = AddToggleOption("Try StopCombat before starting", M().StopCombatOnStart)
	AddHeaderOption("Timer guard")
	oidGuardAll = AddToggleOption("Pause beast timer for ANY OStim scene", M().GuardAllScenes)
	oidDebug = AddToggleOption("Debug notifications", M().DebugMessages)
	oidLog = AddToggleOption("Write log file", OBF_Log.On())     ; 1.0.1
	GlobalVariable g = BearAsWolf()
	if g
		AddHeaderOption("Werebears (Growl)")
		oidBearAsWolf = AddToggleOption("Werebears use werewolf scenes", g.GetValue() >= 1.0)
	endif
	AddHeaderOption("Beast climax (OCum)")
	OCumBeastPie b = BL()
	if b
		oidBL = AddToggleOption("Werewolf/VL cum on partner", b.BeastLoadEnabled)
		oidHuge = AddToggleOption("Big loads (werewolves & werebears)", b.HugeLoad)
		oidMesh = AddToggleOption("Tull/Liquid meshes", b.BeastMeshes)
		oidShot = AddToggleOption("Spurts on outside finishes", b.ExtraCumShot)
		oidStack = AddToggleOption("Stack cum across rounds", b.StackRounds)
		oidRounds = AddSliderOption("Max stacked rounds", b.MaxRounds as float, "{0}")
	endif
EndFunction

Function PageKey()
	AddHeaderOption("Gesture start key")
	oidGesture = AddToggleOption("Use the gesture start key", M().GestureKey)
	AddTextOption("Tap", "start a scene", OPTION_FLAG_DISABLED)
	AddTextOption("Hold + an arrow key", "start from that category", OPTION_FLAG_DISABLED)
	AddTextOption("Double tap", "also bring the nearest follower", OPTION_FLAG_DISABLED)
	AddHeaderOption("Categories (arrow keys)")
	int s = 1
	while s <= 4
		AddTextOption(OBF_Gesture.Label(s), OBF_Gesture.Actions(s), OPTION_FLAG_DISABLED)
		s += 1
	endwhile
	AddTextOption("Start key duty now", OBF_Detect.OwnerText("key"), OPTION_FLAG_DISABLED)
EndFunction

Function PageCombat()
	AddHeaderOption("Combat pause during your scene")
	oidFights = AddToggleOption("Also pause nearby fights", M().PauseNearbyFights)
	AddTextOption("Duty now", OBF_Detect.OwnerText("combat"), OPTION_FLAG_DISABLED)
	AddTextOption("Participants", "always: see Settings", OPTION_FLAG_DISABLED)
EndFunction

Function PageFeeding()
	AddHeaderOption("Climax feeds the beast timer")
	oidFeedHours = AddSliderOption("Hours added per climax (0 = off)", M().FeedHours, "{2} h")
	oidFeedCap = AddSliderOption("Never raise the remaining time above", M().FeedCapHours, "{2} h")
	AddTextOption("Timer duty now", OBF_Detect.OwnerText("timer"), OPTION_FLAG_DISABLED)
EndFunction

string[] Function SizeOptions(bool withGlobal)
	int n = OBF_Size.Count()
	int off = 0
	if withGlobal
		off = 1
	endif
	string[] o = PapyrusUtil.StringArray(n + off)
	if withGlobal
		o[0] = "Use the global size"
	endif
	int i = 0
	while i < n
		o[i + off] = OBF_Size.Label(i)
		i += 1
	endwhile
	return o
EndFunction

string Function SizeText(int idx)
	if idx < 0
		return "Use the global size"
	endif
	return OBF_Size.Label(idx)
EndFunction

Function PageSize()
	AddHeaderOption("Anatomy size (visual only)")
	oidSizeOn = AddToggleOption("Use the size menu", M().SizeEnabled)
	oidSizeGlobal = AddMenuOption("Global size", SizeText(M().SizeGlobal))
	oidSizeWolf = AddMenuOption("Werewolves", SizeText(M().SizeWolf))
	oidSizeBear = AddMenuOption("Werebears", SizeText(M().SizeBear))
	oidSizeVamp = AddMenuOption("Vampire lords", SizeText(M().SizeVamp))
	string[] v = new string[3]
	v[0] = "None"
	v[1] = "Small"
	v[2] = "Large"
	oidSizeVar = AddMenuOption("Random variation", v[M().SizeVariation])
	AddTextOption("Size duty now", OBF_Detect.OwnerText("size"), OPTION_FLAG_DISABLED)
	AddTextOption("NiOverride (RaceMenu)", OBF_Log.YesNo(OBF_Detect.NiOverrideReady()), OPTION_FLAG_DISABLED)
EndFunction

Function PageInterop()
	oidDuty = new int[6]
	AddHeaderOption("OCreatures")
	AddTextOption("OCreatures detected", OBF_Log.YesNo(OBF_Detect.OCRActive()), OPTION_FLAG_DISABLED)
	AddTextOption("Claims from other mods", OBF_Detect.ClaimMask() as string, OPTION_FLAG_DISABLED)
	AddHeaderOption("Who does what (Auto / Always ours / Never ours)")
	int i = 0
	while i < 6
		string d = OBF_Detect.DutyName(i)
		oidDuty[i] = AddMenuOption(DutyTitle(d) + " (" + OBF_Detect.OwnerText(d) + ")", OBF_Detect.ModeText(OBF_Detect.ModeOf(d)))
		i += 1
	endwhile
	SetCursorPosition(1)
	AddHeaderOption("Body priority with OCreatures Reforged")
	string bp = "OCR's bodies"
	if StorageUtil.GetIntValue(None, "OBF_BodyCustom", 0) == 1
		bp = "Custom bodies"
	endif
	oidBodyPrio = AddMenuOption("Body priority", bp)
	AddTextOption("To use custom bodies, set in OCR's ini:", "bBody=0", OPTION_FLAG_DISABLED)
	AddTextOption("Beast Form never edits that file", "", OPTION_FLAG_DISABLED)
EndFunction

string Function DutyTitle(string d)
	if d == "key"
		return "Start key"
	elseif d == "timer"
		return "Beast timer"
	elseif d == "load"
		return "Beast cum load"
	elseif d == "size"
		return "Size menu"
	elseif d == "prompt"
		return "SkyrimNet state"
	endif
	return "Combat pause"
EndFunction

Function PageBody()
	AddHeaderOption("Female body and bones (read only)")
	AddTextOption("Last check", OBF_BodyCheck.Summary(), OPTION_FLAG_DISABLED)
	AddTextOption("Bodies come from", "the stock paths (your body mod, TWO, Growl or vanilla)", OPTION_FLAG_DISABLED)
	AddTextOption("Beast Form ships", "no body meshes", OPTION_FLAG_DISABLED)
	string note = OBF_BodyCheck.OcrIniNote()
	if note != ""
		AddTextOption("OCR setting", "see the help text", OPTION_FLAG_DISABLED)
	endif
EndFunction

Event OnOptionKeyMapChange(int option, int keyCode, string conflictControl, string conflictName)
	if option == oidKey
		if conflictControl != ""
			if !ShowMessage("This key is already used by " + conflictControl + " (" + conflictName + "). Use it anyway?", true, "Yes", "No")
				return
			endif
		endif
		M().SetStartKey(keyCode)
		SetKeyMapOptionValue(oidKey, keyCode)
	endif
EndEvent

Event OnOptionDefault(int option)
	if option == oidKey
		M().SetStartKey(200) ; 1.0.4: the default is Up Arrow (use the unmap button to unbind)
		SetKeyMapOptionValue(oidKey, 200)
	endif
EndEvent

Event OnOptionSelect(int option)
	if option == oidLog
		OBF_Log.SetOn(!OBF_Log.On())
		if OBF_Log.On()
			M().LogStartup()
		endif
		SetToggleOptionValue(option, OBF_Log.On())
	elseif option == oidGuardAll
		M().GuardAllScenes = !M().GuardAllScenes
		SetToggleOptionValue(option, M().GuardAllScenes)
	elseif option == oidStopCombat
		M().StopCombatOnStart = !M().StopCombatOnStart
		SetToggleOptionValue(option, M().StopCombatOnStart)
	elseif option == oidDebug
		M().DebugMessages = !M().DebugMessages
		SetToggleOptionValue(option, M().DebugMessages)
	elseif option == oidGesture
		M().GestureKey = !M().GestureKey
		SetToggleOptionValue(option, M().GestureKey)
	elseif option == oidFights
		M().PauseNearbyFights = !M().PauseNearbyFights
		SetToggleOptionValue(option, M().PauseNearbyFights)
	elseif option == oidSizeOn
		M().SizeEnabled = !M().SizeEnabled
		if !M().SizeEnabled
			OBF_Size.RestoreAll()
		endif
		SetToggleOptionValue(option, M().SizeEnabled)
	elseif option == oidBearAsWolf
		GlobalVariable g = BearAsWolf()
		if g
			if g.GetValue() >= 1.0
				g.SetValue(0.0)
			else
				g.SetValue(1.0)
			endif
			SetToggleOptionValue(option, g.GetValue() >= 1.0)
		endif
	elseif option == oidBL
		BL().BeastLoadEnabled = !BL().BeastLoadEnabled
		SetToggleOptionValue(option, BL().BeastLoadEnabled)
	elseif option == oidHuge
		BL().HugeLoad = !BL().HugeLoad
		SetToggleOptionValue(option, BL().HugeLoad)
	elseif option == oidMesh
		BL().BeastMeshes = !BL().BeastMeshes
		SetToggleOptionValue(option, BL().BeastMeshes)
	elseif option == oidShot
		BL().ExtraCumShot = !BL().ExtraCumShot
		SetToggleOptionValue(option, BL().ExtraCumShot)
	elseif option == oidStack
		BL().StackRounds = !BL().StackRounds
		SetToggleOptionValue(option, BL().StackRounds)
	endif
EndEvent

Event OnOptionMenuOpen(int option)
	if option == oidSizeGlobal
		SetMenuDialogOptions(SizeOptions(false))
		SetMenuDialogStartIndex(M().SizeGlobal)
		SetMenuDialogDefaultIndex(2)
	elseif option == oidSizeWolf
		SetMenuDialogOptions(SizeOptions(true))
		SetMenuDialogStartIndex(M().SizeWolf + 1)
		SetMenuDialogDefaultIndex(0)
	elseif option == oidSizeBear
		SetMenuDialogOptions(SizeOptions(true))
		SetMenuDialogStartIndex(M().SizeBear + 1)
		SetMenuDialogDefaultIndex(0)
	elseif option == oidSizeVamp
		SetMenuDialogOptions(SizeOptions(true))
		SetMenuDialogStartIndex(M().SizeVamp + 1)
		SetMenuDialogDefaultIndex(0)
	elseif option == oidSizeVar
		string[] v = new string[3]
		v[0] = "None"
		v[1] = "Small"
		v[2] = "Large"
		SetMenuDialogOptions(v)
		SetMenuDialogStartIndex(M().SizeVariation)
		SetMenuDialogDefaultIndex(0)
	elseif option == oidBodyPrio
		string[] b = new string[2]
		b[0] = "OCR's bodies"
		b[1] = "Custom bodies"
		SetMenuDialogOptions(b)
		SetMenuDialogStartIndex(StorageUtil.GetIntValue(None, "OBF_BodyCustom", 0))
		SetMenuDialogDefaultIndex(0)
	else
		int i = DutyOfOption(option)
		if i >= 0
			string[] m = new string[3]
			m[0] = "Auto"
			m[1] = "Always ours"
			m[2] = "Never ours"
			SetMenuDialogOptions(m)
			SetMenuDialogStartIndex(OBF_Detect.ModeOf(OBF_Detect.DutyName(i)))
			SetMenuDialogDefaultIndex(0)
		endif
	endif
EndEvent

int Function DutyOfOption(int option)
	int i = 0
	while i < 6
		if oidDuty && oidDuty[i] == option
			return i
		endif
		i += 1
	endwhile
	return -1
EndFunction

Event OnOptionMenuAccept(int option, int index)
	if index < 0
		return
	endif
	if option == oidSizeGlobal
		M().SizeGlobal = index
		SetMenuOptionValue(option, SizeText(index))
	elseif option == oidSizeWolf
		M().SizeWolf = index - 1
		SetMenuOptionValue(option, SizeText(index - 1))
	elseif option == oidSizeBear
		M().SizeBear = index - 1
		SetMenuOptionValue(option, SizeText(index - 1))
	elseif option == oidSizeVamp
		M().SizeVamp = index - 1
		SetMenuOptionValue(option, SizeText(index - 1))
	elseif option == oidSizeVar
		M().SizeVariation = index
		string[] v = new string[3]
		v[0] = "None"
		v[1] = "Small"
		v[2] = "Large"
		SetMenuOptionValue(option, v[index])
	elseif option == oidBodyPrio
		StorageUtil.SetIntValue(None, "OBF_BodyCustom", index)
		if index == 1
			SetMenuOptionValue(option, "Custom bodies")
			ShowMessage("In OCreatures Reforged's own ini set bBody=0 so it leaves female werewolf bodies alone, then run the game once. Beast Form never edits that file.", false, "OK", "OK")
		else
			SetMenuOptionValue(option, "OCR's bodies")
		endif
	else
		int i = DutyOfOption(option)
		if i >= 0
			string d = OBF_Detect.DutyName(i)
			OBF_Detect.SetMode(d, index)
			SetMenuOptionValue(option, OBF_Detect.ModeText(index))
			if i == 0
				M().RegisterKeys()
			endif
			if index == 1 && OBF_Detect.OCRActive()
				ShowMessage("OCreatures is installed. With 'Always ours' both systems may do this duty at the same time.", false, "OK", "OK")
			endif
			ForcePageReset()
		endif
	endif
EndEvent

Event OnOptionSliderOpen(int option)
	if option == oidRounds
		SetSliderDialogStartValue(BL().MaxRounds as float)
		SetSliderDialogDefaultValue(5.0)
		SetSliderDialogRange(1.0, 10.0)
		SetSliderDialogInterval(1.0)
	elseif option == oidRadius
		SetSliderDialogStartValue(M().SearchRadius)
		SetSliderDialogDefaultValue(200.0)
		SetSliderDialogRange(100.0, 500.0)
		SetSliderDialogInterval(25.0)
	elseif option == oidFeedHours
		SetSliderDialogStartValue(M().FeedHours)
		SetSliderDialogDefaultValue(0.25)
		SetSliderDialogRange(0.0, 2.0)
		SetSliderDialogInterval(0.05)
	elseif option == oidFeedCap
		SetSliderDialogStartValue(M().FeedCapHours)
		SetSliderDialogDefaultValue(2.0)
		SetSliderDialogRange(0.25, 6.0)
		SetSliderDialogInterval(0.25)
	endif
EndEvent

Event OnOptionSliderAccept(int option, float value)
	if option == oidRounds
		BL().MaxRounds = value as int
		SetSliderOptionValue(option, value, "{0}")
	elseif option == oidRadius
		M().SearchRadius = value
		SetSliderOptionValue(option, value, "{0} units")
	elseif option == oidFeedHours
		M().FeedHours = value
		SetSliderOptionValue(option, value, "{2} h")
	elseif option == oidFeedCap
		M().FeedCapHours = value
		SetSliderOptionValue(option, value, "{2} h")
	endif
EndEvent

Event OnOptionHighlight(int option)
	if option == oidLog
		SetInfoText("ON (default): OStim Beast Form writes its own log, Data/SKSE/Plugins/OStimBeastForm.log (MO2: overwrite/SKSE/Plugins). Each game load: version, core, what was found, race and scene checks; then beast scenes, climaxes and loads, beast-form changes. Attach it to bug reports. Needs PapyrusUtil.")
	elseif option == oidKey
		SetInfoText("In werewolf or werebear form, out of combat: aim at an adult NPC and press this to start an OStim scene. Default: Up Arrow (new games; an existing save keeps the key it had). It can share a key with OStim's own hotkey. Remap or unbind it here.")
	elseif option == oidGuardAll
		SetInfoText("Also pause the beast-form timer when a scene is started some other way (OStim key, OStimNet/SkyrimNet) while you're a werewolf. Hotkey scenes are always guarded.")
	elseif option == oidStopCombat
		SetInfoText("If you're flagged in combat (common in beast form), try to clear it first. Scenes still refuse if combat continues.")
	elseif option == oidBL
		SetInfoText("When a male werewolf, werebear or Vampire Lord climaxes, add the cum OCum skips for creature scenes (footjobs, handjobs, outside finishes, vaginal/anal overlays). Uses OCum's own textures and cleanup timer.")
	elseif option == oidHuge
		SetInfoText("Werewolves and werebears only: heaviest textures on chest, belly, butt and legs, full Tull/Liquid set, and the beast never runs dry. Vaginal and anal finishes stay inside and never reach the face. Vampire Lords get a normal load.")
	elseif option == oidMesh
		SetInfoText("Wear Tull Animated Creampie / Liquid Pack meshes for as long as OCum's cum textures last, even if OCum's own meshes are off.")
	elseif option == oidStack
		SetInfoText("If the scene keeps going after he cums, every climax adds more: heavier layers on each area and more Tull/Liquid meshes, up to the max rounds. Cleared together by OCum's timer or a bath.")
	elseif option == oidRounds
		SetInfoText("How many climaxes keep adding coverage. After this it stays at full.")
	elseif option == oidShot
		SetInfoText("Play OCum's cum-shot spurts on footjob, handjob and outside finishes, which OCum skips when a creature scene is tagged as sex.")
	elseif option == oidRadius
		SetInfoText("If nothing is under the crosshair, pick the nearest valid NPC in front of you within this distance.")
	elseif option == oidBearAsWolf
		SetInfoText("Werebears count as werewolves in OStim, so every werewolf scene can play on them (same skeleton and animations; bigger body, so expect some clipping). Off: werebears are their own 'Werebear' actor type, for packs that add werebear scenes (none exist yet).")
	elseif option == oidGesture
		SetInfoText("Off by default. On: tap the start key to start a scene, hold it and press an arrow key to start from that category, double tap to also bring the nearest follower. Use a start key that is not an arrow key. Adults only; the same checks apply. Movement controls are never disabled.")
	elseif option == oidFights
		SetInfoText("While your scene runs, other fighters who are attacking the people in it stand down, then resume when it ends (only if they and their target are still alive and loaded). Off by default. Skipped when OCreatures owns this duty.")
	elseif option == oidFeedHours
		SetInfoText("Each climax in your scene adds this much to your remaining beast-form time while the timer is paused. 0 turns it off.")
	elseif option == oidFeedCap
		SetInfoText("Feeding stops adding once the remaining time reaches this many hours. It never shortens time you already have.")
	elseif option == oidSizeOn
		SetInfoText("Off by default. Scales the male beast's genital bones while a scene runs and puts them back when it ends. Visual size only: whether PPA follows this was not verified in game. Needs RaceMenu's NiOverride. Skipped when another system owns the size duty.")
	elseif option == oidSizeGlobal
		SetInfoText("Size used for every male werewolf, werebear and vampire lord unless a kind below says otherwise. M is the normal size. Steps come from sizes.json.")
	elseif option == oidSizeWolf || option == oidSizeBear || option == oidSizeVamp
		SetInfoText("Size for this kind only. 'Use the global size' follows the global step.")
	elseif option == oidSizeVar
		SetInfoText("A small fixed offset per actor, the same every time for the same actor in this save. Nothing is stored per actor.")
	elseif option == oidBodyPrio
		SetInfoText("Only matters with OCreatures Reforged. 'Custom bodies' records that you want the bodies at the stock paths (a body pack, TWO, or your own) instead of OCR's female werewolf body. It cannot change OCR: set bBody=0 in OCR's own ini. Beast Form reads that ini once per load and tells you if it is still bBody=1.")
	else
		int i = DutyOfOption(option)
		if i >= 0
			SetInfoText("Auto: Beast Form does this unless OCreatures or another mod owns it. Always ours: Beast Form does it anyway. Never ours: Beast Form does not do it.")
		endif
	endif
EndEvent
