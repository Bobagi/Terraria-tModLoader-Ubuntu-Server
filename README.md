# Terraria + tModLoader Dedicated Server on Ubuntu — Complete Setup Guide

> **Step-by-step guide to install, configure, and run a modded Terraria (tModLoader) dedicated server on Ubuntu / Linux.** Two methods: **Docker** (recommended) and a **native** install. Covers Steam Workshop mods, firewall (TCP port 7777), RAM limits, the notorious `libicu` startup crash, and common troubleshooting. Works on any VPS provider (Hostinger, DigitalOcean, Hetzner, Vultr, AWS, Linode, Oracle Cloud, etc.).

[![Stars](https://img.shields.io/github/stars/Bobagi/Terraria-tModLoader-Ubuntu-Server?style=for-the-badge)](https://github.com/Bobagi/Terraria-tModLoader-Ubuntu-Server/stargazers)
[![Forks](https://img.shields.io/github/forks/Bobagi/Terraria-tModLoader-Ubuntu-Server?style=for-the-badge)](https://github.com/Bobagi/Terraria-tModLoader-Ubuntu-Server/network/members)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
![Terraria](https://img.shields.io/badge/Terraria-1A1A2E?style=for-the-badge&logo=terraria&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

---

**[🇧🇷 Versão em Português](README.pt-BR.md)**

---

## Table of Contents
1. [Why this guide?](#why-this-guide)
2. [Prerequisites](#prerequisites)
3. [Method A — Docker (recommended)](#method-a--docker-recommended)
4. [Method B — Native install](#method-b--native-install-no-docker)
5. [Installing mods](#installing-mods)
6. [How players connect](#how-players-connect)
7. [Server management](#server-management)
8. [Keep the server updated automatically](#keep-the-server-updated-automatically-fix-you-are-not-using-the-same-version-as-this-server)
9. [Add a live server-status badge (optional)](#add-a-live-server-status-badge-optional)
10. [Live status web page (players online, CPU/RAM, mods)](#live-status-web-page-players-online-cpuram-mods)
11. [Troubleshooting](#troubleshooting)
12. [FAQ](#faq)
13. [Recommended quality-of-life mods](#recommended-quality-of-life-mods)
14. [Acknowledgements](#acknowledgements)
15. [License](#license)

---

## Why this guide?

Most tutorials for hosting a **Terraria server on Linux** either stop at the vanilla server or gloss over the parts that actually break a **modded tModLoader** setup — the firewall, RAM, Steam Workshop mods, and the cryptic startup crashes. This guide was written from a real, working deployment and covers:

- ✅ **Docker method** (recommended, reproducible) — the way the official tModLoader docs suggest
- ✅ **Native method** (no Docker) — the classic install with the official management script
- ✅ Auto-downloading **Steam Workshop mods** on the server by ID (no manual uploads)
- ✅ **Firewall** setup (TCP **7777**) and the VPS "cloud firewall" gotcha
- ✅ **RAM limits** so a heavy modpack (Calamity, Thorium…) can't take down your whole machine
- ✅ Fixing the **`Couldn't find a valid ICU package` crash-loop** (missing `libicu`)
- ✅ Fixing the **container that exits immediately** (missing TTY / EOF restart loop)
- ✅ A curated, tested **quality-of-life mod list** with Workshop IDs

Whether you want to play **Calamity** with friends or just a lightly-modded small world, this gets you online.

---

## Prerequisites

Before you begin, make sure you have:

- A VPS or machine running **Ubuntu 22.04 / 24.04 LTS** (or Debian 12) — 64-bit
- **RAM:** 2 GB is enough for a small world with light mods; **4 GB+** recommended, **6–8 GB** for Calamity-scale modpacks with several players
- `sudo` privileges and basic terminal knowledge
- An **x86-64** machine — **ARM is not supported** by the Terraria/tModLoader server
- Players who own **Terraria** on Steam. For a modded server they also need **[tModLoader](https://store.steampowered.com/app/1281930/tModLoader/)** (free on Steam)
- The **server itself is free** and needs no Steam account to run

> 💡 **Which method?** Use **Docker** unless you have a reason not to — it isolates the server, makes mods and RAM limits trivial, and is what the official tModLoader documentation recommends. The native method is here for people who can't or don't want to use Docker.

---

## Method A — Docker (recommended)

This mirrors a real, running deployment. It uses the community [`jacobsmile/tmodloader1.4`](https://github.com/JACOBSMILE/tmodloader1.4) image, which **auto-downloads Steam Workshop mods by numeric ID** — no manual file transfers.

### 1. Install Docker

```bash
sudo apt-get update
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"   # log out/in afterwards so this takes effect
docker compose version            # confirm Compose V2 is available
```

### 2. Get the server files

Clone this repository (or just copy the `docker/` folder):

```bash
git clone https://github.com/Bobagi/Terraria-tModLoader-Ubuntu-Server.git
cd Terraria-tModLoader-Ubuntu-Server/docker
```

You now have `docker-compose.yml`, a `Dockerfile`, and `.env.example`.

### 3. Set your server password

```bash
cp .env.example .env
nano .env            # set TMOD_PASS=your-strong-password
chmod 600 .env       # keep the password private
```

### 4. Configure the world and mods

Open `docker-compose.yml` and adjust the `environment:` block:

| Variable | Meaning |
|---|---|
| `TMOD_WORLDNAME` | World file name |
| `TMOD_WORLDSIZE` | `1` = Small, `2` = Medium, `3` = Large |
| `TMOD_DIFFICULTY` | `0` = Classic, `1` = Expert, `2` = Master, `3` = Journey |
| `TMOD_MAXPLAYERS` | Max players (e.g. `8`) |
| `TMOD_AUTODOWNLOAD` | Comma-separated **Steam Workshop mod IDs** to download |
| `TMOD_ENABLEDMODS` | Comma-separated Workshop IDs to **enable** (usually the same list) |

The included example enables a light quality-of-life pack (see [Recommended mods](#recommended-quality-of-life-mods)). To play **Calamity**, swap in its Workshop IDs and raise `mem_limit`.

### 5. Understand the `Dockerfile` (the `libicu` fix + version pin)

The compose file builds a **thin derived image** with two fixes on top of the base:

1. **`libicu`** — not optional: without it the .NET runtime inside the container
   **crash-loops on startup** with `Couldn't find a valid ICU package`. See
   [Troubleshooting](#troubleshooting) for the full story.
2. **A pinned tModLoader version** (`ARG TMOD_VERSION`) — the base image bakes the game
   binaries in at build time and goes stale, while Steam auto-updates every player.
   The Dockerfile overlays the **official release zip from GitHub** so your server runs
   the exact version you pin. See
   [Keep the server updated automatically](#keep-the-server-updated-automatically-fix-you-are-not-using-the-same-version-as-this-server).

You don't have to do anything; `docker compose` builds it for you.

### 6. Open the firewall (TCP 7777)

Terraria uses **TCP port 7777**. Allow it:

```bash
sudo ufw allow 22/tcp     # keep SSH open FIRST if you use UFW
sudo ufw allow 7777/tcp   # Terraria / tModLoader
sudo ufw enable
sudo ufw status
```

> ⚠️ Many VPS providers (Hostinger, Oracle Cloud, AWS, GCP) have a **separate cloud firewall / security group**. You must open **TCP 7777** there too, or players will time out even though UFW looks correct.

### 7. Start the server

```bash
docker compose up -d          # first run downloads .NET + mods and generates the world (a few minutes)
docker compose logs -f        # watch progress; wait for "Server started"
```

A healthy first boot looks like this (trimmed) — once you see **`Server started`**, you're live:

<details>
<summary>📟 Example server console output</summary>

```text
[SYSTEM] Finished downloading mods.
Adding Content: Recipe Browser v0.12
Adding Content: Boss Checklist v2.2.4
Adding Content: Census - Town NPC Checklist v0.5.2.7
Adding Content: AlchemistNPC Lite v1.9.9
Adding Content: Ore Excavator (1.4.3/1.4.4 Veinminer) v0.8.9
[SYSTEM] Finished loading mods.
...
95.7% - Generating structures..Standard Minecart Tracks - 80.0%
96.0% - Generating structures..Lava Traps
Listening on port 7777
Type 'help' for a list of commands.
Server started
```
</details>

That's it — your modded Terraria server is live on `your-server-ip:7777`. Skip to [How players connect](#how-players-connect).

---

## Method B — Native install (no Docker)

Prefer no Docker? Use the **official** [tModLoader Dedicated Server Utils](https://docs.tmodloader.net/docs/stable/md__github_workspace_src_t_mod_loader__terraria_release_extras__dedicated_server_utils__r_e_a_d_m_e.html) management script.

### 1. Create a dedicated user

```bash
sudo adduser terraria
sudo su - terraria
```

### 2. Install dependencies (including `libicu`)

The tModLoader server runs on .NET, which needs **ICU** for globalization — the exact thing missing in the Docker case:

```bash
sudo apt-get update
sudo apt-get install -y libicu-dev tar gzip wget
```

### 3. Open the firewall

```bash
sudo ufw allow 22/tcp
sudo ufw allow 7777/tcp
sudo ufw enable
```

### 4. Download the tModLoader server

Grab the official management script and install the server **from the GitHub release** (anonymous — no Steam login required):

```bash
cd ~
mkdir -p tModLoaderServer && cd tModLoaderServer
# Download manage-tModLoaderServer.sh from the latest tModLoader release:
#   https://github.com/tModLoader/tModLoader/releases  (in the extracted server files)
./manage-tModLoaderServer.sh install-tml --github
```

> Alternatively, `install-tml --username <your_steam_username>` installs via SteamCMD. The `--github` route needs no Steam account and is simplest for a headless server.

### 5. Configure the server

Copy the example config from this repo and edit it:

```bash
cp /path/to/native/serverconfig.txt.example ~/tModLoaderServer/serverconfig.txt
nano ~/tModLoaderServer/serverconfig.txt   # set worldname, difficulty, password, maxplayers
```

### 6. Run the server

**Simple (with `screen`):**

```bash
sudo apt-get install -y screen
screen -S terraria
cd ~/tModLoaderServer
./start-tModLoaderServer.sh -nosteam -config serverconfig.txt
# detach with Ctrl+A then D; reattach with: screen -r terraria
```

**Recommended (auto-start with systemd):** use the ready-made unit in [`native/tmodloader-server.service`](native/tmodloader-server.service):

```bash
sudo cp native/tmodloader-server.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now tmodloader-server
journalctl -u tmodloader-server -f
```

---

## Installing mods

Mods live on the **Steam Workshop**. Every mod has a numeric **Workshop ID** — the number in its Workshop URL:
`https://steamcommunity.com/sharedfiles/filedetails/?id=`**`2619954303`**.

### Docker

Put the IDs in **both** `TMOD_AUTODOWNLOAD` (download) and `TMOD_ENABLEDMODS` (enable) in `docker-compose.yml`, then:

```bash
docker compose up -d
```

The image downloads and enables them automatically on the next start. No Steam account, no manual uploads.

### Native

Create a **modpack** in the tModLoader client (Workshop → build a Mod Pack), which generates `install.txt` + `enabled.json`, copy them into `~/.local/share/Terraria/tModLoader/Mods/`, then run:

```bash
./manage-tModLoaderServer.sh install-mods
./manage-tModLoaderServer.sh start
```

> **Every player must enable the same mods.** tModLoader can offer to download the server's mods on join (if they're on the Workshop), but the cleanest experience is everyone subscribing to the same list up front.

---

## How players connect

1. Launch **tModLoader** (not vanilla Terraria) with the **same enabled mods** as the server.
2. **Multiplayer → Join via IP**
3. Enter the server's **public IP**, port **`7777`**, and the **password**.

Find your server's public IP with:

```bash
curl ifconfig.me
```

---

## Server management

### Docker

```bash
docker compose logs -f                       # live logs
docker exec tmodloader inject "say hello"     # run a server console command
docker exec tmodloader inject "playing"       # list connected players
docker exec tmodloader inject "save"          # force a world save
docker compose down                           # stop (saves on shutdown)
docker compose up -d                          # start
docker stats --no-stream tmodloader           # check RAM / CPU
```

### Native

```bash
screen -r terraria        # attach to the console (then type: help, playing, save, exit)
journalctl -u tmodloader-server -f   # if using systemd
```

### Backups

Back up your world regularly. **Docker:**

```bash
tar czf backup-$(date +%F).tar.gz docker/data/tModLoader/Worlds
```

**Native:**

```bash
tar czf backup-$(date +%F).tar.gz ~/.local/share/Terraria/tModLoader/Worlds
```

---

## Keep the server updated automatically (fix: "You are not using the same version as this server")

tModLoader ships a **stable release roughly every month**, and **Steam updates every
player automatically**. The day that happens, a server still on last month's build
rejects everyone with:

```
You are not using the same version as this server.
```

The base Docker image can't save you here — it bakes the game binaries in at build
time, so `:latest` is only as fresh as its last rebuild. This guide's
[`docker/Dockerfile`](docker/Dockerfile) fixes that with a **version-pinned overlay**:
it downloads the official release zip from
[tModLoader's GitHub releases](https://github.com/tModLoader/tModLoader/releases)
(the exact build Steam ships) on top of the base image, pinned by `ARG TMOD_VERSION`.

**Manual update** (any time a new stable lands):

```bash
cd /opt/terraria-tmodloader
sed -i 's|^ARG TMOD_VERSION=.*|ARG TMOD_VERSION=v2026.05.3.0|' Dockerfile  # new tag
docker compose build && docker compose up -d
```

**Automatic update** — copy [`examples/auto-update.sh`](examples/auto-update.sh) and run
it daily from cron. It checks GitHub for a new stable tag, **postpones if players are
online**, backs up the world, bumps the pin, rebuilds and recreates:

```bash
sudo cp examples/auto-update.sh /opt/terraria-tmodloader/auto-update.sh
sudo chmod +x /opt/terraria-tmodloader/auto-update.sh
echo '17 9 * * * root /opt/terraria-tmodloader/auto-update.sh >/dev/null 2>&1' \
  | sudo tee /etc/cron.d/tmodloader-autoupdate
```

> 🧩 **Mod dependencies can change between versions.** After a major bump, watch the
> first boot log: a mod may gain a new required library and be auto-disabled with
> `Missing mod: X required by Y`. Fix: add the library's Workshop ID to
> `TMOD_AUTODOWNLOAD`/`TMOD_ENABLEDMODS` (e.g. Magic Storage needs *SerousCommonLib*,
> ID `2908170107`, since tML 2026.05).

---

## Add a live server-status badge (optional)

Want a badge that shows whether **your** server is online, like this?
`![Server status](https://img.shields.io/badge/terraria%20server-online-brightgreen)`

You can build it with **GitHub Actions only** — no third-party service, and without putting your server's IP anywhere public except your own repository's private settings. A ready-to-copy workflow is included at [`examples/server-status.yml`](examples/server-status.yml).

**Setup (about 2 minutes):**

1. Copy [`examples/server-status.yml`](examples/server-status.yml) to `.github/workflows/server-status.yml` in **your** repository.
2. Go to **Settings → Secrets and variables → Actions → Variables** and add:
   - `TERRARIA_HOST` = your server's IP or hostname *(required)*
   - `TERRARIA_PORT` = `7777` *(optional)*
3. Add the badge to your README (replace `OWNER/REPO`):
   ```markdown
   ![Server status](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/OWNER/REPO/badges/server-status.json)
   ```
4. Run it once from the **Actions** tab to publish the first status.

The workflow TCP-pings your server every 15 minutes and writes a small [Shields.io endpoint](https://shields.io/badges/endpoint-badge) JSON to a dedicated `badges` branch (it never clutters your `main` history). Keeping the host in a **repository Variable** means your IP stays out of the committed files.

> 🔒 **A note on privacy:** a status badge publishes your server's address wherever the badge is shown. If you plan to hide your origin IP behind a CDN/proxy later, prefer pointing `TERRARIA_HOST` at a **hostname** you control rather than a raw IP.

---

## Live status web page (players online, CPU/RAM, mods)

Want a full **status page** your players can bookmark — who's online, server CPU/RAM,
the mod list with Workshop links, the tModLoader version, and a *"Launch tModLoader"*
button? That's a separate companion project:

**➡️ [Bobagi/terraria-status](https://github.com/Bobagi/terraria-status)** — a
zero-dependency Node.js app that polls the Docker container from this guide
(`docker stats` + the console's `playing` command) and serves a themed live dashboard.
Live example: **[terraria.bobagi.space](https://terraria.bobagi.space)**.

It is designed for exactly the setup this guide produces (the JACOBSMILE image's
`inject` helper and tmux console), takes ~10 minutes to deploy behind nginx + certbot,
and is careful about safety: it never exposes the console log (which contains your
server password), never publishes player IPs, and binds to `127.0.0.1` only.

It also **warns when your server's tModLoader version is out of date** (comparing against
the latest GitHub release — the exact thing that causes the version-mismatch kick), and
lets you **click a player to see their character** (health, gear, inventory) via an
optional `side = Server` companion mod that your players don't need to install.

---

## Troubleshooting

### ❌ Container crash-loops: `Couldn't find a valid ICU package`

The single most common tModLoader-on-Linux failure. The .NET runtime forces the `en-US` culture at startup and aborts if **ICU** isn't installed, so the container restarts forever (each loop re-downloading mods). Confirm it in `tModLoader-Logs/Natives.log`:

```
Process terminated. Couldn't find a valid ICU package installed on the system.
```

**Fix (Docker):** install `libicu` in a derived image — this repo's `Dockerfile` already does it:

```dockerfile
FROM jacobsmile/tmodloader1.4:latest
RUN apt-get update && apt-get install -y --no-install-recommends libicu78 && rm -rf /var/lib/apt/lists/*
```

**Fix (native):** `sudo apt-get install -y libicu-dev`.

> ⚠️ **Do NOT "fix" it with `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1`.** That removes the ICU error but tModLoader then crashes with `en-US is an invalid culture identifier` — it hard-requires a real culture. Install ICU; don't disable globalization.
>
> If the package name errors out, your base uses a different Ubuntu: try `libicu76`, `libicu74`, or `libicu72` (match the base image's Ubuntu release).

### ❌ Container starts then exits immediately (restart loop, exit code 0)

The server console reads from stdin; with no TTY it hits EOF and exits cleanly, and Docker restarts it forever. **Fix:** ensure the compose service has both:

```yaml
    stdin_open: true
    tty: true
```

### ❌ "Connection failed" / players can't join

- Confirm the port is open: `sudo ufw status` → look for **`7777/tcp`**
- Open **TCP 7777** in your **VPS provider's cloud firewall** too (the #1 cause)
- Confirm the server is up: `docker compose logs --tail=20` should show `Server started` / `Listening on port 7777`
- Verify your public IP: `curl ifconfig.me`
- Make sure players use **the same mods** and launch **tModLoader**, not vanilla Terraria

### ❌ Server killed / runs out of memory (OOM)

Heavy modpacks (Calamity + friends) can use 4–6 GB. If the host is small, cap the container so it can't take everything down — this repo sets `mem_limit: 4g`. Raise it if you have the RAM, or use a lighter modlist. Check usage with `docker stats`.

### ❌ Mods downloaded but not active

Make sure each ID is in **both** `TMOD_AUTODOWNLOAD` and `TMOD_ENABLEDMODS` (Docker), or that `enabled.json` lists them (native). Restart after any change.

### ❌ World didn't generate / wrong difficulty

Difficulty and size are baked in at world creation. To regenerate, stop the server, delete the `.wld`/`.twld` files in the `Worlds` folder, fix the settings, and start again.

---

## FAQ

**Q: Do I need to own Terraria (or install anything from Steam) to run the server?**
A: No. The dedicated server is free and runs with no Steam account. Only the **players** need to own Terraria, and for a modded server they must run **tModLoader** (free on Steam) with the same mods.

**Q: What port does a Terraria server use?**
A: **TCP 7777** by default. Open it in your OS firewall *and* your VPS provider's cloud firewall. (Note: it's TCP — unlike some games that use UDP.)

**Q: Docker or native — which is better?**
A: **Docker.** It's what the official tModLoader docs recommend, it isolates the server, and it makes mods and RAM limits trivial. Use native only if you can't run Docker.

**Q: How much RAM does a tModLoader server need?**
A: A small world with light mods idles around ~1 GB. Budget **2–3 GB** for a moderate modlist, and **4–6 GB** for Calamity-scale modpacks with several players.

**Q: How do I add the Calamity mod?**
A: Put Calamity's Steam Workshop ID (plus any add-ons) in `TMOD_AUTODOWNLOAD`/`TMOD_ENABLEDMODS`, raise `mem_limit`, and `docker compose up -d`. Every player must also enable Calamity.

**Q: Can players on vanilla Terraria join a tModLoader server?**
A: No. A modded (tModLoader) server needs tModLoader clients. For a no-mods server, run the vanilla Terraria dedicated server instead — same port 7777.

**Q: Can I run this on a Raspberry Pi / ARM server?**
A: No. The Terraria/tModLoader dedicated server is **x86-64 only**.

**Q: How do I move an existing single-player world to the server?**
A: Copy your `.wld` (and `.twld`) into the server's `Worlds` folder and set `TMOD_WORLDNAME` (Docker) or `worldname` (native) to match the file name.

**Q: The server starts but nobody can join — what do I check first?**
A: In order: (1) cloud firewall in your VPS dashboard, (2) `sudo ufw status` for `7777/tcp`, (3) correct public IP, (4) players on tModLoader with the same mods, (5) server logs for `Server started`.

**Q: Which VPS provider should I use?**
A: **Hetzner** and **Vultr** offer great price/performance; **Hostinger** is budget-friendly; **Oracle Cloud** has a free tier (x86 shape). Pick the datacenter closest to your players for the lowest ping.

**Q: How do I make the server restart automatically after a reboot or crash?**
A: Docker: `restart: unless-stopped` (already set). Native: the provided **systemd** unit with `Restart=on-failure` and `systemctl enable`.

---

## Recommended quality-of-life mods

A tested, lightweight pack that improves multiplayer without changing game balance. These are the IDs in the example `docker-compose.yml`:

| Mod | Steam Workshop ID | What it does |
|---|---|---|
| Recipe Browser | `2619954303` | Browse/search every crafting recipe |
| Magic Storage | `2563309347` | One unified storage network |
| Boss Checklist | `2669644269` | Boss order + drop checklist |
| Census – Town NPC Checklist | `2687866031` | What each town NPC needs to move in |
| AlchemistNPC Lite | `2599842771` | An NPC that sells potions & ingredients |
| Ore Excavator | `2565639705` | Vein-mining (mine a whole ore vein at once) |

Want content mods instead? Add **Calamity**, **Thorium**, **Spirit**, etc. by their Workshop IDs — just remember to raise `mem_limit` and have every player enable them.

---

## Acknowledgements

- [tModLoader](https://github.com/tModLoader/tModLoader) and its [Dedicated Server documentation](https://docs.tmodloader.net/docs/stable/md__github_workspace_src_t_mod_loader__terraria_release_extras__dedicated_server_utils__r_e_a_d_m_e.html)
- [JACOBSMILE/tmodloader1.4](https://github.com/JACOBSMILE/tmodloader1.4) — the Docker image used here
- [Terraria Wiki — Server](https://terraria.wiki.gg/wiki/Server) and [Re-Logic](https://www.terraria.org/) for the game
- Everyone who opens issues and contributes improvements ❤️

---

## 💖 Support this project

If this guide saved you time, consider giving the repo a ⭐ — it helps others find it!

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.com/donate?hosted_button_id=23PAVC8AMJGYW)

---

## Contact & Contributing

Found a bug in the guide or have a tip to add?
👉 **[Open an issue](https://github.com/Bobagi/Terraria-tModLoader-Ubuntu-Server/issues/new/choose)** — all feedback is welcome.

Pull requests are also welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

This project is open-source under the [MIT License](LICENSE).
