Scriptname NiOverride Hidden
{Compile-only stub (not shipped). The real script belongs to RaceMenu.}
int Function GetNumBodyOverlays() native global
int Function GetNumHandOverlays() native global
int Function GetNumFeetOverlays() native global
int Function GetNumFaceOverlays() native global
string Function GetNodeOverrideString(ObjectReference ref, bool isFemale, string node, int key, int index) native global
bool Function HasOverlays(ObjectReference ref) native global
Function AddOverlays(ObjectReference ref) native global
Function ApplyNodeOverrides(ObjectReference ref) native global

; RaceMenu NiOverride node transforms (signatures from RaceMenu's NiOverride.psc), added for the Beast Form box compile
Function AddNodeTransformPosition(ObjectReference akRef, bool firstPerson, bool isFemale, string nodeName, string key, float[] position) native global
Function AddNodeTransformRotation(ObjectReference akRef, bool firstPerson, bool isFemale, string nodeName, string key, float[] rotation) native global
Function UpdateNodeTransform(ObjectReference akRef, bool firstPerson, bool isFemale, string nodeName) native global
