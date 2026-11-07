#!/bin/sh
# Run the test suite the way CI does: inside the devcontainer image.
#
# Resolution order (override with DIGESTARR_TEST_RUNNER=docker|local):
#   1. Already inside a container (the devcontainer shell): run pytest directly.
#   2. Docker available: run pytest in the `digestarr-devcontainer` image.
#      The image is (re)built from .devcontainer/Dockerfile.dev on every run, as
#      in CI; with the layer cache that takes a couple of seconds when nothing
#      changed and picks up lockfile or Dockerfile changes automatically.
#      This is the only runner that matches CI (Linux, Python from .python-version).
#   3. Otherwise: fall back to the local interpreter (`PYTHONPATH=src pytest`).
#
# Any arguments are passed to pytest, e.g. ./scripts/test.sh tests/test_config.py -k secrets

set -e

cd "$(dirname "$0")/.."

IMAGE="digestarr-devcontainer"
RUNNER="${DIGESTARR_TEST_RUNNER:-}"

in_container() {
	[ -f /.dockerenv ] || [ -n "${REMOTE_CONTAINERS:-}" ] || [ -n "${CODESPACES:-}" ]
}

docker_available() {
	command -v docker > /dev/null 2>&1 && docker info > /dev/null 2>&1
}

if [ -z "$RUNNER" ]; then
	if in_container; then
		RUNNER="local"
	elif docker_available; then
		RUNNER="docker"
	else
		RUNNER="local"
	fi
fi

case "$RUNNER" in
	docker)
		if ! docker_available; then
			echo "❌ DIGESTARR_TEST_RUNNER=docker but Docker is not available."
			exit 1
		fi
		# Always build: the layer cache makes this a no-op in a couple of seconds
		# and a stale image (lockfile bump, Dockerfile change) is rebuilt as in CI.
		echo "🐳 Building $IMAGE from .devcontainer/Dockerfile.dev (cached)..."
		docker build -q -f .devcontainer/Dockerfile.dev -t "$IMAGE" . > /dev/null
		echo ""

		# Git Bash on Windows rewrites POSIX-looking arguments such as /app into
		# Windows paths; `pwd -W` yields a drive path Docker Desktop understands.
		HOST_DIR="$(pwd -W 2>/dev/null || pwd)"
		export MSYS_NO_PATHCONV=1

		# On Linux hosts, run as the invoking user so coverage files are not root-owned.
		USER_FLAG=""
		case "$(uname -s 2>/dev/null)" in
			MINGW* | MSYS* | CYGWIN*) ;;
			*) USER_FLAG="--user $(id -u):$(id -g)" ;;
		esac

		echo "🧪 Running tests in Docker ($IMAGE)..."
		echo ""
		# shellcheck disable=SC2086
		docker run --rm $USER_FLAG -v "$HOST_DIR:/app" -w /app -e PYTHONPATH=src "$IMAGE" pytest "$@"
		;;
	local)
		if ! in_container && ! docker_available; then
			echo "⚠️  Docker not available: running with the local interpreter ($(python --version 2>&1))."
			echo "    CI runs on Linux with the version in .python-version; results may differ."
			echo ""
		fi
		echo "🧪 Running tests..."
		echo ""
		PYTHONPATH=src pytest "$@"
		;;
	*)
		echo "❌ Unknown DIGESTARR_TEST_RUNNER='$RUNNER' (expected docker or local)."
		exit 1
		;;
esac

echo ""
echo "✅ Tests complete!"
echo ""
echo "📊 Coverage report generated in htmlcov/"
echo "   To view: open htmlcov/index.html"
