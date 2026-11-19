#!/bin/bash
# usage: compile.sh outdir srcdir files...
out="$1"; shift; sd="$1"; shift
mkdir -p "$out"; cd "$sd"
/workspace/tools/caprica -g skyrim --ignorecwd -i "$sd" -i /workspace/skyrim/bf101/src/common -i /workspace/skyrim/release2/putil_imp -i /workspace/skyrim/bf081/imp/stub -i /workspace/skyrim/bf081/imp/ocum -i "/workspace/skyrim/billyy_v3/x/o/OStim Standalone 98163 7.5.1c 2026-10-22T06-08Z CmfxYjrFe/Scripts/Source" -i /workspace/skyrim/billyy_v3/x/o/SkyrimNet-GamePlugin-vbeta28/SkyrimNet-GamePlugin-vbeta28/Source/Scripts -i /workspace/skyrim/sleepambush/imports -f /workspace/skyrim/obdc/tools/TESV_Papyrus_Flags.flg -o "$out" "$@" 2>&1 | grep -v "^Adding import"
