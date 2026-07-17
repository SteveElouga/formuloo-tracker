# deploy/

Descripteurs de déploiement.

- `compose/` — Docker Compose (infra + services). **FT-2** : Traefik, Keycloak, PostgreSQL, RabbitMQ, Redis, MinIO ; profils `app` et `obs` (observabilité, **FT-3**).
- `helm/` — charts Kubernetes/k3s (**phase 2**).

Les données locales (`**/data/`, `**/volumes/`) sont git-ignorées.
