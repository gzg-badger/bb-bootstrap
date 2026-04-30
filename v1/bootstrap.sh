#!/usr/bin/env bash
# Badger Buddy bootstrap (v1)
# Diagnoses Drive readability + macOS TCC, then delegates to install.sh on Drive.
# Hosted: https://raw.githubusercontent.com/gzg-badger/bb-bootstrap/main/v1/bootstrap.sh

set -euo pipefail

RED=$'\033[0;31m'; YEL=$'\033[0;33m'; GRN=$'\033[0;32m'; BLD=$'\033[1m'; NC=$'\033[0m'
ok()   { printf '%s  [ok]%s %s\n' "$GRN" "$NC" "$1"; }
warn() { printf '%s  [!!]%s %s\n' "$YEL" "$NC" "$1"; }
fail() { printf '%s  [xx]%s %s\n' "$RED" "$NC" "$1" >&2; exit 1; }

printf '\n%sBadger Buddy — Bootstrap%s\n  ━━━━━━━━━━━━━━━━━━━━━━━━\n\n' "$BLD" "$NC"

# ── Pre-flight ──────────────────────────────────────────────────────────────

[[ "$(uname -s)" == "Darwin" ]] || fail "Bootstrap is macOS-only."

CS="$HOME/Library/CloudStorage"
if [[ ! -d "$CS" ]]; then
    fail "Google Drive Desktop not installed. Download from https://google.com/drive/download then re-run."
fi

# ── TCC probe ───────────────────────────────────────────────────────────────
# Reading $CS triggers the TCC check. A hard EPERM means Terminal lacks
# Full Disk Access. Capture stderr explicitly — `set -e` won't catch this.

probe_err=$(ls "$CS" 2>&1 >/dev/null || true)
if printf '%s' "$probe_err" | grep -qi 'operation not permitted'; then
    warn "Terminal can't read Google Drive (macOS blocked it for privacy)."
    cat <<'EOF'

  Fix it in three steps:
    1. System Settings will open in 3 seconds.
    2. Find "Terminal" in the Full Disk Access list — toggle it ON.
       (If you also see "Ghostty" once it's installed later, toggle that too.)
    3. Quit Terminal completely (Cmd+Q), reopen, paste the install command again.

EOF
    sleep 3
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles" 2>/dev/null || true
    fail "Quit Terminal (Cmd+Q), reopen, and re-run after granting Full Disk Access."
fi
ok "Terminal can read Google Drive"

# ── W&B account mounted ─────────────────────────────────────────────────────

# Glob-into-array — bash 3.2 safe. With no match, bash leaves the literal
# pattern as one element; [[ -d ]] catches that since the literal won't exist.
WB_DRIVES=("$CS"/GoogleDrive-*wolfandbadger.com*)
[[ -d "${WB_DRIVES[0]}" ]] || fail "No @wolfandbadger.com Drive account mounted. Sign in via the Drive menu-bar icon, then re-run."
WB_DRIVE="${WB_DRIVES[0]}"

if [[ "${#WB_DRIVES[@]}" -gt 1 ]]; then
    warn "Multiple @wolfandbadger.com accounts mounted (${#WB_DRIVES[@]}) — using $(basename "$WB_DRIVE"). Sign out of any wrong ones in Drive's menu-bar icon, then re-run."
else
    ok "Found @wolfandbadger.com account: $(basename "$WB_DRIVE")"
fi

SHARED="$WB_DRIVE/Shared drives/AI Badger Buddy"
if [[ ! -d "$SHARED" ]]; then
    fail "'AI Badger Buddy' shared drive not visible. Ask George for access, then re-run."
fi
ok "Shared drive visible"

# ── Offline-availability + non-placeholder VERSION ──────────────────────────

VFILE="$SHARED/VERSION"
if [[ ! -f "$VFILE" ]]; then
    warn "Shared drive isn't downloaded for offline use yet."
    cat <<EOF

  Fix it:
    1. Finder → Google Drive → Shared drives.
    2. Right-click "AI Badger Buddy" → "Available offline".
    3. Wait for the green tick (1-2 minutes), then re-run.

EOF
    open "$WB_DRIVE/Shared drives" 2>/dev/null || true
    exit 1
fi

# Drive placeholder stubs are 0-byte; real files have content. Belt-and-braces
# probe with `head -c` to catch EIO on partial-sync stubs.
if [[ ! -s "$VFILE" ]] || ! head -c 32 "$VFILE" >/dev/null 2>&1; then
    fail "VERSION file is a Drive placeholder, not synced yet. Toggle 'Available offline' on the AI Badger Buddy folder and wait for sync to complete."
fi
BBCC_VERSION=$(tr -d '[:space:]' <"$VFILE")
ok "Shared drive synced (BB:CC v${BBCC_VERSION})"

# ── Hand off to installer ───────────────────────────────────────────────────
# install.sh sources lib.sh via $SCRIPT_DIR (its own location), so we run it
# in place on Drive rather than copying. install.sh reads from Drive heavily
# throughout install anyway — staging to /tmp wouldn't decouple meaningfully.

INSTALLER="$SHARED/setup/install.sh"
LIB="$SHARED/setup/lib.sh"
# -s catches both missing and 0-byte (placeholder) cases — same fix either way.
[[ -s "$INSTALLER" ]] || fail "install.sh missing or not synced yet — wait for the green tick on AI Badger Buddy and re-run."
[[ -s "$LIB" ]]       || fail "lib.sh missing or not synced yet — wait and re-run."
ok "Installer + lib found on Drive"

printf '\n%sHanding off to BB:CC installer…%s\n\n' "$BLD" "$NC"
exec bash "$INSTALLER" "$@"
