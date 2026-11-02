"""Application version resolution, shared by the startup banner and the health endpoint."""

import importlib.metadata
import os

UNKNOWN_VERSION = "unknown"


def get_app_version() -> str:
    """
    Return the running application's version.

    Resolution order:
      1. ``APP_VERSION`` environment variable: the Docker image always sets it from its
         ``VERSION`` build argument (the image tag in CI, ``unknown`` for a local build)
      2. installed package metadata, which only exists after ``pip install -e .``:
         setuptools-scm derives it from git tags, or reports ``0.0.0`` without any
         (``fallback_version`` in ``pyproject.toml``)
      3. ``"unknown"`` when neither is available: a bare ``src/`` checkout, including
         the devcontainer, which installs the requirements but not the package
    """
    env_version = os.getenv("APP_VERSION")
    if env_version:
        return env_version
    try:
        return importlib.metadata.version("digestarr")
    except importlib.metadata.PackageNotFoundError:
        return UNKNOWN_VERSION
