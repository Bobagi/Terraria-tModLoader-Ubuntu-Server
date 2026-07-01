# Thin image on top of the JACOBSMILE tModLoader 1.4 server image, adding the one
# thing recent Ubuntu bases are missing: libicu.
#
# Why this is needed: tModLoader's bundled .NET runtime forces the en-US culture at
# startup. On a base image without ICU it FailFasts before it ever generates the world
# ("Process terminated. Couldn't find a valid ICU package installed on the system"),
# and Docker's restart policy then loops forever. Invariant-globalization mode
# (DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1) does NOT help — tModLoader rejects it with
# "en-US is an invalid culture identifier". Installing the real ICU runtime is the fix.
#
# If a future base image ships ICU already, this layer is harmless (apt is a no-op).
# On older bases the package may be named libicu72/74/76 instead of libicu78 — adjust.
FROM jacobsmile/tmodloader1.4:latest

RUN apt-get update \
 && apt-get install -y --no-install-recommends libicu78 \
 && rm -rf /var/lib/apt/lists/*
