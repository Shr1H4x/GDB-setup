#!/bin/bash
# ============================================
#   Environment Setup Script
#   Tools: tmux, pwndbg, gef
#   For: Kali Linux
# ============================================

set -e  # Exit on any error

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log()  { echo -e "${CYAN}[*] $1${NC}"; }
ok()   { echo -e "${GREEN}[✔] $1${NC}"; }
fail() { echo -e "${RED}[✘] $1${NC}"; exit 1; }

# ─────────────────────────────────────────
# 1. UPDATE SYSTEM
# ─────────────────────────────────────────
log "Updating package repositories..."
sudo apt update -y || fail "apt update failed"
ok "Repos updated"

# ─────────────────────────────────────────
# 2. INSTALL TMUX
# ─────────────────────────────────────────
log "Installing tmux..."
sudo apt install tmux -y || fail "tmux install failed"
ok "tmux installed"

# Configure tmux - enable mouse support
log "Configuring tmux (mouse support)..."
echo "set -g mouse on" >> ~/.tmux.conf

# Reload tmux config if a session is running
if tmux info &>/dev/null; then
    tmux source ~/.tmux.conf
    ok "tmux config reloaded"
else
    ok "tmux config written to ~/.tmux.conf (will apply on next launch)"
fi

# ─────────────────────────────────────────
# 3. INSTALL PWNDBG
# ─────────────────────────────────────────
log "Cloning pwndbg..."
cd ~
if [ -d "pwndbg" ]; then
    log "pwndbg already exists, pulling latest..."
    cd pwndbg && git pull
else
    git clone https://github.com/pwndbg/pwndbg || fail "Failed to clone pwndbg"
    cd pwndbg
fi

log "Running pwndbg setup.sh..."
./setup.sh || fail "pwndbg setup failed"
ok "pwndbg installed"
cd ~

# ─────────────────────────────────────────
# 4. INSTALL GEF
# ─────────────────────────────────────────
log "Cloning gef..."
cd ~
if [ -d "gef" ]; then
    log "gef already exists, pulling latest..."
    cd gef && git pull && cd ~
else
    git clone https://github.com/hugsy/gef || fail "Failed to clone gef"
fi
ok "gef cloned"

# ─────────────────────────────────────────
# 5. CONFIGURE ~/.gdbinit
# ─────────────────────────────────────────
log "Writing ~/.gdbinit configuration..."
cat > ~/.gdbinit << 'EOF'
define init-pwndbg
source ~/pwndbg/gdbinit.py
end
document init-pwndbg
Initializes PwnDBG
end

define init-gef
source ~/gef/gef.py
end
document init-gef
Initializes GEF (GDB Enhanced Features)
end
EOF
ok "~/.gdbinit configured"

# ─────────────────────────────────────────
# 6. CREATE gdb-gef & gdb-pwndbg WRAPPERS
# ─────────────────────────────────────────
log "Creating /usr/bin/gdb-gef wrapper..."
sudo tee /usr/bin/gdb-gef > /dev/null << 'EOF'
#!/bin/sh
exec gdb -q -ex init-gef "$@"
EOF
sudo chmod +x /usr/bin/gdb-gef
ok "gdb-gef created"

log "Creating /usr/bin/gdb-pwndbg wrapper..."
sudo tee /usr/bin/gdb-pwndbg > /dev/null << 'EOF'
#!/bin/sh
exec gdb -q -ex init-pwndbg "$@"
EOF
sudo chmod +x /usr/bin/gdb-pwndbg
ok "gdb-pwndbg created"

# ─────────────────────────────────────────
# DONE
# ─────────────────────────────────────────
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   ✔ Environment Setup Complete!           ${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "  ${CYAN}tmux${NC}        → launch with: tmux"
echo -e "  ${CYAN}gdb${NC}         → plain gdb (no plugins)"
echo -e "  ${CYAN}gdb-pwndbg${NC}  → gdb with pwndbg plugin"
echo -e "  ${CYAN}gdb-gef${NC}     → gdb with gef plugin"
echo ""
