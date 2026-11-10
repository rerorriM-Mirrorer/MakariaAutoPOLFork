# Testing this source-only checkpoint

`source_snapshot.py` verifies the exact submitted AHK script and a few critical safety invariants without Windows. Run `python3 tests/source_snapshot.py` from the `AHK` directory.

`check_package.py` is the complete-install regression test supplied by the user. It intentionally expects additional files (such as `VanaLauncher.ahk`, helper scripts, Trust artwork and frozen baseline fixtures) that are **not present in the 0.4.34 UPDATE ZIP**. Its failure on this branch is a missing-package dependency, not a passed or failed gameplay regression. Restore those files from a reviewed complete source package before running it. Do not check in personal settings, passwords, 2FA seeds, POL archives, or client logs.
