> **Source checkpoint, not a complete standalone installer.** This directory preserves the source from the 0.4.34 UPDATE ZIP. It omits auxiliary PowerShell scripts, image assets, and baseline fixtures expected by a full installation. Overlay the original ZIP on a backed-up working launcher installation; do not use this branch directory as a fresh install. The uploaded source has not been run under Windows in this publication step.

# AutoPOL AHK 0.4.34 — Restore password paste preparation

With **Launch each checked character automatically** enabled, the next Windower launch begins preflight one second after the previous client's last Enter. AutoPOL continues to track the previous FFXI window while the next POL instance starts and enters the password. If the previous handoff is still pending, the next login waits before entering a one-time code or sending its final confirmation. Window naming and auto-exit use the stable FFXI window checks.

The password sequence uses four cleanup Backspaces, then types and erases `a` before pasting. In the 0.4.33 test, paste appeared to fail with the letter and erasure removed. This restoration applies to both Compatible and Fast. Extract the update into the existing launcher folder and keep your INIs and encrypted credentials.

---

# AutoPOL AHK 0.4.32 — PlayOnline import in one preview

Open **Settings → Manage adventurers → Import from PlayOnline files…**. If AutoPOL can't find the standard PlayOnline installation, select its `PlayOnlineViewer\usr` folder. The preview lists the proposed POL slot, character name, and import action. Click **Import** to add the listed registrations or **Cancel** to go back.

New registrations start with the stored account name as the character name, the Default Windower profile, and the saved encrypted Default login. Rename them and choose a profile in **Manage adventurers → Edit**. An occupied slot displays its saved character and is skipped, so repeating the import preserves earlier edits. Duplicate character names block the batch. The scanner reads supported `homeNN\system.bin` records and uses the folder suffix for the proposed slot. The optional POL member label can still be set in Edit.

**POL Input Timing.** Compatible is the default and gives the new POL window 3 seconds to settle. Fast gives it 1.75 seconds and uses 72% of the usual waits for most later input steps, with a 25 ms floor. The held-Up reset and TOTP safety waits are independent of this setting. Compatible has successful multiclient reports. Fast has a recorded stall, and the Killala run cited in an older Fast test entry was actually Short Up with Compatible timing.

**Update.** Back up the working launcher folder and extract the update ZIP into it. Keep the existing INIs and `data/credentials`. The 0.4.31 notes below describe the earlier workflow.

---

# AutoPOL AHK 0.4.31 — Import directly from PlayOnline files (experimental)

**2026-11-06 | Read-only discovery and confirmation-first registration.** Under **Settings → Manage adventurers → Import from PlayOnline files...**, AutoPOL AHK now looks for `PlayOnlineViewer\usr` under the Windows Program Files (x86) directory. If it cannot find the folder, you can choose the installed `usr` folder manually. It reads ONLY `homeNN\system.bin`, **never `all\login_w.bin`, mail, cookies, or passwords**, and does not change any PlayOnline files.

The tested `usr.zip` contains 72-byte `system.bin` records for `home01`–`home05`, with a printable account-related string at byte offset `0x24`. The app supports only this observed format, with fixed-size/header/ASCII checks and 1–20 folder numbers. **These folder numbers are proposed slot numbers, not independently verified login slots. The stored string is NOT reliably the visible PlayOnline member label** (the user's slot 4 stores an unrelated Square Enix account name). If records cannot be recognized, the importer explains that it cannot safely infer the account list; the existing verified TSV route remains available.

The read-only preview shows folder, candidate slot, stored account-related identifier, FFXI character name, current PlayOnline member label, and Windower profile. Select each row and fill/verify the character and label; the profile dropdown uses the same Windower `settings.xml` choices as the normal character editor. Existing characters with matching saved slots are prefilled but never changed automatically. Before saving, the launcher asks whether you visually compared the proposed slots against the **current PlayOnline account list**, then shows an ADD/SKIP/CONFLICT preview and asks again for confirmation. Duplicate character names, slot collisions, conflicting saved slots, unreadable metadata, multi-bank mode, or missing encrypted Default login prevent unsafe additions. Successful imports only append native launcher registrations to `accounts-metadata.ini` using a backup and atomic replacement; they never overwrite existing registrations/credential references or use raw POL credentials. Imported characters inherit the already encrypted **Default login**.

**First Windows test:** Back up your current 0.4.30 folder, install the 0.4.31 UPDATE ZIP over it without replacing INI or `data\credentials`. Open **Settings → Manage adventurers → Import from PlayOnline files...**. Verify you see your five `homeNN` records; check the actual slots in POL, especially Myrr's **slot 4** (stored name is *not* her PlayOnline label). Fill in your preferred FFXI character names and current POL labels, then inspect the final preview before importing. Check a already-registered Lionstag is **SKIP**, not duplicated. First try Cancel to ensure nothing changes, then confirm only after the mapping is correct. This is not yet Windows/FFXI runtime tested; keep 0.4.30 as rollback. No early overlapping-login feature was added.

**Legacy context:** Older sections lower in this README describe retired proxy and diagnostic experiments for development history; those controls are not present in the current Settings menu.

---

# AutoPOL AHK 0.4.30 — Windower profiles and confirmed POL slot importer

**2026-11-06 | Focused usability update (Windows test pending).** Add/Edit Character now lists the profiles read from `settings.xml` in the folder containing the configured `Windower.exe`. The user-provided laptop sample confirms the blank Default profile plus `960x540`, `1280x720`, and `1600x900`, all with `enablefastlogin=true`. These names are **Windower presentation/launch profiles**, not POL account labels, slots, or FFXI characters.

**Usage:** Open Settings → Manage adventurers → Add or Edit; choose a Windower profile from the editable dropdown. Choosing **Default (Windower)** stores the blank default profile and launches with `-p ""`. If `settings.xml` is absent/malformed, the picker still allows typing a name. An existing saved name absent from XML is retained as an option to prevent silent profile changes. Profile choices are refreshed when opening the editor; Browse Windower to change which installation is consulted. XML is parsed in-process by Windows MSXML6, read-only, with external entities/DTD disabled, no PowerShell process.

**Confirmed POL slot import:** Settings → Manage adventurers → **Import POL slots...** accepts a UTF-8 tab-separated `.tsv` file with exactly four columns: `Slot`, `POLLabel`, `Character`, `WindowerProfile`. Header optional. The POL label is informational; the numeric slot selects the account. The Windower profile can be blank for Default. A live preview shows each row and whether it would be added, skipped because a character already exists, or blocked because another character occupies that slot. **Nothing is committed without explicit confirmation.** Existing registrations/credential references remain unchanged, and new registrations inherit the encrypted shared Default login, which must already be configured. The application does **not** read passwords from POL files, modify `login_w.bin`, import Square Enix account IDs, or decode `usr.zip`. A confirmed single-POL-bank slot list is required; multiple AutoPOL profile banks are rejected as ambiguous.

The user-supplied laptop slot mapping includes the POL label **Myrr** for slot 4. The differently named account-related value found in `home04/system.bin` is a **Square Enix account name**, not the PlayOnline label, per the user's clarification. The importer trusts the user's verified TSV rather than inferring labels from POL binary data. The two saved Windower profile names from the old AutoPOL configuration can be used as initial suggestions, but should be checked before import. No private `usr.zip`, original XML, or credential-bearing AutoPOL JSON is redistributed.

To prepare a TSV in a text editor, use tabs between fields, one verified POL slot per line:

```text
Slot<TAB>POLLabel<TAB>Character<TAB>WindowerProfile
1<TAB>example label<TAB>example character<TAB>960x540
```

`<TAB>` above represents an actual Tab key. A separate ready-filled laptop TSV is provided alongside this test build, not inside the application archive. Importing existing characters does not alter them; edit them explicitly to update slots or profile choices. New registrations require the existing shared encrypted Default login; character-specific credentials can still be set through the editor.

**Install:** Overwrite the existing `AutoPOL-AHK.ahk`, or extract the UPDATE ZIP over your existing installation. Keep `launcher.ini`, `accounts-metadata.ini`, `data/credentials`, Trust textures and other personal data intact. No change to POL input timing, account slot mapping, encrypted credentials, focus recovery, automatic multilogin, or auto-exit. Keep 0.4.29 as rollback until Windows confirms the profile dropdown.

**Verification:** Linux static/source regression tests and a synthetic XML fixture validate the new picker and preserve the 0.4.25 known-good frozen login functions; no native AutoHotkey v2, Windower or FFXI execution was possible in this environment. Source is a separate local development branch, not pushed to GitHub.

## Changelog (most recent first)

- **0.4.30:** Editable Windower profile dropdown from sibling `settings.xml`; confirmation-first user-verified TSV slot import with informational POL member labels and conflict-safe merge; unchanged login routines.

---

# AutoPOL AHK 0.4.29 — Character-only window names, saved selections

**2026-11-06 | Small user-facing polish build.** The user reports the launcher consistently recovers foreground focus during PlayOnline login, and Lionstag successfully logged in on the laptop. These are live observations of earlier builds; **0.4.29 itself has not run on Windows here**. Preserve that working keyboard, credential, and FFXI handoff sequence.

**Character-only captions:** The default is now **on**, with a Settings checkbox to turn it off. When a newly targeted POL viewer is detected, the launcher changes only that window's title to the adventurer name, e.g. `Lionstag`. For an automatic-party handoff, the uniquely confirmed new FFXI window is named in the same manner. The names are cosmetic, not identities: discovery and handoff recognition additionally use registered window handles and PIDs. The FFXI caption may be reset by the game or another tool. An isolated single-character launch still does not automatically label the final game window because the handoff watcher is an automatic-party feature.

**Saved character selection:** Checking/unchecking launch tiles writes `SelectedAdventurers` to `launcher.ini`, and the checked roster is restored by matched names at startup, even after automatic launcher exit. This survives slot-based sorting without selecting a different account. A first-time install with just one saved adventurer checks it automatically. No credentials or extra personal data are saved in the selection field.

**Slot sorting:** On by default; can be turned off under Settings. It changes only display and queue order, never saved POL slot, group, source index, or encrypted credential association.

**Importing PlayOnline slot labels:** The attached `usr.zip` still cannot be read as a verified `slot -> label` table from `login_w.bin`; its binary account records appear opaque. PlayOnline member labels are arbitrary and separate from FFXI names. A user-provided list of bank/group, POL slot and member label, plus FFXI character name and Windower profile, is sufficient to *design* a preview/merge import; that importer is not present in this version. Consult `POL-USERDATA-RESEARCH.md`. Never copy the private `usr.zip` into the launcher or testing package.

**Install:** Overlay the UPDATE ZIP into the existing launcher folder; keep `launcher.ini`, `accounts-metadata.ini`, `data/credentials`, and local Trust assets. A full fresh install needs your account metadata/credentials separately. The login timing, Up-reset, encrypted credentials, and automatic-party advancement are unchanged. Keep 0.4.28 as rollback until the new titles and selection persistence work on Windows.

**Static verification only:** `python tests/check_package.py` verifies saved selection, default settings, named HWND/PID discovery and frozen input/login functions. Windows AHK v2 and PlayOnline visual tests still required. Local commit only; no GitHub push.

## Changelog (most recent first)

- **0.4.29:** Character-only POL/FFXI window titles on by default, saved launch selection, optional slot sorting on by default, preserved account/credential/handoff flows. Read-only POL import research updated; no automatic parser or early handoff mode.

---

# AutoPOL AHK 0.4.28 — Window labels, sorted adventurers and removable imports

**2026-11-06 | Conservative polish batch.** User confirms the launcher reliably recovers focus after switching away from PlayOnline, and that Lionstag logged in successfully on the laptop. Version of the laptop test was not explicitly established. This user-observed behavior is a reason to preserve 0.4.27's exact input, credentials and handoff timing.

**What changed:** Characters are shown (and automatically queued) by ascending saved POL slot, then profile group and character name. This changes only their visible order and next-launch order, never their actual POL slots or original imported account indices. Existing selected characters remain selected by name, and the Manage Adventurers focus follows the same name after a sort. **Remove** now allows imported as well as native registrations to be removed *from this launcher only*: it never changes `login_w.bin`, the source JSON or other accounts' credentials. Native per-character encrypted credential files are removed only after the metadata commit, as before; the shared default is never removed.

**Optional window titles:** Under Settings → Automatic Party Launch, enable **Name PlayOnline and FFXI windows by character** to label a specifically newly detected POL window `PlayOnline Viewer - Character` and, on automatic-party handoff after the existing stable three-second check, label the uniquely detected game window `FINAL FANTASY XI - Character`. This feature is **OFF by default** and affects titles only, not keyboard focus/targeting, login success verification or process identity. Game windows may overwrite their titles; this change is not a guarantee that a title persists. For a one-character launch without automatic party, only its POL window is currently labeled.

**Attached `usr.zip` investigation:** The supplied archive contains PlayOnline account-related user data, including an opaque `login_w.bin`. See `POL-USERDATA-RESEARCH.md` for read-only structural findings and a proposed confirm-before-import workflow. It is **not possible yet to safely auto-populate character names, true slot mappings, Square Enix passwords, TOTP secrets or Windower profile names from that archive**. There is no `usr.zip` importer in 0.4.28, and the private archive is not part of either package.

**Future early-launch experiment:** No change in this batch. The existing automatic-party gate waits for a unique, stable new FFXI window before launching the next character. We can later add an explicit opt-in overlap mode that tracks all pending handoffs independently, rather than assuming that final Enter means login succeeded.

**Installation/testing:** Keep the last confirmed 0.4.27 folder as rollback. Extract the UPDATE ZIP over the existing folder, preserving `launcher.ini`, `accounts-metadata.ini`, `data/credentials`, Trust assets and any original AutoPOL config file. Try opening Manage Adventurers first: check the POL slot order and that removing an *unused* imported registration affects only the launcher; test optional title labels with one character, then an automatic party. Compatible timing and all login code remain unchanged. No Windows/AHK/FFXI live test of 0.4.28 was performed here; static and package verification are listed in `TESTING.md`.

## Changelog (most recent first)

- **0.4.28:** Deterministic POL slot order, imported registration removal without touching source data, optional HWND-scoped POL/game title labels, read-only `usr.zip` import feasibility study; no early-login overlap or credentials changes.

---

# AutoPOL AHK 0.4.27 — Safe skinned-button hover lifecycle

**November 5, 2026 | Focused bug fix.** The user saw `Error: The control is destroyed` at `SyncSkinnedButton` when backing out of Manage Adventurers/Add Character and returning to the main roster. Root cause: the hover registry kept entries for controls in the Manage Adventurers dialog after that GUI was destroyed. A late mouse-move callback then queried the destroyed `Gui.Control.Hwnd` and raised a runtime error.

**Fix:** Every temporary character-management, Add/Edit, and Default Login window now unregisters its skinned button handles before `Destroy()`. Mouse handlers use saved numeric HWNDs with native window/parent checks, and discard stale entries instead of calling a destroyed control getter. The selected amber buttons, hover glow, login timing, console-free credentials, automatic multilogin and auto-exit stay as in 0.4.26. No saved accounts or INI data are modified.

**Install:** Back up the working folder, then replace **only** `AutoPOL-AHK.ahk` with the 0.4.27 script (or overlay the UPDATE ZIP into the same folder). Keep `launcher.ini`, `accounts-metadata.ini`, `data/credentials` and all Trust artwork.

**Windows reproduction check:** Open Settings → Manage adventurers; hover Add, Edit, Remove; close, repeat; open Add, cancel, then select Killala without modifying other profiles. No `control is destroyed` popup should appear; hovered glow should clear when dialogs close. Test one normal login afterward to check for regressions. Static source tests cannot substitute for this Windows check.

## Changelog (most recent first)

- **0.4.27:** Fix stale hover-control registry and late WM_MOUSEMOVE/WM_MOUSELEAVE crashes after closing temporary GUI windows.

---

# AutoPOL AHK 0.4.26 — Streamlined Settings and silent default login

**November 1, 2026 | UI and default cleanup.** The user live-confirmed 0.4.25's **console-free encrypted credential helper** with Franklet: the login succeeded, the PowerShell flash was absent, and AutoPOL AHK automatically exited. Previously, Cioara and Clairvaux successfully auto-logged in with one click in 0.4.20; Killala logged in with **Short Up reset + Compatible timing**. These are user observations, not native tests of this new package.

**Settings now:** Manage adventurers and Default login at the top; Windower.exe (browse); POL input timing (Compatible/Fast); automatic party and optional launcher auto-exit; Login diagnostics (record timings, Open login logs). These are the only controls in Settings. The main window remains status, Launch, Cancel, character buttons, Settings. Removed from visible menus: AutoPOL import, the redundant Windower & Profiles header, Clear selection, Trust texture chooser, extra Up-reset selector, Dry Run, metadata restore, console-free credentials toggle, proxy and hosts experiments, and the separate Diagnostics & recovery window. Import and legacy recovery implementations remain dormant in the source to preserve existing imported-account compatibility and possible manual recovery; no proxy is started by the launcher.

**Defaults:** Short Up reset now applies automatically to regular account lists (all configured slots 1–11). A configured slot 12–20 automatically uses the existing longer reset; this is not an exposed option. Console-free credential retrieval is always selected (no PowerShell console flash reported by the user). Compatible input timing remains the default. Neither actual POL keystroke functions nor the secure credential format or the FFXI handoff algorithm changed.

**Trust artwork:** On startup the launcher uses `assets/trust/backgrounds/` and `assets/trust/buttons/` if populated. Otherwise it **copies the ten original required PNGs** from the user's already installed Trust addon (located via the saved Windower.exe folder or the formerly saved Trust asset path) into that local folder, and uses them thereafter. No manual picker. The downloadable ZIP intentionally does not redistribute third-party binary artwork. On a new PC, install Trust in `Windower\addons\trust` first, or manually copy its assets to the bundled `assets/trust` directories. If unavailable, the existing navy fallback still works. The original amber Trust selection state and hover glow remain; disabled button text is now desaturated slate blue (`#72839B`).

**Old proxy hosts recovery:** Proxy features are retired from the interface. If startup reports an old tagged `#vana-launcher-proxy-v1:` entry in Windows' hosts file, do not launch POL until it is resolved. Back up the hosts file and, only if it is the old launcher-tagged entry, run the retained `Proxy-POL.ps1 -Action Recover` script in an elevated PowerShell window. Do not remove other programs' hosts mappings. This legacy helper is shipped only for recovery and is not used by normal login.

**Installation:** Back up the working folder, then overlay the **0.4.26 UPDATE** into the *same* folder; preserve `launcher.ini`, `accounts-metadata.ini`, `config.json` (if used), and `data/credentials`. The update includes the AHK script, docs, tests, and any new glow dimensions. Trust PNGs are imported automatically on the first new run. Previous `.ini` preferences for removed options are ignored, not deleted. Keep the **0.4.25** script/package as the known-good rollback.

**Verification:** Static invariants and SHA256 comparisons of 18 frozen POL input, focus, credential, and handoff functions against the complete 0.4.25 distribution, plus glow PNG checks and extracted-archive tests. No native Windows AHK v2, POL, or FFXI runtime test of 0.4.26 was possible here. The real local texture copy is also pending a Windows test.

## Changelog (most recent first)

- **0.4.26:** Simplified Settings; hid obsolete import/proxy/recovery/experimental controls; made Short Up (with automatic extended fallback) and console-free encrypted credential helpers the defaults; auto-copy actual installed Trust textures to launcher-local `assets/trust`; improved disabled button text contrast; kept automated party input and credentials unchanged.

---

# AutoPOL AHK 0.4.25 — Short Up parties, streamlined login, optional console-free credentials

**November 1, 2026 | Windows testing build.** Correction to the previous 0.4.24 report: the user successfully logged Killala in with **Short Up reset + Compatible overall timing**, **not Fast overall timing**. The 0.4.20 two-character automatic Cioara/Clairvaux login and launcher auto-exit remain the known-good automatic-party baseline. Short Up across an automatic party is newly available but not yet live-tested.

**Auto Party + Short Up:** Removed the arbitrary queue-length restriction on Short Up. It is selectable independently of Compatible/Fast, and automatically launching several characters can now use it. A Short reset still refuses to launch if *any configured POL slot exceeds 11*, to avoid incomplete resets on extended rosters. The successful Short sequence is unchanged: initial Up-down and 17 additional held Up-down repeats at scheduled 40 ms waits, then a 200 ms post-release pause; actual timer granularity is 50 ms, so observed time may exceed planned waits. Proven remains the default for new installations. No other input pacing has been shortened in this version.

**Streamlined login:** Manual POL Login, Slot-only testing and Existing-POL attachment have been removed from the interface and normal launch code. Launch always starts the requested Windower profile and performs full POL account selection, password and optional TOTP. The successful input plan is still unchanged (including unused internal mode branch kept to preserve its verified source hash). Dry Run and automatic party/auto-exit are unchanged. POL auto-login setup is assumed disabled; the redundant setup checkbox has been removed.

**Console-free credential helper (opt-in test):** Under **Settings → Diagnostics & recovery**, enable **Console-free credential helpers (test; still encrypted)** to replace `WScript.Shell.Exec` with an AHK Win32 `CreateProcessW` subprocess using `CREATE_NO_WINDOW` and in-memory anonymous stdin/stdout pipes. This affects native encrypted password/TOTP retrieval and saves, imported AutoPOL credential reads, importing metadata, and read-only acceleration preflight. It uses **the same existing PowerShell scripts**, does not write plaintext secrets to disk, does not change encrypted credential files, and still checks/recovers the exact POL HWND before sending secrets. **Default OFF until the Windows pipe implementation is live-tested.** Switch it off if a login fails; no credential migration is needed. A plain-text login option was considered but isn't needed to eliminate console creation. Unchanged auxiliary artwork/proxy `Run/RunWait` launchers may still generate unrelated Windows UI (especially UAC).

**Testing:** First use the original helper mode for a known-good single-character login. Then enable the console-free checkbox and repeat with a single character. Verify whether the PowerShell flash has disappeared and the password/TOTP is entered correctly; if not, toggle it OFF and share only the diagnostic timings/error (never credentials). For party mode with Short Up, keep Compatible pacing initially.

Install the UPDATE ZIP over 0.4.24 without replacing `launcher.ini`, `accounts-metadata.ini`, imported AutoPOL JSON or `data/credentials`. Keep **Compatible timing + Short Up**, enable Automatic Party, select two known accounts with configured slots 1–11, and click Launch once. Keep Auto Exit off for a first test if you'd like to see the final status. Cancel if anything misaligns. Timing logs are at `data/diagnostics/login-*.tsv` or **Settings → Diagnostics & recovery → Open login logs...**. They contain timing metadata but not secrets; sharing them is optional. The Windows test has not been performed by the developer.

**Verification:** Static regression and simulated handoff tests passed, plus independent ZIP integrity/extraction checks. Actual AutoHotkey v2, Windower and POL runtime behavior is unverified for this release. The C++ reference repository was not modified.

## Changelog (most recent first)

- **0.4.25:** Allowed Short Up reset with automatic parties; removed Manual/Slot-only/Existing-POL controls; added a separately switchable console-free Win32 helper subprocess with legacy fallback; preserved original encrypted files, native POL input plan, timing, and exact-HWND credential focus verification; corrected the Killala test record.

---

# AutoPOL AHK 0.4.24 — Fast automatic parties and simpler Settings

**November 1, 2026 | Windows testing build.** The user reports a successful **Fast-paced single-character login for Killala** in 0.4.23. Earlier, Cioara and Clairvaux successfully logged in through one-click automatic multilogin with launcher auto-exit using Compatible pacing in 0.4.20. The new combination, **Fast + automatic party**, has *not* yet been tested live.

**Fast automatic launch:** Removed the obsolete `Compatible only` requirement. Enable **Settings → Launch each checked character automatically**, choose **Fast** in POL input timing, and Launch two checked characters once. The existing exact POL-window targeting, password/TOTP focus recovery, per-client FFXI handoff, stable-window check, Cancel and auto-exit remain unchanged. **Compatible stays the default** and is the fallback if Fast drops an input. The separate ~0.9s **Short Up reset** is still limited to a single-character queue, and to account lists without configured slots above 11; the successful Fast test does not validate the short reset.

**Less crowded Settings:** The everyday page keeps Windower.exe, Manage adventurers, AutoPOL import, Default login, clear selection, Trust textures, input timing, automatic-party launch and auto-exit. The **Timing diagnostics** toggle, **Open login logs**, and **Proxy / hosts tools** are reached through **Settings → Diagnostics & recovery**. Logs remain ON by default. Nothing related to password storage, POL input, hosts recovery or account metadata was removed or changed. The UI is more compact without changing functional defaults.

**Test:** Back up the current working installation. Apply the 0.4.24 UPDATE ZIP over it while keeping `launcher.ini`, `accounts-metadata.ini`, imported AutoPOL JSON, and `data/credentials`. In Settings, use **Fast** and enable automatic party, but leave **Proven Up reset** selected under Diagnostics & recovery. Select two characters you can log in safely, click Launch once, and verify each reaches a new FFXI window before the next starts. If one stalls, use Cancel and return to Compatible. Review `data/diagnostics/login-*.tsv` if the problem repeats; the logger contains no password/TOTP values. Automatic exit closes the launcher only.

**Verification:** Source regression checks and ZIP integrity/extraction tests are available in `tests/check_package.py`. No Windows AHK v2, PlayOnline or in-game login was performed by the developer for this release. The C++ AutoPOL fork remains unchanged.

## Changelog (most recent first)

- **0.4.24:** Permitted Fast pacing for automatic party launches; simplified the front-facing Settings page by moving timing-log controls and proxy tools under Diagnostics & recovery. Preserved the separate short-Up multislot safeguard, credential protections, proven Compatible mode and FFXI handoff detection.

---

# AutoPOL AHK 0.4.23 — POL Focus Recovery & Solo Short-Reset Test

**November 1, 2026 | Corrective Windows testing build.** User reported that 0.4.22 blocked the Short reset even with only one character selected and that a PowerShell credential helper could temporarily take focus, leading POL to abort before pasting the password. The user also asked to remove the visual horizontal separators between displayed sections. No live 0.4.23 tests have been performed yet.

**Solo Short reset:** The guard now checks the **actual selected queue size**, not just whether the automatic-party preference is enabled. With exactly one checked character, the ~0.9-second experimental Up reset is permitted even if Auto Party is on. A queue with two or more characters still requires Proven. Any configured account with a slot above 11 produces an explicit block while Short is selected, instead of silently using a different reset and claiming it was a Short test. The original Proven repeat sequence and default remain unchanged. Keep overall **POL input timing = Compatible**.

**Password/TOTP focus:** Native encrypted credentials and imported AutoPOL credentials are still read through the existing PowerShell pipe-based helpers, with no plaintext files. Their commands now request `-WindowStyle Hidden` (best effort). After each password or TOTP retrieval, the launcher **reactivates and checks the exact original POL HWND**, then permits paste/typing only if it is truly in the foreground. Failed focus recovery aborts the login rather than injecting a secret into another application. The existing clipboard restoration and native input sequence are preserved. The helper's console might still briefly flash on some Windows configurations; the exact-HWND check is the actual safety improvement. Redacted timing logs may include a `pol_focus_recovered` event, but never a credential value.

**Appearance:** Removed the ornamental gold horizontal divider rules from the main, Settings, and Proxy views. The actual Trust background, selected amber buttons, hover glow, and existing control positions remain unchanged.

**Test:** Back up your working launcher folder and extract the UPDATE ZIP over it (retain all `.ini` files, imported JSON, `data/credentials`, and Trust images). In Settings, choose Compatible input pacing, then in Diagnostics & recovery select Short Up reset. Leave auto-party enabled if you wish, but **select exactly one character**. Test POL slot selection and password/TOTP. For unattended multilogin with two or more characters, restore Proven before launching. If a credential focus recovery occurs, the diagnostic TSV under `data/diagnostics` can show the event and elapsed step time. Share only noncredential diagnostic files if comfortable. This build has static/source-model checks only; real Windows AHK and PlayOnline testing are pending.

## Changelog (most recent first)

- **0.4.23:** Fixed Short reset being rejected when automatic-party mode was enabled for one selected character; added explicit high-slot restriction; requested hidden credential-helper windows and verified POL HWND focus after password/TOTP retrieval; removed decorative section divider lines. Kept Proven input and multi-character focus safeguards as the defaults.

---

# AutoPOL AHK 0.4.22 — Optional Short Account-List Up Reset

**November 1, 2026 | Experimental timing adjustment, separate from proven Compatible login.** User corrected our target: the initial POL account-list Up reset should be **one second or less**, not the old ~3 seconds. The live-confirmed 0.4.20 automatic party baseline still has ~2.97 seconds of held Up key-downs for accounts 1–11, or ~4.59 seconds for extended 12–20 slot rosters. That hold was retained from the original 0.4.2 conservative experiments; it was **not** the requested target.

**Settings → Diagnostics & recovery → POL account-list Up reset** now has **Proven** (default; unchanged) and **Short** (~0.9 seconds, test solo). Short emits an initial native held Up down plus 17 further downs with a 40 ms planned wait; on the 50 ms Windows timer that aims for ~0.9 seconds rather than the original 33×90 ms. The actual duration can be longer due to scheduling/focus overhead and will appear in the existing per-action TSV diagnostics. It is **not yet confirmed** that POL consumes all those quicker repeats and clamps to the top.

**Safety boundaries:** Extended 12–20-slot configurations always fall back to Proven even when Short is selected. Automatic multilogin is blocked while Short is selected; return to Proven to run the already live-confirmed party flow. Short mode does **not** enable the previously stalled Fast overall pacing: leave POL input timing set to Compatible. No changes to keyboard-injection functions, password or TOTP handling, handoff, auto-exit, Trust UI assets, or external PowerShell helpers.

**Testing:** Back up the working 0.4.21 folder, install the UPDATE ZIP over it (keep all INIs, encrypted credentials and original AutoPOL JSON). With automatic party disabled, select a *single* known-working character and set Compatible timing + Short Up reset. Verify POL navigates to the correct account and logs in. The longer Proven hold is a one-click fallback. Inspect the new `data/diagnostics/login-*.tsv` file if the account list does not clamp; share only if comfortable. This package was verified structurally and through source-level regression tests, **not** in Windows/POL.

## Changelog (most recent first)

- **0.4.22:** Added a separate opt-in short held-Up account reset targeting ~0.9 seconds for nonextended POL rosters. Preserved proven held-Up repeats as default, extended-roster fallback and automatic-party guard, with credential/handoff functions unchanged.

---

# AutoPOL AHK 0.4.21 — Minimal Party Screen and Timing Diagnostics

**October 31, 2026 | Windows AHK v2 beta.** The user has live-confirmed 0.4.20 successfully launched Cioara and Clairvaux with one click and exited automatically afterward, while Myrr was already logged in. That 0.4.20 flow is the known-good baseline; 0.4.21 UI and timing capture require a Windows test.

**Front screen:** Messages at top; Launch / Cancel; large two-column character buttons; one Settings button at the bottom. **Settings → Manage adventurers...** provides a character dropdown and Add, Edit, Remove. The selected character is explicit there; clicking a tile on the main window still checks/unchecks it for launching. Checked characters retain the amber Trust button; a separate gold halo appears on **hover only**, not persistently on the last click. When automatic-party mode is on, the action button reads simply **Launch**.

**Timing recorder (on by default):** Every run records `data/diagnostics/login-YYYYMMDD-HHMMSS-PID.tsv`, including launch-request/preflight timing and Windower start to POL detection, POL detection to input-plan readiness, redacted per-action delays, and POL-to-FFXI handoff timing. The recorder records operation classes and numeric indices, **never actual keys, login passwords, secret seeds, 6-digit TOTP codes, clipboard contents, imported JSON, account IDs, or window captions**. Detailed actions are buffered until the plan finishes to minimize timing interference. Logs are local only; no upload or telemetry is performed. Use **Settings → Open login logs...** to find them, and uncheck **Record login and handoff timings** to disable future events. The program intentionally continues its login behavior if a log file cannot be written.

**The measurements matter:** Once a real 0.4.21 run produces a TSV, compare the `since_windower_ms`, `since_pol_ms`, `input_elapsed_ms`, `handoff_ms`, and actual-spaced-vs-planned waits before changing delays. The original Compatible timings remain unchanged and recommended; Fast stalled in user testing.

**Install:** Back up the working 0.4.20 folder, then extract the **0.4.21 UPDATE ZIP** into that *same* folder, retaining `launcher.ini`, `accounts-metadata.ini`, any imported AutoPOL `config.json`, and encrypted `data/credentials/`. The ZIP includes all Trust/glow artwork and the helper scripts but does not include any user profile or credentials. Diagnostics are saved in the install folder's `data/diagnostics/`, independently of FFXI windows and the launcher closing itself. `VanaLauncher.ahk` remains a compatibility entry point.

**Static verification only:** Source/regression checks, safe logger-source checks and archive checks are run before delivery. Actual UI/logging and multibox behavior in 0.4.21 are awaiting a Windows test.

## Changelog (most recent first)

- **0.4.21:** Moved Add/Edit/Remove into a Settings-managed character dropdown; reduced launcher front to status, Launch/Cancel, tiles and Settings; simplified automatic-party button label; made halo hover-only while preserving amber queued art; added default-on redacted local timing diagnostics and Open Logs action. No known-good input or credential-function changes.

---

# AutoPOL AHK 0.4.20 — Automatic Party Handoff (opt-in beta)

**October 31, 2026 | Windows AHK v2 development/testing build.** **Live observation:** Cioara and Myrr have each logged in successfully with Compatible timing, including Myrr after another game was running. **Fast timing stalled** during user testing; stay on **Compatible**. No one has yet live-tested automatic chaining.

**One-click party:** In **Settings**, check **Launch each checked character automatically (Compatible only)**, and optionally **Close AutoPOL AHK when the final FFXI window is detected**. Both are OFF on existing installations unless you explicitly enable them. On the main screen, check Cioara and Myrr (prefer exactly these two for the first trial) and click **Launch once**. Every selected character is launched serially in the existing roster order. The normal single-character/one-Launch-at-a-time behavior remains unchanged when automatic party is unchecked.

**Handoff protocol, not blind delays:** The launcher captures existing FFXI window handles before launching each Windower profile. It then identifies a distinct newly created PlayOnline Viewer HWND as before and uses the existing proven POL key sequence. When that input plan ends, it **does not** treat Windows accepting SendInput as successful authentication. It waits for a **new**, not previously existing, visible window whose title begins `FINAL FANTASY XI` or `FFXI` (excluding obvious Config/Update/Installer windows); simultaneously, the specific POL window must be closed or no longer have the PlayOnline Viewer title. The same new FFXI HWND must persist for 3 seconds before scheduling the next Windower profile. The next profile receives its own snapshot of existing POL and FFXI windows. If two new windows appear, the previous POL stays at the login screen, or a title varies from these known patterns, the queue **stops safely after 120 seconds**. This signal is a window handoff, **not proof** the character is fully loaded in-game or authenticated. No keys are sent to a prior client.

**Cancellation and auto-close:** The Cancel button and Ctrl+Shift+F10 cancel the *entire* automatic party attempt. A failure aborts further automatic launches and leaves any existing game windows alone. Auto-close applies only to **this AutoPOL AHK launcher**, after the final detected FFXI window handoff; it never closes FFXI/POL and never initiates in-game logout. Auto-close is optional and initially OFF so first testing can preserve the diagnostic message.

**Safety prerequisites:** Full POL login, `singleProfile=true`, working individual character secrets, exact named Windower profiles, admin approval, and **Compatible** timing are required. The code validates selected POL slots, profile arguments and credential-file existence before beginning the unattended sequence. The default proxy remains OFF, and no hosts file changes are performed during launches. A late fullscreen focus switch during a held-Up reset still causes a safe abort rather than blindly injecting into another window.

**Installation:** Back up the current **0.4.19** folder. Extract **AutoPOL-AHK-0.4.20-UPDATE.zip** over the existing installation; keep `launcher.ini`, `accounts-metadata.ini`, original imported AutoPOL JSON, and `data/credentials` as-is. New optional settings persist in launcher.ini. Do not change your proven individual character profile settings.

**First Windows test:** In Settings, set **Compatible**, enable auto party, **leave auto-close OFF**. Select only Cioara and Myrr and click Launch once. Confirm Cioara reaches the new FFXI window; see if Myrr's Windower profile automatically starts. Do not manually switch focus during held-Up input unless intentionally testing the abort path. If it stops, copy the exact status text and identify whether the new game window was visible and whether PlayOnline Viewer remained open. No passwords, secrets or config.json needed. After a successful two-character test, optionally enable launcher auto-close for the next trial. If the program stalls, Cancel stops further launching; any existing FFXI windows remain.

**Verification:** Python structural/regression and synthetic handoff tests passed. Native AutoHotkey v2, actual Win32 window titles, POL-to-FFXI transitions, multi-login focus interactions and auto-close **have not been run here**. This is a deliberately conservative first attempt; the title-based handoff might need adjustment after your PC observations.

## Changelog (most recent first)

- **0.4.20:** Added opt-in serial party launch with verified new PlayOnline and FFXI HWND handoffs, 3-second stability, 120-second timeout, Cancel-all, Compatible-only gating, and optional launcher-only auto-close. Individual login mechanics and existing Trust visual states unchanged.

---

# AutoPOL AHK 0.4.19 — Character Focus & Faster POL Timing (Opt-in)

**October 31, 2026 | Windows AHK v2 test build.** User-confirmed Cioara and Myrr successful individual logins are the compatible baseline. Do not assume the faster timing or unattended chaining is verified. Preserve the working v0.4.18 folder.

**Amber selected state versus Edit/Remove focus:** Clicking a character still checks or unchecks it for the Launch queue. Its Trust `_selected` button art stays amber when checked. A separate soft edge glow follows the *last clicked* character, showing who **Edit/Remove** will act on even if unchecked. Hover adds a brighter temporary halo without altering selection. The PNG glow overlays remain part of the update ZIP.

**Add Character shortcuts:** `Add → Import AutoPOL profiles` and `Add → Default login...` now appear at the bottom of the editor. The Import shortcut closes the editor and opens the existing file chooser, preserving existing native accounts and their credential references. The Default shortcut opens the usual encrypted shared-login editor without discarding the Add form. Blank password for new native characters still inherits the saved default.

**Restore metadata:** No automatic `.bak` restore before import. A restore is a *rollback* and can lose newer native character entries. The current importer safely creates its own pre-import backup and rolls back if the import fails. Explicit `Restore metadata...` remains under **Settings → Diagnostics & recovery...**, for genuinely corrupt metadata. Import from Add or Settings uses the same importer.

**Faster login option:** Under **Settings → POL input timing**, choose **Compatible (proven login timing)** or **Fast (test one character first)**. Compatible stays the default and retains all existing input timing. Fast reduces the initial account-menu wait from 3 seconds to 1.75 seconds and scales other post-ready pauses/key gaps to 72% (minimum 25 ms); **does not shorten** the held-Up slot reset, TOTP expiration safety or native key hold. The planned saving is approximately 2.4 seconds for a first-slot login, subject to Windows/POL readiness and credential-helper overhead. Start with one character and switch back immediately if POL misses input. The user-confirmed compatible speed remains available.

**Consecutive parties:** The current launcher handles newly spawned POL windows by HWND and checks focus before sending each step; a full-screen game can still steal focus. This release **does not** automatically launch the next character; select several characters and use Launch once per character as before. The future unattended flow will check previous-client handoff and new-window identity, not rely solely on a timer.

**Install:** Back up your installed folder. Extract the **0.4.19 UPDATE ZIP into your existing AutoPOL AHK directory**, replacing the script, docs/tests and `assets/glow` additions. Keep `launcher.ini`, `accounts-metadata.ini`, original AutoPOL JSON, and `data/credentials` intact. Do not download the complete ZIP into a new folder if your encrypted local credentials are stored in the original folder. Standalone acceleration proxy stays disabled.

**Verification:** Python static/regression checks and ZIP content/integrity validation completed here; no Windows AHK/POL/FFXI runtime is available. This build is local only (not pushed to GitHub).

## Changelog (most recent first)

- **0.4.19:** Separated Edit/Remove target halo from queued Trust amber art, kept hover glow; added Import AutoPOL and Default Login buttons to Add; moved metadata Restore under diagnostics; added saved Compatible/Fast POL input timing selector. Preserved password/TOTP helpers, slot-reset hold, and proxy implementation.

---

# AutoPOL AHK 0.4.18 — Amber highlights and accessible Settings

**October 31, 2026 | Windows/AHK v2 testing build (not yet Windows-verified).** This is a UI-only follow-up to the user's first report that the Trust-tiled background looks good on their PC. Preserve the existing 0.4.17 folder for rollback until the new controls and Settings are tested.

- **Selection:** Checked adventurers keep a quiet amber outline; moving the mouse over any enabled Launch/Cancel/character/Settings/action button brightens the same outline. The underlying *actual Trust three-piece button textures* still supply the fill and selected-state art. We generated small transparent PNG halos for the exact control sizes in `assets/glow/`; they are included with both update and full packages. No new process or file write happens on mouse movement. Without Trust installed, navy fallback buttons still get the same glow.
- **Settings height fix:** The background Picture used to push relatively positioned Settings controls down by its own 780-pixel height. The first control now uses an explicit `y15` anchor, and Settings is a compact page with a dynamically measured height. **Login diagnostics...** and **Proxy / hosts tools...** open two shorter windows. All existing options and recover-hosts actions remain accessible. The Default Login window received the same explicit first-control anchor fix.
- **Install:** Back up the folder and extract `AutoPOL-AHK-0.4.18-UPDATE.zip` **into the existing AutoPOL AHK folder**. Keep `launcher.ini`, `accounts-metadata.ini`, `data/credentials`, installed Trust images, and original AutoPOL `config.json`. Replacing only `AutoPOL-AHK.ahk` will omit the new `assets/glow/` PNGs, so use the update ZIP.
- **Test:** Open the launcher, select/deselect one character, move your cursor over character and Launch buttons, and verify amber glow appears and disappears without affecting selection; open Settings and both diagnostic windows to check that every option and Close button is visible at PC and laptop resolutions. Confirm a single character still launches using the known-good login sequence. The proxy should remain off; do not start it just to test layout.
- **Verification:** Linux static/regression tests check presence and PNG dimensions of all needed halo files, nonblank headings anchored at the top, page separation, unchanged native POL input/credential/proxy functions. Actual AHK rendering, mouse tracking, Windower launch and POL login require **Windows testing**.

## Changelog (most recent first)

- **0.4.18:** Added amber hover/selected outlines using transparent PNG overlays over real Trust buttons; fixed oversized Settings and Default Login backgrounds; separated regular Settings from login diagnostics and proxy/hosts tools. No changes to login, credentials, import or proxy actions.

---

# AutoPOL AHK 0.4.17 — Direct Windower Profile Launch

**October 31, 2026 — Windows/AHK v2 test build.** Fixes Windower opening its interactive profile picker instead of launching PlayOnline automatically. The user observed that manual profile selection during the 45-second wait allowed the existing account/POL login to complete successfully. This indicates that **the profile launch step**, not the keyboard login sequence, was missing.

## Install and test

Back up the current AutoPOL AHK folder. Close the launcher, replace **`AutoPOL-AHK.ahk`** using the update ZIP in the same folder, and keep `launcher.ini`, `accounts-metadata.ini`, `data/credentials`, and the original AutoPOL JSON untouched. `VanaLauncher.ahk` remains a compatibility entry point; full login continues to require UAC approval. There are **no new helper script requirements** in this version.

Under **Edit → Cioara**, set **Windower profile NAME** to the exact profile you normally select in Windower. This is a name such as `Cioara` or `PC`, **not a file path or the POL account name unless those match**. Leaving the field blank explicitly launches Windower's built-in Default profile. Then select only Cioara and click Launch. The launcher should now skip Windower's interactive profile picker, start a new POL window, and proceed with the already working slot/password/TOTP sequence. The status line reports which Windower profile it requested. Keep other characters unchecked during first verification.

Windower's official CLI documents `-p <profile>` / `--profile <profile>` as direct launch. Previously, a character with a blank profile produced only `"C:\...\Windower.exe"`, opening the profile picker. Version 0.4.17 always sends `-p ""` for Default or `-p "Exact Name"` for a named profile, and accepts the legacy AutoPOL `-p=Name` and current `-p Name` storage forms. The original AutoPOL JSON and stored account/slot mappings are unchanged. [Official Windower CLI](https://docs.windower.net/cli/).

## Verification and status

`python3 tests/check_package.py` source/regression checks pass: profiles are explicitly selected; existing POL input, password/TOTP helper, proxy and UI assets remain byte-for-byte unchanged; no private credentials are bundled. **Not run here:** actual Windows AHK startup, Windower direct-profile launch, native POL login and in-game FFXI. User-reported POL login after manually starting a profile is the latest live-confirmed partial workflow.

## Changelog (most recent first)

- **0.4.17:** Always supply Windower's direct-launch profile argument, including an explicit empty Default name; normalize both `-p=Name` and `-p Name` arguments; label the attempted profile in status. No changes to authentication timing, credential handling, slot navigation, or assets.

---

# AutoPOL AHK 0.4.16 — Clean Imports, Shared Password Fallback & Trust Frames

**October 31, 2026 — Windows AHK v2 testing build.** Update your existing AutoPOL AHK folder in place. Retain `launcher.ini`, `accounts-metadata.ini`, `accounts-metadata.ini.bak`, `data/credentials`, and your AutoPOL `config.json`/JSON copy. Do **not** delete or replace those files; a new ZIP never includes personal credentials.

**AutoPOL import fix:** The legacy `PresetCount` and `PresetN` data are no longer parsed, validated, exported, or saved. Presets were removed from the interface, so malformed/empty old preset metadata should no longer block a valid account import. Accounts, slots, source indices, local credential references, and the original AutoPOL JSON remain protected; an import backs up preexisting metadata and rolls back on errors. You do not need to Restore metadata just to fix `Metadata.PresetCount`. Other invalid account fields still produce a clear validation error rather than silently discarding profiles.

**New character password rule:** Set a password once under **Settings → Default login…**. In **Add Character**, leave the POL password blank to inherit that saved password automatically. Enter a password for a character-specific override. Enter a TOTP secret with an empty password to inherit the default password but keep a character-specific authenticator; the encrypted record resolves the current shared password at login. With *both secret fields blank while editing*, the existing saved login is retained for safety. Existing native credentials and imported AutoPOL accounts are not altered. The shared credential and overrides use Windows-current-user DPAPI; another PC/user requires setting them up again.

**Windower fields:** Settings → Windower executable selects the actual `Windower.exe` file. Add/Edit Character → Windower profile NAME takes the named Windower profile (e.g. `Default`), **not** the folder, the profile's `.xml`, or `Windower.exe`; leave blank for Windower's default profile.

**Trust visuals:** The new `Render-Trust-Frame.ps1` reads the installed Trust `window_background.png` and the real `window_border_left/middle/right.png`, repeating the background at native tile dimensions and assembling thin top/bottom borders like Trust's `FFXIBackgroundView`. It creates only rendered, non-secret PNGs under `data/ui-cache`. The existing 3-piece Trust button textures are retained. Without Trust assets, the launcher falls back to its solid navy windows. The renderer is an experimental visual step and awaits Windows confirmation.

**Suggested Settings cleanup:** Keep Windower executable, Import AutoPOL, Default login and Trust textures. Keep metadata recovery available on errors. Once Windower's built-in fast POL login is confirmed in use, move the legacy acceleration controls and local proxy lab out of everyday Settings; keep any hosts recovery accessible until no tagged entries remain. Move manual/slot-only/dry-run diagnostics into a separate troubleshooting panel. Do not remove the native credentials or POL slot mapping underneath the GUI.

**Testing:** Linux static and regression: `python3 tests/check_package.py`. Windows-only fixture tests (use synthetic accounts/passwords, not real data): `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-AutoPOL-Import.ps1` and `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Native-Secrets.ps1`. Actual AHK v2, Trust rendering, Windower and POL login must be confirmed on Windows. Preserve 0.4.15 as a rollback until successful.

## Changelog (most recent first)

- **0.4.16:** Removed obsolete preset records from active metadata/import; automatic default password for new native characters; separate optional TOTP override with inherited password; clarified Windower executable vs profile name; tiled Trust window/background border support. Unchanged POL input plan, standard native and imported credential reader, and proxy behavior.

---

# AutoPOL AHK 0.4.15 — Metadata Import & Shared Login

**October 31, 2026 | Windows AHK v2 testing build.** Keep existing `launcher.ini`, `accounts-metadata.ini`, `data/credentials`, and imported AutoPOL `config.json`/JSON copy; update the scripts in place rather than creating a new unrelated folder.

In **Settings → Default login...**, enter the shared POL password and optional Base32 TOTP secret. This is encrypted with the Windows user's DPAPI and saved separately from character metadata. In **Add/Edit Character → Login credentials**, choose **Use shared default login (Settings)** to use it; **Enter character-specific password** keeps a separate encrypted credential instead, and **Copy saved login from AutoPOL** retains its previous behavior. Only native characters explicitly configured for the shared default use it. Existing native passwords and AutoPOL-imported account default passwords are not changed. Changing the saved default affects any native characters that use the shared default. Credentials encrypted for one Windows user generally cannot be moved to another PC without re-entry.

**Import fix:** Metadata number fields are validated before conversion. A malformed `accounts-metadata.ini` now yields the specific section/key that failed and restores pre-import metadata if the import's new file cannot be loaded. **If the existing metadata is already damaged, the launcher blocks destructive imports until you use Settings → Restore metadata...**; it validates the `.bak` first and preserves the damaged original under a dated filename. A copied AutoPOL `.json` file may retain its filename for subsequent imported login. The original AutoPOL JSON is never modified. Account-group swapping (`singleProfile=false`) remains unsupported for live login and must not be mistaken for enabled support.

**Legibility:** The character editor's five text inputs and shared-login editor use black text on white; the FFXI navy/gold labels and Trust PNG buttons remain unchanged.

**Testing:** `python3 tests/check_package.py`; on Windows, run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Native-Secrets.ps1` and `...\Test-AutoPOL-Import.ps1` using only synthetic credentials. Actual Windows/FFXI login and AHK GUI rendering are not verified in this environment. Preserve the working v0.4.14 and v0.4.8 folders until verified.

## Changelog (most recent first)

- **0.4.15:** Validated named INI numeric metadata; strict import failure rollback; accepted renamed source JSON in credential reader; added encrypted shared-default login option for native characters; improved character editor input contrast. Preserved Trust button skins and existing POL login sequence.

---

# AutoPOL AHK 0.4.14 — AutoHotkey graphical edition

**October 31, 2026 | Windows AHK v2 testing build.** The project is the AHK counterpart to `rerorriM-Mirrorer/MakariaAutoPOLFork`, previously called Vana'diel Launcher. This update improves AutoPOL imports on different PCs and names the GUI **AutoPOL AHK**. The login, Win32 input, native DPAPI storage, and acceleration code are otherwise unchanged from 0.4.13.

## Updating without losing your accounts

Back up the entire existing `VanaLauncher` folder, then extract **AutoPOL-AHK-0.4.14-UPDATE.zip into that SAME existing folder**. It installs the new `AutoPOL-AHK.ahk`, updates the `Import-AutoPOL.ps1`, `Get-LoginSecrets.ps1`, `Native-Secrets.ps1` helpers, and replaces the old `VanaLauncher.ahk` with a small compatibility entry point. Your old desktop shortcut still works, or open `AutoPOL-AHK.ahk` directly. Approve UAC. Keep the existing `launcher.ini`, `accounts-metadata.ini`, `data/credentials`, and original AutoPOL `config.json` in place. **Do not extract a full fresh package instead of updating when preserving your native Killala credentials.**

The import control is at **Settings → Import AutoPOL profiles**. Choose your original `config.json`, or a copy such as `config (1).json`. The importer accepts valid AutoPOL JSON irrespective of filename; validates account metadata; never writes passwords, seeds, or account secrets into its output INI; and leaves your original JSON unchanged. It preserves native characters by name, skipping an overlapping imported name rather than aborting. The success dialog reports counts; the failure dialog reports a sanitized validation error. When moving to a new PC, select the config file stored **on that PC**: imported credentials are read from that file at login. Native DPAPI encrypted credentials are bound to the Windows user/computer and generally require re-entry on another PC.

**Scope:** Neither AutoPOL EXE nor its GitHub main branch is replaced by this ZIP. The 0.4.13 application is retained as rollback. The earlier AutoPOL account-group mode (`singleProfile=false`) remains unsupported for real automated login by this AHK build; imports can still list those accounts. The standalone POL proxy is optional/off; Windower's per-profile Fast POL Login should not be combined with it.

**Checks:** `python tests/check_package.py` (static/regression). On Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-AutoPOL-Import.ps1` (fake-config fixture). No native Windows, PowerShell, or live POL test was performed in this Linux build environment.

## Changelog (most recent first)

- **0.4.14:** Renamed GUI and canonical script to AutoPOL AHK; retained `VanaLauncher.ahk` compatibility launcher; hardened JSON import for renamed copies/stale paths; preserved native profiles when names overlap; improved error/status messages; aligned credential readers with valid alternate JSON filenames; added read-only importer fixtures.

---

## Previous documentation (preserved)

# Vana'diel Launcher 0.4.13 — Authentic Trust button assembly

**October 30, 2026 | Local Windows/AHK v2 test build.** A narrow rendering change plus removal of the routine launch confirmation; all other POL navigation, credential storage, proxy and queue behavior remains as before. **The new skin has not yet been Windows-tested.** Latest user-confirmed native login is Killala on v0.4.8.

## What's different from 0.4.12

The v0.4.12 skin incorrectly stretched `assets/backgrounds/menu_bg_mid.png` as though it were a button and used `menu_selection_bg.png` as its checked state. Trust actually builds **buttons** from `assets/buttons/menu_button_bg_left.png`, `menu_button_bg_mid.png`, and `menu_button_bg_right.png`, with `_selected` variants for highlighted states. The Trust `ButtonItem.default()` specifies 8px end caps and a repeating 84px center segment; `ButtonCollectionViewCell` horizontally composes those pieces. This release reproduces the three-slice layout in AHK Picture controls beneath a clickable transparent Text overlay. The center is repeated across wider character buttons; selected tiles use the matching selected set. The Trust menu/window background is a **different** rendering layer, not a button asset.

In Settings → **Trust textures...**, choose `Windower\addons\trust` or its `assets\backgrounds` folder. The launcher looks for the full six-piece button set alongside `window_background.png`. After choosing the folder, restart the launcher. It will also auto-discover Trust near the configured Windower executable. No textures are bundled, modified or written back to Trust. Without these assets, buttons remain solid navy as a fallback. Mouse clicking is supported; native Tab/Space behavior remains a known limitation of the Text overlays.

**Launch no longer shows the first-use “EXPERIMENTAL POL LOGIN” popup.** Select the adventurers and click Launch directly. This removes only that routine confirmation; Windows UAC, missing-credential/invalid-slot checks, existing-window attach consent and explicitly enabled hosts/proxy operations retain their protections. The existing login sequence remains unchanged.

## Updating

1. Back up your working launcher folder. Close it, then replace **only** `VanaLauncher.ahk` with the v0.4.13 script (or extract the UPDATE ZIP over your existing launcher folder). Do **not** replace your saved `launcher.ini`, `accounts-metadata.ini`, `data\credentials` or AutoPOL `config.json`.
2. Open the launcher, approve normal Windows elevation, and check whether character/action tiles have the proper three-piece Trust borders. If the texture path is missing, select the installed Trust folder under Settings and restart.
3. Toggle Killala or another character on and off, checking that the button surface actually changes. Test Launch on a character you have used before. Keep VanaLauncher's standalone acceleration proxy OFF if Windower's Fast POL Login is enabled.

Static/regression checks: `python tests/check_package.py`. They check exact preservation of the input, credential and proxy routines, the button texture filenames and selected-state updates, and absence of the normal launch popup. They do **not** execute AutoHotkey/Windows GUI or FFXI. This is a standalone local repository with no configured GitHub remote.

## Changelog (most recent first)

- **0.4.13:** Replaced stretched menu backgrounds with genuine three-piece Trust button assets (8px caps, repeated center, selected variants); fixed PNG state caching; removed routine first-launch confirmation. No changes to the tested POL input plan or credentials.
- **0.4.12:** First use of installed Trust textures via clickable Text overlays; inappropriate menu images used for buttons.

---

## Previous documentation (preserved)

# Vana'diel Launcher 0.4.12 — Trust textures, no white buttons

**October 30, 2026 | Windows AutoHotkey v2 experimental GUI update.** The existing imported/native profiles, DPAPI credentials, POL account selection and confirmed Killala login code are preserved. The visual controls changed; Windows testing is pending.

## Why the previous buttons were white

The 0.4.11 source created normal Win32 Buttons and tried to recolor them through `WM_DRAWITEM`. The user's actual Windows test showed they still appeared white. This release uses clickable **Text** controls with explicit dark backgrounds instead of native Windows button surfaces. When Trust's assets are found, the text sits transparently over real Trust **Picture** textures. The familiar ivory/navy/gold style is retained even without the textures. Mouse clicking remains supported; keyboard Tab/Space behavior for the replaced native buttons needs re-evaluation on Windows. The earlier owner-draw approach is preserved in the 0.4.11 rollback.

## Use Trust's original assets

The launcher checks the configured Windower directory for `addons\trust\assets\backgrounds\menu_bg_mid.png` and `menu_selection_bg.png`. The same folder may also be supplied through **Settings → Trust textures...**, accepting the root Trust addon folder or its `assets\backgrounds` subfolder. After selecting a folder, close and reopen the launcher to apply it. You can also place the files under `assets\trust\backgrounds` inside the launcher folder. No Trust files are copied into this release; it reads your already-installed original textures on your PC, without starting Trust, importing its Lua code or requiring Trust to be running. The selected asset folder path is a non-secret `TrustAssetsFolder` entry in `launcher.ini`.

If the asset folder is not available, large character tiles and action controls display navy instead of white. Selected characters retain an ivory tick, brighter background and gold-ish text, and the Launch button is blue. This does not affect the login path.

## Proxy lab and acceleration

The **Proxy lab** was an isolated, harmless localhost-only rehearsal for HTTP/PML replies and stop/restart checks. It never edited Windows hosts, redirected POL or sped up a real login. It is distinct from the experimental live POL acceleration proxy, which can edit hosts. Windower already supports a per-profile `Enable fast POL login` option (availability depends on the Windower build/profile), so use that rather than stacking a second accelerator. The lab remains in Settings for diagnostics only and can be ignored.

## Update without losing Killala

1. Back up your existing 0.4.11 folder. Do not remove `launcher.ini`, `accounts-metadata.ini`, `data\credentials`, or your older AutoPOL config.
2. Replace **only `VanaLauncher.ahk`** with the new script, or extract the update ZIP over the existing folder.
3. Double-click normally in AHK v2, approve UAC, and inspect the main screen. The action buttons and character tiles should be navy instead of white. In Settings, look for the Trust textures status and browse if not detected. Close and reopen after choosing the folder.
4. Click to select/unselect a character and verify the label and selection highlight. Try a previously verified character with a normal launch. Leave the standalone acceleration proxy OFF.

The new GUI has not been run under Windows here. The last user-confirmed login is Killala on v0.4.8; the latest user feedback is that 0.4.11 still showed white buttons. If the tiles do not display their text over the images, disable Trust textures by temporarily selecting an empty/invalid `TrustAssetsFolder` (or rename the key) and reopen the launcher; dark Text controls remain functional. The 0.4.11 backup is available for rollback.

## Verification and source status

`python tests/check_package.py` verifies static structure, direct character toggling and per-name queue semantics, byte-for-byte frozen login/proxy/credential logic, and absence of native white Button controls. This is **not** an AHK v2 parser or Windows rendering test. No GitHub remote has been configured for VanaLauncher; local development commits only.

## Changelog (most recent first)

- **0.4.12:** Uses Trust menu PNGs when installed, with navy clickable Text fallback; adds Trust folder selector; eliminates dependency on Windows owner-draw Button styling. Core login untouched.
- **0.4.11:** Large two-column adventurer tiles and Launch/Cancel at top, character management below; owner-drawn Windows buttons (live observed white).
- **0.4.10:** Unified Settings window; Windower path and AutoPOL import moved there.
- **0.4.9:** Removed the Down/Up probe and added acceleration preflight.
- **0.4.8:** Native character registration and encrypted login, Killala login user-confirmed.

---

## Earlier instructions and cumulative history (preserved)

# Vana'diel Launcher 0.4.11 — FFXI-style character tiles

**October 30, 2026 | Windows / AutoHotkey v2 testing build.** The main window has been simplified according to the latest layout request. This is a presentation/selection change; it does **not** modify the user-confirmed POL login sequence, native credentials, original AutoPOL profiles, or network proxy routines.

## Update without disturbing your profiles

1. Close the running launcher and back up your existing 0.4.10 folder (keep your earlier 0.4.8 live-login rollback as well).
2. Download the **0.4.11 single script** and replace the existing `VanaLauncher.ahk` in your launcher folder. The other scripts, `launcher.ini`, `accounts-metadata.ini`, and `data\credentials` stay exactly as they are. Alternatively, copy the contents of the 0.4.11 UPDATE ZIP into that existing folder.
3. Double-click the script in AHK v2; accept the usual administrator/UAC prompt. No need to re-register Killala or reimport the characters.

## Main menu

At the top: a status/message panel and a smaller administrator/detail line; immediately below: **Launch [next character]** and **Cancel**. Then come large, **two-column** character buttons. Click a character to check or uncheck it; gold/highlighted tiles are selected, navy ones are not. A checkmark in the button label also communicates selection. Click **Launch** to log in the next selected character. The next click launches the following selected character in list order; no Prepare step. When all selected characters have been tried, Launch can start the sequence again.

At the bottom: **Add**, **Edit**, **Remove**, **Settings**. Edit and Remove target **the last character button clicked**, even if that click unchecked it. Imported AutoPOL profiles retain their existing edit/remove restrictions; native profiles remain fully editable/removable. If the launcher reports that no character has been chosen for editing, simply click that person's tile once before Edit or Remove (and click it again if you want to restore the original selection state).

There is **no 'Adventurers' label, preset dropdown, POL slot column, or profile-group column** in the main window. Historical preset definitions remain in the imported metadata for backward compatibility; this update never discards or rewrites them solely to simplify the UI. POL slots remain in the character editor and internal account metadata because they are needed for accurate login. AutoPOL 'profile groups' are its optional multiple `login_w.N.bin` account lists; they do not have to be visible in ordinary use.

All *buttons* in the main window, Settings, and Add/Edit use native Win32 **owner-draw** painting, with navy/indigo surfaces, ivory text and gold selection/focus borders rather than default white Windows button faces. Keyboard Tab and Space continue to operate the buttons. The Settings dialog continues to hold the Windower path, AutoPOL import, diagnostics and optional proxy controls.

## Windower already provides the POL shortcut

The Windower stable update reported **January 25, 2026** added **Enable fast POL login** under each profile's **pencil (Edit) → Advanced** settings. This skips to FFXI loading after password input, using the approach from jaku's POL-Proxy. It is conceptually equivalent to the experimental localhost PML acceleration in this launcher. Therefore do not run both; **leave VanaLauncher acceleration OFF** if Windower fast POL login is enabled. The old proxy and its safe recovery controls are retained under Settings for historical/debugging purposes, but are never started by selecting or launching characters. If this option is missing or apparently off, verify your Windower version/profile rather than assuming it defaults to ON. Reference: Windower v4 Dev Tracker, 25 January 2026 release notes on FFXIAH.

## Tests and limits

Local Python structural, source fingerprint, queuing-model and package-integrity checks pass. The actual owner-draw Windows rendering, dynamic sizes, color contrast, keyboard interaction, and new selection behavior have **not been run here**; they require a real AHK v2/Windows test. Previous user-reported Windows confirmation: successful Killala login on 0.4.8, and visual feedback that 0.4.10 was improving. Do not interpret static passing as another successful in-game login.

**Changelog, latest first:**
- **0.4.11 (2026-10-30):** Messages and Launch/Cancel moved to top; large selectable two-column character buttons; bottom Add/Edit/Remove/Settings; presets and slot/group columns removed from main surface; all GUI buttons painted in FFXI navy/gold. Login/credentials/proxy unchanged.
- **0.4.10:** Moved Windower path, AutoPOL import and advanced controls into unified Settings.
- **0.4.9:** Removed diagnostic Down/Up probe and added read-only accelerator preflight.
- **0.4.8:** Native character registration and DPAPI credentials; Killala login user-confirmed.

---

## Older instructions and cumulative history (preserved)

# Vana'diel Launcher 0.4.10 — Adventurers first, one Settings window

**October 30, 2026 | AutoHotkey v2 for Windows.** This build changes **only the GUI organization** of v0.4.9. The working launch sequence, direct-selection queue, native Killala credential support, and all optional proxy implementations are preserved without behavioral changes.

## Updating your existing launcher

1. Keep a backup of your current **0.4.9** folder (or the previously user-confirmed **0.4.8** login build). Close Vana'diel Launcher.
2. Download **0.4.10 UPDATE** and extract its `VanaLauncher.ahk` over the old script. Keep the existing `launcher.ini`, `accounts-metadata.ini`, `data\credentials`, imported AutoPOL config, and all PowerShell helpers unchanged. The full ZIP is intended for fresh installs, not for replacing an existing folder with personal state.
3. Double-click with AutoHotkey v2. Approve the normal Windows UAC request. No reimport or character re-registration should be necessary. The new layout still needs real Windows validation.

## Simplified interface

The main window is ordered exactly as follows: **Adventurers** list and checkboxes at the top (no large launcher banner); **Add / Edit / Remove** buttons directly under the list; **Party Preset** dropdown; **Launch** and **Cancel**; status and detail messages; and **Settings** at the bottom. The selected checkboxes immediately define the launch party; there is no Prepare button. One Launch click starts the next selected character.

**Settings** now contains the **Windower.exe path and Browse**, **Import AutoPOL profiles**, **Clear selection**, all previous login-mode/dry-run/autologin and slot-only diagnostic settings, **PlayOnline acceleration** preflight/start/stop/recover, and the local proxy lab. The Settings window can be closed without affecting a running proxy. Existing character editor and saved imported/native profiles are unchanged.

**Acceleration stays optional and OFF until started explicitly.** If you choose to test it, use **Settings → Check acceleration**, and follow the prior 0.4.9 hosts-file precautions below. Do not run the AutoPOL proxy concurrently. Do not share secrets or the personal launcher-state files.

**Verification boundary:** Source-level and packaging regression checks run in Linux. There is no native AHK v2 GUI rendering, Windower or POL login test of this 0.4.10 arrangement yet. The user's latest confirmed in-game login is Killala on 0.4.8. 0.4.9 accelerator and visual styling also await native Windows confirmation. No GitHub remote is configured; local development commits are not remote publication.

## Cumulative changelog (latest first)

- **0.4.10 (2026-10-30):** Removed the decorative launcher heading; put adventurers/character editing/preset/Launch/Cancel/status first; consolidated Windower path, AutoPOL import and all advanced controls inside Settings. Core login, credentials, proxies, selection queue unchanged.
- **0.4.9:** Removed the optional diagnostic Down/Up probe; added FFXI-inspired colors and read-only acceleration preflight.
- **0.4.8:** Native character registration and DPAPI credential storage; user confirmed Killala login.

---

## Previous version notes (retained for history)

# Vana'diel Launcher 0.4.9 — Vana'diel-style UI and acceleration check

**October 30, 2026 | Windows AHK v2 test build.** The user has confirmed a successful Killala login in 0.4.8. Version 0.4.9 keeps that login behavior **without the extra Down/Up probe**, adds an FFXI-inspired blue-and-gold menu theme, and makes the optional PlayOnline acceleration easier to diagnose before touching Windows hosts. Real acceleration has **not yet been verified**.

## Upgrade without losing Killala or your settings

1. Back up your working **0.4.8** folder. Extract the **0.4.9 UPDATE ZIP** into that existing folder. Replace `VanaLauncher.ahk` and add the new `Check-POL-Acceleration.ps1` helper. Keep all previous helpers such as `Native-Secrets.ps1`, `Proxy-POL.ps1` and your `launcher.ini`, `accounts-metadata.ini` and `data/credentials` intact. Never overwrite your data directory with an empty example.
2. Double-click `VanaLauncher.ahk` with **AutoHotkey v2**, approve the Windows UAC prompt, and select your characters. Your familiar direct Launch button remains: selected = prepared, one launch per click. New character registration and encrypted credentials are unchanged.
3. Test a single normal login first to confirm the removal of the probe has not disturbed the POL sequence. This version starts the account-menu held-Up reset immediately after its existing Alt focus-prime. No Down/Up probe is run.

## Try PlayOnline acceleration

This is the **same kind of feature** as original AutoPOL's optional local `POLProxy`: it temporarily directs `wh000.pol.com` to a tiny local responder for the PML `GET /pml/main/index.pml` handoff. It does **not** speed up game assets, password verification or in-game loading. It is independent of the automated login queue.

Before the first live run, close AutoPOL and PlayOnline, ensure you have administrator rights, **back up Windows hosts** (`%SystemRoot%\System32\drivers\etc\hosts`), and avoid concurrent accelerators. In **Advanced settings**:

1. Choose **US** (or your actual POL region), then click **Check acceleration**. This is read-only and reports one of: **CLEAR** (no mapping/port conflict), **OWN_STALE** (Vana marker needing recovery), **HOSTS_CONFLICT** (other mapping—perhaps AutoPOL; don't delete it), **PORT_BUSY**, or **ERROR** (could not inspect). If not CLEAR, do not start the live proxy until the cause is resolved.
2. If CLEAR, click **Start acceleration**, read the system-wide hosts warning, approve it, then wait for the status to say **EXPERIMENTAL LIVE** with `127.0.0.1:51304` for US. Only then launch ONE character. This helper still checks hosts and binds the loopback port itself, and it refuses conflicts, but live behavior has not been proven.
3. Watch whether PlayOnline progresses and whether the PML request counter rises. A request count is only an HTTP observation, **not proof of successful login**. Click **Stop / restore hosts** after the character passes the POL handoff. Confirm the proxy stopped and **Check acceleration** shows CLEAR again. If the Vana marker remains after interruption, use **Recover stale hosts** (only removes the launcher's own marked entry). Never delete unrelated hosts entries.

Optional local checks from a PowerShell console in the extracted folder (all use **temporary fixture hosts**, not your real hosts):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-POL-Acceleration-Check.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-POL-Proxy.ps1
```

If live acceleration is blocked, the normal automatic login still works with acceleration OFF. Do not repeatedly attempt hosts edits to overcome a conflict; share the **sanitized status wording** instead.

## Visual design

Main window, Advanced and Add/Edit Character now use FFXI-inspired **midnight-blue backgrounds, indigo panes, gold separator rules, warm ivory text, and serif headers**, echoing in-game menus like Trust and ConsoleBGPlus. It is an intentional Windows-native approximation, not the original in-game art or an exact skin. Native buttons, accessible controls, character checkboxes, launch/Cancel and profile management are retained.

**Verification boundary:** Static source/regression checks pass in the build environment. Neither the new AHK layout nor the PowerShell preflight/live acceleration was executable here. The **user-confirmed successful Killala login** applies to the prior **0.4.8** version; 0.4.9 is waiting for Windows validation. The project still has no writable GitHub remote.

## Cumulative changelog (most recent)

- **0.4.9:** Removed Down/Up probe and probe counters/messages; protected the exact remainder of the known-working login plan. Added dark blue/gold menu styling to main, Advanced and editor; read-only hosts/port preflight with specific error classifications and disposable fixture tests. Live proxy remains separately opt-in and unchanged.
- **0.4.8:** Native Add/Edit/Remove character profiles and per-user DPAPI encrypted credentials; user subsequently reported Killala logged in successfully.
- **0.4.7:** Character selection directly prepares the next-launch queue.
- **0.4.6:** Auto-elevation and cleaner main controls.
- **0.4.5:** Native login with reversible input probe; user confirmed successful login while elevated.

---

## Previous instructions and history (retained)

# Vana'diel Launcher 0.4.8 — Add characters without AutoPOL

**October 30, 2026 | Windows test build.** Native Add/Edit/Remove Character is now available. You can register Killala directly in the launcher, use either her own POL password/TOTP seed or copy another imported profile's credentials **into independent Windows-user encrypted storage**, and launch using the same successful administrator-elevated login flow. Previously imported AutoPOL characters remain intact. The original login input plan and proxy helpers are unchanged. Native Windows testing of new storage/editor is outstanding.

## Add Killala and launch

1. **Extract the complete 0.4.8 ZIP over your existing launcher folder** (or copy **both** `VanaLauncher.ahk` and the new `Native-Secrets.ps1` beside the original helpers). **Do not delete `launcher.ini`, `accounts-metadata.ini`, `data/credentials`, or your original AutoPOL `config.json`.** Keep a backup of the v0.4.7 folder as a rollback. AutoHotkey v2 is required.
2. Double-click `VanaLauncher.ahk` normally and approve the Windows administrator prompt. Click **Add character...**, enter **Killala**, choose her actual **POL account slot (1–20)**, and enter her **Windower profile name** (blank uses Windower's default profile). The POL slot is an account's position in the POL login list, **not** a character ID.
3. Choose **Enter password and optional TOTP key** to store credentials locally, or choose **Copy saved login from AutoPOL profile: ...** if Killala uses an existing imported profile's SE/POL credentials. A copy stores its own encrypted credential record, so her subsequent login no longer depends on the original AutoPOL JSON. If Killala's POL account is different, use its own credentials instead; never assume another profile's credentials are correct.
4. Click **Save character**. Killala should appear checked, and the button should say **Launch Killala**. Close any old PlayOnline window and click Launch. The standard full-login automation runs after a **new** POL window appears; no Prepare step is required. Keep the live proxy OFF.
5. To edit or remove a native profile, **click its row to highlight** (distinct from checking it for launch), then choose Edit/Remove. Imported AutoPOL profiles remain read-only in this editor so their original account-index mapping is not accidentally broken. Re-importing AutoPOL keeps native profiles.

**Credential privacy:** New native secret files live in `data\credentials\<random-guid>.bin`, encrypted with Windows DPAPI for the Windows user running the elevated launcher. `accounts-metadata.ini` contains only names, slots, Windower arguments, and opaque credential references. Passwords and TOTP *seeds* are never saved in plaintext to launcher settings, passed via process command-line arguments, or bundled in a ZIP. Credentials are transported to the local helper via a process stdin pipe and read back on demand. On a different Windows user/account or after moving the files to a different PC, encrypted credentials generally cannot be decrypted; re-enter them or copy credentials again. As with earlier builds, password paste briefly uses the clipboard, and clipboard history software might retain it. Do not share `config.json`, `data/credentials`, or any local launcher-state file.

**Optional Windows-only test:** Before signing in, open Windows PowerShell in the launcher folder and run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Native-Secrets.ps1`. This uses **fake** passwords/TOTP seeds under `%TEMP%` to check encrypted save/load, one-time-code generation and copying from a synthetic AutoPOL configuration. It cleans up the temporary files, does not use your actual credentials and does not touch Windows hosts.

**Limitations:** Native registration is supported in **single-profile POL mode**. If your AutoPOL setup swaps among multiple `login_w.N.bin` profile groups, the launcher stops and explains the existing unsupported mode. Native profiles are saved to this launcher only; they do **not** rewrite or add accounts to AutoPOL. No real Windows tests of the new editor or DPAPI helper have happened in the build environment, and the live POL proxy remains unverified/off.

## Previous 0.4.7 launch instructions (historical)

## Start the launcher

1. Keep the existing folder (including `Get-LoginSecrets.ps1`, `Import-AutoPOL.ps1`, `launcher.ini` and `accounts-metadata.ini`). Replace only `VanaLauncher.ahk` when upgrading from 0.4.6, then double-click it with **AutoHotkey v2**. The built-in `EnsureAdminOnStartup()` checks `A_IsAdmin`, uses AHK's `*RunAs` to request **Windows UAC** if necessary, and exits the unelevated copy after requesting elevation. Approve the prompt to use full POL login. There is no UAC bypass. You do not need a separate Windows compatibility setting or manually choose Run as administrator.
2. Check the characters you want. No one is selected by default, and there is no Prepare button. Presets and Select none change the same checkmarks. The button displays **Launch Franklet**, **Launch Myrr**, etc. according to the next selected account in list order.
3. Click **Launch** once (or press Enter while the main launcher GUI is focused) to start the currently displayed character. The launcher waits for its **new** POL window and performs the familiar full login. Once the input plan is finished, the button names the next checked character. Click again to launch that one; **it does not wait for successful in-game arrival or proxy completion**. After all selected characters have been attempted, the button says **Launch selected again**, which intentionally restarts that set only if clicked.
4. Checking or unchecking characters between launches **rebuilds the pending queue from the current selection**, from the beginning. Checkboxes/presets are disabled during an active input plan, so mid-login edits cannot alter a running launch. The status reports Windows-submitted events, not proof that POL processed or completed authentication. **Ctrl+Shift+F10** cancels the current input plan.
5. **Advanced settings** still contain manual/slot-only modes, dry run, POL auto-login confirmation, and the optional local/live proxy controls. Defaults remain full login, dry run OFF, POL auto-login disabled confirmation checked; the launcher **does not modify POL's actual auto-login preference**. Make sure that option is truly disabled in POL. The **live proxy is separate and OFF**, pending investigation of the earlier hosts warning.

**AutoPOL acceleration:** Original Makaria AutoPOL has a `POLProxy` option and code that redirects `wh000.pol.com` through Windows hosts to a local POL-port HTTP responder. Our experimental proxy is modeled on that feature. It may skip a slow POL web/PML handoff; it does not accelerate FFXI itself. Our proxy is not the reason your administrator-elevated login worked, and our version remains unverified on your Windows machine. Do not activate two proxies or alter existing hosts entries without investigating the conflict.

**Privacy / rollback:** Keep original AutoPOL, `config.json`, and `login_w.bin` unchanged. The ZIP does not include credentials. Single-file updates preserve previously imported metadata and launcher settings when kept in the same folder. The prior 0.4.5 and 0.4.6 ZIPs remain available as rollback points. No GitHub repo/branch is established for VanaLauncher, and there are no commits or pushes. Python structural/model/regression tests passed locally; **native Windows AHK v2 checkbox events, UAC relaunch and multi-character launching have not been tested for 0.4.7**.

## Cumulative changelog (newest first)

- **0.4.8:** Add/Edit/Remove native character profiles, secure per-Windows-user DPAPI credential file, option to import/copy another AutoPOL account's credentials into local encrypted storage, auto-preserve native profiles across AutoPOL re-imports, no changes to native POL input plan.
- **0.4.7:** Removed Prepare; current checkboxes are the queue, checked list defaults empty, single default Launch button names next character, presets and manual selection refresh it, selection frozen during active login. No alteration to keyboard authentication or proxy helpers.
- **0.4.6:** Added automatic UAC elevation and compact main GUI with Advanced settings.
- **0.4.5:** Integrated full-login input probe. User confirmed successful POL login when running as administrator.
- **0.4.4:** Native Win32 `SendInput` parity and event acceptance diagnostics.
- **0.4.3:** Slot-only existing-POL-window attach for troubleshooting.
- **0.4.2:** Held-Up reset based on user's observed POL clamp/wrap behavior.
- **0.4.1:** Corrected invalid AHK v2 `SetKeyDelay` argument.
- **0.4:** Experimental live POL proxy and hosts recovery helpers.
- **0.3:** Isolated local proxy lab.
- **0.2:** Experimental POL input plan.
- **0.1:** GUI and dry-run queue.

---

## Previous v0.4.6 instructions (retained as history)

# Vana'diel Launcher 0.4.6 — simple launch and automatic administrator check

**October 30, 2026.** The user confirmed a successful full automated PlayOnline login with **0.4.5 run as administrator**. Earlier 0.4.4 runs without administrator privileges submitted 42 Windows events but caused no visible POL navigation. The administrator privilege mismatch is a strong working explanation, not an independently proven root-cause analysis. No live proxy acceleration was confirmed.

## Current use — one launcher, a small main window

1. Keep the original AutoPOL installation. Close any already-open POL window before an automated login. Double-click `VanaLauncher.ahk` using **AutoHotkey v2 (64-bit)**. If not elevated, it requests **Windows UAC** automatically and restarts itself as administrator; approve this prompt. If you decline, you can inspect/import profiles and enable dry run in Advanced, but automatic login is blocked.
2. The main window contains only Windower path/browse, Import AutoPOL profiles, character checkboxes, presets, **Prepare selected party**, **Launch next character**, **Cancel**, status, and **Advanced settings**. The default mode is **full POL login**, **Dry run OFF**, **POL auto-login assumed disabled**; nothing launches until you click Launch next character. This checkbox is a declaration of your POL setting: the launcher does **not** change POL's auto-login option. Verify that POL auto-login really is disabled.
3. Choose a character (for example Franklet), click **Prepare selected party**, then **Launch next character**. Approve the one-time confirmation for this launcher session. It starts a new Windower/POL client, focuses POL, sends a reversible Down/Up input probe as part of the normal run, selects the requested slot and performs the password/TOTP sequence using your original local AutoPOL config.
4. If you want manual login, slot-only testing or dry run, click **Advanced settings**. The previous local proxy lab and live proxy Start/Stop/Recover controls are **also in Advanced**, not deleted. Keep the live proxy **OFF** until its Windows hosts warning is resolved and tested. A legacy Vana proxy hosts marker shows a warning on the main window.
5. Cancel an unexpected sequence via **Ctrl+Shift+F10**. A completed input queue is *not* automatically proof of in-game login. Never send `config.json`, passwords, OTP keys, or clipboard dumps to anyone.

**Why the proxy exists:** POL can request `http://wh000.pol.com/pml/main/index.pml` during its startup/web-page handoff. The experimental regional proxy temporarily maps `wh000.pol.com` to `127.0.0.1` through Windows' hosts file and returns a tiny local PML response with an immediate `gameto:1` action. This may bypass waiting for a remote page and accelerate entry into the game flow. It does **not** speed up game assets, authentication servers or FFXI loading. Its actual benefit and the hosts restoration lifecycle remain unverified on this PC. It affects all POL clients while enabled and can conflict with original AutoPOL; leave it OFF for normal use.

**Package and rollback:** The full ZIP includes script, `.ps1` helpers, `AGENTS.md`, `WORKFLOW.md`, `TESTING.md`, and tests. If updating an existing extracted folder, replace **only** `VanaLauncher.ahk`; its local `launcher.ini` and `accounts-metadata.ini` stay in place. No secrets are included in the ZIP. 0.4.5 remains the last user-confirmed successful version; 0.4.6's new auto-elevation and compact UI still need native Windows validation. No GitHub remote/branch has been configured for VanaLauncher; no commits or pushes.

---

## Earlier versions and diagnostic history (retained)


**October 30, 2026. Experimental.** User-requested startup defaults are now:
**Windower + full POL login** selected, **Dry run OFF**, and the **POL auto-login disabled** checkbox prechecked. This does **not** change PlayOnline's actual auto-login setting; confirm it really is disabled before launching. Nothing launches merely because the GUI opens. The **live POL proxy remains OFF**, separate, and must not be started while its hosts warning is unresolved.

## One-run Franklet test

1. Close previously opened PlayOnline Viewer windows and the old VanaLauncher script. Leave original AutoPOL closed. Replace `VanaLauncher.ahk` in the existing folder (preserves imported profiles and local settings), or extract the full ZIP and import `config.json` there.
2. Open the launcher using **AutoHotkey v2**. Full login and Dry Run OFF should already be selected. Check Franklet's imported slot and that POL auto-login is **really disabled**. Leave **Slot-only attach** unchecked and **Live POL proxy OFF**.
3. Select Franklet only, **Prepare selected party**, then **Launch next character**. Accept the first experimental automation confirmation. A **new** Windower/POL window is required; an already-open POL window is deliberately excluded from automatic authentication.
4. When the new POL window is detected, the launcher checks its process elevation, primes window focus with an Alt press/release (as original AutoPOL does), sends **Down then Up** as an integrated input probe, then performs held-Up reset, slot-specific Down presses, and the entire password/TOTP/Enter sequence using the original local AutoPOL credentials. There is no separate slot-only test or additional manual test step.
5. **Watch POL**. If the arrows still visibly do nothing, use **Ctrl+Shift+F10** to cancel *before the password step*. If a privilege mismatch is detected, the launcher stops and explains it. The launcher cannot automatically prove POL processed the input, even if Windows accepted the events.
6. Note the target process name/PID, the status text (including accepted probe events), and whether POL moved, opened a password field or logged in. Do **not** share passwords, TOTP secrets, `config.json`, or the password clipboard.

**Diagnostics:** The full-run probe is a Down/Up pair which should return the highlight to its starting position on the POL account menu. Its native input events are counted separately from the rest of the login. The launcher checks foreground HWND before every input, compares the target's elevation with its own, and reports successful Windows submission **separately from actual POL response**. A successful call to `SendInput` alone never certifies a login. Historical 0.4.5 behavior: that build checked for elevated POL but did not auto-elevate; **0.4.6 now requests UAC on startup**. There is one login-confirmation message per launcher session, not a second experiment to run.

**Historical user-observed failure preceding 0.4.5 (later full login succeeded with administrator privileges):** v0.4.4 submitted **42 native Windows keyboard events** during a slot-only test and the POL menu still did not move. This establishes that `SendInput` return counts do not prove POL's response. The later administrator-elevated 0.4.5 login did succeed; this supports a privilege-related explanation, without proving the root cause.

---

## New in 0.4.4: native keyboard injection diagnostic (October 30, 2026)

**Observed on user's Windows machine:** v0.4.3 successfully attached and completed
50+ planned input steps without any visible POL menu movement. That confirms
input queue execution, **not** receipt by POL. AutoPOL's C++ `simulateKey`
uses Windows `SendInput`; our prior AHK build used `SendEvent` instead.

0.4.4 switches key injection to **Win32 SendInput**, using the same keyboard
virtual-key API as AutoPOL. It checks `GetForegroundWindow()` against the
selected POL HWND immediately before each event and checks the `SendInput`
return value. The status displays target HWND / PID / executable name and the
number of events Windows accepted. **Windows accepting input is not evidence
that POL reacted.** The full-login password clipboard paste remains untested.

For the safest test: keep one existing POL window on the account-selection
screen, proxy OFF, launch mode **slot selection**, **Dry run OFF**, check
**Slot-only test: use ONE already-open POL window**, and prepare only Franklet.
The script asks for confirmation, sends Up hold/repeats and slot-1 Down taps,
then stops without Enter/password/TOTP or launching another process. Watch
for actual menu movement and capture the final status (no credentials).

If Windows reports `SendInput returned 0/1`, compare elevation of POL/Windower
and the launcher. Do not immediately switch on system-wide proxy or make hosts
edits. If Windows reports acceptance yet the menu stays still, investigate
POL input ownership, focus and its navigation screen rather than calling the
login successful. Preserve your original AutoPOL installation and earlier ZIPs.

---

## New in 0.4.3: attach to the currently open POL window (slot-only)

This revision is for observing why slot selection was not sending inputs.
With just ONE visible PlayOnline Viewer window open at the account list, select
**Windower + POL slot selection (experimental)**, **Dry run OFF**, the auto-login
confirmation, and **Slot-only test: use ONE already-open POL window**. Select one
character and prepare/launch. A confirmation appears before any input. This path
**does not start Windower** and **never enters credentials or confirms a login**.
It runs the same experimental held-Up reset and Down count in that already-open
POL window, then stops. The current key repeat behavior is still unverified in POL.

With that checkbox OFF, navigation/full-login modes continue to launch Windower
and wait for a **new** POL window. While waiting, the UI now shows the number
of already-open windows it excluded. The manual mode never sends POL inputs.

Leave LIVE POL PROXY OFF while diagnosing slot selection. A proxy warning about
hosts or ports is not evidence that a host mapping was changed. Do not edit hosts
manually; use targeted recovery only if a stale Vana tag was actually created.

---

**v0.4.2 held-Up correction (October 30, 2026):** Live POL testing showed that separate Up presses wrap to the bottom, while holding Up clamps at the top. AutoHotkey does not automatically repeat a synthetically held key, so automatic slot reset now emits repeated **Up key-downs without any key-up between them**, then releases Up once before sending `slot - 1` Down taps. The GUI is responsive and cancellation/focus loss releases Up. The user's v0.4.1 dry-run GUI and manual Windower launch passed; automatic slot navigation and the actual AHK key repeat remain unverified. **Manual Windower mode intentionally sends no POL keys.** For the next test, use **Windower + POL slot selection** with the live proxy OFF and Dry run OFF, after closing the previously opened POL window. Replace `VanaLauncher.ahk` only; your imported launcher.ini and accounts-metadata.ini remain in the original folder.

**Retained v0.4.1 startup compatibility fix:** AHK v2 rejects `SetKeyDelay(30, 30, "Event")`; the launcher now uses `SetKeyDelay(30, 30)` and should clear the reported line-9 error. Native GUI/FFXI remains to be verified. For an existing extracted v0.4 folder, replace only `VanaLauncher.ahk`. Keep the live POL proxy OFF during initial testing.

# Vana'diel Launcher — 0.4 live-POL proxy integration experiment

**October 30, 2026. Experimental / native Windows untested.** This is a complete replacement *test folder* for the earlier standalone AHK v2 launcher, not an upgrade to the original AutoPOL executable or XIVCrossbar. **Keep AutoPOL and the 0.1, 0.2, 0.3 ZIPs unchanged.** No source has been pushed to GitHub.

0.4 adds a separately supervised **optional live-POL acceleration proxy**, modeled after Makaria AutoPOL. It can bind a region-specific loopback port and temporarily edit Windows hosts with administrator approval. This makes 0.4 **more invasive than the harmless 0.3 local-only proxy lab**. The feature is off unless the user explicitly chooses **Start live POL proxy** and approves two dialogs (launcher confirmation and Windows UAC). Dry run ON does **not** disable the independent live-proxy Start control: do not click it until ready to test system networking.

**Do not run the experimental live proxy until the non-elevated disposable-hosts fixture tests pass. No claim has been made that 0.4 works with native PlayOnline.** The original AutoPOL accelerated-login mode remains your working fallback.

## Retained 0.4 getting-started instructions (historical defaults)

1. Extract 0.4 into **a separate folder** under your own user account; do not copy over the prior 0.3 folder, Windower addon, or AutoPOL executable. Install AutoHotkey v2 alongside v1 if necessary; the XIVCrossbar wrapper can remain on v1 while migrated separately.
2. **Historical 0.4 behavior (not 0.4.5):** Double-click `VanaLauncher.ahk`. Dry run should be checked, launch mode should be **Windower only**, and both proxy services should show Off. Import your **existing** AutoPOL `config.json` to read names/slots/character preset metadata (no passwords or TOTP seeds are copied into `accounts-metadata.ini`).
3. Check UI preset selection and the dry-run Next queue. See 0.3 history in `TESTING.md` for remaining manual and slot-navigation test steps. The login sequence is **still unverified in actual POL**.
4. To verify the new code without any actual hosts changes, open **Windows PowerShell** in the extracted 0.4 directory and run:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-POL-Proxy.ps1
   ```

   This starts the **real helper** against a disposable `%TEMP%` hosts-file fixture and an OS-selected port. It tests two successful PML GETs, unrelated-path 404, stop/restore byte equality, foreign mapping refusal, and crash recovery. It does **not** require elevation, does not edit Windows hosts, and never launches POL.
5. If the fixture test fails, keep the live-POL mode OFF. Share the error message **without credentials**, and use 0.3 for harmless HTTP lab testing.

## Experimental live-POL integration (only after fixture tests)

Before trying this, **close AutoPOL and PlayOnline completely**, verify no other proxy owns the regional port, and back up your Windows hosts file using an administrator account. Test only **one** POL account initially.

1. In the GUI, click **Start live POL proxy**, enter US / JP / EU, read the confirmation, and approve Windows UAC. The helper binds **127.0.0.1:51304 (US), :51300 (JP), or :51302 (EU)** before appending one tagged hosts record for `wh000.pol.com`. It refuses existing mappings or a blocked port and will not overwrite foreign entries.
2. Wait until the GUI explicitly reports **EXPERIMENTAL LIVE** and the expected port. Then test a single character in Windower-only/manual mode. If a matching POL request arrives, the proxy answers with `gameto:1` PML. Request count shows network handoffs, **not actual logins**.
3. The service remains available for **multiple queued clients**. The Next button never waits for the proxy or for a character to load into the world. Do not confuse “login inputs sent,” “PML served,” and “character present in Vana'diel.”
4. When all relevant clients have moved beyond the POL handoff, click **Stop / restore hosts** and confirm the helper shuts down and removes its tagged mapping. The launcher requests the same cleanup if you close it. A 20-minute cap and parent-process watchdog are backups, not guarantees against power loss.
5. If a stale Vana marker remains after an abnormal exit, **do not open POL**. Click **Recover stale hosts**; approve UAC. Recovery only removes our own tagged records, and refuses to run while an active Vana proxy holds its mutex.

Manual recovery if the GUI cannot run: open elevated Windows PowerShell in the extracted launcher folder and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Proxy-POL.ps1 -Action Recover
```

If recovery fails, manually inspect `%SystemRoot%\System32\drivers\etc\hosts` and remove **only** the line ending in `#vana-launcher-proxy-v1:<token>:<bit>` (where `<token>` and `<bit>` are generated values). Leave all unrelated lines untouched. Do not run AutoPOL while an unexpected mapping is present.

## Retained previous functionality

- Clickable AHK v2 GUI, character selection and saved presets from the original AutoPOL `config.json` metadata. Original files are read-only; no `login_w.bin` edits or profile-group swaps.
- Dry-run next-character queue; manual Windower launch mode; optional slot-only and full POL input modes. An approximately 3-second synthetic **held Up with repeated key-downs (no releases)** resets the wrapping selection list to its top clamp (about 4.6 seconds for 12–20-slot profiles); then `slot - 1` Down taps select the account. The exact timing and repeat acceptance remain to be confirmed in POL.
- Optional AutoPOL-like Enter/password/TOTP sequence. Passwords and one-time codes are requested from the original config on demand; no secrets are copied into imported metadata. The user subsequently confirmed one working full automated login under 0.4.5 with administrator privileges. Further character/party runs remain unverified.
- Cancel Current / Ctrl+Shift+F10 cancels future input steps. Original AutoPOL executable and XIVCrossbar controller scripts remain independent.
- Harmless **Start proxy lab** remains a separate feature on an ephemeral localhost port, with `tests/Test-Proxy.ps1` from v0.3.

## Important limits and security notes

- The real proxy affects name resolution for **all** POL processes while active. A sudden power outage can leave a persistent hosts mapping until manually repaired. We intentionally do **not** install a scheduled task or permanent background service.
- Do not start AutoPOL's proxy concurrently, or use two copies of this launcher. Named mutex, exclusive socket binding, existing-hosts checks and tagged cleanup are present, but have not yet been demonstrated on Windows.
- This is a **Windows-only** project. The build environment cannot run the native AHK, Windows PowerShell 5.1, Windower, or FFXI components. Python source/model/packaging checks are not equivalent to successful native execution.
- Clipboard managers and clipboard history may retain pasted passwords despite restoring the previous clipboard. This is inherited from the 0.2 login sequence; it is not a secure OS credential vault.
- The existing automatic-login logic does not confirm which POL login screen is showing or prove successful authentication; the proxy does not identify individual users. A normal proxy response is only an HTTP event.
- Elevated helpers depend on files in the launcher directory. Keep this directory private to your Windows account and don't run it from an untrusted shared folder.

## Files and provenance

`VanaLauncher.ahk`: GUI, launch queue, POL input, independent lab and live-proxy controls. `Proxy-POL.ps1`: opt-in privileged regional listener/hosts lease and recovery. `Proxy-Local.ps1`: v0.3 harmless lab. `tests/Test-POL-Proxy.ps1`: **native** test to be run on Windows using temporary hosts. `tests/Test-Proxy.ps1`: existing lab HTTP test. `Import-AutoPOL.ps1`: read-only metadata import. `Get-LoginSecrets.ps1`: on-demand imported AutoPOL credential lookup. `Native-Secrets.ps1`: encrypted native credential save/clone/load/TOTP. `tests/Test-Native-Secrets.ps1`: disposable Windows fixture testing. `PROXY-DESIGN.md`: technical design and remaining hazards. `AGENTS.md`, `WORKFLOW.md`, `TESTING.md`: cumulative project practices/history. `tests/check_package.py`: static and independent reference checks.

AutoPOL reference: [MakariaAutoPOLFork](https://github.com/alicestellar/MakariaAutoPOLFork/blob/main/FFXI-Launcher.cpp), main. Shared development guide: [NPCMirror WORKFLOW](https://github.com/rerorriM-Mirrorer/ffxi-NPCmirror/blob/main/WORKFLOW.md). This standalone project still has no writable GitHub repository configured. Nothing has been committed or pushed.


## Cumulative changelog

- **0.4.31 (2026-11-06):** Read-only installed POL `usr/homeNN/system.bin` discovery with editable, double-confirmed slot/name/profile mapping and metadata-only merge. Preserves verified TSV import as a fallback. Does not decode `login_w.bin` or infer POL label from stored account name. Native Windows test pending.

- **0.4.6 (2026-10-30):** Automatically requests UAC and relaunches with administrator privileges on startup; blocks actual POL keyboard automation without elevation; simplifies main UI and moves manual/slot/dry run and proxy controls into Advanced. Original 0.4.5 login input/credential/proxy functions unchanged. **Windows validation pending.**

- **0.4.5 (2026-10-30):** Full-login startup selected; Dry Run OFF; POL auto-login checkbox prechecked without editing POL settings. Reversible Down/Up native input probe integrated into full login, one-time Alt focus-prime, read-only POL elevation preflight with explicit mismatch abort, probe/OS acceptance diagnostics. Proxy unchanged/OFF. **User later confirmed successful administrator-elevated full login.**

- **0.4.4 (2026-10-30):** Native Win32 SendInput keyboard events, result-count checks, foreground targeting and visible HWND/PID/process diagnostics; independent key-up cleanup. User observation: 0.4.4 accepted 42 native events with no visible POL movement; root cause unresolved.
- **0.4.3 (2026-10-30):** Explicit attach to one already-open POL window for slot-only testing, plus new-window discovery status.
- **0.4.2 (2026-10-30):** Replaced wrapping individual Up taps with repeated held Up key-down events, then one release; added cancel/focus-release handling.
- **0.4.1 (2026-10-30):** Fixed invalid AHK v2 `SetKeyDelay` argument; Windows GUI, dry-run, and manual launch later confirmed by user.
- **0.4 (2026-10-30):** Optional elevated regional live proxy experiment, reversible tagged hosts lease and recovery helper. No confirmed POL proxy success.
- **0.3 (2026-10-30):** Independent local-only PowerShell proxy lab and on-demand credential helper improvements.
- **0.2 (2026-10-30):** Experimental POL navigation, queued input and full-login sequence. Initial tap-reset assumption superseded by live observation.
- **0.1 (2026-10-29):** AutoHotkey v2 graphical prototype, metadata import and dry-run queue.

- **0.4.32 (2026-11-06):** Replaced PlayOnline mapping and verification prompts with a single Import/Cancel preview, account-name defaults, and occupied-slot skips. Removed verified TSV import. Clarified timing status text and corrected the diagnostic version stamp.

- **0.4.33 (2026-11-07):** Removed the test letter and its Backspace. Automatic parties now begin the next Windower launch one second after final Enter while tracking the previous FFXI handoff separately.

- **0.4.34 (2026-11-07):** Restored the letter and Backspace before password paste after the 0.4.33 live report. Carries forward the one-second party launch overlap.
