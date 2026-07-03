# Thin image on top of the JACOBSMILE tModLoader 1.4 server image, with two fixes:
#
# ── 1. libicu ────────────────────────────────────────────────────────────────
# tModLoader's bundled .NET runtime forces the en-US culture at startup. On a
# base image without ICU it FailFasts before it ever generates the world
# ("Process terminated. Couldn't find a valid ICU package installed on the
# system"), and Docker's restart policy then loops forever.
# Invariant-globalization mode (DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1) does
# NOT help — tModLoader rejects it with "en-US is an invalid culture
# identifier". Installing the real ICU runtime is the fix.
# If a future base image ships ICU already, this layer is harmless (apt no-op).
# On older bases the package may be libicu72/74/76 instead of libicu78 — adjust.
#
# ── 2. tModLoader version pin ────────────────────────────────────────────────
# The base image bakes the game binaries in at BUILD time, so `:latest` goes
# stale as tModLoader ships monthly stable releases. Steam auto-updates every
# player, and a stale server rejects them all with:
#     "You are not using the same version as this server"
# The overlay below downloads the OFFICIAL release zip from GitHub (the same
# build Steam ships) on top of the baked-in copy, pinned by TMOD_VERSION.
# Bump the ARG (or automate it — see examples/auto-update.sh) and rebuild:
#     docker compose build && docker compose up -d
FROM jacobsmile/tmodloader1.4:latest

# Must match a tag of https://github.com/tModLoader/tModLoader/releases
ARG TMOD_VERSION=v2026.05.3.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends libicu78 ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# The zip holds the game files (dlls, LaunchUtils/, start-*.sh); the image's own
# scripts (entrypoint.sh, prepare-config.sh, autosave.sh, inject) are not in the
# zip and survive the overwrite.
RUN wget -q -O /tmp/tModLoader.zip \
      "https://github.com/tModLoader/tModLoader/releases/download/${TMOD_VERSION}/tModLoader.zip" \
 && unzip -o -q /tmp/tModLoader.zip -d /terraria-server \
 && rm /tmp/tModLoader.zip \
 && chmod +x /terraria-server/LaunchUtils/*.sh /terraria-server/*.sh

LABEL tmod.version="${TMOD_VERSION}"
