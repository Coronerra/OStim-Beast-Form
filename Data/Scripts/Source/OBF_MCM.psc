Scriptname OBF_MCM extends SKI_ConfigBase

OBF_Main Property Main Auto

int oidKey
int oidGuardAll
int oidStopCombat
int oidRadius
int oidDebug

Event OnConfigInit()
	ModName = "OStim Beast Form"
	Pages = new string[1]
	Pages[0] = "Settings"
EndEvent

OBF_Main Function M()
	if !Main
		Main = (Self as Quest) as OBF_Main
	endif
	return Main
EndFunction

Event OnPageReset(string page)
	SetCursorFillMode(TOP_TO_BOTTOM)
	AddHeaderOption("Beast form scenes")
	oidKey = AddKeyMapOption("Start scene hotkey", M().StartKey, OPTION_FLAG_WITH_UNMAP)
	oidRadius = AddSliderOption("Fallback search radius", M().SearchRadius, "{0} units")
	oidStopCombat = AddToggleOption("Try StopCombat before starting", M().StopCombatOnStart)
	AddHeaderOption("Timer guard")
	oidGuardAll = AddToggleOption("Pause beast timer for ANY OStim scene", M().GuardAllScenes)
	oidDebug = AddToggleOption("Debug notifications", M().DebugMessages)
EndEvent

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
		M().SetStartKey(0)
		SetKeyMapOptionValue(oidKey, -1)
	endif
EndEvent

Event OnOptionSelect(int option)
	if option == oidGuardAll
		M().GuardAllScenes = !M().GuardAllScenes
		SetToggleOptionValue(option, M().GuardAllScenes)
	elseif option == oidStopCombat
		M().StopCombatOnStart = !M().StopCombatOnStart
		SetToggleOptionValue(option, M().StopCombatOnStart)
	elseif option == oidDebug
		M().DebugMessages = !M().DebugMessages
		SetToggleOptionValue(option, M().DebugMessages)
	endif
EndEvent

Event OnOptionSliderOpen(int option)
	if option == oidRadius
		SetSliderDialogStartValue(M().SearchRadius)
		SetSliderDialogDefaultValue(200.0)
		SetSliderDialogRange(100.0, 500.0)
		SetSliderDialogInterval(25.0)
	endif
EndEvent

Event OnOptionSliderAccept(int option, float value)
	if option == oidRadius
		M().SearchRadius = value
		SetSliderOptionValue(option, value, "{0} units")
	endif
EndEvent

Event OnOptionHighlight(int option)
	if option == oidKey
		SetInfoText("In werewolf beast form, out of combat: aim at an adult NPC and press this to start an OStim scene. Unbound by default.")
	elseif option == oidGuardAll
		SetInfoText("Also pause the beast-form timer when a scene is started some other way (OStim key, OStimNet/SkyrimNet) while you're a werewolf. Hotkey scenes are always guarded.")
	elseif option == oidStopCombat
		SetInfoText("If you're flagged in combat (common in beast form), try to clear it first. Scenes still refuse if combat continues.")
	elseif option == oidRadius
		SetInfoText("If nothing is under the crosshair, pick the nearest valid NPC in front of you within this distance.")
	endif
EndEvent
