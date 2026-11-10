> **2026-11-10 publication correction:** The historical note below that this project had no remote is superseded. This AHK source checkpoint is now in the `development/autopol-ahk` branch of `rerorriM-Mirrorer/MakariaAutoPOLFork`. Its earlier local development history is described in TESTING.md; remote Git history begins with this source import.

# WORKFLOW.md — Vana'diel Launcher

Follow the current canonical [NPCMirror WORKFLOW](https://github.com/rerorriM-Mirrorer/ffxi-NPCmirror/blob/main/WORKFLOW.md) and its AGATHOS / DESIGN / WORKFLOW development conventions. This new standalone project does not yet have a remote repository or established branch; create one deliberately before source changes intended for publication.

- Preserve known-good AutoPOL and XIVCrossbar installations and credential configuration while migrating.
- Make one coherent functionality change at a time. Prefer real completion signals to guessed delays. Avoid blocking the GUI input thread during queue operations.
- Never put passwords, TOTP seeds, codes or authentication requests in diagnostics or a public repo. Treat the existing AutoPOL config.json as sensitive and user-owned.
- Preserve cancellation at every launch stage and use read-only timing diagnostics for verification. The visible dry-run mode was retired in 0.4.26 at the user's request; test one account before a multiclient launch.
- Avoid unnecessary privileges, changes to the Windows hosts file, or proxy networking until a tested proxy lifecycle is specifically implemented.
- Test static syntax, native AHK startup, Windows Windower process launch, and finally in-game POL sequences separately. Clearly distinguish verified from unverified behavior.
- Preserve the cumulative TESTING.md, record changes, and identify exact commits, pushes and testing status. Package WORKFLOW.md and TESTING.md beside scripts.
