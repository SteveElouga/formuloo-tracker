#!/usr/bin/env python
"""Utilitaire de gestion Django (gateway-graphql)."""
import os
import sys
from pathlib import Path


def main() -> None:
    sys.path.insert(0, str(Path(__file__).resolve().parent / "src"))
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "gateway.settings")
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:  # pragma: no cover
        raise ImportError("Django introuvable — lancez `uv sync`.") from exc
    execute_from_command_line(sys.argv)


if __name__ == "__main__":
    main()
