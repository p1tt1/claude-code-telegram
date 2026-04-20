#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
exec poetry run claude-telegram-bot
