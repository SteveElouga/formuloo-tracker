#!/usr/bin/env bash
# FT-2 — vérifie que la pile infra est saine (DoD : healthchecks = tests).
# Compatible bash 3.2 (macOS) : pas d'expansion de tableau vide sous set -u.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
cd "$here/../deploy/compose"
DC=(docker compose --env-file ../../.env -f docker-compose.yml -f docker-compose.smoke.yml)

native=(traefik postgres keycloak rabbitmq redis)
echo "→ Attente 'healthy' : ${native[*]}"
deadline=$(( $(date +%s) + 240 ))
while :; do
  ok=1
  for s in "${native[@]}"; do
    cid="$("${DC[@]}" ps -q "$s" 2>/dev/null || true)"
    if [ -z "$cid" ]; then ok=0; break; fi
    st="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$cid" 2>/dev/null || echo missing)"
    [ "$st" = "healthy" ] || { ok=0; break; }
  done
  [ "$ok" = 1 ] && break
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "✖ Timeout : conteneurs non 'healthy'."; "${DC[@]}" ps; exit 1
  fi
  sleep 5
done
echo "✓ Conteneurs healthy."

echo "→ Sonde des endpoints (conteneur curl sur les réseaux internes)…"
fail=0
probe() { # libellé  url  [host-header]
  local label="$1" url="$2" host="${3:-}"
  local args=(-s -o /dev/null -w '%{http_code}' --max-time 10)
  if [ -n "$host" ]; then args+=(-H "Host: $host"); fi
  args+=("$url")
  local code
  code="$("${DC[@]}" run --rm --no-deps -T --entrypoint curl smoke "${args[@]}" 2>/dev/null || true)"
  if [ "$code" = "200" ]; then echo "  ✓ $label ($code)"; else echo "  ✖ $label (code=$code) — $url"; fail=1; fi
}

probe "MinIO /health/live"     "http://minio:9000/minio/health/live"
probe "Keycloak /health/ready" "http://keycloak:9000/health/ready"
probe "RabbitMQ management"     "http://rabbitmq:15672/"

if [ "$fail" = 0 ]; then echo "✓ Smoke FT-2 OK — pile infra saine."; else echo "✖ Smoke FT-2 : endpoint(s) KO."; exit 1; fi
