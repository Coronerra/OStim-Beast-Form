Scriptname OBF_Log Hidden
{OStim Beast Form 1.0.1 - own log file for bug reports: Data/SKSE/Plugins/OStimBeastForm.log (MO2: overwrite).
That Guy (Coronerra). Global functions only, no records, no polling. PapyrusUtil is a soft dependency:
without it nothing is written and nothing errors. The MCM toggle lives in StorageUtil (key OBF_LogOff),
so every script of the main file, the Softbody / Tullius patches and the Herm patch share it.
The file restarts after 10 game loads (counter in StorageUtilData/OStimBeastForm_log.json) and one
game load writes at most 2000 lines.}

string Function Version() global
	return "1.0.1"
EndFunction

string Function LogPath() global
	return "Data/SKSE/Plugins/OStimBeastForm.log"
EndFunction

bool Function HasPapyrusUtil() global
	return SKSE.GetPluginVersion("papyrusutil plugin") > 0
EndFunction

; file logging on: PapyrusUtil present and the MCM toggle "Write log file" not turned off
bool Function On() global
	return HasPapyrusUtil() && StorageUtil.GetIntValue(None, "OBF_LogOff", 0) == 0
EndFunction

Function SetOn(bool v) global
	If !HasPapyrusUtil()
		return
	EndIf
	If v
		StorageUtil.UnsetIntValue(None, "OBF_LogOff")
	Else
		StorageUtil.SetIntValue(None, "OBF_LogOff", 1)
	EndIf
EndFunction

; Papyrus.0.log (when Papyrus logging is on) + OStimBeastForm.log
Function Line(string tag, string s) global
	Debug.Trace("[" + tag + "] " + s)
	If !On()
		return
	EndIf
	int n = StorageUtil.AdjustIntValue(None, "OBF_LogLines", 1)
	If n > 2000
		return
	ElseIf n == 2000
		s += "\n[OBF] (2000 lines this game load: the rest only goes to Papyrus.0.log)"
	EndIf
	MiscUtil.WriteToFile(LogPath(), "[" + tag + "] " + s + "\n", true, true)
EndFunction

; once per game load (OBF_Main.Maintenance): new section, restart the file after 10 loads
Function Session(string core) global
	If !On()
		return
	EndIf
	StorageUtil.SetIntValue(None, "OBF_LogLines", 0)
	int n = JsonUtil.GetIntValue("OStimBeastForm_log", "session", 0) + 1
	bool fresh = n > 10 || !MiscUtil.FileExists(LogPath())
	If fresh
		n = 1
	EndIf
	JsonUtil.SetIntValue("OStimBeastForm_log", "session", n)
	JsonUtil.Save("OStimBeastForm_log")
	string h = "===== OStim Beast Form " + Version() + " (" + core + ") | game load " + n + " of 10 in this file | game time " + Utility.GameTimeToString(Utility.GetCurrentGameTime()) + " ====="
	MiscUtil.WriteToFile(LogPath(), h + "\n", !fresh, true)
EndFunction

bool Function Loaded(string plugin) global
	return Game.GetModByName(plugin) != 255 || Game.GetLightModByName(plugin) != 65535
EndFunction

string Function YesNo(bool b) global
	If b
		return "yes"
	EndIf
	return "no"
EndFunction

; "Name (race)" for log lines
string Function Who(Actor a) global
	If !a
		return "nobody"
	EndIf
	Race r = a.GetRace()
	string rn = "no race"
	If r
		rn = r.GetName()
	EndIf
	string sx = "M"
	If a.GetLeveledActorBase().GetSex() == 1
		sx = "F"
	EndIf
	return a.GetDisplayName() + " (" + rn + ", " + sx + ")"
EndFunction
