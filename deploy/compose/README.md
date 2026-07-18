# deploy/compose/

Infrastructure locale (**FT-2**) — edge + état. Observabilité (profil `obs`) = **FT-3** ; services applicatifs = **FT-4/5**.

## Services

| Service | Réseau | Santé |
|---|---|---|
| Traefik 3 (reverse-proxy, `:80`) | edge | `traefik healthcheck` |
| Keycloak 26 (OIDC) | edge, backend | `/health/ready` (mgmt `:9000`) |
| PostgreSQL 16 (base-per-service) | backend | `pg_isready` |
| RabbitMQ 3.13 (+ management) | backend | `rabbitmq-diagnostics ping` |
| Redis 7 | backend | `redis-cli ping` |
| MinIO (S3) | backend | `/minio/health/live` (via `smoke.sh`) |

> **Routage Traefik** : Traefik tourne en edge (sain), mais le **provider Docker + le routage** des services (Keycloak, gateway) sont câblés en **FT-E1/FT-4**, via un **`docker-socket-proxy`** — on ne monte jamais le socket Docker brut dans Traefik (sécurité, DAT §12).

## Fichiers
- `docker-compose.yml` — les 6 services (cœur), réseaux `edge`/`backend`/`observability`.
- `docker-compose.override.dev.yml` — ports exposés sur l'hôte (debug local uniquement).
- `docker-compose.smoke.yml` — conteneur curl éphémère (profil `smoke`) pour les sondes.
- `config/postgres/init-databases.sh` — crée `keycloak` + `projects`/`issues`/`agile`/`notifications` (ADR-004).
- `config/keycloak/health.sh` — healthcheck Keycloak sans curl (bash `/dev/tcp`).

## Utilisation
```bash
cp .env.example .env      # à la racine, puis renseigner
task up                   # démarre la pile (+ ports de debug)
task smoke                # vérifie que tout est healthy (DoD FT-2)
task down                 # arrête
```

Accès dev : Keycloak `http://localhost:8081` · dashboard Traefik `http://localhost:8080` · console MinIO `http://localhost:9001` · RabbitMQ `http://localhost:15672`.
