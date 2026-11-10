"""Offline source checks only. No AutoHotkey/POL execution."""
from pathlib import Path
import hashlib
p = Path(__file__).resolve().parents[1] / "AutoPOL-AHK.ahk"
raw = p.read_bytes()
s = raw.decode("utf-8-sig")
assert hashlib.sha256(raw).hexdigest() == "cdca63a2a1f68d7e9abffac17f9618fe2a1bece73ff490efa23ce602914f8e13", "Source differs from supplied 0.4.34 update"
assert s.startswith("#Requires AutoHotkey v2.0")
assert "AutoPOL AHK 0.4.34" in s
assert "EnsureAdminOnStartup()\nInit()" in s
input_plan = s.split("BuildInputPlan(slot, kind, hasTotp, holdRepeats, repeatWaitMs := 90) {", 1)[1].split("\n}",1)[0]
expected = ['Loop 4', 'result.Push({kind:"key", key:"a", wait:25})', 'result.Push({kind:"key", key:"{Backspace}", wait:25})', 'result.Push({kind:"paste", key:"", wait:300})']
cursor = 0
for fragment in expected:
    cursor = input_plan.index(fragment, cursor) + len(fragment)
assert cursor > 0, "Password paste preparation order changed"
assert 'if IsObject(App.pendingHandoff) && (step.kind = "totp" || App.actionIndex >= App.actions.Length - 1)' in s
assert 'now - handoff.observedAt >= 3000' in s
assert 'ClipboardAll()' in s and 'A_Clipboard := prior' in s
print("PASS: exact 0.4.34 AHK source SHA-256, password input order, handoff gate and clipboard restoration")
print("NOT RUN: complete-install check_package.py, AutoHotkey v2 runtime, POL or FFXI")
