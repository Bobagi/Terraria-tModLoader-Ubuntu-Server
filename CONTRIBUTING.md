# Contributing to the Terraria + tModLoader Ubuntu Server Guide

Thank you for your interest in contributing! Every improvement helps another player host their own modded Terraria server.

## How to contribute

### Report an issue or outdated step

If a command doesn't work on a newer Ubuntu / tModLoader version, or if something is unclear:

1. [Open an issue](https://github.com/Bobagi/Terraria-tModLoader-Ubuntu-Server/issues/new/choose)
2. Say which **method** (Docker or Native) and which step
3. Include the OS version and the error message (for startup crashes, `tModLoader-Logs/Natives.log` is gold)

### Submit a pull request

1. Fork the repository
2. Create a branch: `git checkout -b fix/describe-your-change`
3. Make your changes — keep the tone practical and copy-paste friendly
4. Open a pull request with a clear description of what was changed and why

### Good contributions to make

- Fixing outdated commands (new Ubuntu LTS, new tModLoader release, new base image)
- Updating the `libicu` package version when the base image's Ubuntu changes
- Adding troubleshooting for a real error you hit
- Improving the Portuguese or English wording
- Adding a popular verified mod list (with Steam Workshop IDs)
- Improving the systemd unit or the Docker compose

### Style guidelines

- Write commands as exact copy-paste snippets inside fenced code blocks
- Explain the *why* when it's not obvious (e.g. why `libicu` is needed, why `tty: true`)
- Keep the FAQ honest — don't add questions nobody asks
- If you add a new section, add it to the Table of Contents too
- Keep `README.md` (English) and `README.pt-BR.md` (Portuguese) in sync

## Questions?

Open an issue — that's the fastest way to reach me.
