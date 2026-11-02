"""Application version resolution, shared by the startup banner and the health endpoint."""

import importlib.metadata
import os

UNKNOWN_VERSION = "unknown"


def get_app_version() -> str:
    """
    Return the running application's version.

    Resolution order:
      1. ``APP_VERSION`` environment variable (set by the Docker image from the build tag)
      2. installed package metadata (editable installs and the devcontainer)
      3. ``"unknown"`` when neither is available (bare ``src/`` checkout)
    """
    env_version = os.getenv("APP_VERSION")
    if env_version:
        return env_version
    try:
        return importlib.metadata.version("digestarr")
    except importlib.metadata.PackageNotFoundError:
        return UNKNOWN_VERSION
