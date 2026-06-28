#!/bin/sh
# box.hopbox.dev/install.sh — thin bootstrap for the boxd server.
#
# The canonical boxd installer lives in the hopbox repo and is the single
# source of truth; this just fetches and runs it so the two can never drift.
#
#   curl -fsSL https://box.hopbox.dev/install.sh | sudo sh
#
# Overrides pass straight through to the underlying installer.
exec sh -c "$(curl -fsSL https://raw.githubusercontent.com/hopboxdev/hopbox/main/deploy/install-boxd.sh)"
