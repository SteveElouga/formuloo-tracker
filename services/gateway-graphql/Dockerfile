# syntax=docker/dockerfile:1
# Gateway GraphQL — image multi-stage, non-root (12 facteurs — DAT ADR-008). FT-1.
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder
WORKDIR /app
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
COPY pyproject.toml ./
RUN uv sync --no-dev
COPY src ./src

FROM python:3.12-slim-bookworm AS runtime
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app/src \
    PATH="/app/.venv/bin:$PATH"
RUN groupadd -r app && useradd -r -g app app
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/src /app/src
USER app
EXPOSE 8000
# FT-4 branchera l'ASGI GraphQL ; ici WSGI + /sante/ prouvent l'image.
CMD ["gunicorn", "gateway.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "2"]
