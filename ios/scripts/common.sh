#!/bin/sh

set -eu

SCRIPTS_DIRECTORY="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PROJECT_DIRECTORY="$(CDPATH= cd -- "$SCRIPTS_DIRECTORY/.." && pwd)"

export SCRIPTS_DIRECTORY PROJECT_DIRECTORY
