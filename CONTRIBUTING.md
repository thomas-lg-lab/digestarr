# Contributing to Digestarr

Thank you for contributing to Digestarr.

## Table of Contents

- [Contributing to Digestarr](#contributing-to-digestarr)
  - [Table of Contents](#table-of-contents)
  - [Branching Strategy](#branching-strategy)
  - [Getting Started](#getting-started)
  - [Development Setup](#development-setup)
    - [Prerequisites](#prerequisites)
    - [Canonical Workflow (Devcontainer)](#canonical-workflow-devcontainer)
    - [Optional Host Workflow](#optional-host-workflow)
  - [Code Style](#code-style)
  - [Testing](#testing)
  - [Pull Request Process](#pull-request-process)
  - [Production Image and Deployment](#production-image-and-deployment)

## Branching Strategy

This repository is trunk-based: `main` is the only long-lived branch, and merging is not releasing.

```text
feature/* ──► main ──(publish a release, tag vX.Y.Z)──► latest image
```

| Branch / tag | Purpose | Docker image |
| --- | --- | --- |
| `feature/*`, `fix/*`, … | Short-lived work, one squash PR into `main` | — |
| `main` | Integration, always releasable | `edge` |
| `vX.Y.Z` tag | A release: publish the draft release on GitHub | `latest`, `X.Y.Z`, `X.Y`, `X` |

**Releasing**: release-drafter keeps a draft release up to date from merged PR labels and computes the version; confirm or adjust it and publish the draft (on GitHub, or Actions → Release Drafter → Run workflow). That tag is what moves `latest`.

**Renovate** PRs target `main`. Patch and minor updates merge on their own once the checks pass, which only moves `edge`; majors wait for a review.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a `feature/*` branch from `main`
4. Make your changes and open a pull request targeting `main`

## Development Setup

### Prerequisites

- Docker
- VS Code + Dev Containers extension
- Git

### Canonical Workflow (Devcontainer)

Open the project in the devcontainer:

```text
Command Palette → Dev Containers: Reopen in Container
```

Dependencies are installed in the devcontainer image (built from [.devcontainer/Dockerfile.dev](.devcontainer/Dockerfile.dev)), so the environment is ready to use as soon as the container starts.

If Dev Containers is not available, [docker-compose.dev.yml](docker-compose.dev.yml) uses the same image and provides an equivalent environment:

```bash
docker compose -f docker-compose.dev.yml up -d --build
docker compose -f docker-compose.dev.yml exec app bash
# or using the helper script:
./scripts/dev-container-shell.sh
```

Inside the devcontainer, run checks with either direct commands or helper scripts:

```bash
./scripts/format.sh
./scripts/typecheck.sh
./scripts/test.sh
```

Equivalent direct commands:

```bash
black src tests
ruff check --fix src tests
PYTHONPATH=src mypy src
PYTHONPATH=src pytest --cov=src --cov-branch --cov-report=xml --cov-report=term-missing --cov-report=html
```

### Optional Host Workflow

Host-native development is optional and not the primary workflow. If you use it, mirror the same Python/tool versions as the devcontainer.

Install all dependencies:

```bash
pip install -r requirements-dev.txt
```

Copy the example environment file and fill in your values:

```bash
cp .env.example .env
# Edit .env with your Tautulli URL and API key
```

Use the same app start command as devcontainer:

```bash
./scripts/start.sh
```

## Code Style

- Python 3.14
- Black for formatting
- Ruff for linting
- mypy for type checking
- Type hints for public functions/methods

## Testing

Run all tests:

```bash
./scripts/test.sh
```

From a host checkout the script runs the suite inside the `digestarr-devcontainer` image when Docker is available (same Linux image and Python as CI), and falls back to the local interpreter otherwise. Set `DIGESTARR_TEST_RUNNER=docker` or `local` to force one.

Run a subset:

```bash
./scripts/test.sh tests/test_config.py
./scripts/test.sh -k "test_config"
```

## Pull Request Process

Before submitting:

1. Run formatting/lint checks

   ```bash
   ./scripts/format.sh --check src tests
   ```

2. Run type checks

   ```bash
   ./scripts/typecheck.sh
   ```

3. Run tests

   ```bash
   ./scripts/test.sh
   ```

4. If you changed the dependencies in `pyproject.toml`, regenerate the lockfiles and commit them:

   ```bash
   ./scripts/compile-deps.sh
   ```

5. Update docs when behavior/configuration changes

PR expectations:

- Keep PRs focused
- Fill the PR template (the organisation's default): why, what changes, how it was tested; `Closes #N` when it resolves an issue
- **Use a Conventional Commit PR title**: `<type>[optional scope][optional !]: <description>`, with a type among `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test` (commitlint's config-conventional) and `!` for a breaking change. The required `conventions / title` check blocks any other title. The PR's label, and so its release-notes category and the version bump, comes from the type: `feat` → `feature`, `perf` → `enhancement`, `fix`/`revert` → `fix`, `docs` → `documentation`, the others → `chore`, `(deps)` scope → `dependencies`, `!` → `breaking`.

- Ensure CI passes

## Production Image and Deployment

CI/CD and release management use the organisation's shared workflows (`thomas-lg-lab/.github`):

- Production build definition: `Dockerfile`
- CI/CD pipeline: `.github/workflows/ci.yml` (quality checks, tests, then the shared image build, scan and push)
- Release drafter: `.github/workflows/release-drafter.yml` (draft release notes on push to `main`; publish via `workflow_dispatch`)
- Deployment example: `docker-compose.yml`

The pipeline gates Docker image publishing on passing quality and test checks. Images are published to `ghcr.io/thomas-lg-lab/digestarr` with the following tags:

| Tag | When |
| --- | --- |
| `edge` | Push to `main` |
| `latest` | Published release (`v*` tag) |
| `X.Y.Z`, `X.Y`, `X` | Version tag (`v*`) |
| `sha-<shortsha>` | Push to `main` (traceability; short commit SHA) |

Contributors should not use production compose files as the day-to-day development environment.
