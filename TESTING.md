# Current Development Status — November 10, 2026 — clean fresh-install archive assembled

- **Repo/branch:** `rerorriM-Mirrorer/MakariaAutoPOLFork` / `development/autopol-ahk`. The complete user-supplied `AutoPOL-AHK.zip` was reviewed as a *private local install*, not uploaded wholesale.
- **Preserved source:** the original `AutoPOL-AHK.ahk` remains byte-for-byte equal to the previously published 0.4.34 source (SHA-256 `cdca63a2a1f68d7e9abffac17f9618fe2a1bece73ff490efa23ce602914f8e13`). No login or runtime source was edited.
- **Fresh-install package:** `AutoPOL-AHK-0.4.34-FRESH-INSTALL.zip` was assembled for the user in this chat, 59 files, SHA-256 `a476ac546a512750ef582ec79b3bc0e5a19b7e9051414926e036f3f36f43fbce`. Includes core AHK, compatibility launcher, seven PowerShell helpers, 34 currently required glow PNGs, 10 user-supplied Trust UI assets for their private installation, and installation/development documentation. Generated four absent glow sizes from nearby included art: hover/selected 120x36 and 465x35.
- **Excluded:** all `data/` (including encrypted credentials, diagnostics and caches), `launcher.ini`, `accounts-metadata.ini*`, backup/failed versions, unused glow sizes, research notes and test fixtures from the end-user ZIP. Do not upload the unfiltered user ZIP or publish upstream Trust artwork.
- **Validation:** The complete 0.4.34 Python static regression passed in a separate review directory after providing the four missing glow PNGs and a synthetic `tests/fixtures/windower-settings.xml` fixture. ZIP CRC and file-byte checks passed; no account/credential/config data is included. These are offline/static checks only. No native AutoHotkey, PlayOnline or FFXI test was run.
- **GitHub publication boundary:** The previous public source-only 0.4.34 checkpoint is preserved. The entire fresh-install binary/helper set has **not** been added as individual GitHub sources in this batch. The branch's root `.gitignore` was tightened to cover backed-up metadata, private runtime data and third-party Trust art.
- **Next:** Import the clean, original helper scripts and freely redistributable glow images into the branch, reconstruct a GitHub-buildable fresh-install artifact without upstream Trust artwork, then independently test a Windows fresh install and two-character login before treating it as release-ready.

---

# Current Development Status — 2026-11-10

- **Repository:** `rerorriM-Mirrorer/MakariaAutoPOLFork`, branch `development/autopol-ahk`, derived from the unchanged C++ `main` branch.
- **Source checkpoint:** `AutoPOL-AHK-0.4.34-UPDATE(1).zip` supplied by the user; AHK script SHA-256 `cdca63a2a1f68d7e9abffac17f9618fe2a1bece73ff490efa23ce602914f8e13`. Imported into `AHK/` without runtime edits.
- **Live feedback:** Earlier AutoPOL-AHK automatic login, Fast timing and `a`/Backspace password preparation were reported successful by the user. These observations do not independently prove the uploaded 0.4.34 UPDATE as a full Windows acceptance run.
- **Static tests:** Run `python3 AHK/tests/source_snapshot.py`; source SHA, password input order, overlapped handoff guard and clipboard restoration. Check `python3 -m py_compile` for the included Python scripts. The original full-package test cannot run without missing helpers/assets/fixtures.
- **Next:** Obtain complete non-private helper/asset set and verify the complete suite, then live-test 0.4.34 on Windows using a backup of the working launcher. Do not merge into `main` until independently verified.
- **Cumulative history:** [`AHK/TESTING.md`](AHK/TESTING.md), preserved with a current publication note and public redaction of two POL account labels.

## Delivery register

- 2026-11-10: Imported 0.4.34 **update-only source snapshot** on `development/autopol-ahk`; no C++ modifications; final published SHA is confirmed externally, not embedded in this document.
