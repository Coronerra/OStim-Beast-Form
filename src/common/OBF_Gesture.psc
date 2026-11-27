Scriptname OBF_Gesture Hidden
{OStim Beast Form 1.1.0 - gesture start key helpers (default OFF in the MCM). That Guy (Coronerra).
Tap = normal start. Hold the key and press an arrow key = start a scene from that category. Double tap = also bring the nearest eligible follower.
The four arrow keys are registered only while the start key is held (OBF_Main) and are never used to disable player controls, so there is no control state to get stuck.
Category data: Data/SKSE/Plugins/StorageUtilData/OStimBeastForm/directions.json, per slot up/down/left/right: "<slot>_actions" (OStim action types, CSV) and "<slot>_label".
OStim has no call that lists the scenes that fit a set of actors, so repeating a category asks OStim for another random fitting scene and avoids the one just played.}

int Function SlotOfKey(int keyCode) global
	if keyCode == 200
		return 1 ; up
	elseif keyCode == 208
		return 2 ; down
	elseif keyCode == 203
		return 3 ; left
	elseif keyCode == 205
		return 4 ; right
	endif
	return 0
EndFunction

int Function KeyOfSlot(int slot) global
	if slot == 1
		return 200
	elseif slot == 2
		return 208
	elseif slot == 3
		return 203
	endif
	return 205
EndFunction

string Function SlotName(int slot) global
	if slot == 1
		return "up"
	elseif slot == 2
		return "down"
	elseif slot == 3
		return "left"
	endif
	return "right"
EndFunction

int Function SlotFromName(string s) global
	int i = 1
	while i <= 4
		if SlotName(i) == s
			return i
		endif
		i += 1
	endwhile
	return 0
EndFunction

string Function Actions(int slot) global
	string f = "OStimBeastForm/directions"
	if OBF_Log.HasPapyrusUtil() && JsonUtil.JsonExists(f)
		string s = JsonUtil.GetStringValue(f, SlotName(slot) + "_actions", "")
		if s != ""
			return s
		endif
	endif
	if slot == 1
		return "vaginalsex"
	elseif slot == 2
		return "analsex"
	elseif slot == 3
		return "blowjob,cunnilingus"
	endif
	return "handjob,footjob"
EndFunction

; shown in the MCM. A label that is still a GROK-WRITE marker (or empty) falls back to a neutral name.
string Function Label(int slot) global
	string f = "OStimBeastForm/directions"
	if OBF_Log.HasPapyrusUtil() && JsonUtil.JsonExists(f)
		string s = JsonUtil.GetStringValue(f, SlotName(slot) + "_label", "")
		if s != "" && StringUtil.Find(s, "[[") < 0
			return s
		endif
	endif
	return "Category " + slot + " (" + SlotName(slot) + " arrow)"
EndFunction

; a fitting scene for these actors in the slot's category, different from "avoid" when OStim has another
string Function PickScene(Actor[] actors, int slot, string avoid) global
	if slot < 1 || slot > 4
		return OLibrary.GetRandomScene(actors)
	endif
	string csv = Actions(slot)
	string first = ""
	int tries = 0
	while tries < 5
		string s = OLibrary.GetRandomSceneWithAnyActionCSV(actors, csv)
		if s != ""
			if s != avoid
				return s
			endif
			first = s
		endif
		tries += 1
	endwhile
	return first
EndFunction

; nearest teammate who could join: alive, loaded, free, adult by every check. "exclude" is the main partner. None if nobody fits.
Actor Function NearestFollower(Actor player, Actor exclude, float radius) global
	Actor[] found = MiscUtil.ScanCellNPCs(player, radius, None, true)
	if !found
		return None
	endif
	Actor best = None
	float bestDist = radius + 1.0
	int i = 0
	while i < found.Length
		Actor a = found[i]
		if a && a != player && a != exclude && a.IsPlayerTeammate() && !a.IsDead() && a.Is3DLoaded() && !a.IsDisabled() && !a.IsDeleted() && !a.IsInCombat() && !OActor.IsInOStim(a) && !OBF_Detect.IsMinor(a)
			float d = player.GetDistance(a)
			if d < bestDist
				best = a
				bestDist = d
			endif
		endif
		i += 1
	endwhile
	return best
EndFunction
