# CONTEXT.md — Contexte du projet Formuloo Tracker

Ce document donne à toute personne (ou agent) rejoignant le projet le **contexte complet** en une lecture : pourquoi le projet existe, ce qu'on construit, comment c'est architecturé, et où en est le travail. Pour les **règles opératoires** (Git, sécurité), voir `MEMORY.md`. Pour la **prise en main technique**, voir `README.md`.

---

## 1. Pourquoi ce projet

Formuloo utilise **Jira Cloud (plan Free)**, dont les limites freinent l'équipe : **10 utilisateurs maximum**, **aucun rôle ni permission** (tout le monde peut tout faire), **100 exécutions d'automatisation/mois**, notifications e-mail plafonnées, pas d'archivage de projet, stockage limité à 2 Go.

**Formuloo Tracker** est l'outil interne qui remplace Jira **sans limitation de plan** : utilisateurs illimités, rôles et permissions complets, automatisations libres, **données auto-hébergées et maîtrisées**, **coût de licence nul** (stack 100 % open source).

> **Vision** — Pour les équipes de Formuloo qui subissent les limites du plan gratuit de Jira, Formuloo Tracker est un outil web interne de gestion de projet agile qui fournit tickets, boards, sprints, permissions et rapports **sans aucune limite de licence**, auto-hébergé et gratuit à l'usage.

---

## 2. Ce qu'on construit (périmètre MVP)

Le MVP couvre **34 fonctionnalités « Must »** permettant de **quitter Jira sans perte opérationnelle**, regroupées en blocs :

- **Comptes & sécurité** : authentification (Keycloak/OIDC), profils, utilisateurs **illimités**, désactivation, **rôles par projet** (Admin/Membre/Observateur), permissions.
- **Projets** : multi-projets avec clé (`FORM`), responsable, **archivage** (fonction Premium chez Jira).
- **Tickets** : CRUD, 5 types (Epic/Story/Tâche/Bug/Sous-tâche), clé `CLE-N` immuable, champs standards, priorités, étiquettes, sous-tâches, hiérarchie, liens, commentaires, mentions, pièces jointes, historique, estimation.
- **Workflow & boards** : statuts personnalisables, transitions, **Kanban drag & drop**, board de sprint, filtres rapides.
- **Agile** : backlog priorisé, sprints (planification/démarrage/clôture), epics, objectif de sprint.
- **Recherche & rapports** : recherche plein texte + avancée, filtres sauvegardés, **burndown**, **vélocité**, répartitions, accueil personnel.
- **Notifications & automatisations** : in-app + e-mail, 4 automatisations pré-câblées **sans quota**.
- **Administration & données** : console admin, **import CSV depuis Jira**, export CSV/JSON, sauvegardes.

**Hors MVP** (roadmap V1.1/V2) : JQL, champs personnalisés, éditeur graphique de workflow, roadmap multi-projets, automatisation no-code générique, SSO/SAML, apps mobiles natives, intégrations Git/Slack.

Contraintes structurantes : interface en **français**, **responsive** (desktop 1440 px / mobile 390 px), tolérance à une **connectivité instable** (Douala), **budget licence = 0**.

---

## 3. Architecture en un coup d'œil

Application web autonome, auto-hébergée, **microservices** :

- **Frontend** : SPA **Angular** + **PrimeNG** (preset Aura), client **Apollo** (GraphQL), **schéma-first** (GraphQL Code Generator) avec **couche de mock MSW** pour tourner sans backend, OIDC PKCE, OTel Web SDK.
- **Gateway** : Django + **Strawberry GraphQL** — point d'entrée unique, agrégation, contrôle du JWT, DataLoader, subscriptions temps réel.
- **5 services métier** (Django, exposant du **gRPC**) :
  - `svc-projects` — projets, membres, rôles, statuts, archivage
  - `svc-issues` — tickets, commentaires, liens, historique, pièces jointes, recherche (FTS), import/export
  - `svc-agile` — sprints, backlog, burndown, vélocité, répartitions
  - `svc-notifications` — in-app, e-mails, préférences, automatisations
  - (+ **Keycloak** comme fournisseur d'identité OIDC)
- **Communication** : **GraphQL** navigateur→gateway ; **gRPC** gateway→services et service→service (strictement limité) ; **RabbitMQ** (événements métier) ; **MinIO** (pièces jointes, URL présignées).
- **Données** : **PostgreSQL 16** en *database-per-service* ; **Redis** (cache, rate limiting).
- **Observabilité** : **OpenTelemetry** → Grafana **Alloy** → **Prometheus / Loki / Tempo / Grafana** (+ Alertmanager). Objectif : tout incident diagnosticable en < 15 min.
- **Déploiement** : **Docker Compose** d'abord (dev en local sur Mac), **Kubernetes (k3s)** à terme, **mêmes images** (12 facteurs).

Les décisions sont tracées en **ADR-001→020** dans le DAT (`03-…md`).

### 3.1 Domaine (entités principales)

`Utilisateur`, `Projet`, `MembreProjet` (rôle), `Statut`, `Ticket` (clé `CLE-N`, type, priorité, étiquettes, estimation, hiérarchie parent/sous-tâche), `Sprint`, `LienTicket`, `Commentaire`, `PieceJointe`, `Historique`, `Notification`, `FiltreSauvegarde`. Vocabulaire **métier en français** (langage ubiquitaire).

### 3.2 Personas

- **Amina** — cheffe de projet (Admin projet) : planifie les sprints, suit l'avancement, produit les rapports.
- **Serge** — développeur (Membre) : voit ses tickets, met à jour les statuts, reçoit les mentions.
- **Diane** — direction (Observateur) : vue d'ensemble fiable, en lecture seule.
- **Kevin** — ops/IT (Super Admin) : gère les comptes, garantit sauvegardes et sécurité.

---

## 4. État d'avancement

| Phase | Statut |
|---|---|
| Analyse fonctionnelle & périmètre MVP ([R1]) | ✅ Terminé |
| Spécification fonctionnelle détaillée ([R2]) | ✅ Terminé |
| Architecture technique — DAT, ADR-001→020 ([R3]) | ✅ Terminé (v1.2) |
| Backlog produit — 65 stories, 10 sprints ([R4]) | ✅ Terminé (v1.1) |
| Maquette haute-fidélité — 23 écrans, design system ([R5]) | ✅ Disponible (référence à suivre) |
| Cadrage & décisions (collaboration, outillage) | ✅ Intégré dans [R3]/[R4] |
| **Sprint 0 — socle technique (FT-1→6)** | ⏳ **À démarrer** |

**Prochaine étape** : lever la *Definition of Ready du Sprint 0* (backlog §4, FT-E0) puis **FT-1 — scaffolding du monorepo** (structure, CI, protos, compose).

**Équipe & rythme** : 1 développeur (solo), sprints de 2 semaines, ~20 pts/sprint, MVP visé ≈ 5 mois (souple). **Modèle de collaboration** : hybride — Claude construit le socle et le gros œuvre outillable en tranches verticales testées ; Steve révise et reprend la main story par story.

**Trajectoire post-MVP** : le frontend et le backend seront repris par des **équipes distinctes, en dépôts séparés**. Le monorepo est donc conçu « prêt au split » : le **schéma GraphQL** est la frontière d'intégration, et le frontend tourne de façon **autonome** via sa couche de mock **MSW** (schéma-first + fixtures — DAT ADR-022). L'extraction de `/frontend` en dépôt indépendant en devient quasi triviale.

---

## 5. Carte des documents

| Réf | Fichier | Contenu |
|---|---|---|
| [R1] | `01-analyse-fonctionnalites-jira-et-mvp.md` | Inventaire Jira, priorisation MoSCoW, périmètre MVP |
| [R2] | `02-specification-fonctionnelle-formuloo-tracker.md` | Exigences EF/RG/ENF, modèle de données, permissions |
| [R3] | `03-architecture-technique-formuloo-tracker.md` | Architecture, ADR-001→020, observabilité, déploiement, design system |
| [R4] | `04-backlog-mvp-formuloo-tracker.md` | Epics, 65 user stories, plan de 10 sprints, inventaire des écrans |
| [R5] | `Formuloo Tracker.html` | Maquette haute-fidélité (23 écrans, design system) |
| — | `MEMORY.md` | **Règles opératoires inviolables** (Git, sécurité, non-contournement) |
| — | `README.md` | Prise en main technique du dépôt |

---

*Pour contribuer, lis d'abord `MEMORY.md` (règles) puis `README.md` (mise en route). Toute évolution de contexte est tracée dans les documents parents.*
