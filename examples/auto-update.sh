#!/usr/bin/env bash
# Auto-update a Dockerized tModLoader server to the latest stable release.
#
# WHY YOU WANT THIS: tModLoader ships a stable release roughly every month and
# Steam updates every player automatically. A server left behind rejects them
# all with "You are not using the same version as this server". This script
# keeps the server in lockstep with Steam, and it's polite about it: if anyone
# is playing, it postpones and lets the next cron run retry.
#
# REQUIREMENTS: the version-pinned Dockerfile from this guide (docker/Dockerfile,
# with `ARG TMOD_VERSION=...`), compose project with a container named like
# $CONTAINER below, curl, and the JACOBSMILE image's `inject` + tmux console.
#
# INSTALL:
#   sudo cp examples/auto-update.sh /opt/terraria-tmodloader/auto-update.sh
#   sudo chmod +x /opt/terraria-tmodloader/auto-update.sh
#   # run daily at a quiet hour (server local time):
#   echo '17 9 * * * root /opt/terraria-tmodloader/auto-update.sh >/dev/null 2>&1' \
#     | sudo tee /etc/cron.d/tmodloader-autoupdate
#
# NOTE: the rebuild deliberately does NOT `--pull` the upstream base image — the
# base only supplies steamcmd/entrypoint scripts, and re-pulling could silently
# change the Ubuntu release under you (and the libicu package name with it).
# Refresh the base on purpose, when you choose: docker compose build --pull
set -euo pipefail

# ── adjust these to your setup ───────────────────────────────────────────────
COMPOSE_DIR="/opt/terraria-tmodloader"   # where docker-compose.yml + Dockerfile live
CONTAINER="tmodloader"                   # container_name in your compose file
WORLDS_DIR="$COMPOSE_DIR/data/tModLoader/Worlds"
BACKUP_DIR="/root"                       # where world backups go (keeps last 3)
LOG=/var/log/tmodloader-autoupdate.log
# ─────────────────────────────────────────────────────────────────────────────

cd "$COMPOSE_DIR"
log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

# 1. Latest stable tag (e.g. v2026.05.3.0)
LATEST=$(curl -fsSL --max-time 30 https://api.github.com/repos/tModLoader/tModLoader/releases/latest \
  | grep -oE '"tag_name": *"[^"]+"' | head -1 | sed -E 's/.*"(v[^"]+)".*/\1/' || true)
if [[ -z "$LATEST" ]]; then log "skip: could not read latest tag from GitHub"; exit 0; fi
if [[ ! "$LATEST" =~ ^v[0-9][0-9.]*$ ]]; then log "skip: unexpected tag format '$LATEST'"; exit 0; fi

# 2. Version currently running (the tmod.version label from the Dockerfile)
CURRENT=$(docker inspect --format '{{index .Config.Labels "tmod.version"}}' "$CONTAINER" 2>/dev/null || true)
if [[ "$LATEST" == "$CURRENT" ]]; then exit 0; fi

# 3. Postpone if players are online (nobody likes a surprise kick)
if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  docker exec "$CONTAINER" inject "playing" >/dev/null 2>&1 || true
  sleep 2
  PANE=$(docker exec "$CONTAINER" tmux capture-pane -p -S -30 2>/dev/null || true)
  REPLY=$(echo "$PANE" | awk '{l[NR]=$0} /^playing$/{f=NR} END{if(f) for(i=f+1;i<=NR;i++) print l[i]}')
  if ! echo "$REPLY" | grep -qi "no players connected" && echo "$REPLY" | grep -qE "^: .+"; then
    log "postpone: players online (current $CURRENT, latest $LATEST)"
    exit 0
  fi
fi

log "updating: ${CURRENT:-unknown} -> $LATEST"

# 4. World backup first (upgrades migrate the world one-way); keep the last 3
BK="$BACKUP_DIR/terraria-world-backup-auto-${LATEST}-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$BK" -C "$(dirname "$WORLDS_DIR")" "$(basename "$WORLDS_DIR")" && chmod 600 "$BK"
ls -1t "$BACKUP_DIR"/terraria-world-backup-auto-*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm -f

# 5. Bump the pinned version and rebuild
sed -i -E "s|^ARG TMOD_VERSION=.*|ARG TMOD_VERSION=${LATEST}|" Dockerfile
if ! docker compose build >> "$LOG" 2>&1; then
  log "ERROR: image build failed — server left on ${CURRENT:-unknown}"
  exit 1
fi

# 6. Graceful swap: announce (harmless if empty), save, recreate
docker exec "$CONTAINER" inject "say Server updating to tModLoader ${LATEST} — back in ~2 minutes!" >/dev/null 2>&1 || true
docker exec "$CONTAINER" inject "save" >/dev/null 2>&1 || true
sleep 10
docker compose up -d >> "$LOG" 2>&1
log "done: now on $LATEST"
