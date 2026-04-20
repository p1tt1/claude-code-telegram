.PHONY: install dev test lint format clean help run run-watch run-remote remote-attach remote-stop \
       bump-patch bump-minor bump-major release version \
       service-install service-uninstall service-start service-stop service-restart service-status service-logs

LAUNCHD_LABEL = com.p1tt1.claude-telegram-bot
LAUNCHD_PLIST = $(HOME)/Library/LaunchAgents/$(LAUNCHD_LABEL).plist
PROJECT_DIR   = $(shell pwd)

# Default target
help:
	@echo "Available commands:"
	@echo "  install       - Install production dependencies"
	@echo "  dev           - Install development dependencies"
	@echo "  test          - Run tests"
	@echo "  lint          - Run linting checks"
	@echo "  format        - Format code"
	@echo "  clean         - Clean up generated files"
	@echo "  run           - Run the bot"
	@echo "  run-watch     - Run the bot with auto-restart on code changes"
	@echo "  version       - Show current version"
	@echo "  bump-patch    - Bump patch version (1.2.0 -> 1.2.1), commit, and tag"
	@echo "  bump-minor    - Bump minor version (1.2.0 -> 1.3.0), commit, and tag"
	@echo "  bump-major    - Bump major version (1.2.0 -> 2.0.0), commit, and tag"
	@echo "  release       - Push current version tag to trigger release workflow"
	@echo "  run-remote    - Start bot in tmux on remote Mac (unlocks keychain)"
	@echo "  remote-attach - Attach to running bot tmux session"
	@echo "  remote-stop   - Stop the bot tmux session"
	@echo "  service-install   - Install launchd service (start on login + auto-restart)"
	@echo "  service-uninstall - Remove launchd service"
	@echo "  service-start     - Start the service"
	@echo "  service-stop      - Stop the service"
	@echo "  service-restart   - Restart the service"
	@echo "  service-status    - Show service status"
	@echo "  service-logs      - Tail live logs"

install:
	poetry install --no-dev

dev:
	poetry install
	poetry run pre-commit install --install-hooks || echo "pre-commit not configured yet"

test:
	poetry run pytest

lint:
	poetry run black --check src tests
	poetry run isort --check-only src tests
	poetry run flake8 src tests
	poetry run mypy src

format:
	poetry run black src tests
	poetry run isort src tests

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	rm -rf .coverage htmlcov/ .pytest_cache/ dist/ build/

run:
	poetry run claude-telegram-bot

run-watch:  ## Run the bot with auto-restart on src/ changes (uses watchfiles)
	poetry run watchfiles "claude-telegram-bot" src/

# For debugging
run-debug:
	poetry run claude-telegram-bot --debug

# Remote Mac Mini (SSH session)
run-remote:  ## Start bot on remote Mac in tmux (persists after SSH disconnect)
	security unlock-keychain ~/Library/Keychains/login.keychain-db
	tmux new-session -d -s claude-bot 'poetry run claude-telegram-bot'
	@echo "Bot started in tmux session 'claude-bot'"
	@echo "  Attach: make remote-attach"
	@echo "  Stop:   make remote-stop"

remote-attach:  ## Attach to running bot tmux session
	tmux attach -t claude-bot

remote-stop:  ## Stop the bot tmux session
	tmux kill-session -t claude-bot

# --- launchd Service (macOS) ---

service-install:  ## Install and load the launchd service (starts on login)
	@sed \
		-e 's|{{PROJECT_DIR}}|$(PROJECT_DIR)|g' \
		-e 's|{{HOME}}|$(HOME)|g' \
		config/launchd.plist.template > $(LAUNCHD_PLIST)
	launchctl load $(LAUNCHD_PLIST)
	@echo "Service installed and started."
	@echo "  Logs:   make service-logs"
	@echo "  Status: make service-status"

service-uninstall:  ## Unload and remove the launchd service
	-launchctl unload $(LAUNCHD_PLIST)
	-rm -f $(LAUNCHD_PLIST)
	@echo "Service removed."

service-start:  ## Start the launchd service
	launchctl start $(LAUNCHD_LABEL)

service-stop:  ## Stop the launchd service (won't auto-restart)
	launchctl stop $(LAUNCHD_LABEL)

service-restart:  ## Restart the launchd service
	launchctl stop $(LAUNCHD_LABEL)
	sleep 2
	launchctl start $(LAUNCHD_LABEL)

service-status:  ## Show launchd service status
	launchctl list | grep $(LAUNCHD_LABEL) || echo "Service not loaded"

service-logs:  ## Tail bot logs (stdout + stderr interleaved)
	tail -f $(HOME)/Library/Logs/claude-telegram-bot.log $(HOME)/Library/Logs/claude-telegram-bot.error.log

# --- Version Management ---

version:  ## Show current version
	@poetry version -s

bump-patch:  ## Bump patch version, commit, and tag
	poetry version patch && \
	NEW_VERSION=$$(poetry version -s) && \
	git add pyproject.toml && \
	git commit -m "release: v$$NEW_VERSION" && \
	git tag "v$$NEW_VERSION" && \
	git push && git push origin "v$$NEW_VERSION" && \
	echo "Released v$$NEW_VERSION. Tag pushed — release workflow will run on GitHub."

bump-minor:  ## Bump minor version, commit, and tag
	poetry version minor && \
	NEW_VERSION=$$(poetry version -s) && \
	git add pyproject.toml && \
	git commit -m "release: v$$NEW_VERSION" && \
	git tag "v$$NEW_VERSION" && \
	git push && git push origin "v$$NEW_VERSION" && \
	echo "Released v$$NEW_VERSION. Tag pushed — release workflow will run on GitHub."

bump-major:  ## Bump major version, commit, and tag
	poetry version major && \
	NEW_VERSION=$$(poetry version -s) && \
	git add pyproject.toml && \
	git commit -m "release: v$$NEW_VERSION" && \
	git tag "v$$NEW_VERSION" && \
	git push && git push origin "v$$NEW_VERSION" && \
	echo "Released v$$NEW_VERSION. Tag pushed — release workflow will run on GitHub."

release:  ## Push the current version tag to trigger the release workflow
	CURRENT_VERSION=$$(poetry version -s) && \
	git push && git push origin "v$$CURRENT_VERSION" && \
	echo "Pushed v$$CURRENT_VERSION. Release workflow will run on GitHub."
