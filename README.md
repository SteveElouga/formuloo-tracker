# Formuloo Tracker

**L'outil agile interne de Formuloo : boards, sprints, rapports et permissions — utilisateurs illimités, données maîtrisées, 0 licence.**

Formuloo Tracker est un « mini-Jira » auto-hébergé qui remplace Jira Cloud (plan Free) sans ses limitations. Application web (Angular + PrimeNG), architecture microservices (Django + gRPC), API GraphQL, 100 % open source.

> **Statut : amorçage (avant FT-1).** Le dépôt est en cours d'initialisation. Ce README décrit la cible et la mise en route prévue. Voir l'avancement dans `CONTEXT.md` §4.

---

## Sommaire
- [Aperçu](#aperçu)
- [Stack technique](#stack-technique)
- [Structure du monorepo](#structure-du-monorepo)
- [Prérequis](#prérequis)
- [Démarrage rapide](#démarrage-rapide)
- [Workflow de développement](#workflow-de-développement)
- [Tests](#tests)
- [Observabilité](#observabilité)
- [Documentation](#documentation)
- [Sécurité & secrets](#sécurité--secrets)
- [Licence & propriété](#licence--propriété)

---

## Aperçu

Le MVP couvre comptes & permissions, projets, tickets (hiérarchie, commentaires, pièces jointes, historique), workflow & board Kanban, backlog & sprints, recherche, rapports (burndown, vélocité), notifications, automatisations pré-câblées, et import CSV depuis Jira. Interface **en français**, **responsive** (desktop 1440 px / mobile 390 px), pensée pour une **connectivité instable**. Détails : `CONTEXT.md`.

## Stack technique

| Couche | Technologies |
|---|---|
| Frontend | **Angular** · **PrimeNG** (preset Aura) · Apollo Angular · Angular Signals · Transloco · Tiptap |
| Gateway | Django · **Strawberry GraphQL** (HTTP + WebSocket) |
| Services métier | Django · **gRPC** (`grpcio` + protobuf, gestion via `buf`) |
| Identité | **Keycloak** (OIDC / PKCE) |
| Données | **PostgreSQL 16** (database-per-service) · **Redis** |
| Événements / Fichiers | **RabbitMQ** · **MinIO** (S3) |
| Observabilité | OpenTelemetry · Grafana **Alloy** · **Prometheus / Loki / Tempo / Grafana** |
| Exécution | **Docker Compose** → **Kubernetes (k3s)** · Traefik |
| Outillage | **pnpm** · **uv** (Python 3.12) · **Node 20 LTS** · **Taskfile** · GitHub Actions |

## Structure du monorepo

```
formuloo-tracker/
├── protos/          # Contrats gRPC (source de vérité, versionnés, buf)
├── services/        # Services Django + gRPC
│   ├── gateway-graphql/
│   ├── svc-projects/
│   ├── svc-issues/
│   ├── svc-agile/
│   └── svc-notifications/
├── frontend/        # SPA Angular + PrimeNG
├── deploy/          # docker-compose, config (traefik, alloy, prometheus…), helm (phase 2)
├── .githooks/       # Hooks Git versionnés (pre-commit, commit-msg, pre-push)
├── scripts/         # Scripts utilitaires (install-hooks.sh, …)
└── docs/            # Analyse, SFD, DAT, backlog, maquette, MEMORY, CONTEXT
```

## Prérequis

- **Docker** + **Docker Compose**
- **Node 20 LTS** + **pnpm**
- **Python 3.12** + **uv**
- **buf** (contrats gRPC), **Taskfile** (orchestration)
- Machine ≥ **16 Go de RAM** (la pile complète ≈ 10 Go ; le profil observabilité `obs` est activable à la demande)

## Démarrage rapide

```bash
# 1. Cloner puis se placer à la racine
git clone <url-du-depot> formuloo-tracker && cd formuloo-tracker

# 1bis. Activer les hooks Git (OBLIGATOIRE — refuse les commits sur main/develop, valide les messages)
sh scripts/install-hooks.sh

# 2. Configurer l'environnement (ne jamais committer .env)
cp .env.example .env   # renseigner les variables

# 3. Lancer l'infrastructure + les services (profil applicatif)
task up                # ou: docker compose --profile app up -d

# 4. (Optionnel) Activer l'observabilité (LGTM) — consomme ~2,5 Go
task up:obs            # ou: docker compose --profile obs up -d

# 5. Frontend en développement
cd frontend && pnpm install && pnpm start
```

*(Les cibles `task …` seront fournies par le Sprint 0 — FT-1/FT-2.)*

## Workflow de développement

> **Les règles Git sont inviolables et détaillées dans [`MEMORY.md`](./MEMORY.md). Lis-le avant toute contribution.** Résumé :

1. **`main` et `develop` sont protégées** : jamais de commit ni de push direct dessus.
2. `develop` part de `main` ; **toute branche de travail part de `develop`**.
3. Une **branche dédiée par implémentation** : `feat/ft-<id>-<slug>`, `fix/…`, `chore/…`.
4. **Rebase sur `develop` à jour** avant de pousser ; ouvrir une **MR ciblant `develop`**.
5. Fusion **uniquement par MR** (CI verte + rebasé + DoD + revue). Historique **linéaire** (squash/rebase).
6. `develop` → `main` **uniquement par MR**, puis **tag SemVer** sur `main`.
7. **Commits** : [Conventional Commits](https://www.conventionalcommits.org) (`feat(issues): FT-18 …`).
8. **Développement dirigé par le frontend** + **TDD** (strict sur le métier, cf. `docs`/DAT ADR-018).
9. **Garde-fous automatiques** (`scripts/install-hooks.sh`) : les hooks refusent tout commit/push sur `main`/`develop`, bloquent le `.env` et valident les Conventional Commits.

## Tests

| Niveau | Outils |
|---|---|
| E2E | Playwright (1 parcours critique par écran) |
| Intégration gateway | pytest + schéma GraphQL réel + gRPC mocké + snapshot + `buf breaking` |
| Intégration service | pytest-django + grpcio-testing + PostgreSQL éphémère (testcontainers) |
| Unitaire back | pytest — **RG-020→030 à 100 %** (bloquant) |
| Unitaire front | Jest + Angular Testing Library + mocks Apollo |
| Performance | k6 (seuils ENF-01/02/03) |

## Observabilité

Grafana expose 7 dashboards (vue d'ensemble, par service, gateway/UX, PostgreSQL, RabbitMQ, métier, SLO) et 10 alertes. Corrélation **logs ↔ traces ↔ métriques** via `trace_id`. Objectif : diagnostiquer tout incident en < 15 min.

## Documentation

- [`CONTEXT.md`](./CONTEXT.md) — contexte projet complet
- [`MEMORY.md`](./MEMORY.md) — **règles opératoires inviolables**
- `docs/01…04` — analyse, spécification (SFD), architecture (DAT), backlog
- `Formuloo Tracker.html` — maquette haute-fidélité (référence UI)

## Sécurité & secrets

- **Ne jamais lire ni committer `.env`** (voir `MEMORY.md` §3). Seul `.env.example` est versionné.
- Autorisation vérifiée **côté serveur** à chaque appel ; JWT courts ; pièces jointes réservées aux membres du projet.
- Alignement **OWASP ASVS niveau 1** ; scan d'images en CI.

## Licence & propriété

Projet **interne à Formuloo**. Données auto-hébergées et propriété exclusive de Formuloo. **Coût de licence : 0** (composants open source uniquement).

> **Dépôt public** : le code source est ouvert ; les **données** restent auto-hébergées et privées. Pense à ajouter un fichier `LICENSE` (sans licence, le code est « tous droits réservés » par défaut).

---

*Pour comprendre le « pourquoi » et l'architecture : `CONTEXT.md`. Pour les règles de contribution : `MEMORY.md`.*
