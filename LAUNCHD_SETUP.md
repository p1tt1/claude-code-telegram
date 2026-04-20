# macOS launchd Service Setup

Runs the Claude Code Telegram Bot as a persistent LaunchAgent — starts on login,
auto-restarts on crash, stops cleanly on `make service-stop`.

> **Linux users:** See `SYSTEMD_SETUP.md`.

## Quick Setup

### 1. Install dependencies

```bash
make dev
```

### 2. Install and start the service

```bash
make service-install
```

This renders `config/launchd.plist.template` with your paths, writes it to
`~/Library/LaunchAgents/com.p1tt1.claude-telegram-bot.plist`, and loads it.

### 3. Verify it's running

```bash
make service-status
# com.p1tt1.claude-telegram-bot   0   12345

make service-logs
# (live tail of stdout + stderr)
```

A PID in `service-status` output means the bot is running.

## Common Commands

```bash
make service-start     # start
make service-stop      # stop (no auto-restart until next login or start)
make service-restart   # stop + start
make service-status    # check PID
make service-logs      # tail logs live
make service-uninstall # remove from LaunchAgents entirely
```

## Log Files

```
~/Library/Logs/claude-telegram-bot.log        # stdout
~/Library/Logs/claude-telegram-bot.error.log  # stderr
```

## Updating the Bot

After pulling new code:

```bash
git pull
make service-restart
```

## Uninstall

```bash
make service-uninstall
```
