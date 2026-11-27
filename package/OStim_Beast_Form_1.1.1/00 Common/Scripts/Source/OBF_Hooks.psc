Scriptname OBF_Hooks Hidden
{OStim Beast Form 1.1.0 - ModEvents we send for other mods. That Guy (Coronerra).
Fired only when something happened; never periodic. Listen with RegisterForModEvent("OBF_SceneStart", "OnBeastSceneStart"), handler
signature (string eventName, string strArg, float numArg, Form sender). See Docs/OStim Beast Form/Extension_Guide.txt.
Events: OBF_Ready, OBF_SceneStart, OBF_SceneEnd, OBF_TimerPaused, OBF_TimerResumed, OBF_Feed, OBF_SizeChanged, OBF_BodyReport, OBF_StateChanged.}

Function Fire(string eventName, string s, float n, Form sender) global
	int h = ModEvent.Create(eventName)
	if h
		ModEvent.PushString(h, s)
		ModEvent.PushFloat(h, n)
		ModEvent.PushForm(h, sender)
		ModEvent.Send(h)
	endif
EndFunction
