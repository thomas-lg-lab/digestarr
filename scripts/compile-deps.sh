#!/bin/sh
# Regenerate requirements.txt and requirements-dev.txt from pyproject.toml.
#
# Dependency constraints live in pyproject.toml ([project] dependencies and the "dev"
# extra). Run this after changing them and commit both lockfiles.
#
# Renovate recompiles the locks on its own PRs with its pip-compile manager: it reads
# the command back from each lockfile header. `python -m piptools` makes sure the
# pip-tools pinned in requirements-dev.txt is the one used here, whatever `pip-compile`
# is first on PATH.

set -e

export LC_ALL=C
export LANG=C

cd "$(dirname "$0")/.."

echo "📦 Compiling requirements.txt..."
python -m piptools compile pyproject.toml \
    --output-file requirements.txt \
    --strip-extras \
    --quiet

echo "📦 Compiling requirements-dev.txt..."
python -m piptools compile pyproject.toml \
    --extra dev \
    --output-file requirements-dev.txt \
    --strip-extras \
    --quiet

echo "✅ Lockfiles updated. Remember to commit requirements.txt and requirements-dev.txt."
