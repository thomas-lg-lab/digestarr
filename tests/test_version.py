"""Unit tests for application version resolution."""

import importlib.metadata

import pytest

from src.version import UNKNOWN_VERSION, get_app_version


class TestGetAppVersion:
    """Tests for get_app_version()."""

    @pytest.mark.unit
    def test_env_var_wins_over_package_metadata(self, monkeypatch):
        """APP_VERSION (set by the Docker image) takes precedence."""
        monkeypatch.setenv("APP_VERSION", "9.9.9")
        monkeypatch.setattr("importlib.metadata.version", lambda _pkg: "1.2.3")
        assert get_app_version() == "9.9.9"

    @pytest.mark.unit
    def test_empty_env_var_falls_back_to_package_metadata(self, monkeypatch):
        """An empty APP_VERSION is treated as unset."""
        monkeypatch.setenv("APP_VERSION", "")
        monkeypatch.setattr("importlib.metadata.version", lambda _pkg: "1.2.3")
        assert get_app_version() == "1.2.3"

    @pytest.mark.unit
    def test_unknown_when_package_not_installed(self, monkeypatch):
        """A bare src/ checkout without metadata reports 'unknown'."""
        monkeypatch.delenv("APP_VERSION", raising=False)

        def _raise_not_found(_pkg: str) -> str:
            raise importlib.metadata.PackageNotFoundError("digestarr")

        monkeypatch.setattr("importlib.metadata.version", _raise_not_found)
        assert get_app_version() == UNKNOWN_VERSION
