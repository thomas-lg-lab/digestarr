# Copilot Instructions

## Project Overview

**digestarr** is a lightweight Docker container that fetches recently added media from Plex via the Tautulli API and posts rich Discord embeds summarising new movies, TV shows, episodes, and music. It runs either on a schedule (APScheduler) or as a one-shot (`RUN_ONCE=true`).

## Tech Stack

- **Python 3.14** — minimum required version
- **Pydantic v2** — config validation (`src/config.py`)
- **APScheduler** — scheduled execution (`src/scheduler.py`)
- **discord-webhook** — Discord embed posting (`src/discord_client.py`)
- **requests** — HTTP client for the media sources (`src/tautulli_client.py`, `src/tracearr_client.py`)
- **Black** — formatter (line length 120)
- **Ruff** — linter (see `pyproject.toml` for enabled rule sets)
- **mypy** — type checker (strict optional, `check_untyped_defs`)
- **pytest + pytest-cov** — test runner with branch coverage

## Source Layout

```
src/
  app.py               # Entry point, wires scheduler/run-once
  config.py            # Pydantic config model, loaded from config.yml
  media_source.py      # Backend-neutral contract every source implements
  tautulli_client.py   # Fetches recently added media from Tautulli
  tracearr_client.py   # Same, from Tracearr: regroups and enriches its raw feed
  discord_client.py    # Builds and sends Discord embeds
  scheduler.py         # APScheduler wrapper
  health_server.py     # Optional GET /health endpoint (scheduled mode only)
  logging_config.py    # Logging setup
  version.py           # Version resolution (APP_VERSION, package metadata, "unknown")
tests/
  test_*.py            # Unit tests (pytest markers: unit, integration)
```

## Branching Strategy

```
feature/* ──► main ──(published release, tag vX.Y.Z)──► latest
```

- Trunk-based: short-lived branches, one squash PR into `main`; `main` builds the `edge` image
- Only a published release (a `v*` tag) builds `latest`
- Renovate PRs target `main`

## Code Style

- Format with Black (`./scripts/format.sh`)
- Lint with Ruff (`ruff check --fix`)
- Type-check with mypy (`./scripts/typecheck.sh`)
- Add type hints to all public functions and methods
- Use `%`-style logging (not f-strings) in log calls — enforced by Ruff rule `G`
- Never use bare `assert` outside tests; raise explicit exceptions instead

## Testing

- Run all tests: `./scripts/test.sh` (pass pytest arguments through, e.g. `./scripts/test.sh tests/test_config.py -k secrets`)
- `scripts/test.sh` mirrors CI: when Docker is available it runs pytest inside the `digestarr-devcontainer` image (rebuilt from `.devcontainer/Dockerfile.dev` on every run, cached, so lockfile changes are picked up; Linux + the Python of `.python-version`); inside the devcontainer, or without Docker, it falls back to the local interpreter. Force a runner with `DIGESTARR_TEST_RUNNER=docker|local`
- Only the Docker runner is authoritative: a host interpreter may differ in Python version and platform (the project targets 3.14, see `.python-version`)
- Unit tests mock at the class level; integration tests mock only at the HTTP boundary
- Mark tests with `@pytest.mark.unit` or `@pytest.mark.integration`
- All new behaviour must be covered by tests

## Dependency / Lockfile Management

- Runtime deps: `[project] dependencies` in `pyproject.toml` → compiled to `requirements.txt`
- Dev deps: the `dev` extra in `pyproject.toml` (dev tooling only; it inherits the runtime deps) → compiled to `requirements-dev.txt`
- `pyproject.toml` is the single source of truth for constraints; the lockfiles are generated, never edited by hand
- Renovate recompiles the lockfiles on its own PRs with its pip-compile manager, which replays the command in each lockfile header; it does not run `scripts/compile-deps.sh`, so keep the script's options and those headers in step
- After changing dependencies in `pyproject.toml`, regenerate and commit the lockfiles:
  ```bash
  ./scripts/compile-deps.sh
  ```
- Docker and the devcontainer install from the lockfiles, not the loose requirements

## Pull Requests

When creating a pull request, always follow the structure defined in `.github/pull_request_template.md`:
- Fill in the **Summary** section with a clear description of what the PR does and why
- Complete the **Checklist** items that apply
- Fill in the **Related issues** section if applicable

PR titles must follow [Conventional Commits](https://www.conventionalcommits.org/) (e.g. `feat: add X`, `fix: correct Y`, `chore: update Z`).

Valid types are the **keys** from `.github/conventional-commit-types.json` (not the label values):
`feat`, `improve`, `perf`, `fix`, `bugfix`, `hotfix`, `revert`, `breaking`, `security`, `docs`, `refactor`, `style`, `cleanup`, `chore`, `test`, `build`, `ci`, `actions`, `deps`, `deprecate`, `release`, `wip`

> ⚠️ The JSON values are GitHub label names — they are **not** valid commit types and must never be used as PR title prefixes. The following are label names only and have no valid use as a prefix:
> - `feature` → use `feat`
> - `enhancement` → use `improve` or `perf`
> - `documentation` → use `docs`
> - `github-actions` → use `ci` or `actions`
> - `dependencies` → use `deps`
> - `deprecated` → use `deprecate`

Append `!` before the colon to denote a breaking change (e.g. `feat!: redesign config schema`).
