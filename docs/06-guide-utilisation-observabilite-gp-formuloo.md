# Guide d'utilisation — Observabilité · GP-Formuloo

| | |
|---|---|
| **Statut** | Guide d'exploitation — vivant |
| **Version** | 0.1 — 18/07/2026 |
| **Audience** | Développeurs (instrumentation) et exploitants (investigation) de GP-Formuloo |
| **Objet** | Utiliser correctement la pile d'observabilité pour obtenir une **observabilité propre** du projet |
| **Références** | DAT §8, ADR-006, plan `05-plan-implementation-observabilite`, `observability/README.md` (mécanique de la pile), document maître §10 |
| **Structure** | Suit le standard **Diátaxis** : *Prérequis → Prise en main → Concepts → Tâches → Référence → Dépannage* |

> **Promesse** : bien utilisé, ce socle permet de répondre à « quoi, où, depuis quand, pour qui, pourquoi » sur **tout incident en moins de 15 minutes**, depuis Grafana uniquement (DAT §8).

---

## 1. Prérequis

### 1.1 Matériel

| Ressource | Minimum | Recommandé | Note |
|---|---|---|---|
| RAM | 8 Go (profil `obs` seul + 1 service) | **16 Go** | Pile complète ≈ 10 Go dont **~2,5 Go** pour l'observabilité (DAT §9.1) |
| Disque | 20 Go libres | 100 Go SSD | Rétention traces/logs/métriques (voir §7) |
| CPU | 2 vCPU | 4 vCPU | — |

> Le profil `obs` est **optionnel et à la demande** (ADR-020) pour économiser ~2,5 Go quand on développe sans observer.

### 1.2 Logiciels

- **Docker** + **Docker Compose v2** (Docker Desktop sur Mac/Windows, ou Docker Engine sur Linux).
- **openssl** (génération de secrets).
- *(optionnel)* **Task** (Taskfile) — cibles `obs:up` / `obs:down` prévues au plan.
- *(optionnel)* **sloth** (génération des règles SLO), **k6** (parcours de fumée).

### 1.3 Ports à laisser libres

Grafana **3000** · Prometheus **9090** · Alertmanager **9093** · Loki **3100** · Tempo **3200** · Pyroscope **4040** · Collector OTLP **4317/4318** · Alloy/Faro **12347** · Uptime Kuma **3001** · GlitchTip **8000**.

### 1.4 Spécifique macOS ⚠

Docker Desktop (Mac/Windows) exécute les conteneurs dans une VM Linux. Deux pièges connus :

- **Accès à `~/Documents`** : la VM doit avoir l'autorisation macOS d'accéder au dossier, sinon les *bind mounts* échouent avec `operation not permitted`. Solution : *Réglages Système → Confidentialité → Accès complet au disque → Docker* (puis redémarrer Docker Desktop), **ou** placer la pile hors d'un dossier protégé (`~/dev/…`).
- **`node-exporter`** : le montage `/` ne doit **pas** utiliser la propagation `rslave` (incompatible Docker Desktop) — déjà corrigé dans la pile.

### 1.5 Secrets & configuration

- `cp .env.example .env` puis remplir. **Ne jamais committer `.env`** (S2 ; seul `.env.example` est versionné).
- `GT_SECRET_KEY` : `openssl rand -hex 32`.
- Alerting : le webhook n'est **pas** une variable d'environnement (Alertmanager ne les lit pas) — il vit dans un fichier secret monté (`alertmanager/secrets/…`, hors Git).

### 1.6 Connaissances de base

Comprendre les **4 signaux** (traces, métriques, logs, profils) et le protocole **OTLP**. La §3 en donne l'essentiel.

---

## 2. Prise en main rapide (≈ 10 min)

> **Où lancer la pile ?** Cible : profil `obs` dans `deploy/compose/` (`docker compose --profile obs up -d`). Tant que la **Phase 0** du plan n'est pas réalisée, la pile se lance depuis le dossier autonome `observability/` avec `docker compose up -d`.

| Étape | Action | Vérification attendue |
|---|---|---|
| 0 | `cp .env.example .env` et remplir | — |
| 1 | Démarrer la pile (`docker compose up -d`) | `docker compose ps` : services *Up/healthy*. `glitchtip-migrate` en *exited (0)* = **normal** (one-shot) |
| 2 | Ouvrir Grafana `:3000` (admin / `GRAFANA_ADMIN_PASSWORD`) → **Explore** | Les 4 datasources répondent : Prometheus, Loki, Tempo, Pyroscope |
| 3 | Envoyer une **trace de fumée** (voir encadré) | `HTTP 200 {"partialSuccess":{}}` |
| 4 | Attendre ~25 s, chercher la trace (Explore → Tempo) | Le span apparaît (rouge = erreur, 600 ms) |
| 5 | Depuis la trace → *logs de ce span* ; depuis un log → *Voir la trace* | La **corrélation fonctionne dans les deux sens** |

> **Trace de fumée** — envoie un span *marqué erreur + lent (600 ms)* pour qu'il **passe le tail sampling à coup sûr** (voir §4.5) :
>
> ```bash
> TID=$(openssl rand -hex 16); NOW=$(date +%s)000000000
> curl -s -o /dev/null -w "TraceID=$TID → HTTP %{http_code}\n" \
>   http://localhost:4318/v1/traces -H 'Content-Type: application/json' \
>   -d '{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"smoke-test"}}]},"scopeSpans":[{"spans":[{"traceId":"'"$TID"'","spanId":"'"$(openssl rand -hex 8)"'","name":"smoke","kind":2,"startTimeUnixNano":"'"$NOW"'","endTimeUnixNano":"'"$((NOW+600000000))"'","status":{"code":2}}]}]}]}'
> # Vérifier après ~25 s :
> sleep 25; curl -s -o /dev/null -w "Tempo → HTTP %{http_code}\n" "http://localhost:3200/api/traces/$TID"   # 200 attendu
> ```

---

## 3. Concepts — les 4 signaux et la corrélation

| Signal | Backend | Ce qu'il répond | Émis par |
|---|---|---|---|
| **Traces** | Tempo | *Où* le temps est passé, sur tout le chemin d'une requête | OTel SDK (auto : Django, gRPC, SQL, RabbitMQ, Redis) |
| **Métriques** | Prometheus | *Combien / à quelle vitesse* (RED par service, USE infra) | OTel + connecteurs `spanmetrics` du Collector |
| **Logs** | Loki | *Quoi* précisément, en clair, corrélé à la trace | stdout JSON → Alloy → Loki |
| **Profils** | Pyroscope | *Pourquoi c'est lent* au niveau CPU/mémoire | SDK Pyroscope |
| *(Erreurs)* | GlitchTip | Regroupement des exceptions, contexte, fréquence | SDK front + back |
| *(Dispo)* | Uptime Kuma | Le service répond-il, vu de l'extérieur | Sondes synthétiques |

**Routage (important) :**

- Les **backends** (Python/Django) envoient l'OTLP au **Collector** (`:4318`/`:4317`), jamais directement aux stockages.
- Le **frontend** (Angular) envoie via **Faro → Alloy** (`:12347`).
- Le Collector applique le **tail sampling** et dérive les métriques RED **avant** échantillonnage, puis route vers Tempo / Prometheus / Loki.
- La **corrélation** est câblée dans les datasources Grafana : *métrique → trace* (exemplars), *trace → logs* (derived fields), *trace → profil*. Le fil conducteur est le **`trace_id`** propagé en **W3C Trace Context** de bout en bout.

---

## 4. Instrumenter proprement son service

C'est le cœur d'une observabilité *propre*. Rappel : c'est une exigence de la **Definition of Done** de chaque story (backlog §2.3, voir la checklist du plan §7).

### 4.1 Backend Python / Django (gateway & services)

1. **Dépendances** (versions figées, ADR-017) : `opentelemetry-distro`, `opentelemetry-exporter-otlp`, instrumentations `django`, `asgi`, `grpc`, `psycopg`, `redis`.
2. **Lancement** via l'auto-instrumentation : `opentelemetry-instrument gunicorn …` (ou `uvicorn` en ASGI).
3. **Configuration par environnement** (jamais en dur) :

   ```
   OTEL_SERVICE_NAME=svc-issues
   OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
   OTEL_RESOURCE_ATTRIBUTES=deployment.environment=dev
   OTEL_SDK_DISABLED=true          # true par défaut hors profil obs (démarrage sans pile)
   ```
4. **Logs JSON structurés** sur stdout, avec injection automatique de `trace_id`/`span_id`. Jeu de champs imposé (DAT §8.2a) :
   `timestamp, level, service, message, trace_id, span_id, user_id, projet_cle, ticket_cle, event`.
5. **Profils** : SDK Pyroscope Python → `http://pyroscope:4040`.
6. **Erreurs** : SDK GlitchTip (DSN par service, via env).

### 4.2 Frontend Angular

- **Grafana Faro Web SDK** → Alloy `:12347` : Web Vitals (LCP/INP/CLS), erreurs JS, traces des appels GraphQL.
- **Propagation W3C** : ajouter l'en-tête `traceparent` via un lien Apollo → la trace navigateur **se relie** à la trace backend (indispensable pour CT-10, réseau instable).
- Désactivé en mode **mock** (MSW). Endpoint via env.

### 4.3 Conventions de nommage (observabilité *propre*)

| Élément | Règle | Exemple |
|---|---|---|
| `service.name` | kebab-case, un par service | `svc-issues`, `gateway-graphql` |
| Nom de span | opération métier ou technique, **pas** de valeur variable | `creerTicket`, `Issues.Transition` |
| Métrique métier | préfixe `formuloo_`, domaine **en français** (ADR-014) | `formuloo_tickets_crees_total` |
| Attribut de span | `snake_case`, borné | `user_id`, `projet_cle`, `ticket_cle` |

### 4.4 Hygiène de cardinalité (règle n°1 de propreté) 🔑

- **Ne jamais** mettre une valeur à forte cardinalité (`user_id`, `ticket_cle`, ID de requête, URL complète) en **label de métrique** → explosion de séries, Prometheus qui sature.
- Ces valeurs vont en **attribut de span** ou **champ de log** (cardinalité libre, sans coût métrique).
- Garder les labels de métrique **bornés** : `service`, `rpc`, `code`, `resultat`, `canal`.
- **Masquer** les données sensibles/PII (paramètres SQL, en-têtes d'auth) — la redaction est configurée dans le Collector (`attributes/redact`).

### 4.5 Comprendre le tail sampling (sinon on croit à tort que « ça ne marche pas »)

Le Collector ne **stocke pas 100 %** des traces. Politique par défaut : **100 % des erreurs**, **100 % des requêtes lentes** (> seuil), **10 % du reste**. Conséquences pratiques :

- Une trace de **test banale** a ~10 % de chances d'être stockée → pour un test déterministe, la marquer **erreur** ou **lente** (cf. §2).
- Il y a un **délai** (`decision_wait` ≈ 10 s + batch) avant qu'une trace apparaisse : **attendre ~25 s** avant de conclure.
- Les routes de santé (`/health/`, `/ready/`) sont **filtrées** volontairement (bruit).

### 4.6 Checklist « une story est observable » (extrait DoD §2.3)

- [ ] Spans OTel sur chaque nouveau résolveur GraphQL / RPC gRPC (avec `user_id`, `projet_cle`).
- [ ] Logs JSON avec `trace_id`/`span_id`.
- [ ] RED visible dans Grafana ; le dashboard du service **montre la nouvelle opération**.
- [ ] Compteur `formuloo_*` si la story crée un fait métier.
- [ ] Contexte W3C conservé à travers gRPC/RabbitMQ.
- [ ] Aucun secret/PII en clair.

---

## 5. Investiguer dans Grafana (le réflexe < 15 min)

**Scénario type (DAT §8.5)** — *« La création de ticket est lente »* :

1. **Dashboard Gateway** → repérer le **P95** de la mutation `creerTicket` en hausse.
2. Cliquer un **exemplar** sur la courbe de latence → saute à une **trace Tempo** représentative.
3. La trace montre *où* : 1,8 s dans `svc-issues` sur l'`INSERT` historique.
4. Depuis le span → **logs corrélés** (même `trace_id`) → un **lock PostgreSQL** apparaît.
5. Dashboard **PostgreSQL** → confirme un import CSV massif concurrent. **Diagnostic sans SSH, en quelques minutes.**

**Gestes utiles :**

- **Explore → Tempo → Search** : filtrer par `Service Name` (ex. `svc-issues`) ; ou **TraceQL** pour coller un `trace_id`.
- **Trace → logs** : bouton *logs de ce span* (fenêtre ±5 min).
- **Log → trace** : champ *Voir la trace* (derived field sur `trace_id`).
- **Sélecteur de temps** : le mettre sur une fenêtre récente (*Last 15 minutes / 1 hour*) — une trace récente hors plage ne s'affiche pas en recherche.

**Dashboards livrés (provisionnés en code, DAT §8.3) :** Vue d'ensemble · Par service (×5) · Gateway/UX · PostgreSQL · RabbitMQ/DLQ · Métier · SLO.

---

## 6. Alerting & SLO

- Les règles vivent dans Prometheus (`prometheus/rules/`) ; les **SLO** sont générés par **sloth** (`slo/units-service.yml` → `rules-slo.yml`), puis Prometheus rechargé.
- Alertmanager route les alertes. **En lab : webhook Slack** (fichier secret monté). **Cible Formuloo : Telegram + Email** (DAT §8.4, plan §3 R4).
- Chaque alerte **doit** porter un **runbook** en annotation (« que faire »). Une alerte sans action possible est supprimée (anti-fatigue).
- Seuils de référence (DAT §8.4) : service down > 2 min, taux d'erreur > 5 %/5 min, P95 écriture ticket > 500 ms, P95 board > 2 s, DLQ ≥ 1, disque > 80/90 %, TLS < 15 j, échecs Keycloak > 20/5 min, sauvegarde absente > 26 h.

---

## 7. Rétention & coût

| Signal | Rétention cible (DAT §8) | Réglage |
|---|---|---|
| Métriques (Prometheus) | 30 j | `--storage.tsdb.retention.time` |
| Logs (Loki) | 30 j | rétention label-based + compaction |
| Traces (Tempo) | 14 j | `compactor.block_retention` |

> La pile actuelle est réglée plus court (15 j) ; aligner selon le budget disque du serveur (plan §3 R5). Le tail sampling (§4.5) est le principal levier de réduction du volume de traces.

---

## 8. Dépannage (troubleshooting)

| Symptôme | Cause probable | Action |
|---|---|---|
| Trace absente de Tempo, mais `curl` renvoie `200` | Tail sampling (trace ni en erreur ni lente) **ou** délai | Marquer le span erreur/lent ; attendre ~25 s ; re-tester |
| Collector logs : `dial tcp …:4317: connection refused` (Tempo) | Tempo 2.7+ écoute sur `localhost` | Forcer `grpc.endpoint: 0.0.0.0:4317` dans `tempo-config.yaml`, redémarrer Tempo |
| `mkdir /host_mnt/Users/.../Documents: operation not permitted` | macOS bloque l'accès de Docker à `~/Documents` | Accès complet au disque à Docker (puis redémarrer) **ou** déplacer la pile hors `~/Documents` |
| `path / is mounted … not a shared or slave mount` | `node-exporter` monte `/` avec `rslave` | Retirer `rslave` du montage |
| `glitchtip-migrate` en *exited (0)* | Comportement **normal** (job one-shot de migration) | Aucune |
| Datasource « not working » | Conteneur cible pas prêt / URL interne | `docker compose ps` ; vérifier l'URL interne du datasource |
| Le curl OTLP renvoie 200 mais rien n'arrive | Variables shell vides dans le payload (heredoc sans assignations) | Vérifier que `TID`/timestamps sont bien renseignés (`echo`) |

**Boîte à outils diagnostic :**

```bash
docker compose ps                                             # état + health
docker logs $(docker ps -qf name=otel-collector|head -1) 2>&1 | grep -iE "error|tempo|export|refused" | tail
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3200/api/traces/<TRACE_ID>   # Tempo par ID
```

---

## 9. Sécurité & durcissement (avant toute exposition réelle)

> La configuration livrée est un **lab** : ports publiés, **pas de TLS ni d'auth inter-services**. Ne pas exposer tel quel.

Avant mise en réseau (durcissement §7.4 / DAT §9.2) :

- **TLS** via Traefik (Let's Encrypt) ; seuls **80/443** ouverts sur l'hôte (+ SSH filtré).
- **Grafana derrière Traefik + OAuth Keycloak** (pas d'admin/mot de passe en clair exposé).
- Réseaux Docker séparés : `edge`, `backend` (non exposé), `observability`.
- Secrets via variables d'environnement / secrets de plateforme (S3) ; rotation documentée.
- Ne **jamais** lire ni committer un `.env` (S1/S2).

---

## 10. Référence rapide

**Endpoints (interne conteneur) :** Collector OTLP `otel-collector:4318` (HTTP) / `:4317` (gRPC) · Faro `alloy:12347` · Pyroscope `pyroscope:4040` · GlitchTip `glitchtip:8000`.

**Variables clés :** `OTEL_SERVICE_NAME`, `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_RESOURCE_ATTRIBUTES`, `OTEL_SDK_DISABLED`, `GRAFANA_ADMIN_PASSWORD`, `GT_SECRET_KEY`, `GT_DB_PASSWORD`.

**Fichiers de config de la pile :** `otel-collector-config.yaml` (pipeline central) · `tempo-config.yaml` · `loki-config.yaml` · `alloy-config.alloy` · `prometheus/` · `alertmanager/` · `grafana/provisioning/datasources/datasources.yaml` · `slo/` · `k6/`.

**Glossaire :** *RED* (Rate/Errors/Duration) · *USE* (Utilization/Saturation/Errors) · *exemplar* (lien métrique→trace) · *tail sampling* (échantillonnage après trace complète) · *W3C Trace Context* (propagation `traceparent`) · *DLQ* (dead-letter queue, doit rester à 0).

**Voir aussi :** plan `05-plan-implementation-observabilite`, DAT §8, ADR-006, `observability/README.md`, document maître §10.

---

*Guide vivant — v0.1. À porter sur branche `docs/…` (MEMORY.md R1/R3) et à faire évoluer avec la pile.*
