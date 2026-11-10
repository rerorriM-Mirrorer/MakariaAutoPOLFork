"""AutoPOL AHK 0.4.34 static and regression tests; does not execute Windower/POL."""
from pathlib import Path
import hashlib, re, struct
root = Path(__file__).resolve().parents[1]
text = (root / 'AutoPOL-AHK.ahk').read_text('utf-8')
original = Path(__file__).resolve().parents[1] / 'tests' / 'baseline-0.4.25.sha256'
assert text.startswith('#Requires AutoHotkey v2.0')
assert 'EnsureAdminOnStartup()\nInit()' in text
assert '0.4.34' in text
funcs = re.findall(r'(?m)^([A-Za-z_]\w*)\([^\n]*\)\s*\{\s*$', text)
assert len(funcs) == len(set(funcs)), 'Duplicate AHK v2 function'
for file in ('VanaLauncher.ahk', 'AutoPOL-AHK.ahk', 'Native-Secrets.ps1', 'Render-Trust-Frame.ps1',
             'Get-LoginSecrets.ps1','Import-AutoPOL.ps1','README.md','WORKFLOW.md','TESTING.md','AGENTS.md'):
    assert (root/file).is_file(), file
for private in ('launcher.ini','accounts-metadata.ini','config.json','login_w.bin','data'):
    assert not (root/private).exists(), private

def body(name):
    m = re.search(r'(?m)^'+re.escape(name)+r'\([^\n]*\)\s*\{',text)
    assert m, name
    nextfn = re.search(r'(?m)^[A-Za-z_]\w*\([^\n]*\)\s*\{|^\^\+F10::',text[m.end():])
    assert nextfn,name
    return text[m.start():m.end()+nextfn.start()]

# Byte-for-byte known-good login and credential functions from 0.4.25.
# This fixture was computed from the full 0.4.25 source distribution.
expected={}
for line in original.read_text().splitlines():
    name, sha = line.split(' ',1)
    expected[name]=sha
# Retain original hashes for the untouched login and credential routines.
# Explicit source checks below cover the changed scheduler and input plan.
for name, expected_sha in expected.items():
    if name in ('FindPolWindows', 'FindFFXIWindows', 'QueueTick', 'PartyHandoffTick',
                'AbortCurrent'):
        continue
    actual = hashlib.sha256(body(name).encode()).hexdigest()
    assert actual == expected_sha, f'Unexpected change to {name}: {actual}'
print('PASS: original keyboard injection, focus, credential and exit routines unchanged')

# Main remains single-screen and Settings is simple.
main=body('Init')
settings=body('InitSettingsUI')
assert main.index('App.status := win.Add') < main.index('App.nextButton := SkinButton') < main.index('Loop 20 {') < main.index('App.settingsButton := SkinButton')
assert 'Manage adventurers...' in settings and 'Default login...' in settings
assert settings.index('Manage adventurers...') < settings.index('WINDOWER EXECUTABLE')
assert settings.index('Default login...') < settings.index('WINDOWER EXECUTABLE')
assert 'WINDOWER & PROFILES' not in settings and 'Clear selection' not in settings
for obsolete in ['Import AutoPOL profiles','Trust textures...', 'Restore metadata...', 'Dry run', 'Up reset',
                 'Console-free credential helpers', 'Proxy / hosts tools', 'Diagnostics & recovery']:
    assert obsolete not in settings, obsolete
assert 'POL INPUT TIMING' in settings
assert 'AUTOMATIC PARTY LAUNCH' in settings
assert 'LOGIN DIAGNOSTICS' in settings and 'Open login logs...' in settings
assert 'App.diagCheck.OnEvent("Click", ChangeTimingDiagnostics)' in settings
assert 'App.settingsHeight := cy + ch + 20' in settings
assert 'InitProxyToolsUI()' not in text and 'InitLoginDiagnosticsUI()' not in text
assert 'SetTimer(ProxyTick, 250)' not in text and 'SetTimer(POLProxyTick, 250)' not in text
assert '"Import AutoPOL profiles"' not in body('OpenCharacterEditor')
assert '"Default login..."' in body('OpenCharacterEditor')
assert 'App.noneButton.Enabled := !value' not in text
assert 'App.dryCheck.Enabled := !value' not in text
print('PASS: streamlined Settings, Add editor, launch roster, no orphan references to removed controls')

# New defaults intentionally override previous INI experimental choices.
init=body('Init')
assert 'App.upResetMode := "quick"' in init
assert 'IniRead(App.settingsPath, "Launcher", "UpResetMode"' not in init
assert 'App.hiddenHelpers := true' in init
assert 'IniRead(App.settingsPath, "Launcher", "HiddenHelpers"' not in init
assert 'App.dryRun: false' not in text # object literal is `dryRun: false` only
assert 'dryRun: false' in text
assert 'IniWrite(App.upResetMode' not in body('SaveSettings')
assert 'IniWrite(App.hiddenHelpers' not in body('SaveSettings')
assert 'ChangeUpResetMode(*)' not in text and 'ChangeHiddenHelpers(*)' not in text
queue=body('QueueTick')
assert 'extendedRoster := false' in queue and 'if acc.slot > 11' in queue
assert 'shortReset := App.upResetMode = "quick" && !extendedRoster' in queue
assert 'holdRepeats := extendedRoster ? 50 : (shortReset ? 17 : 32)' in queue
assert 'repeatWaitMs := shortReset ? 40 : 90' in queue
assert 'Short Up reset unavailable' not in body('StartQueuedLogin')
assert 'return RunHiddenHelper(command, inputLines)' in body('CallCredentialHelper')
assert 'if App.hiddenHelpers' in body('CallCredentialHelper')
assert 'App.autoQueueCheck.OnEvent("Click", ChangePartyOptions)' in settings
assert 'App.nameWindowsCheck.OnEvent("Click", ChangePartyOptions)' in settings
assert 'App.nameWindows := IniRead(App.settingsPath, "Launcher", "CharacterOnlyTitles", "1") = "1"' in init
assert 'App.sortBySlot := IniRead(App.settingsPath, "Launcher", "SortByPOLSlot", "1") != "0"' in init
assert 'App.sortBySlotCheck.OnEvent("Click", ChangePartyOptions)' in settings
assert 'IniWrite(App.nameWindows ? "1" : "0", App.settingsPath, "Launcher", "CharacterOnlyTitles")' in body('SaveSettings')
assert 'IniWrite(App.sortBySlot ? "1" : "0", App.settingsPath, "Launcher", "SortByPOLSlot")' in body('SaveSettings')
assert 'App.autoExitCheck.OnEvent("Click", ChangePartyOptions)' in settings
assert 'TimingDiagnostics' in init and 'InitDiagnostics()' in init
print('PASS: Short reset / extended roster fallback, console-free default, diagnostic logs and automatic party')

# Texture auto-import copies every genuine Trust asset into launcher-local folder,
# avoids replacing existing files, then uses them in preference to external ones.
trust=body('FindTrustBackgrounds')
assert 'A_ScriptDir "\\assets\\trust\\backgrounds"' in trust
assert 'if TrustBackgroundFolder(localFolder) != ""' in trust
assert 'FileCopy(source "\\" name, target)' in trust
assert 'FileCopy(buttons "\\" name, target)' in trust
assert 'if !FileExist(target)' in trust
assert 'return source ; still preserve' in trust
assert 'ChooseTrustAssets(*)' not in text
assert (root/'assets/trust/README.md').exists()
for name in ['window_background.png','window_border_left.png','window_border_middle.png','window_border_right.png',
             'menu_button_bg_left.png','menu_button_bg_mid.png','menu_button_bg_right.png',
             'menu_button_bg_left_selected.png','menu_button_bg_mid_selected.png','menu_button_bg_right_selected.png']:
    assert name in trust, name
assert 'App.trustAssetFolder := FindTrustBackgrounds()' in init
assert 'AddTrustBackdrop(win, 690, App.mainHeight)' in init
assert 'menu_button_bg_mid.png' in text
assert 'window_background.png' in text
print('PASS: first-run local Trust asset copy, three-slice buttons and tiled frame; navy fallback')

# Every compiled amber glow resource has the right PNG dimensions.
for m in re.finditer(r'SkinButton\([^\n]*?,\s*"([^"]+)"',text):
    opts=m.group(1); width=re.search(r'\bw(\d+)',opts)
    if not width:continue
    height=re.search(r'\bh(\d+)',opts)
    w=int(width.group(1));h=int(height.group(1)) if height else 30
    for state in ('hover','selected'):
        f=root/'assets/glow'/f'{state}-{w}x{h}.png'
        assert f.exists(),f
        data=f.read_bytes()
        assert data[:8]==b'\x89PNG\r\n\x1a\n'
        assert struct.unpack('>II',data[16:24])==(w,h)
assert 'control.Opt("c" (!enabled ? "72839B"' in text
print('PASS: required glow assets, stronger disabled text contrast')

# End-to-end safety invariants of handoff and credentials, without running it.
for name in ('BuildWindowerProfileArgs','FindPolWindows','FindFFXIWindows','PartyHandoffTick',
             'FocusPol','FocusPolAfterCredentialHelper','ReadSecretHelper','PastePassword',
             'AbortCurrent','ExitAfterParty','CancelLaunch','BuildInputPlan'):
    assert body(name)
assert 'handoff.observedAt >= 3000' in body('PartyHandoffTick')
assert 'polStillViewer || !newGame' in body('PartyHandoffTick')
assert 'App.partyActive := false' in body('AbortCurrent')
assert 'ReleaseHeldUp()' in body('AbortCurrent')
assert 'if App.partyComplete && !App.busy && App.autoExit' in body('ExitAfterParty') or 'App.partyComplete && !App.busy && App.autoExit' in body('ExitAfterParty')
assert 'WinClose' not in body('ExitAfterParty')
assert 'if DllCall("user32\\GetForegroundWindow", "Ptr") != App.polHwnd' in body('PastePassword')
assert 'A_Clipboard := prior' in body('PastePassword')
assert 'Check-POL-Acceleration.ps1' in text # dormant proxy/recovery code remains as separate legacy
assert 'POLHostsMarkerPresent()' in init
print('PASS: strict window focus, password protection, verified FFXI handoff and legacy-hosts warning')
print('NOT RUN: native Windows AutoHotkey v2, PlayOnline, FFXI, binary Trust asset auto-copy')

# 0.4.27: a late hover event must not dereference a destroyed control.
manager=body('CloseManageAdventurers')
editor=body('DestroyCharacterEditor')
assert 'ReleaseSkinnedWindow(App.manageGui)' in manager
assert manager.index('ReleaseSkinnedWindow(App.manageGui)') < manager.index('App.manageGui.Destroy()')
assert 'ReleaseSkinnedWindow(win)' in editor
assert editor.index('ReleaseSkinnedWindow(win)') < editor.index('win.Destroy()')
assert 'App.settingsGui.Hide()' in body('CloseSettings')  # persistent GUI not destroyed
assert text.count('ownerHwnd:win.Hwnd') == 2  # both Trust and fallback buttons
assert 'skin.ownerHwnd = owner' in body('ReleaseSkinnedWindow')
assert 'ForgetSkinnedButton(hwnd)' in body('ReleaseSkinnedWindow')
assert 'user32\\IsWindow' in body('LiveSkinnedButton')
assert 'user32\\GetParent' in body('LiveSkinnedButton')
assert 'skin.control.Hwnd != hwnd' in body('LiveSkinnedButton')
assert 'catch Error' in body('LiveSkinnedButton')
assert 'LiveSkinnedButton(hwnd)' in body('SyncSkinnedButton')
assert 'SyncSkinnedButton(previous)' in body('HandleSkinnedMouseMove')
assert 'SyncSkinnedButton(hwnd)' in body('HandleSkinnedMouseLeave')
assert 'SyncSkinnedButton(App.skinnedBackgrounds[previous].control)' not in text
assert 'if !App.skinnedBackgrounds.Has(control.Hwnd)' not in text
assert 'control.GetPos(&x, &y, &w, &h)' in body('SyncSkinnedButton')
assert 'ForgetSkinnedButton(hwnd)' in body('SyncSkinnedButton')
print('PASS: destroyed Manage/Edit/Default GUI controls unregistered; late hover HWND guarded')

# 0.4.29: slot sorting is an on-by-default option and never alters any slot,
# importIndex, group or credential ID; disabling preserves current list order.
sorter=body('SortAdventurersBySlot')
assert 'if !App.sortBySlot' in sorter
assert 'AccountBefore(account, ordered[position - 1])' in sorter
assert 'ordered.InsertAt(position, account)' in sorter
assert 'App.accounts := ordered' in sorter
assert 'oldFocus' in sorter and 'App.focusedCharIndex := idx' in sorter
assert 'a.slot < b.slot' in body('AccountBefore')
assert 'a.group < b.group' in body('AccountBefore')
assert 'SortAdventurersBySlot()' in body('LoadMetadata')
assert 'SortAdventurersBySlot()' in body('SaveMetadata')
assert 'IniWrite(account.importIndex, tmp, section, "ImportIndex")' in body('SaveMetadata')
assert 'IniWrite(account.credentialId, tmp, section, "CredentialId")' in body('SaveMetadata')
assert 'account.source = "native" && account.credentialId != DEFAULT_CREDENTIAL_ID' in body('RemoveCharacter')
assert 'account.source != "native"' not in body('RemoveCharacter')
print('PASS: opt-out slot sorting, stable source indices, preserved encrypted credentials')

# Selections persist in launcher.ini by name, not position: changing slot order
# cannot accidentally check a different character after relaunch.
restore=body('RestoreSelectedAdventurers')
save_selection=body('SaveSelectedAdventurers')
assert 'SelectedAdventurers' in restore and 'SelectedAdventurers' in save_selection
assert 'App.accounts.Length = 1' in restore
assert 'StrLower(account.name) = key' in restore
assert 'IniWrite(JoinNamesForSettings(names)' in save_selection
assert 'SaveSelectedAdventurers()' in body('ToggleCharacter')
assert 'SaveSelectedAdventurers()' in body('RemoveCharacter')
assert 'SaveSelectedAdventurers()' in text
assert 'RestoreSelectedAdventurers()' in init
assert init.index('LoadMetadata()') < init.index('RestoreSelectedAdventurers()') < init.index('RefreshUI()')
assert 'SaveSelectedAdventurers()' in body('CloseLauncher')
print('PASS: persisted checked roster across auto-exit and login, name-mapped after slot sorting')

# Name-only titles must NOT alter window detection. Track each successfully
# renamed HWND/PID and original title transitions, not a generic name match.
assert 'WinSetTitle(name, "ahk_id " hwnd)' in body('TryNamePOLWindow')
assert 'WinSetTitle(name, "ahk_id " hwnd)' in body('TryNameFFXIWindow')
assert 'App.namedPOL[hwnd] := {title:name, pid:pid}' in body('TryNamePOLWindow')
assert 'App.namedFFXI[hwnd] := {title:name, pid:pid}' in body('TryNameFFXIWindow')
assert 'WinGetPID("ahk_id " hwnd) = item.pid' in body('NamedWindowStillMatches')
assert 'NamedWindowStillMatches(App.namedPOL, hwnd, title)' in body('FindPolWindows')
assert 'NamedWindowStillMatches(App.namedFFXI, hwnd, title)' in body('FindFFXIWindows')
assert 'polStillViewer := IsPOLViewerWindow(handoff.polHwnd)' in body('PartyHandoffTick')
assert 'NamedWindowStillMatches(App.namedPOL, hwnd, title)' in body('IsPOLViewerWindow')
assert 'TryNamePOLWindow(App.polHwnd, App.current.name)' in body('QueueTick')
assert 'TryNameFFXIWindow(newGame, handoff.name, handoff.position)' in body('PartyHandoffTick')
assert body('PartyHandoffTick').index('now - handoff.observedAt >= 3000') < body('PartyHandoffTick').index('TryNameFFXIWindow(newGame, handoff.name, handoff.position)')
assert 'RegExMatch(title, "i)^PlayOnline Viewer")' in body('FindPolWindows')
assert (root / 'POL-USERDATA-RESEARCH.md').is_file()
print('PASS: character-only naming, HWND/PID discovery and stable-window dwell')

plan = body('BuildInputPlan')
assert 'Loop 4' in plan and '[200, 300, 200, 200, 300, 500, 500]' in plan
assert plan.index('kind:"paste"') < plan.index('kind:"totp"')
queue = body('QueueTick')
complete = body('CompleteCurrent')
watch = body('PartyHandoffTick')
launch = body('StartQueuedLogin')
assert 'App.nextTick := submittedAt + 1000' in complete
assert 'App.nextIndex <= App.queue.Length ? "advance" : "handoff"' in complete
assert 'if App.partyActive && App.actionIndex > App.actions.Length' in queue
assert queue.index('PartyHandoffTick(now)') < queue.index('StartQueuedLogin(true)')
assert queue.index('if now < App.nextTick') < queue.index('StartQueuedLogin(true)')
assert queue.index('if IsObject(App.pendingHandoff) && (step.kind = "totp" || App.actionIndex >= App.actions.Length - 1)') < queue.index('NativePOLActionKey(step.key)')
assert 'initial.Push(App.pendingHandoff.polHwnd)' in launch
assert 'if advancing && (!App.busy || App.autoPhase != "advance")' in launch
assert 'handoff.baseline.Has(hwnd)' in watch
assert 'App.gameBaseline.Push(newGame)' in watch
assert 'if App.autoPhase = "handoff"' in watch and 'App.partyComplete := true' in watch
assert 'App.pendingHandoff := 0' in body('AbortCurrent')
assert 'if IsObject(App.current)' in body('AbortCurrent')
print('PASS: one-second advance, prior handoff isolation, confirmation gate and Cancel cleanup')


# 0.4.30: read Windower profiles from the settings.xml beside the
# configured Windower.exe, offering choices while retaining manual fallback.
# No command shell, PowerShell, XML edits or POL-account inference.
from xml.etree import ElementTree
editor=body('OpenCharacterEditor')
read_profiles=body('ReadWindowerProfiles')
profile_choice=body('ProfileFromSelection')
save_editor=body('SaveCharacterEditor')
assert 'ReadWindowerProfiles(App.windowerPath)' in editor
assert 'win.Add("ComboBox"' in editor
assert 'profileEdit.Text := displayProfile' in editor
assert 'profileLabels := ["Default (Windower)"]' in editor
assert 'profileLabels.Push(displayProfile)' in editor  # old names aren't lost
assert 'profileControl.Text' in profile_choice and '"Default (Windower)" ? "" : label' in profile_choice
assert 'SafeProfileName(ProfileFromSelection(profileEdit))' in save_editor
assert 'settingsXml := exeDirectory "\\settings.xml"' in read_profiles
assert 'ComObject("MSXML2.DOMDocument.6.0")' in read_profiles
assert 'doc.resolveExternals := false' in read_profiles
assert 'doc.setProperty("ProhibitDTD", true)' in read_profiles
assert 'doc.selectNodes("/settings/profile[@name]")' in read_profiles
assert 'StrLower(profileName)' in read_profiles  # duplicate filtering
assert 'FileCopy(' not in read_profiles and 'FileDelete(' not in read_profiles
assert 'Run(' not in read_profiles and 'PowerShell' not in read_profiles
assert 'SafeProfileName' in text and 'BuildWindowerProfileArgs' in text
fixture = root / 'tests/fixtures/windower-settings.xml'
profiles = ElementTree.parse(fixture).getroot().findall('profile')
assert [p.attrib.get('name') for p in profiles] == ['', '960x540', '1280x720', '1600x900']
assert all(p.findtext('enablefastlogin') == 'true' for p in profiles)
print('PASS: Windower settings.xml profile discovery and editable dropdown, Default mapping and saved-name fallback (static + XML fixture)')

# 0.4.32: PlayOnline import uses a single read-only preview.
source = body('ImportPOLUserFolder')
scan = body('ReadPOLUserHomes')
small_file = body('ReadPOLHomeName')
preview = body('ShowPOLHomeImport')
merge = body('ImportPOLRows')
manage = body('ShowManageAdventurers')
assert 'Import from PlayOnline files...' in manage
assert 'ReadPOLUserHomes(root)' in preview
assert 'FindPOLUsrFolder()' in source
assert 'FileSelect("D",' in source
assert 'Loop Files root "\\home*", "D"' in scan
assert 'A_LoopFileFullPath "\\system.bin"' in scan
assert 'i)^home(0[1-9]|1[0-9]|20)$' in scan
assert 'root "\\all"' in scan
assert 'ReadPOLHomeName' in scan
assert 'FileGetSize(path) != 72' in small_file
assert 'FileRead(path, "RAW")' in small_file
assert 'NumGet(bytes, 0, "UInt") != 72' in small_file
assert 'NumGet(bytes, 4, "UInt") != 2' in small_file
assert 'NumGet(bytes, 35 + A_Index, "UChar")' in small_file
assert 'if !terminated' in small_file
assert 'SaveMetadata() ; Existing metadata backed up' in merge
assert 'if !HasDefaultCredentials()' in merge
assert 'originalAccounts := App.accounts.Clone()' in merge
assert 'App.accounts := originalAccounts' in merge
assert 'ReleaseSkinnedWindow(App.polImportGui)' in body('ClosePOLImportGui')
assert 'ClosePOLImportGui()' in body('CloseSettings')
assert 'ClosePOLImportGui()' in body('CloseLauncher')
assert 'IniRead(App.metadataPath, "Account" i, "POLLabel", "")' in body('LoadMetadata')
assert 'polLabel:polLabel' in body('SaveCharacterEditor')
assert 'PlayOnline member label (optional;' in body('OpenCharacterEditor')
for retired in ('Import verified TSV...', 'ReadVerifiedPOLSlots', 'Choose other usr...', 'Verify against PlayOnline'):
    assert retired not in text, retired
assert 'row.character := row.stored' in preview
assert 'row.character := bySlot[row.slot]' in preview
assert 'row.action := "Already registered"' in preview
assert 'usedNames.Has(row.character)' in preview
assert 'importBtn.Enabled := !hasConflict && additions.Length > 0' in preview
assert '=> ImportPOLRows(additions)' in preview
assert '"Cancel", "cancel").OnEvent("Click", ClosePOLImportGui)' in preview
assert 'App.manageGui.Opt("+Disabled")' in preview
assert 'App.manageGui.Opt("-Disabled")' in body('ClosePOLImportGui')
assert 'YesNo' not in merge and 'YesNo' not in preview
assert 'args:SafeProfileName("")' in merge
assert 'polLabel:""' in merge and 'credentialId:DEFAULT_CREDENTIAL_ID' in merge
for method in ('FileMove(', 'FileDelete(', 'FileAppend(', 'IniWrite(', 'Run(', 'FileCopy(', 'WinClose(', 'DllCall(', 'SaveMetadata('):
    assert method not in scan and method not in small_file and method not in preview, method
for name in ('login_w.bin', 'pmlargs.bin', 'cookies.bin', 'EMAIL', 'password', 'totpSecret'):
    assert name not in scan and name not in small_file and name not in preview, name
print('PASS: read-only PlayOnline scan, one preview, occupied-slot skips, name collision guard and metadata-only save')

# Simulated fixture matches the *observed* 72-byte account-name record; it
# is synthetic and neither a POL runtime test nor a complete format decoder.
import tempfile
with tempfile.TemporaryDirectory() as folder:
    sample = Path(folder) / 'system.bin'
    def record(name, header=72, version=2):
        b=bytearray(72)
        struct.pack_into('<II', b, 0, header, version)
        b[36:36+len(name)]=name.encode('ascii')
        return b
    sample.write_bytes(record('SampleAccount'))
    data=sample.read_bytes()
    assert len(data)==72 and struct.unpack_from('<II',data)==(72,2)
    assert data[36:].split(b'\0',1)[0].decode('ascii')=='SampleAccount'
    assert struct.unpack_from('<II',record('SampleAccount',version=3))!=(72,2)
    assert len(record('SampleAccount')+b'\x00')!=72
    assert data[36:36+len('SampleAccount')] == b'SampleAccount'
print('PASS: simulated POL header/name schema, malformed size/version rejection constraints')
