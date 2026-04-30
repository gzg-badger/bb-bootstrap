# bb-bootstrap

Diagnostic bootstrap for the [Badger Buddy](https://wolfandbadger.com) install on macOS. Probes Google Drive readability + macOS TCC permissions, then delegates to the real installer on the W&B shared drive.

Solves a chicken-and-egg: the BB:CC installer lives on Google Drive, but a fresh macOS user account can't read Drive until Terminal is granted Full Disk Access. The bootstrap is hosted here on GitHub so the very first command works without any prior permissions.

## Install command

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gzg-badger/bb-bootstrap/main/v1/bootstrap.sh)"
```

If macOS Full Disk Access isn't granted to Terminal, the bootstrap opens System Settings to the right pane and tells the user what to do. After fix, re-paste the command.

## Versioning

- `v1/bootstrap.sh` — current stable
- Bumps require pasting a new command for all users, so changes here are deliberate

## What it does

1. Confirms macOS + Drive Desktop installed
2. Probes `~/Library/CloudStorage` readability — opens FDA pane on EPERM
3. Locates the `@wolfandbadger.com` Drive account
4. Checks the `AI Badger Buddy` shared drive is visible + offline
5. Copies `setup/install.sh` to a temp dir and `exec`s it

The bootstrap contains no secrets — its job is purely to detect failure modes before the real installer hits them silently.
