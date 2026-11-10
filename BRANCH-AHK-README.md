# AutoPOL AHK development branch

The **C++ Makaria AutoPOL** launcher remains unchanged in this fork's `main` branch. This branch adds the **AHK v2** launcher source under [`AHK/`](AHK/).

**This is an UPDATE-only source checkpoint (0.4.34), not a complete installer.** The uploaded archive contains the main `.ahk` script, README, cumulative TESTING, WORKFLOW and original static test, but does not contain auxiliary `.ps1` helpers, baseline test fixture or button art. Do not try to run a fresh installation from these files alone; preserve your existing known-good installation, encrypted credentials, and local configuration. Do not add any private credentials or POL files to GitHub.

Run `python3 AHK/tests/source_snapshot.py` for the available offline verification. The original test `check_package.py` requires the complete distributable package and is retained for future reconstruction. See [`TESTING.md`](TESTING.md) for the actual status and [`AHK/TESTING.md`](AHK/TESTING.md) for earlier development history.
