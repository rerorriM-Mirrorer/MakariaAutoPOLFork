#Requires AutoHotkey v2.0
#SingleInstance Force

; AutoPOL AHK 0.4.34 — overlap Windower startup with the previous FFXI handoff.
; No automatic hosts-file modification, BlockInput, or POL binary rewriting.
; User-requested defaults: full login, dry run OFF, Short Up for standard rosters.
; Proxy UI is retired; legacy helpers remain solely for manual hosts recovery.
SetWorkingDir(A_ScriptDir)
SetTitleMatchMode(1)
SetKeyDelay(30, 30)

; Use a single timer-driven input sequence so the UI stays responsive.
; Retain a distinct current POL HWND for the entire input sequence.
global DEFAULT_CREDENTIAL_ID := "00000000-0000-4000-8000-000000000001"

global App := {
    gui: 0, settingsGui: 0, charButtons: [], selectedNames: Map(), focusedCharIndex: 0,
    namedPOL: Map(), namedFFXI: Map(), sortBySlot: true, sortBySlotCheck: 0,
    skinnedBackgrounds: Map(), hoveredSkinHwnd: 0, trustAssetFolder: "", trustPathField: 0, mainBackdrop: 0, mainHeight: 460, uiReady: false,
    settingsBackdrop: 0, settingsHeight: 395, loginDiagnosticsGui: 0, proxyToolsGui: 0, loginDiagnosticsHeight: 320, proxyToolsHeight: 510,
    addButton: 0, editButton: 0, removeButton: 0, settingsButton: 0, footerDivider: 0, manageGui: 0, managePicker: 0, polImportGui: 0,
    noneButton: 0, status: 0, details: 0,
    windowerField: 0, pacingControl: 0, pacing: "compatible", upResetControl: 0, upResetMode: "compatible", autoQueueCheck: 0, autoExitCheck: 0, autoQueue: false, autoExit: false, nameWindows: false, nameWindowsCheck: 0, partyActive: false, partyComplete: false, autoPhase: "", gameBaseline: [], pendingHandoff: 0, dryCheck: 0,
    nextButton: 0, cancelButton: 0, proxyStart: 0, proxyStop: 0, proxyStatus: 0,
    windowerPath: "", sourceConfig: "", settingsPath: A_ScriptDir "\launcher.ini",
    metadataPath: A_ScriptDir "\accounts-metadata.ini", credentialFolder: A_ScriptDir "\data\credentials",
    mode: "unknown", metadataHealthy: true, accounts: [], queue: [], nextIndex: 1,
    dryRun: false, hiddenHelpers: false, hiddenHelpersCheck: 0, busy: false, current: 0, actions: [], actionIndex: 1,
    nextTick: 0, deadline: 0, initialWindows: [], polHwnd: 0, lastWaitNotice: 0,
    upHeld: false, upOwner: 0, nativeAccepted: 0, targetIdentity: "", targetElevation: "unknown",
    lastError: "", secretPassword: "", hasTotp: false, pendingTotp: "",
    proxyPid: 0, proxyToken: "", proxyState: "stopped", proxyPort: 0, proxyRequests: 0,
    polProxyPid: 0, polProxyToken: "", polProxyState: "stopped", polProxyPort: 0, polProxyRequests: 0,
    polProxyStart: 0, polProxyStop: 0, polProxyRecover: 0, polProxyStatus: 0, polProxyCheck: 0, polProxyRegion: 0,
    polProxyStatusPath: A_ScriptDir "\data\pol-proxy-status.ini",
    polProxyStopPath: A_ScriptDir "\data\pol-proxy-stop.ini",
    proxyPath: A_ScriptDir "\data\proxy-status.ini", proxyStopPath: A_ScriptDir "\data\proxy-stop.ini",
    ; Per-run local timing recorder. Never record key values, clipboard,
    ; passwords, TOTP codes, full paths, window captions or account IDs.
    diagnosticsEnabled: true, diagCheck: 0, diagFolder: A_ScriptDir "\data\diagnostics",
    diagFile: "", diagStartTick: 0, diagLastActionTick: 0,
    diagPolDetectedAt: 0, diagInputStartedAt: 0,
    diagLaunchTick: 0, diagRequestTick: 0, diagActionBuffer: "", diagWriteError: false
}

EnsureAdminOnStartup()
Init()

; Full POL automation requires sufficient Windows integrity to inject keys into POL.
; Elevation is requested once at startup with Windows UAC, never silently.
; If denied, retain the GUI for import and dry-run, but block real login.
EnsureAdminOnStartup() {
    if A_IsAdmin
        return
    try {
        Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"', A_ScriptDir)
        ExitApp()
    } catch Error as err {
        MsgBox("Administrator approval was not granted. Actual POL automation requires restarting as administrator.", "POL login needs administrator access", "Icon!")
    }
}

; Shared FFXI-inspired colors for the main, Settings and character-editor
; windows. Keeps normal Win32 buttons for accessibility and keyboard access.
ApplyFFXITheme(win) {
    win.BackColor := "0E1B35"
    win.SetFont("s9 Norm cE8E3D8", "Segoe UI")
}

; Trust's FFXI UI uses a window background and three-slice BUTTONS as
; separate layers. ButtonItem.default() pairs 8px left/right caps with a
; repeated 84px middle strip. Highlighted buttons have their own six assets.
; Prefer the launcher-local copies; first use imports installed Trust PNGs without changing Trust.
TrustButtonFolder(backgrounds) {
    if backgrounds = ""
        return ""
    folder := RTrim(backgrounds, "\/") "\..\buttons"
    for filename in ["menu_button_bg_left.png", "menu_button_bg_mid.png", "menu_button_bg_right.png",
        "menu_button_bg_left_selected.png", "menu_button_bg_mid_selected.png", "menu_button_bg_right_selected.png"] {
        if !FileExist(folder "\" filename)
            return ""
    }
    return folder
}

TrustBackgroundFolder(path) {
    if path = ""
        return ""
    path := RTrim(path, "\/")
    for folder in [path, path "\backgrounds", path "\assets\backgrounds", path "\trust\assets\backgrounds", path "\addons\trust\assets\backgrounds"] {
        if FileExist(folder "\window_background.png") && TrustButtonFolder(folder) != ""
            return folder
    }
    return ""
}

FindTrustBackgrounds() {
    global App
    ; Trust assets are installed once into our own folder, independent of the
    ; Windower addon afterwards. Existing per-user Trust folders are never altered.
    localFolder := A_ScriptDir "\assets\trust\backgrounds"
    if TrustBackgroundFolder(localFolder) != ""
        return localFolder
    paths := []
    saved := IniRead(App.settingsPath, "Launcher", "TrustAssetsFolder", "")
    if saved != ""
        paths.Push(saved)
    if App.windowerPath != "" {
        SplitPath(App.windowerPath, , &winDir)
        paths.Push(winDir)
    }
    paths.Push(A_ScriptDir, A_ScriptDir "\..", A_ScriptDir "\..\..")
    for base in paths {
        if source := TrustBackgroundFolder(base) {
            ; Don't prevent the launcher opening if the drive is read-only.
            try {
                DirCreate(localFolder)
                DirCreate(A_ScriptDir "\assets\trust\buttons")
                for name in ["window_background.png", "window_border_left.png", "window_border_middle.png", "window_border_right.png"] {
                    target := localFolder "\" name
                    if !FileExist(target)
                        FileCopy(source "\" name, target)
                }
                buttons := TrustButtonFolder(source)
                for name in ["menu_button_bg_left.png", "menu_button_bg_mid.png", "menu_button_bg_right.png",
                    "menu_button_bg_left_selected.png", "menu_button_bg_mid_selected.png", "menu_button_bg_right_selected.png"] {
                    target := A_ScriptDir "\assets\trust\buttons\" name
                    if !FileExist(target)
                        FileCopy(buttons "\" name, target)
                }
            } catch Error {
                ; If files cannot be copied, keep reading the installed Trust assets.
            }
            if TrustBackgroundFolder(localFolder) != ""
                return localFolder
            return source ; still preserve the working external texture fallback
        }
    }
    return "" ; navy and gold fallback without an installed Trust addon
}

; Trust's window background is a tiny repeated image, not one stretched
; sprite. Generate a tiled PNG (plus the real three-part 3px borders) once
; per size and selected Trust folder. This is decorative and fail-open.
TrustFramePath(width, height) {
    global App
    if App.trustAssetFolder = "" || !FileExist(A_ScriptDir "\Render-Trust-Frame.ps1")
        return ""
    for required in ["window_background.png", "window_border_left.png", "window_border_middle.png", "window_border_right.png"] {
        if !FileExist(App.trustAssetFolder "\" required)
            return ""
    }
    checksum := 0
    Loop Parse, App.trustAssetFolder
        checksum := Mod(checksum * 33 + Ord(A_LoopField), 2147483647)
    cacheFolder := A_ScriptDir "\data\ui-cache"
    frame := cacheFolder "\trust-" checksum "-" width "x" height ".png"
    if FileExist(frame)
        return frame
    ps := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
    if !FileExist(ps)
        return ""
    DirCreate(cacheFolder)
    cmd := '"' ps '" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' A_ScriptDir '\Render-Trust-Frame.ps1" -AssetFolder "' App.trustAssetFolder '" -Width ' width ' -Height ' height ' -OutputPng "' frame '"'
    try RunWait(cmd, A_ScriptDir, "Hide")
    catch Error
        return ""
    return FileExist(frame) ? frame : ""
}

AddTrustBackdrop(win, width, height) {
    path := TrustFramePath(width, height)
    if path = ""
        return 0
    ; Insert before all foreground labels, inputs, and buttons so the frame
    ; cannot intercept their mouse events. Solid navy GUI remains fallback.
    return win.Add("Picture", "x0 y0 w" width " h" height, path)
}

ResizeTrustBackdrop(picture, width, height) {
    if !IsObject(picture)
        return
    path := TrustFramePath(width, height)
    if path != "" {
        picture.Value := path
        picture.Move(0, 0, width, height)
    }
}

; Create one click-receiving Text overlay above separate 8px caps and repeated
; 84px middle PNG pieces, rather than stretching menu background artwork.
; This is the same horizontal composition as Trust's ButtonCollectionViewCell.
; AHK Picture controls draw the native PNG pixels; SS_NOTIFY Text is clickable.
SkinButton(win, options, caption, role := "small", characterIndex := 0) {
    global App
    if !RegExMatch(options, "i)(?:^|\s)h\d+")
        options .= " h30"
    buttonFolder := TrustButtonFolder(App.trustAssetFolder)
    if buttonFolder != "" {
        selected := role = "launch" ; launch is always accented when actionable
        suffix := selected ? "_selected" : ""
        anchor := win.Add("Picture", options, buttonFolder "\menu_button_bg_left" suffix ".png")
        anchor.GetPos(&x, &y, &w, &h)
        ; Preserve the original control position for relative x+/y+ layout.
        ; Trust uses 8px caps and repeats the 84px center texture horizontally.
        leftWidth := Min(8, Floor(w / 2))
        middleWidth := Max(0, w - 2 * leftWidth)
        anchor.Move(x, y, leftWidth, h)
        pieces := [{image:anchor, dx:0, width:leftWidth, part:"left", currentPath:buttonFolder "\menu_button_bg_left" suffix ".png"}]
        offset := 0
        while offset < middleWidth {
            segment := Min(84, middleWidth - offset)
            mid := win.Add("Picture", "x" (x + leftWidth + offset) " y" y " w" segment " h" h (InStr(" " options, " Hidden") ? " Hidden" : ""),
                buttonFolder "\menu_button_bg_mid" suffix ".png")
            pieces.Push({image:mid, dx:leftWidth + offset, width:segment, part:"mid", currentPath:buttonFolder "\menu_button_bg_mid" suffix ".png"})
            offset += segment
        }
        right := win.Add("Picture", "x" (x + w - leftWidth) " y" y " w" leftWidth " h" h (InStr(" " options, " Hidden") ? " Hidden" : ""),
            buttonFolder "\menu_button_bg_right" suffix ".png")
        pieces.Push({image:right, dx:w - leftWidth, width:leftWidth, part:"right", currentPath:buttonFolder "\menu_button_bg_right" suffix ".png"})
        halo := AddButtonHalo(win, x, y, w, h, InStr(" " options, " Hidden") != 0)
        opt := "x" x " y" y " w" w " h" h " Center 0x200 +0x100 BackgroundTrans cEFE9DD"
        if InStr(" " options, " Hidden")
            opt .= " Hidden"
        if InStr(" " options, " Disabled")
            opt .= " Disabled"
        surface := win.Add("Text", opt, caption)
        App.skinnedBackgrounds[surface.Hwnd] := {control:surface, pieces:pieces, halo:halo, haloPath:"", role:role, index:characterIndex, folder:buttonFolder, ownerHwnd:win.Hwnd}
        return surface
    }
    ; Keep the non-Trust fallback dark and clickable, with the SAME hover halo.
    color := role = "launch" ? "2B4D72" : role = "cancel" ? "243A59" : "203957"
    bg := win.Add("Text", options " Background" color)
    bg.GetPos(&x, &y, &w, &h)
    halo := AddButtonHalo(win, x, y, w, h, InStr(" " options, " Hidden") != 0)
    opt := "x" x " y" y " w" w " h" h " Center 0x200 +0x100 BackgroundTrans cEFE9DD"
    if InStr(" " options, " Hidden")
        opt .= " Hidden"
    if InStr(" " options, " Disabled")
        opt .= " Disabled"
    surface := win.Add("Text", opt, caption)
    App.skinnedBackgrounds[surface.Hwnd] := {control:surface, pieces:[{image:bg, dx:0, width:w, part:"fallback", currentPath:""}], halo:halo, haloPath:"", role:role, index:characterIndex, folder:"", ownerHwnd:win.Hwnd}
    return surface
}

; This is an original transparent amber highlight, not a stretched Trust menu
; image. Pre-rendered PNGs cover every launcher button size, so hover needs no
; subprocesses or Win32 owner-draw code. The Text surface remains clickable.
GlowFile(width, height, hover := false) {
    kind := hover ? "hover" : "selected"
    path := A_ScriptDir "\assets\glow\" kind "-" width "x" height ".png"
    return FileExist(path) ? path : ""
}

AddButtonHalo(win, x, y, width, height, hidden := false) {
    path := GlowFile(width, height, false)
    if path = ""
        return 0
    ; The halo begins invisible for every button, even in Settings where no
    ; initial SyncSkinnedButton call happens until the pointer enters.
    return win.Add("Picture", "x" x " y" y " w" width " h" height " Hidden", path)
}

; Keep only live skin controls. A destroyed GUI can leave mouse events queued,
; and Windows can reuse its HWND. Never read an old Gui.Control.Hwnd getter
; during WM_MOUSEMOVE/LEAVE without checking the saved numeric HWND first.
ForgetSkinnedButton(hwnd) {
    global App
    if App.hoveredSkinHwnd = hwnd
        App.hoveredSkinHwnd := 0
    if App.skinnedBackgrounds.Has(hwnd)
        App.skinnedBackgrounds.Delete(hwnd)
}

LiveSkinnedButton(hwnd) {
    global App
    if !hwnd || !App.skinnedBackgrounds.Has(hwnd)
        return 0
    skin := App.skinnedBackgrounds[hwnd]
    ; A live control must still belong to the same live GUI that registered it.
    ; This also protects against an HWND reused by an unrelated window.
    if (!DllCall("user32\IsWindow", "Ptr", hwnd, "Int") || !DllCall("user32\IsWindow", "Ptr", skin.ownerHwnd, "Int")
        || DllCall("user32\GetParent", "Ptr", hwnd, "Ptr") != skin.ownerHwnd) {
        ForgetSkinnedButton(hwnd)
        return 0
    }
    try {
        if skin.control.Hwnd != hwnd {
            ForgetSkinnedButton(hwnd)
            return 0
        }
    } catch Error {
        ForgetSkinnedButton(hwnd)
        return 0
    }
    return skin
}

; Call this before destroying any temporary GUI, not just character editors.
; Settings itself is hidden and reused, so its controls remain registered.
ReleaseSkinnedWindow(win) {
    global App
    try owner := win.Hwnd
    catch Error
        return
    doomed := []
    for hwnd, skin in App.skinnedBackgrounds {
        if skin.ownerHwnd = owner
            doomed.Push(hwnd)
    }
    for _, hwnd in doomed
        ForgetSkinnedButton(hwnd)
}

; Windows TrackMouseEvent delivers WM_MOUSELEAVE without polling the cursor.
HandleSkinnedMouseMove(wParam, lParam, msg, hwnd) {
    global App
    record := LiveSkinnedButton(hwnd)
    if !IsObject(record)
        return
    try {
        if !record.control.Enabled || !record.control.Visible
            return
    } catch Error {
        ForgetSkinnedButton(hwnd)
        return
    }
    if App.hoveredSkinHwnd = hwnd
        return
    previous := App.hoveredSkinHwnd
    App.hoveredSkinHwnd := hwnd
    if previous
        SyncSkinnedButton(previous) ; numeric HWND, no destroyed-control getter
    SyncSkinnedButton(hwnd)
    tme := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
    NumPut("UInt", tme.Size, tme, 0)
    NumPut("UInt", 0x2, tme, 4) ; TME_LEAVE
    NumPut("Ptr", hwnd, tme, 8)
    DllCall("user32\TrackMouseEvent", "Ptr", tme.Ptr, "Int")
}

HandleSkinnedMouseLeave(wParam, lParam, msg, hwnd) {
    global App
    if App.hoveredSkinHwnd != hwnd
        return
    App.hoveredSkinHwnd := 0
    SyncSkinnedButton(hwnd) ; safe for late WM_MOUSELEAVE after GUI destruction
}

; Trust's amber fill = queued for launch. The outer glow is hover-only.
; Supports either a live Gui.Control or a saved numeric HWND, since hover
; events must never dereference stale GUI objects.
SyncSkinnedButton(controlOrHwnd) {
    global App
    try hwnd := IsObject(controlOrHwnd) ? controlOrHwnd.Hwnd : controlOrHwnd
    catch Error
        return
    skin := LiveSkinnedButton(hwnd)
    if !IsObject(skin)
        return
    control := skin.control
    try {
        control.GetPos(&x, &y, &w, &h)
        enabled := control.Enabled
        visible := control.Visible
    } catch Error {
        ForgetSkinnedButton(hwnd)
        return
    }
    chosen := skin.role = "launch" && enabled
    if skin.role = "character" && skin.index <= App.accounts.Length
        chosen := App.selectedNames.Has(StrLower(App.accounts[skin.index].name))
    hovered := App.hoveredSkinHwnd = hwnd && enabled
    suffix := chosen ? "_selected" : ""
    for piece in skin.pieces {
        picture := piece.image
        picture.Move(x + piece.dx, y, piece.width, h)
        picture.Visible := visible
        if piece.part = "fallback"
            continue
        path := skin.folder "\menu_button_bg_" piece.part suffix ".png"
        if piece.currentPath != path {
            picture.Value := path
            piece.currentPath := path
        }
    }
    if IsObject(skin.halo) {
        skin.halo.Move(x, y, w, h)
        active := enabled && visible && hovered
        if active {
            path := GlowFile(w, h, hovered)
            if path != "" {
                if skin.haloPath != path {
                    skin.halo.Value := path
                    skin.haloPath := path
                }
                skin.halo.Visible := true
            } else
                skin.halo.Visible := false
        } else
            skin.halo.Visible := false
    }
    try {
        control.Opt("c" (!enabled ? "72839B" : (chosen || hovered) ? "FFF0C9" : "EFE9DD"))
        control.Redraw()
    } catch Error {
        ; The owner may have been destroyed while a late hover redraw arrived.
        ForgetSkinnedButton(hwnd)
    }
}

ToggleCharacter(index, *) {
    global App
    if App.busy || index > App.accounts.Length
        return
    name := App.accounts[index].name
    key := StrLower(name)
    App.focusedCharIndex := index ; independent edit/removal focus; does not control queued selection
    if App.selectedNames.Has(key)
        App.selectedNames.Delete(key)
    else
        App.selectedNames[key] := true
    RefreshCharacterButtons()
    UpdateSelectionQueue()
    SaveSelectedAdventurers()
    DiagEvent("roster_toggle", "roster_index=" index " checked=" (App.selectedNames.Has(key) ? 1 : 0))
}

RefreshCharacterButtons() {
    global App
    for i, control in App.charButtons {
        if i <= App.accounts.Length {
            name := App.accounts[i].name
            control.Text := (App.selectedNames.Has(StrLower(name)) ? "✓  " : "○  ") name
            control.Visible := true
            control.Enabled := !App.busy
            SyncSkinnedButton(control)
        } else {
            control.Visible := false
            SyncSkinnedButton(control)
        }
    }
}

PositionCharacterFooter() {
    global App
    rows := Max(1, Ceil(App.accounts.Length / 2))
    top := 179 + rows * 61 + 13
    App.footerDivider.Move(22, top - 12, 646, 2)
    App.settingsButton.Move(517, top, 151, 40)
    SyncSkinnedButton(App.settingsButton)
    App.mainHeight := top + 65
    if App.uiReady {
        ResizeTrustBackdrop(App.mainBackdrop, 690, App.mainHeight)
        App.gui.Show("w690 h" App.mainHeight " NA")
    }
}

; This recorder stores timings and *operation classes* only. It never
; accesses password, clipboard or generated TOTP values. Per-action records
; are buffered until a phase boundary to avoid disk I/O between keypresses.
InitDiagnostics() {
    global App
    App.diagStartTick := A_TickCount
    App.diagActionBuffer := ""
    App.diagLastActionTick := 0
    if !App.diagnosticsEnabled
        return
    try {
        DirCreate(App.diagFolder)
        App.diagFile := App.diagFolder "\login-" FormatTime(A_Now, "yyyyMMdd-HHmmss") "-" DllCall("kernel32\GetCurrentProcessId", "UInt") ".tsv"
        FileAppend("wall_time`telapsed_ms`tevent`tdetails`n", App.diagFile, "UTF-8")
        DiagEvent("session_start", "version=0.4.34 pacing=" App.pacing " up_reset=" App.upResetMode " automatic_party=" (App.autoQueue ? 1 : 0) " auto_exit=" (App.autoExit ? 1 : 0) " window_labels=" (App.nameWindows ? 1 : 0))
    } catch Error {
        ; Log file errors must NEVER prevent working POL logins.
        App.diagWriteError := true
        App.diagFile := ""
    }
}

DiagPhase(phase) {
    ; Only known literal states, never user-supplied window or account text.
    return phase = "handoff" ? "handoff" : phase = "advance" ? "advance" : "input"
}

DiagEvent(event, details := "") {
    global App
    if !App.diagnosticsEnabled || App.diagFile = ""
        return
    try {
        ; event/details are fixed numeric or internal enum fields authored here.
        FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") "`t" (A_TickCount - App.diagStartTick) "`t" event "`t" details "`n", App.diagFile, "UTF-8")
    } catch Error {
        App.diagWriteError := true
    }
}

FlushActionDiagnostics() {
    global App
    if App.diagActionBuffer = ""
        return
    if App.diagnosticsEnabled && App.diagFile != "" {
        try FileAppend(App.diagActionBuffer, App.diagFile, "UTF-8")
        catch Error
            App.diagWriteError := true
    }
    App.diagActionBuffer := ""
}

DiagnosticQueueTick(*) {
    global App
    if !App.busy {
        QueueTick()
        return
    }
    beforeHwnd := App.polHwnd
    beforePlan := App.actions.Length
    beforeStep := App.actionIndex
    beforePosition := App.nextIndex
    stepClass := ""
    plannedWait := 0
    if beforePlan > 0 && beforeStep >= 1 && beforeStep <= beforePlan {
        step := App.actions[beforeStep]
        ; Never record key values, TOTP digits or password content.
        stepClass := step.kind
        plannedWait := PacedPOLWait(step)
    }
    callStarted := A_TickCount
    QueueTick()
    after := A_TickCount
    if !App.diagnosticsEnabled
        return
    if beforeHwnd = 0 && App.polHwnd != 0 {
        App.diagPolDetectedAt := after
        DiagEvent("pol_window_detected", "party_position=" beforePosition " since_windower_ms=" (after - App.diagLaunchTick))
    }
    if beforePlan = 0 && App.actions.Length > 0 {
        App.diagInputStartedAt := after
        App.diagLastActionTick := 0
        App.diagActionBuffer := ""
        DiagEvent("input_plan_ready", "party_position=" beforePosition " actions=" App.actions.Length " since_pol_ms=" (after - App.diagPolDetectedAt))
    }
    if stepClass != "" && App.actionIndex != beforeStep {
        ; One line per completed step, but write only after the plan/abort.
        ; Actual spacing exposes polling overhead and POL readiness costs.
        spacing := App.diagLastActionTick ? after - App.diagLastActionTick : 0
        App.diagLastActionTick := after
        App.diagActionBuffer .= FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") "`t" (after - App.diagStartTick) "`tinput_action`tparty_position=" beforePosition " step=" beforeStep " class=" stepClass " planned_wait_ms=" plannedWait " actual_spacing_ms=" spacing " call_ms=" (after - callStarted) "`n"
    }
    if beforePlan > 0 && (App.actions.Length = 0 || !App.busy) {
        FlushActionDiagnostics()
        DiagEvent("pol_input_finished", "party_position=" beforePosition " input_elapsed_ms=" (after - App.diagInputStartedAt))
    }
}

ChangeTimingDiagnostics(*) {
    global App
    if App.busy {
        App.diagCheck.Value := App.diagnosticsEnabled ? 1 : 0
        SetStatus("Finish or cancel the current login before changing timing diagnostics.")
        return
    }
    App.diagnosticsEnabled := App.diagCheck.Value = 1
    SaveSettings()
    if App.diagnosticsEnabled {
        if App.diagFile = ""
            InitDiagnostics()
        DiagEvent("diagnostics_enabled", "source=settings")
    } else {
        FlushActionDiagnostics()
        ; Don't call the logging helper after disabling diagnostics.
    }
    SetStatus(App.diagnosticsEnabled ? "Login timings will be saved under data\diagnostics. No passwords or TOTP values are logged." : "Login timing diagnostics disabled. You can enable them again in Settings.")
}

OpenTimingLogs(*) {
    global App
    try {
        DirCreate(App.diagFolder)
        Run('explorer.exe "' App.diagFolder '"')
    } catch Error {
        SetStatus("Unable to open login logs folder. Check the launcher installation directory.")
    }
}

Init() {
    global App
    App.windowerPath := IniRead(App.settingsPath, "Launcher", "WindowerPath", "")
    App.sourceConfig := IniRead(App.settingsPath, "Launcher", "AutoPOLConfigPath", "")
    App.pacing := IniRead(App.settingsPath, "Launcher", "LoginPacing", "compatible")
    if App.pacing != "fast"
        App.pacing := "compatible"
    App.upResetMode := "quick" ; Short for <=11; extended lists automatically retain longer proven schedule.
    App.autoQueue := IniRead(App.settingsPath, "Launcher", "AutomaticParty", "0") = "1"
    App.autoExit := IniRead(App.settingsPath, "Launcher", "ExitAfterParty", "0") = "1"
    ; 0.4.28 used a default-OFF NameWindows setting. Use a new key so
    ; upgrading enables the requested character-only titles once, while any
    ; future opt-out remains persistent. The old key is left untouched.
    App.nameWindows := IniRead(App.settingsPath, "Launcher", "CharacterOnlyTitles", "1") = "1"
    App.sortBySlot := IniRead(App.settingsPath, "Launcher", "SortByPOLSlot", "1") != "0"
    App.diagnosticsEnabled := IniRead(App.settingsPath, "Launcher", "TimingDiagnostics", "1") != "0"
    ; Franklet confirmed no flash and a successful login with the console-free pipe.
    App.hiddenHelpers := true
    InitDiagnostics()
    if (App.windowerPath = "" && FileExist(A_ScriptDir "\Windower.exe"))
        App.windowerPath := A_ScriptDir "\Windower.exe"
    LoadMetadata()
    RestoreSelectedAdventurers()
    App.trustAssetFolder := FindTrustBackgrounds()

    win := Gui("+MinSize690x300", "AutoPOL AHK — 0.4.30")
    App.gui := win
    ApplyFFXITheme(win)
    App.mainBackdrop := AddTrustBackdrop(win, 690, App.mainHeight)
    win.MarginX := 22
    win.MarginY := 16
    win.SetFont("s10 Norm cF0EEE6", "Segoe UI")
    ; Messaging is always above the launch controls, never below the roster.
    App.status := win.Add("Text", "x22 y16 w646 h51 Border Background192F54 cF0EEE6", "Ready. Choose the characters you want to launch.")
    App.details := win.Add("Text", "x22 y73 w646 h25 cB9C7DD", A_IsAdmin ? "Administrator access ready." : "Admin access required for automated login.")
    win.SetFont("s12 Bold", "Segoe UI")
    App.nextButton := SkinButton(win, "x22 y107 w421 h52 Disabled", "Launch", "launch")
    App.nextButton.OnEvent("Click", LaunchNext)
    App.cancelButton := SkinButton(win, "x456 y107 w212 h52 Disabled", "Cancel", "cancel")
    App.cancelButton.OnEvent("Click", CancelLaunch)
    ; Deliberately no decorative divider between launch and character rows.

    ; Two-column character tiles. Hidden unused slots allow native profiles and
    ; AutoPOL reimports without rebuilding the window or losing event handlers.
    win.SetFont("s11 Bold", "Segoe UI")
    Loop 20 {
        idx := A_Index
        col := Mod(idx - 1, 2)
        row := Floor((idx - 1) / 2)
        x := 22 + col * 328
        y := 179 + row * 61
        tile := SkinButton(win, "x" x " y" y " w318 h52 Hidden", "", "character", idx)
        tile.OnEvent("Click", ToggleCharacter.Bind(idx))
        App.charButtons.Push(tile)
    }
    win.SetFont("s10 Norm", "Segoe UI")
    App.footerDivider := win.Add("Text", "x22 y245 w646 h2 Hidden")
    ; All account management now lives under Settings. Keep the front screen
    ; focused on status, Launch/Cancel, character selection and one Settings button.
    App.settingsButton := SkinButton(win, "x517 y255 w151 h40", "Settings")
    App.settingsButton.OnEvent("Click", ShowSettings)

    RefreshUI()
    InitSettingsUI()
    OnMessage(0x200, HandleSkinnedMouseMove)
    OnMessage(0x2A3, HandleSkinnedMouseLeave)
    UpdateSelectionQueue(false)
    ResizeTrustBackdrop(App.mainBackdrop, 690, App.mainHeight)
    App.uiReady := true
    win.OnEvent("Close", CloseLauncher)
    win.Show("w690 h" App.mainHeight)
    SetTimer(DiagnosticQueueTick, 50)
    if POLHostsMarkerPresent() {
        SetStatus("Old AutoPOL AHK proxy hosts marker detected. Restore the Windows hosts file before logging in; see legacy recovery instructions in README.")
    }
}

; Everyday Settings only. Diagnostic logs remain available without another
; submenu; retired proxy, import, restoration, and test modes have no controls.
InitSettingsUI() {
    global App
    cfg := Gui("+Owner" App.gui.Hwnd, "AutoPOL AHK — Settings")
    App.settingsGui := cfg
    ApplyFFXITheme(cfg)
    App.settingsBackdrop := AddTrustBackdrop(cfg, 610, 540)
    cfg.MarginX := 20
    cfg.MarginY := 15
    cfg.SetFont("s14 Bold cE9D5A7", "Georgia")
    cfg.Add("Text", "xm y15 w560 h35 Center Border Background1B3158", "S E T T I N G S")
    cfg.SetFont("s9 Norm cE5EAF3", "Segoe UI")
    SkinButton(cfg, "xm y+12 w220 h34", "Manage adventurers...").OnEvent("Click", ShowManageAdventurers)
    SkinButton(cfg, "x+10 yp w185 h34", "Default login...").OnEvent("Click", (*) => ShowDefaultLogin(cfg))
    App.sortBySlotCheck := cfg.Add("CheckBox", "xm y+12 w555 cE7E5DC" (App.sortBySlot ? " Checked" : ""), "Sort adventurers by PlayOnline slot")
    App.sortBySlotCheck.OnEvent("Click", ChangePartyOptions)
    cfg.Add("Text", "xm y+15 w555 cE4C98D", "WINDOWER EXECUTABLE")
    App.windowerField := cfg.Add("Edit", "xm y+6 w425 ReadOnly Background162748 cF2ECDD", App.windowerPath)
    SkinButton(cfg, "x+8 yp-1 w122", "Browse...").OnEvent("Click", BrowseWindower)
    cfg.Add("Text", "xm y+16 w555 cE4C98D", "POL INPUT TIMING")
    App.pacingControl := cfg.Add("DropDownList", "xm y+6 w330 Choose" (App.pacing = "fast" ? 2 : 1) " c000000 BackgroundFFFFFF",
        ["Compatible", "Fast"])
    App.pacingControl.OnEvent("Change", ChangeLoginPacing)
    cfg.Add("Text", "xm y+16 w555 cE4C98D", "AUTOMATIC PARTY LAUNCH")
    App.autoQueueCheck := cfg.Add("CheckBox", "xm y+7 w555 cE7E5DC" (App.autoQueue ? " Checked" : ""), "Launch each checked character automatically")
    App.autoQueueCheck.OnEvent("Click", ChangePartyOptions)
    App.autoExitCheck := cfg.Add("CheckBox", "xm y+7 w555 cE7E5DC" (App.autoExit ? " Checked" : ""), "Close AutoPOL AHK when the final FFXI window is detected")
    App.autoExitCheck.OnEvent("Click", ChangePartyOptions)
    App.nameWindowsCheck := cfg.Add("CheckBox", "xm y+7 w555 cE7E5DC" (App.nameWindows ? " Checked" : ""), "Name PlayOnline and FFXI windows after the character")
    App.nameWindowsCheck.OnEvent("Click", ChangePartyOptions)
    cfg.Add("Text", "xm y+16 w555 cE4C98D", "LOGIN DIAGNOSTICS")
    App.diagCheck := cfg.Add("CheckBox", "xm y+7 w555 cE7E5DC" (App.diagnosticsEnabled ? " Checked" : ""),
        "Record login and handoff timings (no credentials)")
    App.diagCheck.OnEvent("Click", ChangeTimingDiagnostics)
    SkinButton(cfg, "xm y+10 w190 h32", "Open login logs...").OnEvent("Click", OpenTimingLogs)
    closeBtn := SkinButton(cfg, "xm y+16 w145 h32", "Close Settings")
    closeBtn.OnEvent("Click", CloseSettings)
    cfg.OnEvent("Close", CloseSettings)
    cfg.OnEvent("Escape", CloseSettings)
    closeBtn.GetPos(&cx, &cy, &cw, &ch)
    App.settingsHeight := cy + ch + 20
    ResizeTrustBackdrop(App.settingsBackdrop, 610, App.settingsHeight)
}

ShowSettings(*) {
    global App
    App.settingsGui.Show("w610 h" App.settingsHeight)
}

CloseSettings(*) {
    global App
    ClosePOLImportGui()
    CloseManageAdventurers()
    App.settingsGui.Hide()
    return true
}

CloseLauncher(*) {
    global App
    if App.busy {
        result := MsgBox("A POL input sequence is underway. Cancel it and close?", "AutoPOL AHK", "YesNo Icon?")
        if result != "Yes"
            return true
        AbortCurrent("Canceled while closing.")
    }
    ClosePOLImportGui()
    SaveSelectedAdventurers()
    StopProxyLab()
    StopPOLProxy(false)
    FlushActionDiagnostics()
    DiagEvent("launcher_exit", "party_complete=" (App.partyComplete ? 1 : 0))
    ExitApp()
}

; Metadata comes from a separate INI file, which is user-editable and can
; contain arbitrary strings. Validate before any number conversion so one
; malformed numeric field explains its section/key instead of crashing Integer().
MetadataUInt(section, key, fallback, maximum) {
    global App
    raw := Trim(IniRead(App.metadataPath, section, key, fallback))
    if !RegExMatch(raw, "^[0-9]{1,3}$")
        throw Error("Invalid numeric metadata at " section "." key "; expected an integer from 0 to " maximum ".")
    value := Number(raw)
    if value > maximum
        throw Error("Metadata " section "." key " is outside its allowed range (0-" maximum ").")
    return value
}

; Sort the *display and queue* by POL slot, then profile group and name.
; Never renumber slots or importIndex: those are real POL/credential mappings.
; A stable insertion sort is sufficient for the maximum 20 accounts, and
; avoids relying on locale-specific string Sort behavior.
AccountBefore(a, b) {
    if a.slot != b.slot
        return a.slot < b.slot
    if a.group != b.group
        return a.group < b.group
    return StrLower(a.name) < StrLower(b.name)
}

SortAdventurersBySlot() {
    global App
    if !App.sortBySlot
        return
    oldFocus := ""
    if App.focusedCharIndex > 0 && App.focusedCharIndex <= App.accounts.Length
        oldFocus := StrLower(App.accounts[App.focusedCharIndex].name)
    ordered := []
    for _, account in App.accounts {
        position := ordered.Length + 1
        while position > 1 && AccountBefore(account, ordered[position - 1])
            position -= 1
        ordered.InsertAt(position, account)
    }
    App.accounts := ordered
    App.focusedCharIndex := 0
    if oldFocus != "" {
        for idx, account in App.accounts {
            if StrLower(account.name) = oldFocus {
                App.focusedCharIndex := idx
                break
            }
        }
    }
}

LoadMetadata(strict := false) {
    global App
    App.accounts := []
    ; Reloaded files may have a different order: do not retain a stale
    ; index that would target another character in Manage Adventurers.
    App.focusedCharIndex := 0
    App.mode := "unknown"
    if !FileExist(App.metadataPath) {
        App.metadataHealthy := true
        return
    }
    try {
        App.mode := IniRead(App.metadataPath, "Metadata", "Mode", "unknown")
        count := MetadataUInt("Metadata", "AccountCount", "0", 20)
        if (count < 0 || count > 20)
            throw Error("Invalid account count")
        Loop count {
            i := A_Index
            name := IniRead(App.metadataPath, "Account" i, "Name", "")
            slot := MetadataUInt("Account" i, "Slot", "0", 20)
            group := MetadataUInt("Account" i, "Group", "0", 5)
            args := IniRead(App.metadataPath, "Account" i, "Args", "")
            polLabel := IniRead(App.metadataPath, "Account" i, "POLLabel", "")
            if (name = "" || slot < 1 || slot > 20 || group < 0 || group > 5)
                throw Error("Invalid metadata entry " i)
            source := IniRead(App.metadataPath, "Account" i, "Source", "import")
            if source != "import" && source != "native"
                throw Error("Unknown account source")
            credentialId := IniRead(App.metadataPath, "Account" i, "CredentialId", "")
            importIndex := MetadataUInt("Account" i, "ImportIndex", i, 20)
            if source = "native" && !RegExMatch(credentialId, "i)^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$")
                throw Error("Invalid saved credential reference")
            if source = "import" && (importIndex < 1 || importIndex > 20)
                throw Error("Invalid original account index")
            App.accounts.Push({name:name, polLabel:polLabel, slot:slot, group:group, args:args,
                source:source, credentialId:credentialId, importIndex:importIndex})
        }
        SortAdventurersBySlot()
        ; Presets were retired from the launcher in 0.4.11. Historic INIs
        ; sometimes contain blank/stale PresetCount and broken PresetN records.
        ; Neither is relevant to characters, so do not parse or validate them.
        App.metadataHealthy := true
    } catch Error as err {
        App.metadataHealthy := false
        App.accounts := []
        App.mode := "unknown"
        if strict
            throw Error(err.Message)
        MsgBox("Metadata could not be loaded:`n" err.Message "`n`nYour saved file is unchanged. Restore its .bak copy if needed.", "AutoPOL AHK", "Icon!")
    }
}

; The checked launch roster belongs to the user's launcher settings, not
; transient GUI controls. Store names (not array indices): resorting or editing
; a slot must never accidentally check a different account after restart.
; Names are POL launcher labels, not passwords or Square Enix identities.
RestoreSelectedAdventurers() {
    global App
    raw := IniRead(App.settingsPath, "Launcher", "SelectedAdventurers", "<unset>")
    selected := Map()
    if raw = "<unset>" {
        ; First upgrade / new install: a one-adventurer installation is ready
        ; to launch, but later intentional Clear Selection remains respected.
        if App.accounts.Length = 1
            selected[StrLower(App.accounts[1].name)] := true
    } else {
        for _, value in StrSplit(raw, "|") {
            key := StrLower(Trim(value))
            if key != "" {
                for _, account in App.accounts {
                    if StrLower(account.name) = key {
                        selected[key] := true
                        break
                    }
                }
            }
        }
    }
    App.selectedNames := selected
}

SaveSelectedAdventurers() {
    global App
    names := []
    for _, account in App.accounts {
        if App.selectedNames.Has(StrLower(account.name))
            names.Push(account.name)
    }
    try IniWrite(JoinNamesForSettings(names), App.settingsPath, "Launcher", "SelectedAdventurers")
    catch Error as err
        SetStatus("Could not save checked adventurers: " err.Message)
}

JoinNamesForSettings(names) {
    joined := ""
    for _, name in names
        joined .= (joined = "" ? "" : "|") name
    return joined
}

RefreshUI() {
    global App
    ; Visible selections survive native character updates and reimports by name.
    valid := Map()
    for _, account in App.accounts {
        key := StrLower(account.name)
        if App.selectedNames.Has(key)
            valid[key] := true
    }
    App.selectedNames := valid
    if App.focusedCharIndex > App.accounts.Length
        App.focusedCharIndex := 0
    RefreshCharacterButtons()
    PositionCharacterFooter()
}

SaveMetadata() {
    global App
    if !App.metadataHealthy
        throw Error("Saved profile metadata is unreadable. Restore its backup in Settings before modifying profiles.")
    ; Keep the queue and exported metadata in the same predictable slot order.
    ; Original importIndex/credential IDs never change when the array moves.
    SortAdventurersBySlot()
    ; Write a complete new file; never overwrite the original in place.
    ; INI holds character metadata only: NEVER passwords, seeds or TOTP codes.
    tmp := App.metadataPath ".writing"
    try {
        if FileExist(tmp)
            FileDelete(tmp)
        IniWrite(App.mode, tmp, "Metadata", "Mode")
        IniWrite(App.accounts.Length, tmp, "Metadata", "AccountCount")
        for i, account in App.accounts {
            section := "Account" i
            IniWrite(account.name, tmp, section, "Name")
            IniWrite(account.HasOwnProp("polLabel") ? account.polLabel : "", tmp, section, "POLLabel")
            IniWrite(account.slot, tmp, section, "Slot")
            IniWrite(account.group, tmp, section, "Group")
            IniWrite(account.args, tmp, section, "Args")
            IniWrite(account.source, tmp, section, "Source")
            IniWrite(account.credentialId, tmp, section, "CredentialId")
            IniWrite(account.importIndex, tmp, section, "ImportIndex")
        }
        if FileExist(App.metadataPath)
            FileCopy(App.metadataPath, App.metadataPath ".bak", 1)
        FileMove(tmp, App.metadataPath, 1)
    } catch Error as err {
        try FileDelete(tmp)
        throw Error("Could not save character metadata: " err.Message)
    }
}

; Account controls in a separate dialog let the launch screen stay minimal.
; The selection here is explicit rather than implicitly using the last tile
; clicked (which also toggles its launch checkbox).
ShowManageAdventurers(*) {
    global App
    if App.busy {
        SetStatus("Finish or cancel the current login before editing accounts.")
        return
    }
    if IsObject(App.polImportGui) {
        App.polImportGui.Show()
        return
    }
    CloseManageAdventurers()
    manager := Gui("+Owner" App.settingsGui.Hwnd, "AutoPOL AHK — Manage adventurers")
    App.manageGui := manager
    ApplyFFXITheme(manager)
    AddTrustBackdrop(manager, 510, 280)
    manager.MarginX := 20
    manager.MarginY := 15
    manager.SetFont("s11 Bold cE4C98D", "Georgia")
    manager.Add("Text", "x20 y18 w465 h27 Center", "M A N A G E   A D V E N T U R E R S")
    manager.SetFont("s9 Norm cE7E5DC", "Segoe UI")
    manager.Add("Text", "x20 y+14 w460", "Character to edit or remove:")
    choices := []
    for _, account in App.accounts
        choices.Push(account.name)
    if choices.Length = 0
        choices.Push("(no characters registered)")
    chosen := App.focusedCharIndex > 0 && App.focusedCharIndex <= App.accounts.Length ? App.focusedCharIndex : 1
    App.managePicker := manager.Add("DropDownList", "x20 y+7 w465 Choose" chosen " c000000 BackgroundFFFFFF", choices)
    SkinButton(manager, "x20 y+18 w146 h37", "Add").OnEvent("Click", ManageAddCharacter)
    editBtn := SkinButton(manager, "x179 yp w146 h37", "Edit")
    editBtn.OnEvent("Click", ManageEditCharacter)
    removeBtn := SkinButton(manager, "x338 yp w147 h37", "Remove")
    removeBtn.OnEvent("Click", ManageRemoveCharacter)
    if App.accounts.Length = 0 {
        editBtn.Enabled := false
        removeBtn.Enabled := false
    }
    SkinButton(manager, "x20 y+13 w465 h35", "Import from PlayOnline files...").OnEvent("Click", ImportPOLUserFolder)
    manager.Add("Text", "x20 y+8 w465 cB9C7DD", "Preview new registrations before adding them to the launcher.")
    manager.OnEvent("Close", CloseManageAdventurers)
    manager.OnEvent("Escape", CloseManageAdventurers)
    manager.Show("w510 h280")
}

CloseManageAdventurers(*) {
    global App
    if IsObject(App.manageGui) {
        ReleaseSkinnedWindow(App.manageGui)
        App.manageGui.Destroy()
        App.manageGui := 0
        App.managePicker := 0
    }
}

ManageAddCharacter(*) {
    CloseManageAdventurers()
    AddCharacter()
}

ManageEditCharacter(*) {
    global App
    if App.managePicker.Value < 1 || App.managePicker.Value > App.accounts.Length
        return
    App.focusedCharIndex := App.managePicker.Value
    CloseManageAdventurers()
    EditCharacter()
}

ManageRemoveCharacter(*) {
    global App
    if App.managePicker.Value < 1 || App.managePicker.Value > App.accounts.Length
        return
    App.focusedCharIndex := App.managePicker.Value
    CloseManageAdventurers()
    RemoveCharacter()
}


; Read PlayOnline's homeNN/system.bin files ONLY. Do not open all/login_w.bin,
; mail, cookies or other account state. Based on one observed POL usr archive:
; a 72-byte record with an account-related NUL-terminated ASCII name at 0x24.
; These names may be Square Enix account identifiers, NOT POL member labels.
; homeNN is a proposed slot, not proof of registration order.
FindPOLUsrFolder() {
    candidates := []
    try candidates.Push(EnvGet("ProgramFiles(x86)") "\PlayOnline\SquareEnix\PlayOnlineViewer\usr")
    candidates.Push(A_ProgramFiles "\PlayOnline\SquareEnix\PlayOnlineViewer\usr")
    for _, candidate in candidates {
        if DirExist(candidate) && FileExist(candidate "\home01\system.bin")
            return candidate
    }
    return ""
}

ReadPOLHomeName(path) {
    if FileGetSize(path) != 72
        throw Error("unsupported system.bin size")
    bytes := FileRead(path, "RAW")
    if bytes.Size != 72 || NumGet(bytes, 0, "UInt") != 72 || NumGet(bytes, 4, "UInt") != 2
        throw Error("unknown system.bin layout")
    name := ""
    terminated := false
    Loop 36 {
        value := NumGet(bytes, 35 + A_Index, "UChar")
        if value = 0 {
            terminated := true
            break
        }
        if value < 32 || value > 126
            throw Error("non-ASCII stored name")
        name .= Chr(value)
    }
    if !terminated || Trim(name) = "" || !RegExMatch(name, '^[A-Za-z0-9 _.-]{1,35}$')
        throw Error("missing or unsupported stored name")
    return name
}

ReadPOLUserHomes(root) {
    root := RTrim(root, "\/")
    if !DirExist(root) || !DirExist(root "\all")
        throw Error("Select the PlayOnlineViewer\usr directory containing all and homeNN folders.")
    rows := []
    found := Map()
    ; Loop directory names first; Windows wildcard matching does not reliably
    ; expand home* in the middle of a path like usr\home*\system.bin.
    Loop Files root "\home*", "D" {
        if !RegExMatch(A_LoopFileName, 'i)^home(0[1-9]|1[0-9]|20)$', &m)
            continue
        slot := Integer(m[1])
        if found.Has(slot) || !FileExist(A_LoopFileFullPath "\system.bin")
            continue
        ; Unknown versions are skipped rather than guessed; no file is modified.
        try storedName := ReadPOLHomeName(A_LoopFileFullPath "\system.bin")
        catch Error
            continue
        found[slot] := true
        rows.Push({slot:slot, stored:Trim(storedName)})
    }
    if rows.Length = 0
        throw Error("No supported home01-home20/system.bin records found. No data was imported.")
    ; Explicit numeric ordering independent of directory enumeration.
    Loop rows.Length {
        i := A_Index
        j := i
        while j > 1 && rows[j].slot < rows[j-1].slot {
            tmp := rows[j-1]
            rows[j-1] := rows[j]
            rows[j] := tmp
            j -= 1
        }
    }
    return rows
}

ImportPOLUserFolder(*) {
    global App
    if App.busy || IsObject(App.polImportGui)
        return
    if !App.metadataHealthy {
        MsgBox("Saved character metadata is unreadable. Import is blocked to protect your registrations.", "Import blocked", "Icon!")
        return
    }
    if App.mode = "group" {
        MsgBox("Multiple POL account banks are configured. homeNN folders cannot establish a unique bank and slot. Nothing changed.", "Import blocked", "Icon!")
        return
    }
    root := FindPOLUsrFolder()
    if root = "" {
        root := FileSelect("D", , "Choose PlayOnlineViewer\usr folder (read-only)")
        if root = ""
            return
    }
    ShowPOLHomeImport(root)
}

ShowPOLHomeImport(root) {
    global App
    try rows := ReadPOLUserHomes(root)
    catch Error as err {
        MsgBox(err.Message, "PlayOnline scan", "Icon!")
        return
    }
    bySlot := Map()
    usedNames := Map()
    usedNames.CaseSense := "Off"
    for _, account in App.accounts {
        if account.group = 0
            bySlot[account.slot] := account.name
        usedNames[account.name] := true
    }
    additions := []
    hasConflict := false
    for _, row in rows {
        if bySlot.Has(row.slot) {
            row.character := bySlot[row.slot]
            row.action := "Already registered"
        } else {
            row.character := row.stored
            if usedNames.Has(row.character) {
                row.action := "Name conflict"
                hasConflict := true
            } else {
                row.action := "Add"
                usedNames[row.character] := true
                additions.Push(row)
            }
        }
    }

    win := Gui("+Owner" App.manageGui.Hwnd, "AutoPOL AHK — Import from PlayOnline")
    App.polImportGui := win
    ApplyFFXITheme(win)
    win.MarginX := 18
    win.MarginY := 15
    win.SetFont("s12 Bold cE4C98D", "Georgia")
    win.Add("Text", "xm ym w556 h25 Center", "I M P O R T   F R O M   P L A Y O N L I N E")
    win.SetFont("s9 Norm cE7E5DC", "Segoe UI")
    win.Add("Text", "xm y+10 w556 h38", "New characters start with the stored account name, the Default Windower profile, and your saved Default login. You can edit them after import.")
    lv := win.Add("ListView", "xm y+6 w556 r9 NoSortHdr -Multi c000000 BackgroundFFFFFF", ["POL slot", "Character name", "Action"])
    for _, row in rows
        lv.Add(, row.slot, row.character, row.action)
    for colNo, colWidth in [76, 290, 156]
        lv.ModifyCol(colNo, colWidth)
    summary := hasConflict ? "Resolve duplicate character names in Manage adventurers before importing."
        : additions.Length = 0 ? "All detected slots are already registered."
        : additions.Length " new registration(s). Slot numbers come from the PlayOnline folders."
    win.Add("Text", "xm y+10 w556 h32 cB9C7DD", summary)
    importBtn := SkinButton(win, "xm y+6 w120 h36", "Import")
    importBtn.Enabled := !hasConflict && additions.Length > 0
    importBtn.OnEvent("Click", (*) => ImportPOLRows(additions))
    SkinButton(win, "x+10 yp w120 h36", "Cancel", "cancel").OnEvent("Click", ClosePOLImportGui)
    win.OnEvent("Close", ClosePOLImportGui)
    win.OnEvent("Escape", ClosePOLImportGui)
    App.manageGui.Opt("+Disabled")
    win.Show("AutoSize")
}

ImportPOLRows(additions) {
    global App, DEFAULT_CREDENTIAL_ID
    if !IsObject(App.polImportGui)
        return
    if App.busy || !App.metadataHealthy || App.mode = "group" {
        MsgBox("The launcher is busy, saved metadata is unreadable, or multiple account banks are configured.", "POL import blocked", "Icon!")
        return
    }
    if App.accounts.Length + additions.Length > 20 {
        MsgBox("The resulting roster would exceed 20 registrations.", "Import limit", "Icon!")
        return
    }
    if !HasDefaultCredentials() {
        MsgBox("Set Settings > Default login first. New registrations use that saved login.", "Default login needed", "Icon!")
        return
    }
    originalAccounts := App.accounts.Clone()
    originalMode := App.mode
    try {
        for _, row in additions {
            App.accounts.Push({name:row.character, polLabel:"",
                slot:row.slot, group:0, args:SafeProfileName(""),
                source:"native", credentialId:DEFAULT_CREDENTIAL_ID, importIndex:0})
        }
        if App.mode = "unknown"
            App.mode := "single"
        SaveMetadata() ; Existing metadata backed up and replaced atomically.
    } catch Error as err {
        App.accounts := originalAccounts
        App.mode := originalMode
        MsgBox("No registrations were committed: `n" err.Message, "POL import failed", "Icon!")
        return
    }
    RefreshUI()
    UpdateSelectionQueue(false)
    SaveSelectedAdventurers()
    ClosePOLImportGui()
    CloseManageAdventurers()
    SetStatus("Imported " additions.Length " PlayOnline registration(s).")
}

ClosePOLImportGui(*) {
    global App
    if IsObject(App.polImportGui) {
        if IsObject(App.manageGui)
            App.manageGui.Opt("-Disabled")
        ReleaseSkinnedWindow(App.polImportGui)
        try App.polImportGui.Destroy()
        App.polImportGui := 0
    }
}

HighlightedCharacter() {
    global App
    return App.focusedCharIndex ; most recently clicked character tile
}

AddCharacter(*) {
    global App
    if App.busy
        return
    if App.accounts.Length >= 20 {
        MsgBox("The launcher supports up to 20 registered accounts.", "Profile limit", "Icon!")
        return
    }
    OpenCharacterEditor(0)
}

EditCharacter(*) {
    global App
    if App.busy
        return
    idx := HighlightedCharacter()
    if idx = 0 {
        MsgBox("Click the character button first, then Edit. The last character you touched is the edit target.", "Choose a character", "Icon!")
        return
    }
    if App.accounts[idx].source = "import" {
        MsgBox("This profile is imported from AutoPOL. To avoid invalidating its account/password mapping, edits to imported profiles remain in AutoPOL for now.`n`nYou can add a separate native character profile here without modifying AutoPOL.", "Imported profile", "Iconi")
        return
    }
    OpenCharacterEditor(idx)
}

RemoveCharacter(*) {
    global App, DEFAULT_CREDENTIAL_ID
    if App.busy
        return
    idx := HighlightedCharacter()
    if idx = 0 {
        MsgBox("Click the character button first, then Remove. The last character you touched is the removal target.", "Choose a character", "Icon!")
        return
    }
    account := App.accounts[idx]
    if MsgBox("Remove " account.name " from AutoPOL AHK?`n`nOnly this launcher's registration is removed. POL account data, imported JSON, and any other character credentials are left untouched.", "Remove character", "YesNo Icon?") != "Yes"
        return
    oldAccounts := App.accounts.Clone()
    App.accounts.RemoveAt(idx)
    try {
        SaveMetadata()
    } catch Error as err {
        App.accounts := oldAccounts
        MsgBox(err.Message, "Remove failed", "Icon!")
        return
    }
    ; Metadata is committed first. Failure to delete leaves only encrypted
    ; orphan data, never a broken profile reference.
    if account.source = "native" && account.credentialId != DEFAULT_CREDENTIAL_ID
        try FileDelete(App.credentialFolder "\" account.credentialId ".bin")
    if App.selectedNames.Has(StrLower(account.name))
        App.selectedNames.Delete(StrLower(account.name))
    App.focusedCharIndex := 0
    RefreshUI()
    UpdateSelectionQueue(false)
    SaveSelectedAdventurers()
    SetStatus("Removed " account.name " from this launcher. POL and other character credentials are unchanged.")
}

; One CurrentUser-DPAPI credential is automatically inherited by new native
; characters whose password is blank. Imported AutoPOL JSON retains its own defaults.
HasDefaultCredentials() {
    global App, DEFAULT_CREDENTIAL_ID
    return !!FileExist(App.credentialFolder "\" DEFAULT_CREDENTIAL_ID ".bin")
}

ShowDefaultLogin(parentWindow := 0) {
    global App
    if !IsObject(parentWindow)
        parentWindow := App.settingsGui
    if App.busy {
        MsgBox("Finish the current launch before updating shared credentials.", "Login in progress", "Icon!")
        return
    }
    win := Gui("+Owner" parentWindow.Hwnd, "AutoPOL AHK — Default login")
    ApplyFFXITheme(win)
    AddTrustBackdrop(win, 470, 410)
    win.MarginX := 18
    win.MarginY := 14
    win.SetFont("s12 Bold cE9D5A7", "Georgia")
    win.Add("Text", "xm y14 w425 h32 Center Background1B3158", "DEFAULT LOGIN")
    win.SetFont("s9 Norm cE7E5DC", "Segoe UI")
    win.Add("Text", "xm y+10 w425 h46", "New native characters automatically inherit this password when their password field is blank. Imported AutoPOL accounts and saved character-specific passwords remain unchanged.")
    win.Add("Text", "xm y+10", "Shared POL password")
    pw := win.Add("Edit", "xm y+4 w340 Password c000000 BackgroundFFFFFF")
    win.Add("Text", "xm y+10", "Shared TOTP Base32 secret (optional)")
    seed := win.Add("Edit", "xm y+4 w340 Password c000000 BackgroundFFFFFF")
    win.Add("Text", "xm y+9 w425 h39 cB9C7DD", (HasDefaultCredentials() ? "A default is saved. Enter both fields to replace it; existing credentials cannot be displayed." : "No shared default saved yet.") " Stored encrypted for this Windows user.")
    SkinButton(win, "xm y+13 w173 h35", "Save default login").OnEvent("Click", (*) => SaveDefaultLogin(win, pw, seed))
    SkinButton(win, "x+12 yp w120 h35", "Cancel").OnEvent("Click", (*) => DestroyCharacterEditor(win))
    win.OnEvent("Close", (*) => DestroyCharacterEditor(win))
    win.OnEvent("Escape", (*) => DestroyCharacterEditor(win))
    win.Show("w465 h405")
}

SaveDefaultLogin(win, passwordEdit, totpEdit) {
    global DEFAULT_CREDENTIAL_ID
    password := passwordEdit.Value
    totp := Trim(totpEdit.Value)
    if password = "" {
        MsgBox("Enter the shared POL password to save or replace the default login.", "Password required", "Icon!")
        return
    }
    if totp != "" && !RegExMatch(totp, 'i)^[A-Z2-7 ]+=*$') {
        MsgBox("The TOTP value must be a Base32 secret, not the current six-digit code.", "Check TOTP", "Icon!")
        return
    }
    try {
        InvokeNativeSecretHelper("set-default", DEFAULT_CREDENTIAL_ID, [EncodeBase64(password), EncodeBase64(totp)])
        DestroyCharacterEditor(win)
        SetStatus("Shared default login saved securely. New native characters inherit its password when left blank.")
    } catch Error as err {
        MsgBox("Could not save default login: " err.Message, "Default unchanged", "Icon!")
    } finally {
        password := ""
        totp := ""
    }
}

OpenCharacterEditor(index) {
    global App, DEFAULT_CREDENTIAL_ID
    editing := index > 0
    previous := editing ? App.accounts[index] : 0
    win := Gui("+Owner" App.gui.Hwnd, editing ? "Edit character" : "Add character")
    ApplyFFXITheme(win)
    win.MarginX := 18
    win.MarginY := 14
    win.SetFont("s13 Bold cE9D5A7", "Georgia")
    win.Add("Text", "w430 Border Center Background1B3158 h36", editing ? "Edit " previous.name : "Register a new adventurer")
    win.SetFont("s9 Norm cE7E5DC", "Segoe UI")
    win.Add("Text", "xm y+12", "Character name")
    nameEdit := win.Add("Edit", "xm y+4 w330 c000000 BackgroundFFFFFF", editing ? previous.name : "")
    win.Add("Text", "xm y+11", "PlayOnline account slot (1–20)")
    slotEdit := win.Add("Edit", "xm y+4 w100 Number c000000 BackgroundFFFFFF", editing ? previous.slot : "")
    win.Add("Text", "xm y+11", "PlayOnline member label (optional; not used to select account)")
    polLabelEdit := win.Add("Edit", "xm y+4 w330 c000000 BackgroundFFFFFF", editing && previous.HasOwnProp("polLabel") ? previous.polLabel : "")
    ; Read current Windower profile names each time the editor opens.
    ; Editable ComboBox preserves manual entry if settings.xml is missing,
    ; and keeps a previously saved profile that no longer appears in the XML.
    currentProfile := editing ? ProfileFromArgs(previous.args) : ""
    availableProfiles := ReadWindowerProfiles(App.windowerPath)
    profileLabels := ["Default (Windower)"]
    for foundName in availableProfiles {
        if foundName != ""
            profileLabels.Push(foundName)
    }
    displayProfile := currentProfile = "" ? "Default (Windower)" : currentProfile
    foundSaved := false
    for candidate in profileLabels {
        if candidate = displayProfile {
            foundSaved := true
            break
        }
    }
    if !foundSaved
        profileLabels.Push(displayProfile)
    win.Add("Text", "xm y+11", "Windower profile")
    profileEdit := win.Add("ComboBox", "xm y+4 w330 c000000 BackgroundFFFFFF", profileLabels)
    profileEdit.Text := displayProfile
    if availableProfiles.Length > 0
        profileHelp := "Profiles loaded from Windower settings.xml; manual entry is also allowed."
    else
        profileHelp := "No Windower settings.xml found; type a name or choose Default."
    win.Add("Text", "xm y+5 w430 cB9C7DD", profileHelp)
    win.Add("Text", "xm y+13", "Login credentials")
    methods := ["Password blank = saved default; otherwise character-specific"]
    cloneIndices := []
    for i, acc in App.accounts {
        if acc.source = "import" {
            methods.Push("Copy saved login from AutoPOL profile: " acc.name " (slot " acc.slot ")")
            cloneIndices.Push(i)
        }
    }
    initialMethod := 1
    methodControl := win.Add("DropDownList", "xm y+5 w430 c000000 BackgroundFFFFFF Choose" initialMethod, methods)
    win.Add("Text", "xm y+8 w430 cB9C7DD", "Copying creates an encrypted local copy; it does not change AutoPOL.")
    win.Add("Text", "xm y+12", "POL password (blank = shared default for new character)")
    passwordEdit := win.Add("Edit", "xm y+4 w330 Password c000000 BackgroundFFFFFF")
    win.Add("Text", "xm y+11", "TOTP Base32 secret (optional; never the current 6-digit code)")
    totpEdit := win.Add("Edit", "xm y+4 w330 Password c000000 BackgroundFFFFFF")
    if editing
        win.Add("Text", "xm y+7 w430 cB9C7DD", "Editing: both fields blank keeps saved credentials. To change login, enter a new password or TOTP.")
    else
        win.Add("Text", "xm y+7 w430 cB9C7DD", "A blank password automatically uses Settings > Default login. A TOTP here overrides the default TOTP.")
    SkinButton(win, "xm y+15 w160 h30", "Save character").OnEvent("Click", (*) => SaveCharacterEditor(win, index, nameEdit, slotEdit, polLabelEdit, profileEdit, methodControl, cloneIndices, passwordEdit, totpEdit))
    SkinButton(win, "x+10 yp w115 h30", "Cancel").OnEvent("Click", (*) => DestroyCharacterEditor(win))
    if !editing {
        SkinButton(win, "xm y+12 w195 h34", "Default login...").OnEvent("Click", (*) => ShowDefaultLogin(win))
    }
    win.OnEvent("Close", (*) => DestroyCharacterEditor(win))
    win.OnEvent("Escape", (*) => DestroyCharacterEditor(win))
    win.Show("w470")
}

; Applies to both the Add/Edit editor and the Default Login dialog.
DestroyCharacterEditor(win) {
    ReleaseSkinnedWindow(win)
    try win.Destroy()
}

; Windower keeps its named launch profiles in settings.xml alongside
; Windower.exe. Only read this file: do not modify it or infer POL slots from it.
; COM/MSXML is included with Windows and does not require a PowerShell window.
ReadWindowerProfiles(windowerExe) {
    names := []
    if windowerExe = ""
        return names
    SplitPath(windowerExe, &exeName, &exeDirectory)
    if StrLower(exeName) != "windower.exe"
        return names
    settingsXml := exeDirectory "\settings.xml"
    if !FileExist(settingsXml)
        return names
    try {
        doc := ComObject("MSXML2.DOMDocument.6.0")
        doc.async := false
        doc.resolveExternals := false
        doc.validateOnParse := false
        doc.setProperty("ProhibitDTD", true)
        if !doc.load(settingsXml)
            return names
        nodes := doc.selectNodes("/settings/profile[@name]")
        seen := Map()
        Loop nodes.length {
            node := nodes.item(A_Index - 1)
            profileName := node.getAttribute("name") ""
            if profileName = "" ; The built-in default is always the first entry.
                continue
            if StrLen(profileName) > 120 || RegExMatch(profileName, '["\r\n]')
                continue
            key := StrLower(profileName)
            if !seen.Has(key) {
                seen[key] := true
                names.Push(profileName)
            }
        }
    } catch Error {
        ; A missing, malformed or inaccessible file must never block editing
        ; a character: the ComboBox remains editable with the existing name.
        return []
    }
    return names
}

; "Default (Windower)" is a friendly dropdown label, not a real profile name.
; Save the blank profile for Windower's -p "" argument as before.
ProfileFromSelection(profileControl) {
    label := Trim(profileControl.Text)
    return label = "Default (Windower)" ? "" : label
}

; Windower documents `-p <profile>` to skip its profile picker and
; launch PlayOnline directly. AutoPOL also historically stored `-p=Name`.
; Recognize both storage formats, but always produce the documented syntax.
ProfileFromArgs(args) {
    if RegExMatch(Trim(args), '^-p(?:=|\s+)(?:"([^"]*)"|([^\s"]+))$', &match)
        return match[1] != "" ? match[1] : match[2]
    return ""
}

SafeProfileName(value) {
    value := Trim(value)
    if StrLen(value) > 120 || RegExMatch(value, '["\r\n]')
        throw Error("Windower profile contains unsupported characters or is too long")
    ; The empty name is Windower's built-in Default profile. The -p flag
    ; must still be supplied, or Windower shows its interactive profile UI.
    return '-p "' value '"'
}

BuildWindowerProfileArgs(savedArgs) {
    savedArgs := Trim(savedArgs)
    if savedArgs = ""
        return SafeProfileName("")
    if !RegExMatch(savedArgs, '^-p(?:=|\s+)(?:"([^"]*)"|([^\s"]+))$', &match)
        throw Error("Unsupported Windower profile arguments. Edit the character to enter a profile name.")
    return SafeProfileName(match[1] != "" ? match[1] : match[2])
}

SaveCharacterEditor(win, index, nameEdit, slotEdit, polLabelEdit, profileEdit, methodControl, cloneIndices, passwordEdit, totpEdit) {
    global App, DEFAULT_CREDENTIAL_ID
    name := Trim(nameEdit.Value)
    if !RegExMatch(name, '^[^\r\n\[\]=;]{1,80}$') {
        MsgBox("Enter a valid character name (1–80 characters; no newlines or INI separators).", "Check character", "Icon!")
        return
    }
    slotText := Trim(slotEdit.Value)
    if !RegExMatch(slotText, '^(?:[1-9]|1[0-9]|20)$') {
        MsgBox("Enter the correct PlayOnline slot (1 to 20).", "Check POL slot", "Icon!")
        return
    }
    slot := Integer(slotText)
    polLabel := Trim(polLabelEdit.Value)
    if polLabel != "" && !RegExMatch(polLabel, '^[^\r\n\[\]=;]{1,80}$') {
        MsgBox("The POL member label must be 1–80 characters without INI separators.", "Check POL label", "Icon!")
        return
    }
    try args := SafeProfileName(ProfileFromSelection(profileEdit))
    catch Error as err {
        MsgBox(err.Message, "Check Windower profile", "Icon!")
        return
    }
    for i, acc in App.accounts {
        if i != index && StrLower(acc.name) = StrLower(name) {
            MsgBox("A profile named " name " already exists. Edit that profile or choose another name.", "Duplicate character", "Icon!")
            return
        }
    }
    duplicates := []
    for i, acc in App.accounts {
        if i != index && acc.slot = slot
            duplicates.Push(acc.name)
    }
    if duplicates.Length && MsgBox("POL slot " slot " is already used by " JoinNames(duplicates) ".`n`nIf both characters use the same POL account, this may be correct. Continue?", "Shared POL slot", "YesNo Icon?") != "Yes"
        return
    if App.mode = "group" {
        MsgBox("This configuration uses AutoPOL's multiple profile-group files. AutoPOL AHK currently supports native accounts only in single-profile mode; no POL files were changed.", "Profile groups unsupported", "Icon!")
        return
    }
    editing := index > 0
    oldAccount := editing ? App.accounts[index] : 0
    credentialId := editing ? oldAccount.credentialId : ""
    method := methodControl.Value
    password := passwordEdit.Value
    totp := Trim(totpEdit.Value)
    ; Adding: an empty password automatically inherits the shared default.
    ; Editing with *both* secret fields empty keeps the current login, so
    ; routine name/slot/profile edits cannot accidentally replace passwords.
    ; An entered TOTP with blank password uses default password + custom TOTP.
    if method = 1 && password = "" && (!editing || totp != "") && !HasDefaultCredentials() {
        MsgBox("Set the shared password in Settings > Default login, or enter this character's password.", "Shared password missing", "Icon!")
        return
    }
    if method = 1 && totp != "" && !RegExMatch(totp, 'i)^[A-Z2-7 ]+=*$') {
        MsgBox("TOTP must be a Base32 secret (letters A–Z and digits 2–7), not a six-digit generated code.", "Invalid TOTP key", "Icon!")
        return
    }
    newId := ""
    committed := false
    try {
        if method = 1 {
            if password = "" && totp = "" {
                if !editing
                    credentialId := DEFAULT_CREDENTIAL_ID
                ; Editing without replacement secrets preserves existing login.
            } else {
                newId := NewCredentialId()
                ; A blank password + nonblank TOTP is stored as an encrypted
                ; TOTP override. Native-Secrets resolves password dynamically
                ; from the shared default at login time.
                InvokeNativeSecretHelper("save", newId, [EncodeBase64(password), EncodeBase64(totp)])
                credentialId := newId
            }
        } else {
            newId := NewCredentialId()
            srcIdx := cloneIndices[method - 1]
            source := App.accounts[srcIdx]
            if !FileExist(App.sourceConfig)
                throw Error("The imported AutoPOL JSON is unavailable for copying. Import it again or enter credentials.")
            InvokeNativeSecretHelper("clone", newId, [EncodeBase64(source.name), source.slot ""], source.importIndex)
            credentialId := newId
        }
        newAccount := {name:name, polLabel:polLabel, slot:slot, group:0, args:args,
            source:"native", credentialId:credentialId, importIndex:0}
        if editing
            App.accounts[index] := newAccount
        else {
            App.accounts.Push(newAccount)
            index := App.accounts.Length
        }
        oldMode := App.mode
        if App.mode = "unknown"
            App.mode := "single"
        try SaveMetadata()
        catch Error as err {
            if editing
                App.accounts[index] := oldAccount
            else
                App.accounts.Pop()
            App.mode := oldMode
            throw err
        }
        committed := true
        if editing && oldAccount.credentialId != credentialId && oldAccount.credentialId != DEFAULT_CREDENTIAL_ID
            try FileDelete(App.credentialFolder "\" oldAccount.credentialId ".bin")
        DestroyCharacterEditor(win)
        if editing && StrLower(oldAccount.name) != StrLower(name) && App.selectedNames.Has(StrLower(oldAccount.name))
            App.selectedNames.Delete(StrLower(oldAccount.name))
        App.selectedNames[StrLower(name)] := true
        App.focusedCharIndex := index
        RefreshUI()
        UpdateSelectionQueue(false)
        SaveSelectedAdventurers()
        SetStatus((editing ? "Updated " : "Added ") name ". Selected and ready to launch.")
    } catch Error as err {
        if newId != "" && !committed
            try FileDelete(App.credentialFolder "\" newId ".bin")
        MsgBox("Unable to save character: " err.Message, "Profile not saved", "Icon!")
    } finally {
        password := ""
        totp := ""
    }
}

NewCredentialId() {
    guid := Buffer(16, 0)
    if DllCall("Ole32\CoCreateGuid", "Ptr", guid.Ptr, "Int") != 0
        throw Error("Could not allocate a credential reference")
    out := Buffer(80, 0)
    if !DllCall("Ole32\StringFromGUID2", "Ptr", guid.Ptr, "Ptr", out.Ptr, "Int", 40, "Int")
        throw Error("Could not format the credential reference")
    return StrLower(Trim(StrGet(out, "UTF-16"), "{}"))
}

EncodeBase64(value) {
    if value = ""
        return "" ; an absent optional TOTP seed is encoded as an empty line
    length := StrPut(value, "UTF-8") - 1
    raw := Buffer(length + 1, 0)
    StrPut(value, raw, "UTF-8")
    chars := 0
    flags := 0x40000001 ; Base64, no embedded CRLF
    if !DllCall("Crypt32\CryptBinaryToStringW", "Ptr", raw.Ptr, "UInt", length, "UInt", flags, "Ptr", 0, "UIntP", &chars)
        throw Error("Credential encoding failed")
    result := Buffer(chars * 2, 0)
    if !DllCall("Crypt32\CryptBinaryToStringW", "Ptr", raw.Ptr, "UInt", length, "UInt", flags, "Ptr", result.Ptr, "UIntP", &chars)
        throw Error("Credential encoding failed")
    return StrGet(result, "UTF-16")
}

; Hidden helper subprocess, preserving the existing DPAPI/JSON PowerShell readers.
; Unlike WScript.Shell.Exec(), CREATE_NO_WINDOW prevents console creation
; before PowerShell even starts; no temporary plaintext files or CLI secrets.
; Anonymous inherited stdin and stdout+stderr pipes follow the Win32 pattern.
; This is an optional test alternative to Exec. Output stays in
; memory, and callers must never log it (it can contain Base64 credentials).
RunHiddenHelper(command, inputLines := []) {
    if A_PtrSize != 8
        throw Error("Hidden helper requires 64-bit AutoHotkey v2")
    sa := Buffer(24, 0)
    NumPut("UInt", 24, sa, 0)
    NumPut("Int", 1, sa, 16) ; SECURITY_ATTRIBUTES.bInheritHandle
    stdoutRead := 0, stdoutWrite := 0, stdinRead := 0, stdinWrite := 0
    processHandle := 0, threadHandle := 0
    try {
        if !DllCall("kernel32\CreatePipe", "PtrP", &stdoutRead, "PtrP", &stdoutWrite, "Ptr", sa.Ptr, "UInt", 0)
            throw Error("Cannot create hidden helper output pipe")
        if !DllCall("kernel32\CreatePipe", "PtrP", &stdinRead, "PtrP", &stdinWrite, "Ptr", sa.Ptr, "UInt", 0)
            throw Error("Cannot create hidden helper input pipe")
        ; Parent ends must not be inherited or ReadFile might never get EOF.
        if !DllCall("kernel32\SetHandleInformation", "Ptr", stdoutRead, "UInt", 1, "UInt", 0)
            || !DllCall("kernel32\SetHandleInformation", "Ptr", stdinWrite, "UInt", 1, "UInt", 0)
            throw Error("Cannot configure hidden helper pipes")
        startup := Buffer(104, 0) ; STARTUPINFOW, 64-bit
        NumPut("UInt", 104, startup, 0)
        NumPut("UInt", 0x100, startup, 60) ; STARTF_USESTDHANDLES
        NumPut("Ptr", stdinRead, startup, 80)
        NumPut("Ptr", stdoutWrite, startup, 88)
        NumPut("Ptr", stdoutWrite, startup, 96)
        procInfo := Buffer(24, 0) ; PROCESS_INFORMATION, 64-bit
        writable := Buffer(StrPut(command, "UTF-16") * 2, 0)
        StrPut(command, writable, "UTF-16")
        created := DllCall("kernel32\CreateProcessW",
            "Ptr", 0, "Ptr", writable.Ptr,
            "Ptr", 0, "Ptr", 0, "Int", 1, "UInt", 0x08000000,
            "Ptr", 0, "Str", A_ScriptDir, "Ptr", startup.Ptr,
            "Ptr", procInfo.Ptr, "Int") ; CREATE_NO_WINDOW
        if !created
            throw Error("Could not start hidden Windows helper")
        processHandle := NumGet(procInfo, 0, "Ptr")
        threadHandle := NumGet(procInfo, 8, "Ptr")
        ; Only the child keeps these ends now.
        DllCall("kernel32\CloseHandle", "Ptr", stdoutWrite)
        stdoutWrite := 0
        DllCall("kernel32\CloseHandle", "Ptr", stdinRead)
        stdinRead := 0
        for _, line in inputLines {
            ; Base64 transport is ASCII; no raw credentials enter the pipe.
            data := Buffer(StrPut(line "`r`n", "UTF-8"), 0)
            n := StrPut(line "`r`n", data, "UTF-8") - 1
            sent := 0
            if !DllCall("kernel32\WriteFile", "Ptr", stdinWrite,
                "Ptr", data.Ptr, "UInt", n, "UIntP", &sent, "Ptr", 0)
                || sent != n
                throw Error("Hidden helper input failed")
        }
        DllCall("kernel32\CloseHandle", "Ptr", stdinWrite)
        stdinWrite := 0
        output := ""
        chunk := Buffer(4096, 0)
        total := 0
        loop {
            received := 0
            if !DllCall("kernel32\ReadFile", "Ptr", stdoutRead, "Ptr", chunk.Ptr,
                "UInt", chunk.Size, "UIntP", &received, "Ptr", 0)
                break ; EOF (ERROR_BROKEN_PIPE)
            total += received
            if total > 1048576
                throw Error("Windows helper output exceeded safe limit")
            if received
                output .= StrGet(chunk, received, "UTF-8")
        }
        if DllCall("kernel32\WaitForSingleObject", "Ptr", processHandle, "UInt", 30000, "UInt") != 0
            throw Error("Windows helper did not exit")
        exitCode := 0
        if !DllCall("kernel32\GetExitCodeProcess", "Ptr", processHandle, "UIntP", &exitCode)
            throw Error("Cannot read Windows helper result")
        return {output:output, exitCode:exitCode}
    } finally {
        ; Close inherited handles even on an exception; secrets never hit disk.
        for handle in [stdoutRead, stdoutWrite, stdinRead, stdinWrite, threadHandle, processHandle] {
            if handle
                DllCall("kernel32\CloseHandle", "Ptr", handle)
        }
    }
}

; Select the test Win32 CREATE_NO_WINDOW helper or legacy WScript.Exec.
; Both retain the original helper scripts, file formats and anonymous pipes.
CallCredentialHelper(command, inputLines := []) {
    global App
    if App.hiddenHelpers
        return RunHiddenHelper(command, inputLines)
    proc := ComObject("WScript.Shell").Exec(command)
    for _, line in inputLines
        proc.StdIn.WriteLine(line)
    proc.StdIn.Close()
    output := proc.StdOut.ReadAll()
    return {output:output, exitCode:proc.ExitCode}
}

InvokeNativeSecretHelper(action, credentialId, inputLines := [], importIndex := 0) {
    global App
    if !RegExMatch(credentialId, 'i)^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$')
        throw Error("Invalid credential ID")
    ps := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
    helper := A_ScriptDir "\Native-Secrets.ps1"
    if !FileExist(ps) || !FileExist(helper)
        throw Error("Native credential helper or Windows PowerShell is missing")
    command := '"' ps '" -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "' helper '" -Action ' action ' -CredentialId ' credentialId
    if action = "clone"
        command .= ' -InputConfig "' App.sourceConfig '" -SourceIndex ' importIndex
    helperResult := CallCredentialHelper(command, inputLines)
    output := helperResult.output
    if helperResult.exitCode != 0
        throw Error("Windows could not save/read the encrypted login credentials. Check the selected account and Windows user permissions.")
    return output
}

ReadNativeSecretHelper(credentialId, request) {
    global App
    result := InvokeNativeSecretHelper(request, credentialId)
    if request = "presence" {
        return {hasTotp: !!RegExMatch(result, 'm)^HAS_TOTP=1\r?$')}
    }
    if request = "password" {
        if !RegExMatch(result, 'm)^PASSWORD_B64=([A-Za-z0-9+/=]+)\r?$', &match)
            throw Error("Encrypted password response unavailable")
        App.hasTotp := !!RegExMatch(result, 'm)^HAS_TOTP=1\r?$')
        return DecodeBase64(match[1])
    }
    if request = "totp" {
        if !RegExMatch(result, 'm)^TOTP=([0-9]{6})\r?$', &match)
            throw Error("Encrypted TOTP response unavailable")
        if !RegExMatch(result, 'm)^TOTP_REMAINING=([0-9]{1,2})\r?$', &ttl)
            throw Error("Encrypted TOTP timing unavailable")
        return {code:match[1], remaining:Integer(ttl[1])}
    }
    throw Error("Unknown credential request")
}

SelectNone(*) {
    global App
    if App.busy
        return
    App.selectedNames := Map()
    RefreshCharacterButtons()
    UpdateSelectionQueue()
    SaveSelectedAdventurers()
}

BrowseWindower(*) {
    global App
    if App.busy
        return
    selected := FileSelect(1, App.windowerPath, "Select Windower.exe", "Executables (*.exe)")
    if selected = ""
        return
    SplitPath(selected, &name)
    if StrLower(name) != "windower.exe" {
        MsgBox("Select Windower.exe specifically.", "Selection rejected", "Icon!")
        return
    }
    App.windowerPath := selected
    App.windowerField.Value := selected
    SaveSettings()
}

SaveSettings() {
    global App
    try {
        IniWrite(App.windowerPath, App.settingsPath, "Launcher", "WindowerPath")
        IniWrite(App.sourceConfig, App.settingsPath, "Launcher", "AutoPOLConfigPath")
        IniWrite(App.pacing, App.settingsPath, "Launcher", "LoginPacing")
        IniWrite(App.autoQueue ? "1" : "0", App.settingsPath, "Launcher", "AutomaticParty")
        IniWrite(App.autoExit ? "1" : "0", App.settingsPath, "Launcher", "ExitAfterParty")
        IniWrite(App.nameWindows ? "1" : "0", App.settingsPath, "Launcher", "CharacterOnlyTitles")
        IniWrite(App.sortBySlot ? "1" : "0", App.settingsPath, "Launcher", "SortByPOLSlot")
        IniWrite(App.diagnosticsEnabled ? "1" : "0", App.settingsPath, "Launcher", "TimingDiagnostics")
    } catch Error as err {
        MsgBox("Settings could not be saved:`n" err.Message, "AutoPOL AHK", "Icon!")
    }
}

; Recovery is opt-in and preserves the unreadable original with a dated name.
; Only metadata INI files are involved; original AutoPOL JSON and encrypted
; credential binaries are never moved or deleted.
RestoreMetadataBackup(*) {
    global App
    if App.busy
        return
    backup := App.metadataPath ".bak"
    if !FileExist(backup) {
        MsgBox("No accounts-metadata.ini.bak was found beside the launcher. Keep the existing accounts-metadata.ini and data\credentials folder, and restore a working copy from your PC backup before importing.", "Backup not found", "Icon!")
        return
    }
    if MsgBox("Restore the saved accounts-metadata.ini.bak? The current metadata file will be archived with a timestamp. This does not modify passwords, encrypted credentials, or AutoPOL config.json.", "Restore character metadata", "YesNo Icon?") != "Yes"
        return
    currentPath := App.metadataPath
    App.metadataPath := backup
    try LoadMetadata(true)
    catch Error as err {
        App.metadataPath := currentPath
        LoadMetadata()
        MsgBox("The saved backup is also unreadable: " err.Message, "Cannot restore", "Icon!")
        return
    }
    App.metadataPath := currentPath
    archive := currentPath ".failed-" FormatTime(A_Now, "yyyyMMdd-HHmmss")
    try {
        if FileExist(currentPath)
            FileCopy(currentPath, archive, 0)
        FileCopy(backup, currentPath, 1)
        LoadMetadata(true)
        App.focusedCharIndex := 0
        RefreshUI()
        UpdateSelectionQueue(false)
        SetStatus("Character metadata restored from .bak. You can now import AutoPOL profiles.")
    } catch Error as err {
        if FileExist(archive)
            try FileCopy(archive, currentPath, 1)
        LoadMetadata()
        MsgBox("Restoring metadata failed: " err.Message, "Restore failed", "Icon!")
    }
}

ImportAutoPOL(*) {
    global App
    if App.busy
        return
    if !App.metadataHealthy {
        MsgBox("Existing character metadata is unreadable. Importing now might overwrite native profiles. Use Settings > Restore metadata... to recover the saved backup first, then import again.", "Restore profiles first", "Icon!")
        return
    }
    ; A source path saved on another PC may not exist here. Open in our
    ; current folder rather than silently failing to display a file chooser.
    initial := FileExist(App.sourceConfig) ? App.sourceConfig : A_ScriptDir
    selected := FileSelect(1, initial, "Select AutoPOL account configuration", "JSON config (*.json)")
    if selected = ""
        return
    if !RegExMatch(selected, "i)\.json$") {
        MsgBox("Choose an AutoPOL JSON configuration file.", "Import canceled", "Icon!")
        return
    }
    helper := A_ScriptDir "\Import-AutoPOL.ps1"
    ps := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
    if !FileExist(helper) || !FileExist(ps) {
        MsgBox("AutoPOL importer or Windows PowerShell 5.1 is missing. Use the complete AutoPOL AHK package.", "Import unavailable", "Icon!")
        return
    }
    ; Retain local profiles, including their DPAPI credential references.
    ; A native profile wins when the same name occurs in AutoPOL JSON.
    natives := []
    nativeKeys := Map()
    for _, account in App.accounts {
        if account.source = "native" {
            natives.Push(account)
            nativeKeys[StrLower(account.name)] := true
        }
    }
    previousSource := App.sourceConfig
    previousWindower := App.windowerPath
    backup := App.metadataPath ".before-reimport.bak"
    hadMetadata := !!FileExist(App.metadataPath)
    backupMade := false
    SetStatus("Reading AutoPOL configuration. Existing characters are preserved...")
    try {
        if hadMetadata {
            FileCopy(App.metadataPath, backup, 1)
            backupMade := true
        }
        command := '"' ps '" -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "' helper '" -InputConfig "' selected '" -OutputIni "' App.metadataPath '"'
        helperResult := CallCredentialHelper(command)
        safeOutput := helperResult.output
        ; PowerShell stdout/stderr are merged into an anonymous pipe. Only
        ; the importer's own sanitized failure categories may be shown.
        safeError := ""
        exitCode := helperResult.exitCode
        if exitCode != 0 {
            ; The importer emits only validation categories, not JSON fragments
            ; (which could contain passwords or TOTP seeds).
            if safeError = ""
                safeError := "Importer exited with code " exitCode " (see the AutoPOL config and account fields)"
            throw Error(SubStr(safeError, 1, 280))
        }
        LoadMetadata(true)
        if (App.mode != "single" && App.mode != "group") || App.accounts.Length = 0
            throw Error("No readable AutoPOL accounts were imported; previous characters have been restored")
        incoming := []
        existing := Map()
        skipped := 0
        for _, imported in App.accounts {
            key := StrLower(imported.name)
            if nativeKeys.Has(key) {
                skipped += 1
                continue
            }
            if existing.Has(key)
                throw Error("The AutoPOL configuration contains duplicate character names; no changes saved")
            existing[key] := true
            incoming.Push(imported)
        }
        if incoming.Length + natives.Length > 20
            throw Error("More than 20 unique characters; no changes saved")
        for _, native in natives
            incoming.Push(native)
        App.accounts := incoming
        ; Preserve imported source indices even when a native duplicate was
        ; skipped: Get-LoginSecrets indexes the original AutoPOL array.
        SaveMetadata()
        App.sourceConfig := selected
        SplitPath(selected, , &sourceDir)
        possibleExe := sourceDir "\Windower.exe"
        if FileExist(possibleExe) {
            App.windowerPath := possibleExe
            App.windowerField.Value := possibleExe
        }
        SaveSettings()
        App.focusedCharIndex := 0
        RefreshUI()
        UpdateSelectionQueue(false)
        SetStatus("Imported " (App.accounts.Length - natives.Length) " AutoPOL characters; retained " natives.Length " local profiles" (skipped ? "; skipped " skipped " matching name(s)." : "."))
        MsgBox("AutoPOL import completed. " (App.accounts.Length - natives.Length) " imported, " natives.Length " existing local profiles retained" (skipped ? ", " skipped " duplicate(s) skipped." : ".") "`n`nOriginal JSON and passwords were not modified.", "Import complete", "Iconi")
    } catch Error as err {
        App.sourceConfig := previousSource
        App.windowerPath := previousWindower
        if IsObject(App.windowerField)
            App.windowerField.Value := previousWindower
        try {
            if backupMade
                FileCopy(backup, App.metadataPath, 1)
            else if !hadMetadata && FileExist(App.metadataPath)
                FileDelete(App.metadataPath)
            LoadMetadata()
            RefreshUI()
            UpdateSelectionQueue(false)
        }
        SetStatus("AutoPOL import failed; previous profiles restored.")
        MsgBox("Import did not succeed. Existing AutoPOL configuration and local profiles were preserved.`n`n" err.Message, "Import failed", "Icon!")
    }
}

ChangeLoginPacing(*) {
    global App
    if App.busy {
        App.pacingControl.Choose(App.pacing = "fast" ? 2 : 1)
        SetStatus("Finish the current POL login before changing input timing.")
        return
    }
    App.pacing := App.pacingControl.Value = 2 ? "fast" : "compatible"
    SaveSettings()
    SetStatus(App.pacing = "fast" ?
        "Fast POL input timing selected. Use Compatible if POL misses an action." :
        "Compatible POL input timing selected.")
}

; Short Up is now the default for normal rosters (Killala live-confirmed),
; and larger account lists automatically retain the proven extended schedule.
; Franklet live-confirmed hidden credential helpers with no console flash.
; These are opt-in and do not alter individual Launch behavior or POL timing.
ChangePartyOptions(*) {
    global App
    if App.busy {
        App.autoQueueCheck.Value := App.autoQueue ? 1 : 0
        App.autoExitCheck.Value := App.autoExit ? 1 : 0
        App.nameWindowsCheck.Value := App.nameWindows ? 1 : 0
        App.sortBySlotCheck.Value := App.sortBySlot ? 1 : 0
        SetStatus("Finish or cancel the current launch before changing automatic-party settings.")
        return
    }
    App.autoQueue := App.autoQueueCheck.Value = 1
    App.autoExit := App.autoExitCheck.Value = 1
    App.nameWindows := App.nameWindowsCheck.Value = 1
    sortChanged := App.sortBySlot != (App.sortBySlotCheck.Value = 1)
    App.sortBySlot := App.sortBySlotCheck.Value = 1
    if sortChanged {
        ; Disabling leaves the current order intact; subsequent edits retain
        ; that order. Re-enabling immediately sorts and rebuilds the queue.
        SortAdventurersBySlot()
        RefreshUI()
        UpdateSelectionQueue(false)
    }
    SaveSettings()
    UpdateLaunchLabel()
    SetStatus(App.autoQueue ? "Automatic party enabled. Click Launch once for all checked characters." : "Automatic party disabled: Launch remains one character per click.")
}

; Fast mode reduces only post-ready pauses. Keep the 32/50-repeat held-Up
; reset intact: POL wraps on discrete presses but clamps on a held Up.
; TOTP expiry and its rollover guard are never accelerated.
PacedPOLWait(step) {
    global App
    original := step.wait
    if App.pacing != "fast"
        return original
    if step.kind = "up_down" || step.kind = "up_repeat" || step.kind = "up_release" || step.kind = "totp"
        return original
    return Max(25, Round(original * 0.72))
}

; Rebuild on every character-selection change. Do not reset progress when the
; selection is identical: Launch continues with the next chosen character.
UpdateSelectionQueue(announce := true) {
    global App
    if App.busy
        return
    selected := []
    for i, account in App.accounts
        if App.selectedNames.Has(StrLower(account.name))
            selected.Push(i)
    changed := selected.Length != App.queue.Length
    if !changed {
        for i, idx in selected {
            if idx != App.queue[i] {
                changed := true
                break
            }
        }
    }
    if changed {
        App.queue := selected
        App.nextIndex := 1
        App.partyComplete := false ; cancel any pending launcher auto-close
    }
    UpdateLaunchLabel()
    if !announce
        return
    if App.queue.Length = 0 {
        SetStatus("Choose one or more adventurers to enable Launch.")
        return
    }
    names := []
    for _, idx in App.queue
        names.Push(App.accounts[idx].name)
    SetStatus("Selected: " JoinNames(names) (App.autoQueue ? ". Click Launch to start the entire party." : ". Click Launch for the next selected character."))
}

UpdateLaunchLabel() {
    global App
    if !IsObject(App.nextButton)
        return
    if App.queue.Length = 0 {
        App.nextButton.Text := "Launch"
        App.nextButton.Enabled := false
    } else if App.nextIndex > App.queue.Length {
        App.nextButton.Text := App.autoQueue ? "Launch" : "Launch selected again"
        App.nextButton.Enabled := !App.busy
    } else {
        App.nextButton.Text := App.autoQueue ? "Launch" : "Launch " App.accounts[App.queue[App.nextIndex]].name
        App.nextButton.Enabled := !App.busy
    }
    SyncSkinnedButton(App.nextButton)
}

LaunchNext(*) {
    StartQueuedLogin()
}

StartQueuedLogin(advancing := false) {
    global App
    if App.busy && !advancing {
        SetStatus("Current POL sequence is still running. Cancel it or let the inputs finish.")
        return
    }
    ; Always use the currently checked characters. Nothing to prepare.
    UpdateSelectionQueue(false)
    if App.queue.Length = 0 {
        SetStatus("Select at least one character before clicking Launch.")
        return
    }
    App.diagRequestTick := A_TickCount
    DiagEvent("launch_requested", "party_position=" App.nextIndex " automatic_party=" (App.autoQueue ? 1 : 0))
    if App.nextIndex > App.queue.Length {
        ; Pressing Launch again after the last selected character replays
        ; the same checked selection; never relaunch anyone automatically.
        App.nextIndex := 1
        UpdateLaunchLabel()
    }
    idx := App.queue[App.nextIndex]
    account := App.accounts[idx]
    ; Full POL login is the only normal launch mode. Single and automatic
    ; party both run the same known-good account/credential input plan.
    kind := 3
    ; Use the live-confirmed short reset for normal lists; automatically use
    ; the proven longer sequence if any registered POL account slot is above 11.
    if App.dryRun {
        SetStatus("SIMULATED [" App.nextIndex "/" App.queue.Length "]: " account.name " (slot " account.slot "; full POL login).")
        App.nextIndex += 1
        UpdateLaunchLabel()
        return
    }
    if !A_IsAdmin {
        SetStatus("Administrator privileges required for automated POL input. Restart as administrator.")
        MsgBox("POL ignored keyboard events when the launcher was not elevated. Close this launcher and start it with Run as administrator. Approve the Windows UAC prompt to enable automatic login.", "Administrator access required", "Icon!")
        return
    }
    if App.mode != "single" {
        MsgBox("Actual mode currently requires AutoPOL singleProfile=true. No profile-group file swaps are performed.", "Blocked", "Icon!")
        return
    }
    if !FileExist(App.windowerPath) {
        MsgBox("Choose Windower.exe first.", "Blocked", "Icon!")
        return
    }
    SplitPath(App.windowerPath, &exeName, &exeDir)
    if StrLower(exeName) != "windower.exe" {
        MsgBox("Only Windower.exe can be launched.", "Blocked", "Icon!")
        return
    }
    ; Always pass an explicit profile flag, including for the Default profile.
    ; Launching bare Windower.exe opens its interactive profile picker and
    ; leaves the POL window waiter idle until the user clicks a profile.
    try windowerArgs := BuildWindowerProfileArgs(account.args)
    catch Error as err {
        MsgBox("Cannot launch " account.name ":`n" err.Message, "Check Windower profile", "Icon!")
        return
    }
    if account.slot > 20 || account.slot < 1 {
        MsgBox("Invalid POL slot.", "Blocked", "Icon!")
        return
    }
    if kind = 3 && account.source = "import" && !FileExist(App.sourceConfig) {
        MsgBox("Re-import the original AutoPOL config.json for this imported character. Native profiles do not need it.", "Credentials unavailable", "Icon!")
        return
    }
    if kind = 3 && account.source = "native" && !FileExist(App.credentialFolder "\" account.credentialId ".bin") {
        MsgBox("This character's encrypted credential file is missing. Edit the character to save credentials again.", "Credentials unavailable", "Icon!")
        return
    }
    ; Preflight the complete selected roster BEFORE starting an unattended party.
    ; It is safer to stop before Cioara than to open Myrr and discover a missing
    ; credential/profile or wrong POL slot partway through the handoff sequence.
    if App.autoQueue && !App.partyActive && kind = 3 {
        for _, queuedIndex in App.queue {
            candidate := App.accounts[queuedIndex]
            if candidate.slot < 1 || candidate.slot > 20 {
                SetStatus("Automatic party blocked: invalid POL slot for " candidate.name ".")
                return
            }
            try BuildWindowerProfileArgs(candidate.args)
            catch Error as err {
                SetStatus("Automatic party blocked: Windower profile argument for " candidate.name " is invalid.")
                return
            }
            if candidate.source = "import" && !FileExist(App.sourceConfig) {
                SetStatus("Automatic party blocked: imported AutoPOL JSON is missing for " candidate.name ".")
                return
            }
            if candidate.source = "native" && !FileExist(App.credentialFolder "\" candidate.credentialId ".bin") {
                SetStatus("Automatic party blocked: encrypted credential file missing for " candidate.name ".")
                return
            }
        }
    }
    ; Read only the TOTP-presence flag before the potentially long POL window
    ; search. Never keep a plaintext password while waiting for a window.
    try {
        accountInfo := ReadSecretHelper(idx, "presence", account.name, account.slot)
        App.hasTotp := accountInfo.hasTotp
    } catch Error as err {
        ClearSecrets()
        MsgBox("Could not validate the original AutoPOL account credentials.`n" err.Message, "Login unavailable", "Icon!")
        return
    }
    ; Cancel can interrupt the credential helper while the next launch is queued.
    if advancing && (!App.busy || App.autoPhase != "advance")
        return
    try {
        initial := FindPolWindows()
        if IsObject(App.pendingHandoff)
            initial.Push(App.pendingHandoff.polHwnd)
        gameBefore := App.autoQueue ? FindFFXIWindows() : []
        ; -p "" directly selects Windower's Default profile; named profiles
        ; likewise bypass the launcher. Preserve the exact working POL plan.
        command := '"' App.windowerPath '" ' windowerArgs
        App.diagLaunchTick := A_TickCount
        Run(command, exeDir, , &pid)
        DiagEvent("windower_started", "roster_index=" idx " party_position=" App.nextIndex " run_ms=" (A_TickCount - App.diagLaunchTick) " preflight_and_run_ms=" (A_TickCount - App.diagRequestTick))
        App.partyComplete := false
        if App.autoQueue {
            App.partyActive := true
            App.partyComplete := false
            App.autoPhase := ""
            App.gameBaseline := gameBefore
        }
        App.busy := true
        App.current := {name:account.name, slot:account.slot, index:App.nextIndex, accountIndex:idx, kind:kind, pid:pid}
        App.initialWindows := initial
        App.polHwnd := 0
        App.nativeAccepted := 0
        App.targetElevation := "unknown"
        App.targetIdentity := ""
        App.lastWaitNotice := 0
        App.upHeld := false
        App.upOwner := 0
        App.actions := []
        App.actionIndex := 1
        App.deadline := A_TickCount + 45000
        App.nextTick := 0
        SetBusy(true)
        profileLabel := ProfileFromArgs(windowerArgs)
        SetStatus("Launching " account.name " with Windower profile " (profileLabel = "" ? "Default" : profileLabel) ". Waiting for its NEW POL window (max 45 seconds)." (App.partyActive ? " Party auto-handoff armed." : ""))
    } catch Error as err {
        ClearSecrets()
        if !advancing {
            App.busy := false
            App.partyActive := false
            App.autoPhase := ""
            App.current := 0
        }
        MsgBox("Windower did not start:`n" err.Message, "Launch failed", "Icon!")
    }
}
; Display labels only; *all* targeting still uses the verified HWND.
; Native prefixes disappear when replaced by the character-only caption,
; so discovery must retain the exact HWND and PID. A title is not proof of login.
; A window caption is cosmetic, not an identity. Store the confirmed HWND,
; its PID and assigned title before renaming so detection continues even
; when the native "PlayOnline Viewer" / "FINAL FANTASY XI" prefix disappears.
; A recycled HWND must never become a different adventurer's window.
NamedWindowStillMatches(registry, hwnd, title) {
    if !registry.Has(hwnd)
        return false
    item := registry[hwnd]
    if title != item.title
        return false
    return WinGetPID("ahk_id " hwnd) = item.pid
}

TryNamePOLWindow(hwnd, name) {
    global App
    if !App.nameWindows || !hwnd || !WinExist("ahk_id " hwnd)
        return
    try {
        if !RegExMatch(WinGetTitle("ahk_id " hwnd), "i)^PlayOnline Viewer")
            return
        pid := WinGetPID("ahk_id " hwnd)
        WinSetTitle(name, "ahk_id " hwnd)
        if WinGetTitle("ahk_id " hwnd) = name
            App.namedPOL[hwnd] := {title:name, pid:pid}
        DiagEvent("pol_window_named", "party_position=" App.nextIndex)
    } catch Error {
        DiagEvent("pol_window_name_skipped", "party_position=" App.nextIndex)
    }
}

TryNameFFXIWindow(hwnd, name, position) {
    global App
    if !App.nameWindows || !hwnd || !WinExist("ahk_id " hwnd)
        return
    try {
        title := WinGetTitle("ahk_id " hwnd)
        if !RegExMatch(title, "i)^(FINAL FANTASY XI|FFXI(?:\s|$))")
            return
        pid := WinGetPID("ahk_id " hwnd)
        WinSetTitle(name, "ahk_id " hwnd)
        if WinGetTitle("ahk_id " hwnd) = name
            App.namedFFXI[hwnd] := {title:name, pid:pid}
        DiagEvent("ffxi_window_named", "party_position=" position)
    } catch Error {
        DiagEvent("ffxi_window_name_skipped", "party_position=" position)
    }
}

; Checks whether the *same* targeted POL HWND is still presenting its viewer.
; After renaming, the exact assigned caption is treated as viewer-active until
; the process exits or changes caption, rather than bypassing handoff gating.
IsPOLViewerWindow(hwnd) {
    global App
    if !hwnd || !WinExist("ahk_id " hwnd)
        return false
    try {
        title := WinGetTitle("ahk_id " hwnd)
        return RegExMatch(title, "i)^PlayOnline Viewer") || NamedWindowStillMatches(App.namedPOL, hwnd, title)
    } catch Error {
        return true ; unknown state must NOT advance an automatic party
    }
}

FindPolWindows() {
    global App
    handles := []
    for _, hwnd in WinGetList() {
        try {
            title := WinGetTitle("ahk_id " hwnd)
            if RegExMatch(title, "i)^PlayOnline Viewer") || NamedWindowStillMatches(App.namedPOL, hwnd, title)
                handles.Push(hwnd)
        } catch Error {
            continue
        }
    }
    return handles
}

FindFFXIWindows() {
    global App
    handles := []
    for _, hwnd in WinGetList() {
        try {
            title := WinGetTitle("ahk_id " hwnd)
            if (RegExMatch(title, "i)^(FINAL FANTASY XI|FFXI(?:\s|$))") && !RegExMatch(title, "i)(Config|Update|Installer|Settings)"))
                || NamedWindowStillMatches(App.namedFFXI, hwnd, title)
                handles.Push(hwnd)
        } catch Error {
            continue
        }
    }
    return handles
}

; Track one submitted login separately from the next POL input plan.
; Never submit a second final confirmation until the older handoff is resolved.
PartyHandoffTick(now) {
    global App
    handoff := App.pendingHandoff
    if now > handoff.deadline {
        AbortCurrent("Automatic party paused: no confirmed FFXI handoff for " handoff.name " within 120 seconds.")
        return
    }
    polStillViewer := IsPOLViewerWindow(handoff.polHwnd)
    newGame := 0
    for _, hwnd in FindFFXIWindows() {
        if handoff.baseline.Has(hwnd)
            continue
        if newGame {
            newGame := 0 ; two new game windows: ambiguous handoff
            break
        }
        newGame := hwnd
    }
    if polStillViewer || !newGame {
        handoff.candidate := 0
        handoff.observedAt := 0
    } else if handoff.candidate != newGame {
        handoff.candidate := newGame
        handoff.observedAt := now
        DiagEvent("ffxi_window_candidate", "party_position=" handoff.position " since_input_ms=" (now - handoff.submittedAt))
    } else if now - handoff.observedAt >= 3000 {
        TryNameFFXIWindow(newGame, handoff.name, handoff.position)
        ; The next launch may have taken its baseline before this window appeared.
        App.gameBaseline.Push(newGame)
        App.pendingHandoff := 0
        DiagEvent("ffxi_handoff_stable", "party_position=" handoff.position " handoff_ms=" (now - handoff.submittedAt) " total_since_windower_ms=" (now - handoff.launchTick))
        if App.autoPhase = "handoff" {
            App.busy := false
            App.autoPhase := ""
            App.partyActive := false
            App.partyComplete := true
            SetBusy(false)
            DiagEvent("party_complete", "party_size=" App.queue.Length " auto_exit=" (App.autoExit ? 1 : 0))
            SetStatus("FFXI windows detected for the full launch queue." (App.autoExit ? " Closing launcher." : ""))
            if App.autoExit
                SetTimer(ExitAfterParty, -1500)
        }
    }
}

ExitAfterParty(*) {
    global App
    if App.partyComplete && !App.busy && App.autoExit {
        DiagEvent("auto_exit", "complete=1")
        CloseLauncher()
    }
}

QueueTick(*) {
    global App
    if !App.busy
        return
    try {
        now := A_TickCount
        if IsObject(App.pendingHandoff)
            PartyHandoffTick(now)
        if !App.busy || App.autoPhase = "handoff"
            return
        if App.autoPhase = "advance" {
            if now < App.nextTick
                return
            StartQueuedLogin(true)
            if App.busy && App.autoPhase = "advance"
                AbortCurrent("Automatic party stopped before the next Windower launch.")
            return
        }
        if !IsObject(App.current) {
            AbortCurrent("Lost launch state.")
            return
        }
        if App.polHwnd = 0 {
            if now > App.deadline {
                AbortCurrent("No distinct new POL window appeared within 45 seconds. No inputs sent.")
                return
            }
            for _, hwnd in FindPolWindows() {
                known := false
                for _, oldHwnd in App.initialWindows {
                    if oldHwnd = hwnd {
                        known := true
                        break
                    }
                }
                if !known {
                    if App.polHwnd != 0 {
                        AbortCurrent("Multiple new POL windows. Refusing to choose one.")
                        return
                    }
                    App.polHwnd := hwnd
                }
            }
            if App.polHwnd = 0 {
                ; An existing window is excluded, not silently considered a
                ; new POL login. Explain the waiting gate during live tests.
                if !App.lastWaitNotice || now - App.lastWaitNotice >= 3000 {
                    App.lastWaitNotice := now
                    left := Max(0, Ceil((App.deadline - now) / 1000))
                    SetStatus("Waiting for a NEW POL window (" left "s left); " App.initialWindows.Length " existing window(s) excluded.")
                }
                return
            }
            ; The selected HWND was absent from the startup baseline: label
            ; exactly this new viewer, never any pre-existing POL session.
            TryNamePOLWindow(App.polHwnd, App.current.name)
            App.nextTick := now + (App.pacing = "fast" ? 1750 : 3000)
            App.deadline := now + 20000
            App.targetIdentity := DescribePOLWindow(App.polHwnd)
            App.targetElevation := QueryProcessElevation(WinGetPID("ahk_id " App.polHwnd))
            App.details.Text := "POL target: " App.targetIdentity "; elevated=" App.targetElevation "; launcher elevated=" (A_IsAdmin ? "yes" : "no") "."
            if App.targetElevation = "yes" && !A_IsAdmin {
                AbortCurrent("POL is running elevated while VanaLauncher is not. Start VanaLauncher with Run as administrator, then retry. No inputs sent.")
                return
            }
            SetStatus("New POL: " App.targetIdentity ". Waiting " (App.pacing = "fast" ? "1.75" : "3") " seconds for account menu (" App.pacing " timing).")
            return
        }
        if !WinExist("ahk_id " App.polHwnd) {
            AbortCurrent("POL window disappeared. Inputs canceled.")
            return
        }
        ; While Up is held, do not silently change focus and resume the repeat.
        ; A click into another application cancels the sequence and releases Up.
        if App.upHeld && !WinActive("ahk_id " App.upOwner) {
            AbortCurrent("POL lost focus during held-Up reset. Up released; inputs canceled.")
            return
        }
        if now < App.nextTick
            return
        if App.actions.Length = 0 {
            ; Require a real caption (matching AutoPOL's readiness test).
            style := WinGetStyle("ahk_id " App.polHwnd)
            if !(style & 0x00C00000) {
                if now > App.deadline
                    AbortCurrent("POL did not show a caption. No inputs sent.")
                return
            }
            ; User verified: individual Up presses WRAP, physical held Up CLAMPS.
            ; Synthetic AHK {Up down} does not generate automatic key repeats,
            ; so emit repeated downs without an intervening key-up; release once.
            ; Proven remains unchanged. The Short ~0.9s version
            ; packs up to 18 held-Up down events into ~18 timer ticks.
            ; Extended 12-20 slot rosters keep the proven reset; they may
            ; need more repeats than a single second reliably permits.
            extendedRoster := false
            for _, acc in App.accounts {
                if acc.slot > 11 {
                    extendedRoster := true
                    break
                }
            }
            shortReset := App.upResetMode = "quick" && !extendedRoster
            holdRepeats := extendedRoster ? 50 : (shortReset ? 17 : 32)
            repeatWaitMs := shortReset ? 40 : 90
            App.actions := BuildInputPlan(App.current.slot, App.current.kind, App.hasTotp, holdRepeats, repeatWaitMs)
            if shortReset
                SetStatus("Short held-Up reset for " App.current.name ": approximately 0.9 seconds; verify correct POL account before relying on it.")
            App.actionIndex := 1
            ; AutoPOL primes foreground focus with an Alt press/release. Do the
            ; same here, once only, before normal inputs.
            if !FocusPol(App.polHwnd) {
                AbortCurrent("Cannot focus POL for input preflight.")
                return
            }
            try {
                NativePOLKey(0x12)
            } finally {
                ; Release Alt even if the focus-prime injection throws.
                NativePOLKey(0x12, true, true)
            }
            if !WinActive("ahk_id " App.polHwnd) {
                AbortCurrent("POL lost focus during input preflight.")
                return
            }
        }
        if App.actionIndex > App.actions.Length {
            CompleteCurrent()
            return
        }
        step := App.actions[App.actionIndex]
        ; Let the next POL reach the login screen, but serialize handoffs.
        ; Defer TOTP generation too, so a code cannot expire in this wait.
        if IsObject(App.pendingHandoff) && (step.kind = "totp" || App.actionIndex >= App.actions.Length - 1)
            return
        if !FocusPol(App.polHwnd) {
            AbortCurrent("POL did not become active. Inputs canceled to avoid typing into another window.")
            return
        }
        if step.kind = "up_down" {
            App.upHeld := true
            App.upOwner := App.polHwnd
            NativePOLKey(0x26) ; VK_UP down, no release between repeats
            SetStatus("Win32 SendInput: holding Up for " App.current.name "; target " App.targetIdentity ".")
        } else if step.kind = "up_repeat" {
            if !App.upHeld
                throw Error("Up repeat without an active key hold")
            NativePOLKey(0x26)
        } else if step.kind = "up_release" {
            ReleaseHeldUp()
            SetStatus("Up released; selecting POL slot " App.current.slot " for " App.current.name ".")
        } else if step.kind = "key" {
            NativePOLActionKey(step.key)
        } else if step.kind = "paste" {
            ; Acquire the password at its actual POL input step. This avoids
            ; retaining a plaintext credential during the 45s window wait.
            ; Verify this exact POL HWND after hidden credential retrieval.
            ; A fullscreen FFXI client could still take foreground meanwhile.
            LoadCredentials(App.current.accountIndex, App.accounts[App.current.accountIndex])
            FocusPolAfterCredentialHelper("password")
            PastePassword()
        } else if step.kind = "totp" {
            ; Fetch a NEW 30-second code at the actual point of use, not
            ; during the potentially 45-second POL startup wait.
            codeInfo := ReadSecretHelper(App.current.accountIndex, "totp", App.current.name, App.current.slot)
            FocusPolAfterCredentialHelper("totp")
            if codeInfo.remaining < 7 {
                ; Code may expire before POL accepts the final confirmation.
                ; Wait for a new time step, then fetch a fresh code.
                App.nextTick := A_TickCount + (codeInfo.remaining + 1) * 1000
                SetStatus("Near TOTP rollover; waiting for a fresh code before typing.")
                return
            }
            for _, digit in StrSplit(codeInfo.code, "")
                NativePOLActionKey(digit)
            codeInfo := 0
        } else if step.kind = "pause" {
            ; Explicit timing step, no input.
        } else {
            AbortCurrent("Invalid input plan operation.")
            return
        }
        App.nextTick := A_TickCount + PacedPOLWait(step)
        App.actionIndex += 1
        if App.partyActive && App.actionIndex > App.actions.Length {
            CompleteCurrent()
            return
        }
        if Mod(App.actionIndex, 6) = 0
            SetStatus("POL plan " (App.actionIndex-1) "/" App.actions.Length "; Win32 accepted " App.nativeAccepted " events; target " App.targetIdentity ".")
    } catch Error as err {
        ; Never display secrets, clipboard contents or PowerShell stdout.
        ; Input failures are deliberately explicit. Other failures remain
        ; summarized without exposing credentials or PowerShell output.
        if InStr(err.Message, "SendInput") || InStr(err.Message, "foreground")
            AbortCurrent("POL injection stopped: " err.Message)
        else
            AbortCurrent("POL automation stopped on a Windows/AHK error (" Type(err) ").")
    }
}

FocusPol(hwnd) {
    try {
        if WinActive("ahk_id " hwnd)
            return true
        WinActivate("ahk_id " hwnd)
        ; Activation can be asynchronous. Confirm before emitting any input.
        return !!WinWaitActive("ahk_id " hwnd, , 0.5)
    } catch {
        return false
    }
}

; Hidden subprocess retrieval is synchronous. Retain the proven foreground
; recovery/verification anyway, because a fullscreen FFXI switch can still
; occur during retrieval. Never paste/type to whichever window has focus.
FocusPolAfterCredentialHelper(phase) {
    global App
    if !App.polHwnd || !WinExist("ahk_id " App.polHwnd)
        throw Error("POL window disappeared during credential retrieval; no secret sent")
    hadFocus := WinActive("ahk_id " App.polHwnd) != 0
    if !FocusPol(App.polHwnd) || DllCall("user32\GetForegroundWindow", "Ptr") != App.polHwnd
        throw Error("POL lost foreground during credential retrieval; no secret sent")
    if !hadFocus
        DiagEvent("pol_focus_recovered", "phase=" phase " source=credential_helper")
}

; The target label proves only which HWND/process was selected, never
; that POL actually acted on a keyboard event. No login secrets are recorded.
DescribePOLWindow(hwnd) {
    try {
        pid := WinGetPID("ahk_id " hwnd)
        exe := WinGetProcessName("ahk_id " hwnd)
        return Format("HWND=0x{:X}, PID={}, EXE={}", hwnd, pid, exe)
    } catch {
        return Format("HWND=0x{:X}, process unavailable", hwnd)
    }
}

; Read-only process privilege check. Higher-integrity POL can ignore
; injected events from an unelevated launcher while SendInput reports success.
; Unknown result must never be presented as a confirmed privilege match.
QueryProcessElevation(pid) {
    handle := DllCall("kernel32\OpenProcess", "UInt", 0x1000, "Int", 0, "UInt", pid, "Ptr")
    if !handle
        return "unknown"
    token := 0
    try {
        if !DllCall("Advapi32\OpenProcessToken", "Ptr", handle, "UInt", 0x8, "PtrP", &token, "Int")
            return "unknown"
        info := Buffer(4, 0)
        required := 0
        if !DllCall("Advapi32\GetTokenInformation", "Ptr", token, "Int", 20,
                "Ptr", info.Ptr, "UInt", info.Size, "UIntP", &required, "Int")
            return "unknown"
        return NumGet(info, 0, "UInt") ? "yes" : "no"
    } catch {
        return "unknown"
    } finally {
        if token
            DllCall("kernel32\CloseHandle", "Ptr", token)
        DllCall("kernel32\CloseHandle", "Ptr", handle)
    }
}

; Match Makaria AutoPOL's actual injection API rather than AHK SendEvent.
; Native INPUT / KEYBDINPUT layout: INPUT is 40 bytes x64, 28 bytes x86;
; the union begins at byte 8 x64 and byte 4 x86.
; A return of 1 says Windows queued the INPUT, not that POL consumed it.
; VK flags 0 = key down, 0x0002 = KEYEVENTF_KEYUP.
NativePOLKey(vk, release := false, emergency := false) {
    global App
    if !emergency {
        ; Detect an unexpected focus change rather than injecting into it.
        hwnd := DllCall("user32\GetForegroundWindow", "Ptr")
        if hwnd != App.polHwnd
            throw Error("POL lost foreground before SendInput; no further keys sent")
    }
    inputSize := A_PtrSize = 8 ? 40 : 28
    unionOffset := A_PtrSize = 8 ? 8 : 4
    keyInput := Buffer(inputSize, 0)
    NumPut("UInt", 1, keyInput, 0) ; INPUT_KEYBOARD
    NumPut("UShort", vk, keyInput, unionOffset)
    NumPut("UInt", release ? 0x0002 : 0, keyInput, unionOffset + 4)
    sent := DllCall("user32\SendInput", "UInt", 1, "Ptr", keyInput.Ptr, "Int", inputSize, "UInt")
    if sent != 1
        throw Error("SendInput returned " sent "/1; Windows error " A_LastError ". POL may be elevated or input-blocked")
    App.nativeAccepted += 1
}

; The login sequence also uses Win32 SendInput for its ordinary keyboard
; actions. Password paste keeps its separate legacy clipboard path, unverified.
NativePOLActionKey(key) {
    vk := 0
    switch key {
        case "{Up}": vk := 0x26
        case "{Down}": vk := 0x28
        case "{Enter}": vk := 0x0D
        case "{Escape}": vk := 0x1B
        case "{Backspace}": vk := 0x08
        case "a": vk := 0x41
        default:
            if RegExMatch(key, "^[0-9]$")
                vk := Ord(key)
    }
    if vk = 0
        throw Error("Unsupported POL input key name; no input injected")
    NativePOLKey(vk)
    try {
        Sleep(30)
    } finally {
        ; Once the down has been injected, ALWAYS release it, even if
        ; focus changes between calls. Do not leave a key pressed elsewhere.
        NativePOLKey(vk, true, true)
    }
}

; Always pair a held Up with a release, including Cancel, window loss or
; a failed Win32 injection. An emergency release must work after focus loss.
ReleaseHeldUp() {
    global App
    if !App.upHeld
        return
    hwnd := App.upOwner
    App.upHeld := false
    App.upOwner := 0
    try NativePOLKey(0x26, true, true)
    catch {
        ; Only an emergency fallback; never count this as verified delivery.
        try SendEvent("{Up up}")
    }
    if hwnd && WinExist("ahk_id " hwnd) && !WinActive("ahk_id " hwnd) {
        try ControlSend("{Up up}", , "ahk_id " hwnd)
    }
}

; Closely follows Makaria AutoPOL's login-input order and basic waits.
; Account-menu reset differs from AutoPOL: observed POL wraps for discrete Up
; taps but clamps for held Up. Keep the key logically down through repeats.
BuildInputPlan(slot, kind, hasTotp, holdRepeats, repeatWaitMs := 90) {
    result := []
    result.Push({kind:"up_down", key:"", wait:repeatWaitMs})
    Loop holdRepeats
        result.Push({kind:"up_repeat", key:"", wait:repeatWaitMs})
    result.Push({kind:"up_release", key:"", wait:200})
    Loop (slot - 1)
        result.Push({kind:"key", key:"{Down}", wait:200})
    ; Navigation-only deliberately stops before any confirm/credential field.
    if kind = 2
        return result

    ; AutoPOL sleeps 200 ms once more after slot navigation, then sends
    ; exactly SEVEN initial Enter presses (3 + 4), not eight.
    result.Push({kind:"pause", key:"", wait:200})
    for _, ms in [200, 300, 200, 200, 300, 500, 500]
        result.Push({kind:"key", key:"{Enter}", wait:ms})
    Loop 4
        result.Push({kind:"key", key:"{Backspace}", wait:25})
    ; AutoPOL sends 'a' and backspace before pasting the password.
    result.Push({kind:"key", key:"a", wait:25})
    result.Push({kind:"key", key:"{Backspace}", wait:25})
    result.Push({kind:"paste", key:"", wait:300})
    for _, item in [
        {key:"{Enter}", ms:500}, {key:"{Down}", ms:300}]
        result.Push({kind:"key", key:item.key, wait:item.ms})
    if hasTotp {
        result.Push({kind:"key", key:"{Enter}", wait:35})
        result.Push({kind:"totp", key:"", wait:35})
        result.Push({kind:"key", key:"{Escape}", wait:100})
        result.Push({kind:"key", key:"{Down}", wait:100})
    }
    result.Push({kind:"key", key:"{Enter}", wait:50})
    result.Push({kind:"key", key:"{Enter}", wait:500})
    return result
}

; Clipboard is retained only for the brief paste operation and always restored.
; Use AutoPOL-style Ctrl+V instead of putting passwords in key sequences.
PastePassword() {
    global App
    if App.secretPassword = ""
        throw Error("Password missing")
    prior := ClipboardAll()
    try {
        A_Clipboard := App.secretPassword
        if !ClipWait(0.7)
            throw Error("Clipboard unavailable")
        ; A full-screen FFXI client can steal focus while the clipboard is
        ; being prepared. Never paste a password into an unexpected window.
        if DllCall("user32\GetForegroundWindow", "Ptr") != App.polHwnd
            throw Error("POL lost foreground before password paste; no password sent")
        SendEvent("^v")
        Sleep(150)
    } finally {
        A_Clipboard := prior
        prior := 0
        App.secretPassword := ""
    }
}

; A console-free PowerShell child reads ORIGINAL config.json and prints only a
; Base64-encoded transient password and 6-digit TOTP to a PRIVATE pipe.
; Neither secret is stored on disk, placed on the command line, or logged.
LoadCredentials(accountIndex, account) {
    global App
    password := ReadSecretHelper(accountIndex, "password", account.name, account.slot)
    if password = ""
        throw Error("No password for selected account")
    App.secretPassword := password
    ; The helper sets the presence flag, not a TOTP code, on password read.
}

ReadSecretHelper(accountIndex, request, expectedName, expectedSlot) {
    global App
    account := App.accounts[accountIndex]
    if account.source = "native"
        return ReadNativeSecretHelper(account.credentialId, request)
    ; Imported profiles still use the original read-only AutoPOL helper.
    accountIndex := account.importIndex
    if !FileExist(App.sourceConfig) || !RegExMatch(App.sourceConfig, "i)\.json$")
        throw Error("Imported AutoPOL JSON file is unavailable; import its path again from Settings.")
    ps := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
    helper := A_ScriptDir "\Get-LoginSecrets.ps1"
    if !FileExist(ps) || !FileExist(helper)
        throw Error("Windows PowerShell or credential helper not present")
    if request != "password" && request != "totp" && request != "presence"
        throw Error("Unknown credential operation")
    ; Command line contains only a file path, account index and operation.
    command := '"' ps '" -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "' helper '" -InputConfig "' App.sourceConfig '" -AccountIndex ' accountIndex ' -Mode ' request
    helperResult := CallCredentialHelper(command)
    output := helperResult.output
    if helperResult.exitCode != 0
        throw Error("Local credential helper failed. Check AutoPOL config.json and its TOTP key.")
    ; Validate account identity immediately before accepting its secrets.
    if !RegExMatch(output, "m)^NAME_B64=([A-Za-z0-9+/=]+)\r?$", &encodedName)
        throw Error("Credential helper did not identify account")
    if !RegExMatch(output, "m)^SLOT=([0-9]{1,2})\r?$", &actualSlot)
        throw Error("Credential helper omitted account slot")
    if DecodeBase64(encodedName[1]) != expectedName || Integer(actualSlot[1]) != expectedSlot
        throw Error("Original AutoPOL account does not match imported metadata. Re-import.")
    if request = "password" {
        if !RegExMatch(output, "m)^PASSWORD_B64=([A-Za-z0-9+/=]+)\r?$", &match)
            throw Error("No password returned by credential helper")
        App.hasTotp := !!RegExMatch(output, "m)^HAS_TOTP=1\r?$")
        result := DecodeBase64(match[1])
    } else if request = "presence" {
        result := {hasTotp: !!RegExMatch(output, "m)^HAS_TOTP=1\r?$")}
    } else {
        if !RegExMatch(output, "m)^TOTP=([0-9]{6})\r?$", &match)
            throw Error("No six-digit code returned by credential helper")
        if !RegExMatch(output, "m)^TOTP_REMAINING=([0-9]{1,2})\r?$", &ttl)
            throw Error("No time-step remaining value returned")
        result := {code:match[1], remaining:Integer(ttl[1])}
    }
    output := ""
    return result
}

DecodeBase64(encoded) {
    ; crypt32 decodes into an AHK Buffer; no temporary files, COM array, or
    ; accidental UTF-16 reinterpretation of the password.
    size := 0
    if !DllCall("Crypt32\CryptStringToBinaryW", "Str", encoded, "UInt", 0,
            "UInt", 1, "Ptr", 0, "UIntP", &size, "Ptr", 0, "Ptr", 0)
        throw Error("Base64 decoding failed")
    raw := Buffer(size + 1, 0)
    if !DllCall("Crypt32\CryptStringToBinaryW", "Str", encoded, "UInt", 0,
            "UInt", 1, "Ptr", raw.Ptr, "UIntP", &size, "Ptr", 0, "Ptr", 0)
        throw Error("Base64 decoding failed")
    return StrGet(raw, size, "UTF-8")
}

ClearSecrets() {
    global App
    App.secretPassword := ""
    App.hasTotp := false
    App.pendingTotp := ""
}

CompleteCurrent() {
    global App
    ReleaseHeldUp()
    name := App.current.name
    count := App.actions.Length
    accepted := App.nativeAccepted
    target := App.targetIdentity
    elevated := App.targetElevation
    if App.partyActive && App.current.kind = 3 {
        submittedAt := A_TickCount
        baseline := Map()
        for _, hwnd in App.gameBaseline
            baseline[hwnd] := true
        App.pendingHandoff := {name:name, position:App.current.index, polHwnd:App.polHwnd,
            baseline:baseline, candidate:0, observedAt:0, submittedAt:submittedAt,
            deadline:submittedAt + 120000, launchTick:App.diagLaunchTick}
        App.nextIndex += 1
        App.autoPhase := App.nextIndex <= App.queue.Length ? "advance" : "handoff"
        App.nextTick := submittedAt + 1000
        App.current := 0
        App.polHwnd := 0
        App.actions := []
        App.gameBaseline := []
        ClearSecrets()
        status := "POL inputs finished for " name ". Tracking its FFXI window."
        SetStatus(status (App.autoPhase = "advance" ? " Next launch queued for one second after final Enter." : ""))
        return
    }
    App.nextIndex += 1
    App.busy := false
    App.current := 0
    App.polHwnd := 0
    App.actions := []
    ClearSecrets()
    SetBusy(false)
    App.details.Text := "POL target: " target "; elevated=" elevated "; launcher elevated=" (A_IsAdmin ? "yes" : "no") "."
    SetStatus("INPUT PLAN FINISHED: Windows accepted " accepted " keyboard events across " count " actions. Confirm the POL login on screen.")
}

CancelLaunch(*) {
    AbortCurrent("User canceled launch. No further POL inputs will be sent.")
}

AbortCurrent(reason) {
    global App
    if !App.busy
        return
    DiagEvent("launch_aborted", "party_position=" App.nextIndex " phase=" DiagPhase(App.autoPhase))
    FlushActionDiagnostics()
    ReleaseHeldUp()
    ; The process has already started, so skip its queue entry to prevent
    ; blindly launching the same character twice. User may prepare a new queue.
    if IsObject(App.current)
        App.nextIndex += 1
    App.busy := false
    App.current := 0
    App.polHwnd := 0
    App.actions := []
    App.partyActive := false
    App.partyComplete := false
    App.autoPhase := ""
    App.pendingHandoff := 0
    App.gameBaseline := []
    ClearSecrets()
    SetBusy(false)
    SetStatus(reason " Automatic chaining is stopped; Launch is available for the next selected character.")
}

SetBusy(value) {
    global App
    for _, button in App.charButtons {
        button.Enabled := !value && button.Visible
        if button.Visible
            SyncSkinnedButton(button)
    }
    App.autoQueueCheck.Enabled := !value
    App.autoExitCheck.Enabled := !value
    App.nameWindowsCheck.Enabled := !value
    App.nextButton.Enabled := false
    App.cancelButton.Enabled := value
    SyncSkinnedButton(App.nextButton)
    SyncSkinnedButton(App.cancelButton)
    if !value
        UpdateLaunchLabel()
}

SetStatus(value) {
    global App
    App.status.Value := value
}

JoinNames(names) {
    text := ""
    for _, name in names
        text .= (text = "" ? "" : ", ") name
    return text
}

; Emergency cancel is available when the launcher GUI is not focused.
^+F10::CancelLaunch()

; This is an isolated loopback lab, NOT real POL acceleration. It never edits
; the Windows hosts file and deliberately binds an ephemeral port rather than
; the US/JP/EU POL ports. The controller/FFXI runtime is unaffected.
StartProxyLab(*) {
    global App
    if (App.proxyPid && ProcessExist(App.proxyPid)) {
        SetProxyStatus("Proxy lab already running (PID " App.proxyPid ").")
        return
    }
    answer := MsgBox("Start an isolated local HTTP test server?`n`nIt listens only on 127.0.0.1 using a temporary, OS-selected port. It DOES NOT connect to PlayOnline, edit hosts, or accelerate real logins.", "Start local proxy lab", "YesNo Icon?")
    if answer != "Yes"
        return
    helper := A_ScriptDir "\Proxy-Local.ps1"
    powershell := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
    if !FileExist(helper) || !FileExist(powershell) {
        SetProxyStatus("Proxy-Local.ps1 or Windows PowerShell 5.1 is missing.")
        return
    }
    try {
        DirCreate(A_ScriptDir "\data")
        if FileExist(App.proxyStopPath)
            FileDelete(App.proxyStopPath)
        App.proxyToken := Format("{:08X}{:06X}{:04X}", DllCall("GetCurrentProcessId", "UInt"), A_TickCount, Random(0, 65535))
        parentPid := DllCall("GetCurrentProcessId", "UInt")
        command := '"' powershell '" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' helper '" -StatusPath "' App.proxyPath '" -StopPath "' App.proxyStopPath '" -Token ' App.proxyToken ' -ParentPid ' parentPid ' -Port 0 -LifetimeSeconds 600'
        Run(command, A_ScriptDir, "Hide", &pid)
        App.proxyPid := pid
        App.proxyState := "starting"
        App.proxyPort := 0
        App.proxyRequests := 0
        App.proxyStart.Enabled := false
        App.proxyStop.Enabled := true
        SetProxyStatus("Starting local-only proxy lab (PID " pid ")...")
    } catch Error as err {
        App.proxyPid := 0
        App.proxyToken := ""
        App.proxyStart.Enabled := true
        App.proxyStop.Enabled := false
        SetProxyStatus("Proxy lab could not start: " err.Message)
    }
}

StopProxyLab(*) {
    global App
    if !App.proxyPid
        return
    if ProcessExist(App.proxyPid) {
        try {
            ; Explicit token ensures a stale stop request cannot stop another
            ; lab instance. The helper ALSO exits if its parent process exits.
            if FileExist(App.proxyStopPath)
                FileDelete(App.proxyStopPath)
            FileAppend(App.proxyToken, App.proxyStopPath, "UTF-8-RAW")
            App.proxyState := "stopping"
            SetProxyStatus("Stop requested. Waiting for helper to exit...")
        } catch Error as err {
            SetProxyStatus("Could not request stop: " err.Message)
        }
    }
}

ProxyTick(*) {
    global App
    if !App.proxyPid
        return
    if !ProcessExist(App.proxyPid) {
        App.proxyState := "stopped"
        App.proxyPid := 0
        App.proxyStart.Enabled := true
        App.proxyStop.Enabled := false
        SetProxyStatus("Local proxy lab stopped. It did not change POL or Windows hosts.")
        return
    }
    if App.proxyState = "stopping" || !FileExist(App.proxyPath)
        return
    try {
        token := IniRead(App.proxyPath, "Proxy", "token", "")
        pid := Integer(IniRead(App.proxyPath, "Proxy", "pid", "0"))
        if token != App.proxyToken || pid != App.proxyPid
            return
        state := IniRead(App.proxyPath, "Proxy", "state", "unknown")
        if state != "ready" && state != "stopped"
            return
        App.proxyState := state
        App.proxyPort := Integer(IniRead(App.proxyPath, "Proxy", "port", "0"))
        App.proxyRequests := Integer(IniRead(App.proxyPath, "Proxy", "requests", "0"))
        errors := Integer(IniRead(App.proxyPath, "Proxy", "errors", "0"))
        if state = "ready" && App.proxyPort > 0
            SetProxyStatus("LAB listening on 127.0.0.1:" App.proxyPort " | requests " App.proxyRequests " | errors " errors ". No hosts changes.")
    } catch {
        ; File can be replaced between IniRead calls; try next tick.
    }
}

SetProxyStatus(message) {
    global App
    if IsObject(App.proxyStatus)
        App.proxyStatus.Value := message
}

; Read-only environment inspection. Does not edit hosts, start a server or
; change DNS. Separate results for stale Vana entry, foreign mapping, port
; conflict, and clear-to-try. The live helper independently rechecks on start.
CheckPOLAcceleration(*) {
    global App
    if App.polProxyPid && ProcessExist(App.polProxyPid) {
        SetPOLProxyStatus("Acceleration already running. Stop it before checking a new session.")
        return false
    }
    helper := A_ScriptDir "\Check-POL-Acceleration.ps1"
    powershell := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
    if !FileExist(helper) || !FileExist(powershell) {
        SetPOLProxyStatus("Missing Check-POL-Acceleration.ps1 or Windows PowerShell. Use the complete update ZIP.")
        return false
    }
    region := App.polProxyRegion.Text
    try {
        command := '"' powershell '" -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "' helper '" -Region ' region
        helperResult := CallCredentialHelper(command)
        if helperResult.exitCode != 0
            throw Error("Proxy preflight failed")
        output := helperResult.output
        ; Only whitelisted status words, not raw hosts contents, are shown.
        if !RegExMatch(output, 'm)^RESULT=(CLEAR|OWN_STALE|HOSTS_CONFLICT|PORT_BUSY|ERROR)\r?$', &match)
            throw Error("Unrecognized proxy preflight output")
        result := match[1]
        switch result {
            case "CLEAR":
                SetPOLProxyStatus(region " checks CLEAR: no wh000.pol.com hosts mapping, and the regional port is available. Ready to try Start acceleration.")
                return true
            case "OWN_STALE":
                SetPOLProxyStatus("Previous Vana proxy marker found in hosts. Use Recover stale hosts; then Check again. No changes made.")
            case "HOSTS_CONFLICT":
                SetPOLProxyStatus("Another entry already maps wh000.pol.com (possibly AutoPOL). Leave it intact; resolve the conflict before starting our proxy.")
            case "PORT_BUSY":
                SetPOLProxyStatus(region " POL port is occupied. Close the other proxy or app first, then Check again.")
            default:
                SetPOLProxyStatus("Read-only preflight could not inspect hosts or the regional port. No changes made.")
        }
    } catch Error as err {
        SetPOLProxyStatus("Read-only preflight failed (" Type(err) "). Hosts untouched; acceleration not enabled.")
    }
    return false
}

; The real POL proxy runs as a supervised elevated subprocess. This GUI
; never mutates hosts directly; the helper owns tagged cleanup/recovery.
StartPOLProxy(*) {
    global App
    if App.polProxyPid && ProcessExist(App.polProxyPid) {
        SetPOLProxyStatus("Proxy already running. Stop it before starting another.")
        return
    }
    if POLHostsMarkerPresent() {
        SetPOLProxyStatus("A Vana launcher hosts entry already exists. Recover it before starting.")
        return
    }
    country := App.polProxyRegion.Text
    ; Start only after an up-to-date, read-only preflight. The helper still
    ; has its own port binding and hosts verification to handle races.
    if !CheckPOLAcceleration()
        return
    message := "EXPERIMENTAL SYSTEM-WIDE POL REDIRECT`n`nThis tool will request administrator approval, bind a loopback TCP port, then temporarily map wh000.pol.com to 127.0.0.1 in Windows hosts.`n`nThis affects ALL POL clients until stopped, and has NOT been validated in actual POL. Never run AutoPOL's proxy at the same time. The separate Recover button can repair a stale tagged entry after a crash.`n`nPower loss can leave the mapping behind until recovery. Test ONE account only.`n`nEnable for region " country "?"
    if MsgBox(message, "Confirm live proxy", "YesNo Icon!") != "Yes"
        return
    powershell := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
    helper := A_ScriptDir "\Proxy-POL.ps1"
    if !FileExist(powershell) || !FileExist(helper) {
        SetPOLProxyStatus("Proxy helper or Windows PowerShell missing.")
        return
    }
    try {
        DirCreate(A_ScriptDir "\data")
        if FileExist(App.polProxyStopPath)
            FileDelete(App.polProxyStopPath)
        if FileExist(App.polProxyStatusPath)
            FileDelete(App.polProxyStatusPath)
        App.polProxyToken := Format("{:08X}{:08X}{:08X}", Random(1,2147483647), Random(1,2147483647), Random(1,2147483647))
        parentPid := DllCall("GetCurrentProcessId", "UInt")
        command := '*RunAs "' powershell '" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' helper '" -Action Run -StatusPath "' App.polProxyStatusPath '" -StopPath "' App.polProxyStopPath '" -Token ' App.polProxyToken ' -ParentPid ' parentPid ' -Region ' country ' -LifetimeSeconds 1200'
        Run(command, A_ScriptDir, "Hide", &pid)
        App.polProxyPid := pid
        App.polProxyState := "starting"
        App.polProxyPort := 0
        App.polProxyRequests := 0
        App.polProxyStart.Enabled := false
        App.polProxyStop.Enabled := true
        SetPOLProxyStatus("Starting live POL proxy for " country " (UAC requested). Awaiting hosts verification...")
    } catch Error as err {
        App.polProxyPid := 0
        App.polProxyToken := ""
        App.polProxyStart.Enabled := true
        App.polProxyStop.Enabled := false
        SetPOLProxyStatus("Start canceled or failed: " Type(err) ". No successful proxy activation reported.")
    }
}

StopPOLProxy(ask := true, *) {
    global App
    if !App.polProxyPid || !ProcessExist(App.polProxyPid) {
        SetPOLProxyStatus("Proxy process not running. If a hosts marker remains, click Recover stale hosts.")
        return
    }
    if ask && MsgBox("Stop the live proxy and restore the hosts file?`n`nWait until clients have passed the PML handoff. Subsequent requests will not be accelerated.", "Stop live POL proxy", "YesNo Icon?") != "Yes"
        return
    try {
        if FileExist(App.polProxyStopPath)
            FileDelete(App.polProxyStopPath)
        FileAppend(App.polProxyToken, App.polProxyStopPath, "UTF-8-RAW")
        App.polProxyState := "stopping"
        SetPOLProxyStatus("Stop requested. The helper restores hosts BEFORE closing the listener.")
    } catch Error as err {
        SetPOLProxyStatus("Could not issue stop. Run Recover after helper exits: " Type(err))
    }
}

RecoverPOLHosts(*) {
    global App
    if App.polProxyPid && ProcessExist(App.polProxyPid) {
        SetPOLProxyStatus("First stop the active proxy. Recovery refuses to run alongside it.")
        return
    }
    if !POLHostsMarkerPresent() {
        SetPOLProxyStatus("No Vana launcher proxy marker found. Nothing to recover.")
        return
    }
    if MsgBox("Remove ONLY Vana'diel Launcher's tagged wh000.pol.com hosts line?`n`nThis requests UAC and leaves every unrelated hosts entry untouched.", "Recover hosts", "YesNo Icon!") != "Yes"
        return
    powershell := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
    helper := A_ScriptDir "\Proxy-POL.ps1"
    try {
        command := '*RunAs "' powershell '" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' helper '" -Action Recover'
        Run(command, A_ScriptDir, "Hide")
        SetPOLProxyStatus("Recovery launched. Click again after UAC/process completes to recheck hosts; do not start POL while marker remains.")
    } catch Error as err {
        SetPOLProxyStatus("Recovery failed or UAC canceled. Hosts may remain redirected.")
    }
}

POLHostsMarkerPresent() {
    path := A_WinDir "\System32\drivers\etc\hosts"
    try {
        return InStr(FileRead(path), "#vana-launcher-proxy-v1:") != 0
    } catch {
        ; A missing permission does NOT mean hosts is safe; the helper's own
        ; privileged preflight is authoritative.
        return false
    }
}

POLProxyTick(*) {
    global App
    if !App.polProxyPid
        return
    if !ProcessExist(App.polProxyPid) {
        state := App.polProxyState
        App.polProxyPid := 0
        App.polProxyStart.Enabled := true
        App.polProxyStop.Enabled := false
        if POLHostsMarkerPresent()
            SetPOLProxyStatus("PROXY EXITED, HOSTS MARKER REMAINS. Use Recover stale hosts BEFORE opening POL.")
        else if state = "stopping"
            SetPOLProxyStatus("Proxy stopped. No Vana launcher hosts marker remains.")
        else
            SetPOLProxyStatus("Proxy process exited. Check status and the hosts file before relying on acceleration.")
        return
    }
    if !FileExist(App.polProxyStatusPath)
        return
    try {
        if IniRead(App.polProxyStatusPath, "Proxy", "token", "") != App.polProxyToken
            return
        if Integer(IniRead(App.polProxyStatusPath, "Proxy", "pid", "0")) != App.polProxyPid
            return
        state := IniRead(App.polProxyStatusPath, "Proxy", "state", "unknown")
        if state = "ready" {
            App.polProxyState := state
            App.polProxyPort := Integer(IniRead(App.polProxyStatusPath, "Proxy", "port", "0"))
            App.polProxyRequests := Integer(IniRead(App.polProxyStatusPath, "Proxy", "requests", "0"))
            errors := Integer(IniRead(App.polProxyStatusPath, "Proxy", "errors", "0"))
            SetPOLProxyStatus("EXPERIMENTAL LIVE: 127.0.0.1:" App.polProxyPort " | PML requests " App.polProxyRequests " | errors " errors ". Next character is independent.")
        } else if state = "repair-required" {
            App.polProxyState := state
            SetPOLProxyStatus("HOSTS REPAIR REQUIRED. Keep POL closed; use Recover after helper exits.")
        } else if state = "blocked" {
            App.polProxyState := state
            SetPOLProxyStatus("Live helper blocked acceleration (hosts edit, port or launch failed). Click Check acceleration for conflict details; nothing is confirmed active.")
        }
    } catch {
        ; Atomic status file may be replaced while observed; retry next tick.
    }
}

SetPOLProxyStatus(message) {
    global App
    if IsObject(App.polProxyStatus)
        App.polProxyStatus.Value := message
}
