"""Réglages Django minimaux (12 facteurs — config par variables d'environnement). FT-1."""
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent


def _bool(name: str, default: str = "0") -> bool:
    return os.environ.get(name, default).lower() not in ("0", "", "false", "no")


SECRET_KEY = os.environ.get("GATEWAY_SECRET_KEY", "dev-insecure-change-me")
DEBUG = _bool("GATEWAY_DEBUG", "0")
ALLOWED_HOSTS = [h for h in os.environ.get(
    "GATEWAY_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",") if h]

INSTALLED_APPS: list[str] = []
MIDDLEWARE = ["django.middleware.common.CommonMiddleware"]
ROOT_URLCONF = "gateway.urls"

DATABASES = {
    "default": {"ENGINE": "django.db.backends.sqlite3", "NAME": ":memory:"},
}

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
LANGUAGE_CODE = "fr-fr"
USE_TZ = True
