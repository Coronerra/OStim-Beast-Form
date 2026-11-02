Scriptname OBF_PlayerAlias extends ReferenceAlias

Event OnPlayerLoadGame()
	(GetOwningQuest() as OBF_Main).Maintenance()
EndEvent
