# Plan d'implémentation — Observabilité · Formuloo Tracker

| | |
|---|---|
| **Statut** | Proposition — à revoir par Steve, puis à porter sur branche `docs/…` (R1/R3) |
| **Version** | 0.1 — 18/07/2026 |
| **Portée** | Mise en œuvre de l'observabilité (logs, métriques, traces, profils, erreurs, dispo) du MVP |
| **Références** | DAT §8 (chapitre prioritaire), ADR-006 / ADR-008 / ADR-020, ENF-01/02/07/08, MEMORY.md, backlog §2.2/§2.3 (DoR/DoD) |
| **Objectif opérationnel** | Tout incident diagnosticable en **< 15 min** via Grafana (logs ↔ traces ↔ métriques corrélés) — DAT §8 |

---

## 0. Objet & positionnement

Ce document décrit **comment** brancher l'observabilité sur Formuloo Tracker, du socle local jusqu'à Kubernetes, en respectant deux contraintes structurantes :

1. **L'observabilité n'est pas un chantier isolé.** Elle est déjà inscrite dans la **Definition of Done de chaque story** (backlog §2.3 : « spans OTel sur les nouveaux RPC/résolveurs, logs structurés, métriques RED visibles dans Grafana »). Le plan traite donc l'observabilité comme un **fil transverse** : un socle à poser une fois, puis une **checklist appliquée à chaque story** (voir §7).
2. **Instrumenter tôt, mais minimal d'abord.** L'auto-instrumentation OTel (qui accroche le *framework*, pas le code métier) est posée dès maintenant sur la gateway existante ; les spans/métriques **métier** custom arrivent au fil des features, quand les opérations se stabilisent.

Ce plan **complète** le DAT §8 sans le contredire, et acte quelques **réconciliations** (§3) entre le DAT tel qu'écrit et la pile d'observabilité réellement montée (OTel Collector + LGTM + Pyroscope + GlitchTip + Uptime Kuma).

---

## 1. État des lieux (18/07/2026)

| Élément | État actuel | Cible |
|---|---|---|
| Pile d'observabilité | **Montée et fonctionnelle**, mais **hors dépôt**, dans un dossier séparé (`observability/`) lancé isolément | Intégrée dans `deploy/compose/` comme **profil `obs`** (DAT §9.1, ADR-020) |
| Chaîne validée | Trace de bout en bout **OK** (app → OTLP → Collector → tail sampling → Tempo → Grafana) après correctifs | Idem, reproductible via `Taskfile` |
| Gateway GraphQL | Squelette FT-1 (Django/WSGI, `/sante/`) — **non instrumentée** | Auto-instrumentation OTel + logs JSON corrélés |
| Frontend Angular | Squelette FT-1 — **pas de RUM** | OTel Web SDK / Faro → Alloy (Web Vitals, erreurs, traces fetch) |
| Services métier | **Non encore créés** (FT-E2→E11) | Instrumentés au fil de l'eau via la DoD |
| Correctifs déjà identifiés | node-exporter `rslave` (Docker Desktop Mac), Tempo écoutant sur `localhost` au lieu de `0.0.0.0`, accès macOS à `~/Documents` | **À porter** dans la copie du dépôt (§5, Phase 0) |

> **À retenir de la mise au point initiale** — trois pièges déjà rencontrés et corrigés, à ne pas réintroduire lors de l'intégration au dépôt :
> - `node-exporter` : retirer la propagation `rslave` du montage `/` (incompatible Docker Desktop Mac/Win).
> - `tempo` : forcer `grpc.endpoint: 0.0.0.0:4317` (Tempo 2.7+ écoute sinon sur `localhost`, injoignable inter-conteneurs → `connection refused`).
> - macOS : la VM de Docker doit avoir l'accès disque à `~/Documents` (sinon `operation not permitted`) — non bloquant sur VPS/k3s.

---

## 2. Principes directeurs

- **P1 — Config, pas code.** Endpoint et activation via variables d'environnement (`OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SDK_DISABLED`), jamais en dur — 12 facteurs, mêmes images dev→prod (ADR-008).
- **P2 — Non-bloquant en local.** L'app démarre même sans la pile obs (profil `obs` à la demande, ADR-020) : `OTEL_SDK_DISABLED=true` par défaut hors profil obs.
- **P3 — Auto-instrumentation d'abord.** Django, ASGI/Strawberry, gRPC, psycopg, redis, pika en auto ; spans/métriques métier custom seulement quand l'opération est stable.
- **P4 — Corrélation native.** `trace_id`/`span_id` injectés dans les logs JSON ; exemplars métriques→traces ; W3C Trace Context de bout en bout (navigateur → GraphQL → gRPC → SQL → RabbitMQ).
- **P5 — Langue (ADR-014).** Domaine en **français** (`formuloo_tickets_crees_total`, `projet_cle`…), technique en anglais.
- **P6 — Versions figées (ADR-017, §16.2).** Toute dépendance OTel et toute image infra épinglées par version/tag immuable.

---

## 3. Réconciliations d'architecture à acter

Ces écarts entre le DAT §8 (tel qu'écrit) et la pile réellement montée doivent être tranchés **avant** l'intégration. Proposition : les acter dans un **ADR-023** (ou révision d'ADR-006).

| # | DAT §8 dit | Pile réelle | Décision proposée |
|---|---|---|---|
| R1 | « Collecte par **Alloy** (collector OTLP unique) » | **OTel Collector** central (ingest OTLP, tail sampling, spanmetrics/servicegraph, routage) **+ Alloy** pour logs conteneurs + récepteur **Faro** | Acter le **Collector** comme point de contrôle central ; Alloy = logs + Faro. Met à jour le schéma §8.1 |
| R2 | Non mentionnés | **Pyroscope** (profils, §4.9 doc maître), **GlitchTip** (erreurs, §4.6), **Uptime Kuma** (dispo) | Garder les 3 au MVP (valeur forte, coût faible). GlitchTip = complément aux erreurs OTel, pas doublon |
| R3 | Tail sampling : 100 % erreurs + **> 1 s** + 10 % | Collector : 100 % erreurs + **> 500 ms** + 10 % | Aligner sur **> 1 s** (réduit le volume) ou paramétrer par environnement |
| R4 | Alerting : **Email + Telegram** | Alertmanager câblé sur **Slack** | Basculer sur **Telegram + Email** (secret bot Telegram via env, S3) |
| R5 | Rétention : Prom **30 j**, Loki **30 j**, Tempo **14 j** | Prom 15 j, Tempo 15 j | Aligner sur le DAT (30/30/14) selon budget disque |
| R6 | Obs = profil `obs` dans `deploy/compose/` | Pile dans un dossier séparé hors dépôt | **Migrer** dans le dépôt (Phase 0) |

---

## 4. Architecture cible d'observabilité

Flux réconcilié (R1) :

```
Navigateur (Angular)
   └─ Faro Web SDK ── OTLP/HTTP ─▶ Alloy :12347 ─┐
                                                 │
Services Django + Gateway                        ├─▶ Loki   (logs JSON)
   ├─ OTel SDK Python ── OTLP ─▶ OTel Collector ─┼─▶ Tempo  (traces)
   │   (auto: Django, gRPC,      (:4317/:4318)   └─▶ Prometheus (métriques + exemplars)
   │    psycopg, redis, pika)     • tail sampling
   ├─ Pyroscope SDK ──────────▶ Pyroscope :4040 (profils)
   ├─ logs stdout JSON ───────▶ Alloy (docker.sock) ─▶ Loki
   └─ erreurs ────────────────▶ GlitchTip :8000

Grafana ◀── Prometheus / Loki / Tempo / Pyroscope   (corrélation + exemplars + trace→logs→profil)
Alertmanager ◀── Prometheus (règles SLO §8.4) ──▶ Telegram + Email
Uptime Kuma :3001 ── sondes synthétiques ─▶ gateway / keycloak
```

**Endpoints (à exposer aux apps via env) :**

| Cible | Endpoint interne | Émetteur |
|---|---|---|
| Traces + métriques + logs OTLP | `http://otel-collector:4318` (HTTP) / `:4317` (gRPC) | Backends Python |
| RUM navigateur (Faro) | `http://alloy:12347` (via edge en prod) | Frontend Angular |
| Profils continus | `http://pyroscope:4040` | Backends Python (SDK Pyroscope) |
| Erreurs (DSN) | `http://glitchtip:8000` (DSN par projet) | Front + back |

---

## 5. Phasage de mise en œuvre

### Phase 0 — Socle observabilité (Sprint 0, Enabler)

*Objectif : la pile obs vit dans le dépôt, se lance à la demande, et la chaîne est prouvée.*

- Migrer la pile dans `deploy/compose/docker-compose.observability.yml` (**profil `obs`**) + `config/` (`alloy/`, `prometheus/`, `loki/`, `tempo/`, `grafana/provisioning/`, `alertmanager/`).
- Porter les **3 correctifs** (§1) ; épingler toutes les images (ADR-017).
- Réseaux Docker `edge` / `backend` / `observability` (§9.2) ; Grafana derrière Traefik + **OAuth Keycloak**.
- Acter les réconciliations §3 (R1–R6) et l'**ADR-023**.
- Provisionner les datasources (déjà faites) + 1er dashboard « Vue d'ensemble ».
- Cible `Taskfile` : `task obs:up` / `task obs:down`.
- **DoD Phase 0** : `docker compose --profile obs up -d` OK ; trace de fumée visible dans Tempo ; Grafana accessible via Traefik.

### Phase 1 — Instrumenter la gateway GraphQL (existe déjà — FT-1/FT-4)

- Ajouter à `pyproject.toml` (versions figées) : `opentelemetry-distro`, `opentelemetry-exporter-otlp`, instrumentations `django`, `asgi`, `grpc`, `psycopg`, `redis`. Lancement via `opentelemetry-instrument gunicorn/uvicorn …`.
- Env : `OTEL_SERVICE_NAME=gateway-graphql`, `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_RESOURCE_ATTRIBUTES=deployment.environment=dev`, `OTEL_SDK_DISABLED` (P2).
- **Logs JSON structurés** sur stdout avec le jeu de champs DAT §8.2a (`timestamp, level, service, message, trace_id, span_id, user_id, projet_cle, ticket_cle, event`) + injection `trace_id/span_id`.
- Profiling : SDK Pyroscope Python (push `:4040`).
- **DoD Phase 1** : une requête GraphQL réelle produit une trace `gateway-graphql` dans Tempo, des logs corrélés dans Loki, et des métriques RED (spanmetrics) dans Prometheus.

### Phase 2 — Frontend RUM (Angular — FT-1/FT-7)

- Intégrer **Grafana Faro Web SDK** (ou OTel Web SDK) → Alloy `:12347` : Web Vitals (LCP/INP/CLS), erreurs JS, traces des appels GraphQL.
- **Propagation W3C** : lien Apollo ajoutant `traceparent` → corrélation navigateur ↔ gateway (indispensable pour CT-10, réseau instable Douala).
- Erreurs front → **GlitchTip** (SDK JS, DSN par env).
- Endpoint et activation via env ; désactivé en mode `mock` (MSW).
- **DoD Phase 2** : une action utilisateur génère **une seule trace** navigateur→gateway ; dashboard « Gateway / expérience » affiche les Web Vitals.

### Phase 3 — Chaque service métier, au fil de l'eau (FT-E2 → FT-E11, via la DoD)

*Pas de gros ticket unique : chaque story de feature embarque son observabilité (backlog §2.3).* Pour chaque nouveau service (`svc-projects`, `svc-issues`, `svc-agile`, `svc-notifications`) :

- Auto-instrumentation (serveur gRPC, psycopg, pika, redis) + logs JSON + RED (spanmetrics).
- **Propagation de contexte** sur gRPC **et** RabbitMQ (liens de spans producteur/consommateur).
- **Métriques métier** au fil des features : `formuloo_tickets_crees_total`, `formuloo_transitions_total`, `formuloo_sprints_actifs`, `formuloo_notifications_envoyees_total{canal}`, `formuloo_import_lignes_total{resultat}`.
- Dashboard « Par service » provisionné (gabarit réutilisable).
- Fournir un **template de service instrumenté** (Phase 0/1) pour que chaque nouveau service parte déjà câblé.

### Phase 4 — Dashboards, SLO & alerting (progressif, consolidé ~FT-62)

- Provisionner **en code** les 7 dashboards du DAT §8.3 (Vue d'ensemble, Par service ×5, Gateway/UX, PostgreSQL, RabbitMQ/DLQ, Métier, SLO).
- Règles Alertmanager du DAT §8.4 (service down, taux d'erreur > 5 %, P95 ticket > 500 ms, P95 board > 2 s, DLQ ≥ 1, disque, TLS, Keycloak, sauvegarde) → **Telegram + Email** (R4), chaque alerte avec **runbook** en annotation.
- **SLO** liés à ENF-01/02/07 ; seuils perf alimentés par **k6 nocturne** (FT-62).
- Exporters USE infra : node-exporter, cAdvisor, **postgres-exporter**, métriques RabbitMQ/Redis/MinIO (DAT §8.2b).
- GlitchTip : 1 projet par service (DSN via env) ; Uptime Kuma : sondes gateway + Keycloak.

### Phase 5 — Migration Kubernetes (k3s, ADR-008 — post-MVP, ~FT-64+)

*Mêmes images, zéro réécriture applicative (l'instrumentation est pilotée par env).*

- **Alloy en DaemonSet** (logs de nœud + Faro), **OTel Collector en Deployment** (ingest + tail sampling).
- **OTel Operator** pour l'injection d'auto-instrumentation (annotations de pods) ; `ServiceMonitor`/`PodMonitor` pour Prometheus.
- LGTM via Helm (ou `kube-prometheus-stack` + Loki + Tempo) ; Faro exposé par Ingress.
- Secrets via **Secrets k8s** (S3) ; profil `obs` → namespace `observability`.
- **DoD Phase 5** : un pod annoté émet ses traces/métriques sans changement de code ; dashboards et alertes identiques à Compose.

---

## 6. Backlog — tickets FT proposés

Exprimés comme **enablers** (`[Enabler]`, backlog §2.1). **IDs à confirmer/renuméroter** selon le backlog vivant.

| ID proposé | Titre | Type | Sprint visé | Réf. |
|---|---|---|---|---|
| FT-6c | [Enabler] Socle observabilité — profil `obs` + réconciliations (ADR-023) | Enabler | S0 | Phase 0 |
| FT-6d | [Enabler] Instrumentation gateway (OTel + logs JSON + Pyroscope) | Enabler | S0/S1 | Phase 1 |
| FT-6e | [Enabler] RUM frontend (Faro + propagation W3C + GlitchTip JS) | Enabler | S1 | Phase 2 |
| *(intégré DoD)* | Instrumentation par service | — | S2→S9 | Phase 3 / §7 |
| FT-62 (existant) | Perf k6 nocturne → seuils SLO | — | ~S9 | Phase 4 |
| FT-64 (existant) | Pilote VPS — pile obs en préprod | — | ~S9/10 | Phase 4 |
| FT-65+ | [Enabler] Migration k3s de l'observabilité | Enabler | Post-MVP | Phase 5 |

> **Rappel Sprint 0 (FT-E0)** : l'objectif est de **prouver toute la chaîne** Angular→GraphQL→gRPC→PostgreSQL→RabbitMQ→notification **tracée dans Grafana**. Les enablers FT-6c/6d/6e ci-dessus en sont le volet observabilité.

---

## 7. Checklist DoD « Observabilité » (à appliquer à chaque story)

Reprend et détaille le backlog §2.3. Une story de feature n'est **Done** que si :

- [ ] **Traces** : spans OTel sur chaque nouveau résolveur GraphQL / RPC gRPC, avec `user_id`, `projet_cle`, opération (paramètres SQL masqués).
- [ ] **Logs** : JSON structuré stdout avec `trace_id`/`span_id` injectés (champs DAT §8.2a).
- [ ] **Métriques** : RED visible dans Grafana ; le **dashboard du service affiche la nouvelle opération**.
- [ ] **Métier** : compteur `formuloo_*` ajouté si la story crée un fait métier (ticket, transition, notification, import…).
- [ ] **Propagation** : contexte W3C conservé à travers gRPC/RabbitMQ pour toute chaîne nouvelle.
- [ ] **Alerte/SLO** : seuil ou règle mis à jour si la story touche un chemin critique (ENF-01/02/07).
- [ ] **Sécurité** : aucun secret/PII en clair dans traces/logs (redaction OTel).

---

## 8. Conventions & garde-fous (MEMORY.md)

- **Branches (R1/R3)** : tout ce plan se réalise sur des branches dédiées créées depuis `develop` — ex. `feat/ft-6c-socle-observabilite`, `docs/plan-observabilite`. **Jamais** de commit direct sur `main`/`develop` (R2).
- **MR → `develop` (R4/R5)** : rebase obligatoire, CI verte, DoD cochée, référence `FT-x`. Commits **Conventional Commits** (ADR-019) : `feat(obs): FT-6d instrumentation gateway`.
- **Secrets (S1/S2/S3)** : `.env` **jamais lu ni committé** ; DSN GlitchTip, token bot Telegram, mots de passe Grafana → **variables d'environnement / secrets de plateforme**, `.env.example` seul versionné.
- **Versions figées (ADR-017)** : épingler dépendances OTel et images infra.

---

## 9. Risques & décisions ouvertes

| # | Sujet | Décision attendue |
|---|---|---|
| D1 | Réconciliation Collector vs Alloy (R1) | Valider **ADR-023** et mettre à jour le schéma DAT §8.1 |
| D2 | Périmètre MVP de Pyroscope / GlitchTip / Uptime Kuma (R2) | Confirmer les 3 au MVP ou en différer certains |
| D3 | Seuil de tail sampling (R3) et rétentions (R5) | Fixer les valeurs cibles selon budget disque VPS |
| D4 | Canal d'alerte (R4) | Créer le bot Telegram + secret ; retirer Slack |
| D5 | Budget RAM (~2,5 Go obs sur 16 Go) | Confirme le maintien du profil `obs` à la demande en dev (ADR-020) |
| D6 | Emplacement du dépôt | La pile obs quitte `observability/` (dossier séparé) pour `deploy/compose/` (profil `obs`) |

---

## 10. Annexes

**A. Variables d'environnement (extrait) — à ajouter dans `.env.example`**

```
# ─── Observabilité (profil obs) ───
OTEL_SDK_DISABLED=true                       # true par défaut hors profil obs (P2)
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=dev
GRAFANA_ADMIN_PASSWORD=dev-grafana-change-me
GT_SECRET_KEY=dev-glitchtip-change-me        # GlitchTip
GT_DB_PASSWORD=dev-glitchtip-db-change-me
ALERT_TELEGRAM_BOT_TOKEN=dev-change-me       # secret (S3)
ALERT_TELEGRAM_CHAT_ID=dev-change-me
```

**B. Versions de référence** — épingler selon §16.2 (Python 3.12, Node 20, pnpm 9, uv). Pour OTel : dernière ligne stable compatible OTLP 1.x, figée au lockfile.

**C. Composants de la pile** — otel-collector, prometheus, loki, tempo, pyroscope, grafana, alertmanager, alloy, node-exporter, blackbox-exporter, uptime-kuma, glitchtip (+db/redis/worker/migrate).

---

*Fin du plan — v0.1. À réviser par Steve puis à porter sur branche dédiée (MEMORY.md R1/R3) avant intégration au backlog.*
