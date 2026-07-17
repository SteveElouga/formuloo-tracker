# Backlog Produit — MVP Formuloo Tracker
# Epics, User Stories, Plan de Sprints

| Champ | Valeur |
|---|---|
| **Produit** | Formuloo Tracker (mini Jira interne) |
| **Type de document** | Backlog produit priorisé + plan de release MVP |
| **Version** | 1.4 |
| **Date** | 17/07/2026 |
| **Équipe** | 1 développeur fullstack (solo) |
| **Cadence** | Sprints de 2 semaines |
| **Estimation** | Story points — suite de Fibonacci (1, 2, 3, 5, 8, 13) |
| **Méthodes** | Pratiques Atlassian (stories 3C, INVEST) · **TDD** · **Développement conduit par le frontend** |
| **Documents parents** | [R1] Analyse & MVP · [R2] SFD (exigences EF-x, règles RG-x) · [R3] DAT · [R5] Maquette (design system, écrans) |

## Historique des révisions

| Version | Date | Modifications |
|---|---|---|
| 1.0 | 04/07/2026 | Backlog initial complet du MVP |
| 1.1 | 17/07/2026 | Intégration du cadrage : inventaire des écrans (§3.1), posture TDD strict métier / pragmatique UI (§2.1/§2.3), Definition of Ready du Sprint 0 (§4 FT-E0). |
| 1.2 | 17/07/2026 | Plateforme GitLab (au lieu de GitHub) : CI, registre et DoR Sprint 0 mis à jour (aligné DAT ADR-021). |
| 1.3 | 17/07/2026 | Plateforme : décision finale GitHub (aligné DAT ADR-021) : CI GitHub Actions, registre ghcr.io, DoR Sprint 0. |
| 1.4 | 17/07/2026 | Dépôt public (aligné DAT ADR-021 v1.5) : protection de branches gratuite ; DoR Sprint 0 mise à jour. |

---

## 1. Méthode de rédaction du backlog (pratiques Atlassian)

Ce backlog applique les standards Atlassian de rédaction et de gestion :

1. **Hiérarchie** : `Epic → Story → Sous-tâches`. Les 12 epics correspondent aux blocs fonctionnels du MVP [R1 §3.2]. Chaque story référence les exigences de la SFD [R2] (traçabilité EF-x / RG-x).
2. **Format des stories (les 3 C)** :
   - **Carte** : « En tant que *[persona]*, je veux *[objectif]* afin de *[bénéfice]* » — les personas sont ceux de [R2 §3.2] (Amina, Serge, Diane, Kevin).
   - **Conversation** : la description pointe les EF/RG de la SFD qui font office de contexte détaillé.
   - **Confirmation** : chaque story a des **critères d'acceptation testables** (pass/fail), qui deviennent les scénarios de tests TDD.
3. **INVEST** : chaque story est Indépendante (autant que possible — les dépendances résiduelles sont explicites), Négociable, apporte une Valeur utilisateur, Estimable, Small (≤ 8 points ; toute story estimée 13 a été découpée), Testable.
4. **Backlog DEEP** : Détaillé au bon niveau (les sprints proches sont raffinés finement), Estimé, Émergent (il vivra), Priorisé (l'ordre du document = l'ordre du backlog).
5. **Enablers** : les stories techniques (socle, CI, observabilité) sont assumées comme des stories d'« habilitation » — elles portent la mention `[Enabler]` et une valeur exprimée du point de vue du développeur/exploitant, conformément à la pratique des flow items techniques.

### 1.1 Hypothèse de vélocité (solo)

| Paramètre | Valeur | Commentaire |
|---|---|---|
| Capacité brute | 10 j/homme par sprint | Développeur seul, temps plein |
| Vélocité cible initiale | **~20 pts / sprint** | Hypothèse conservatrice ; **à recalibrer après les sprints 1 et 2** avec la vélocité réelle mesurée (rapport de vélocité, comme dans l'outil qu'on construit !) |
| Total backlog MVP | **~200 pts** | → **10 sprints ≈ 20 semaines ≈ 5 mois** |
| Buffer | Sprint 10 volontairement léger | Absorbe les découvertes et la recette |

---

## 2. Workflow d'une story : TDD conduit par le frontend

**Principe directeur** : le frontend est le **consommateur qui dicte les contrats**. Aucune API n'est développée « en avance » côté back : c'est le besoin réel de l'écran Angular qui définit la requête GraphQL, laquelle définit le RPC gRPC nécessaire. (Pattern *consumer-driven contracts*.)

Chaque story suit **le même cycle en 7 étapes** — c'est la définition opérationnelle du TDD frontend-driven pour ce projet :

```
┌──────────────────────────────────────────────────────────────────────┐
│ 1. 🔴 FRONT — Écrire d'abord les tests du composant Angular          │
│    (Testing Library / Jest) et le scénario E2E (Playwright, marqué   │
│    @wip) à partir des critères d'acceptation de la story.            │
│ 2. 📝 CONTRAT — Écrire la query/mutation GraphQL idéale pour l'écran │
│    (fichier .graphql versionné). C'est LE contrat, dicté par le front.│
│ 3. 🟢 FRONT — Implémenter le composant contre un MOCK du schéma      │
│    (Apollo MockedProvider / MSW). Tests front au vert. L'UI est      │
│    démontrable avec données simulées.                                │
│ 4. 🔴 GATEWAY — Écrire les tests du résolveur GraphQL (pytest,       │
│    schéma exécuté avec services gRPC mockés). Étendre le schéma.     │
│ 5. 🔴→🟢 SERVICE — Écrire les tests du handler gRPC et des règles    │
│    de gestion (pytest + grpcio-testing, base éphémère), PUIS         │
│    implémenter : proto → génération → handler → ORM. Rouge → Vert    │
│    → Refactor. Les RG-xxx touchées ont chacune leur test nommé.      │
│ 6. 🔗 INTÉGRATION — Brancher le front sur le vrai gateway ;          │
│    activer le test E2E (retirer @wip) ; il passe en local (compose). │
│ 7. ✅ DoD — Observabilité, revue de code (auto-revue outillée +      │
│    PR), CI verte, story démontrable → Done.                          │
└──────────────────────────────────────────────────────────────────────┘
```

### 2.1 Pyramide de tests et outillage (100 % gratuit)

| Niveau | Outils | Cible |
|---|---|---|
| E2E (peu, critiques) | **Playwright** contre l'environnement compose | 1 parcours par story « écran » ; les parcours de recette de [R2 §10] |
| Intégration gateway | pytest + schéma GraphQL réel + gRPC mocké ; **tests de contrat** (snapshot du schéma GraphQL, `buf breaking` sur les protos) | chaque résolveur |
| Intégration service | pytest-django + grpcio-testing + PostgreSQL éphémère (testcontainers) | chaque RPC |
| Unitaire back | pytest — **les 11 RG (RG-020→030) exigent une couverture 100 %** (ENF-11) | règles de gestion, sérialisation |
| Unitaire front | Jest + Angular Testing Library + Apollo mocks | composants, guards, stores |

> **Posture TDD (cadrage — [R3] ADR-018)** : **strict et bloquant sur le métier** (RG et handlers gRPC test-first, **100 % de couverture des RG-020→030 en CI**, un test de permission par mutation) ; **pragmatique sur l'UI** (tests de composants obligatoires, ordre test-avant-code recommandé mais non imposé ; gate global = pas de régression de couverture). Perf : **k6** en CI nocturne (seuils ENF-01/02/03, cf. FT-62).

### 2.2 Definition of Ready (DoR) — une story peut entrer en sprint si :
- [ ] Critères d'acceptation écrits et testables (pass/fail) ;
- [ ] Références EF/RG identifiées ; maquette ou croquis de l'écran disponible si story UI ;
- [ ] Dépendances (stories amont) terminées ou planifiées avant dans le sprint ;
- [ ] Estimée ≤ 8 points.

### 2.3 Definition of Done (DoD) — une story est terminée si :
- [ ] **Les tests métier ont été écrits avant le code** (commits témoins : test rouge d'abord) — obligatoire pour les RG et handlers gRPC ; recommandé, non bloquant, pour les composants d'UI ([R3] ADR-018) ;
- [ ] Tous les critères d'acceptation passent (tests automatisés, pas de vérification manuelle seule) ;
- [ ] Couverture : 100 % des RG touchées ; pas de baisse de la couverture globale ;
- [ ] Contrats : schéma GraphQL snapshot validé ; `buf breaking` sans rupture ;
- [ ] Observabilité incluse : spans OTel sur les nouveaux RPC/résolveurs, logs structurés, métriques RED visibles dans Grafana (le dashboard du service affiche la nouvelle opération) ;
- [ ] Sécurité : autorisation vérifiée côté service (test « Observateur ne peut pas ») pour toute mutation ;
- [ ] CI verte (lint + tests + build images) ; migration de BDD réversible ;
- [ ] Démontrable de bout en bout dans l'environnement compose local.

> **Note Atlassian** : les critères d'acceptation valident *la story* ; la DoD valide *la qualité de tout incrément*. Les deux sont cumulatifs.

---

## 3. Carte des epics

| Epic | Nom | EF couvertes | Stories | Points | Sprints visés |
|---|---|---|---|---|---|
| **FT-E0** | [Enabler] Socle technique & squelette marchant | ENF, DAT | 6 | 21 | S0 |
| **FT-E1** | Comptes & authentification | EF-1 | 5 | 18 | S1 |
| **FT-E2** | Projets, membres & rôles | EF-2, §7 [R2] | 6 | 21 | S2 |
| **FT-E3** | Tickets — création & consultation | EF-3 (cœur), EF-4 | 7 | 24 | S3 |
| **FT-E4** | Tickets — collaboration | EF-3 (commentaires, PJ, liens, historique) | 6 | 21 | S4 |
| **FT-E5** | Board Kanban | EF-5 | 4 | 16 | S5 |
| **FT-E6** | Backlog, sprints & epics | EF-6 | 6 | 22 | S6 |
| **FT-E7** | Recherche & filtres | EF-7 | 4 | 13 | S7 |
| **FT-E8** | Notifications | EF-9 | 4 | 13 | S7 |
| **FT-E9** | Rapports & accueil | EF-8 | 5 | 16 | S8 |
| **FT-E10** | Automatisations pré-câblées | EF-10 | 2 | 6 | S8 |
| **FT-E11** | Import/Export & administration | EF-11 | 5 | 18 | S9 |
| **FT-E12** | Durcissement, recette & mise en service | EF-12, ENF, [R2 §10] | 5 | 13 | S9–S10 |
| | **Total** | | **65** | **~222** | **10 sprints** |

> La vélocité réelle tranchera : si elle s'établit à 22+, le MVP tient en 9 sprints ; à 18, prévoir 11. Le plan (§5) garde le sprint 10 comme amortisseur.

### 3.1 Inventaire des écrans (maquette [R5]) ↔ stories

La maquette haute-fidélité étiquette chaque écran par ses stories, en **desktop 1440 px** et **mobile 390 px**. Cet inventaire est le **contrat visuel** du développement dirigé par le frontend.

| # | Écran (maquette) | Stories | Epic |
|---|---|---|---|
| 1 | Connexion (OIDC) + page d'accroche | FT-7 | E1 |
| 2 | Administration › Utilisateurs · Inviter · Désactivation | FT-9 · FT-11 · FT-58 | E1/E11 |
| 3 | Mon compte › Profil | FT-10 | E1 |
| 4 | Projets · Créer un projet · Archivés | FT-12 · FT-13 · FT-17 | E2 |
| 5 | Paramètres du projet (Membres · Statuts · Archivage) | FT-14 · FT-16 · FT-17 | E2 |
| 6 | Ticket — création, panneau, hiérarchie, transitions, historique | FT-18 → FT-24 | E3 |
| 7 | Modale de création de ticket | FT-18 | E3 |
| 8 | Modale de suppression de ticket | FT-24 | E3 |
| 9 | Pièces jointes · Liens entre tickets | FT-27 · FT-28 | E4 |
| 10 | Centre de notifications | FT-29 | E4 |
| 11 | Gabarits d'e-mail (assignation, mention) | FT-30 | E4 |
| 12 | Board Kanban (+ drag & drop, filtres) | FT-31 → FT-34 | E5 |
| 13 | Backlog & planification · Démarrer · Clôturer le sprint | FT-35 → FT-38 | E6 |
| 14 | Panneau Epics — avancement (Épopées) | FT-39 | E6 |
| 15 | Recherche globale, avancée & filtres sauvegardés | FT-41 → FT-43 | E7 |
| 16 | Préférences de notification | FT-45 | E8 |
| 17 | Rapports — Burndown · Vélocité · Répartitions | FT-49 → FT-51 | E9 |
| 18 | Accueil personnel « Pour vous » | FT-52 | E9 |
| 19 | Automatisations du projet | FT-54 | E10 |
| 20 | Import CSV Jira — assistant de mapping | FT-56 | E11 |
| 21 | Import Jira — rapport d'exécution | FT-57 | E11 |
| 22 | Console d'administration — supervision & stockage | FT-58 | E11 |
| 23 | Export complet des données | FT-59 | E11 |

> Chaque écran existe en desktop 1440 px et mobile 390 px : le responsive est une exigence de conception dès la première story « écran », pas une adaptation *a posteriori*. Design tokens et typographies : [R3] §16.4.

---

## 4. Backlog détaillé (ordre = priorité)

Format de chaque story : **ID · Titre** — story 3C — critères d'acceptation (CA) — tests TDD clés — dépendances — points.

### FT-E0 — [Enabler] Socle technique & squelette marchant (Sprint 0 — 21 pts)

> Objectif du sprint 0 : **prouver toute la chaîne** Angular → GraphQL → gRPC → PostgreSQL → RabbitMQ → notification, tracée dans Grafana (mitigation du risque R-1 du DAT).

**Modèle de collaboration (cadrage)** : hybride — Claude construit le socle et le gros œuvre outillable (FT-1→6, gabarits, CI, observabilité) en tranches verticales testées ; Steve révise chaque incrément et reprend la main story par story. WIP = 1, DoD non négociée.

**Definition of Ready — Sprint 0** (à lever avant FT-1) :
- [ ] Dépôt GitHub **public** créé ; `main` et `develop` protégées via PR + CI verte (gratuit sur dépôt public), accès Steve OK ;
- [ ] Outils installés : Docker + Compose, Node 20 LTS + pnpm, Python 3.12 + uv, `buf`, Taskfile, Playwright ;
- [ ] Versions figées ([R3] §16.2) : `.nvmrc`, `.python-version`, infra épinglée ;
- [ ] Design tokens ([R3] §16.4) transcrits en preset Aura + variables CSS ; polices Sora/Inter/JetBrains Mono self-hostées ;
- [ ] `.env.example` documenté (secrets hors Git) ; MailPit prévu pour le SMTP de dev (FT-8) ;
- [ ] **À confirmer par Steve** : RAM du Mac ≥ 16 Go (sinon profil `obs` optionnel en local) ; VPS maintenant ou plus tard ; nom de domaine ; fournisseur SMTP préprod ; nom du realm Keycloak + Super Admin initial ; disponibilité d'un export CSV Jira réel (fixtures FT-56/57).

| ID | Story | CA principaux | Tests TDD clés | Dép. | Pts |
|---|---|---|---|---|---|
| FT-1 | **Monorepo & CI** — En tant que développeur, je veux un monorepo avec CI (lint, tests, build, protos) afin que chaque commit soit vérifié automatiquement. | Structure `/protos /services /frontend /deploy /docs` ; pipeline GitHub Actions verte sur PR ; `buf lint` + `buf breaking` bloquants ; images poussées sur ghcr.io taguées SHA. | Le pipeline lui-même (échec si test rouge, si proto cassé). | — | 3 |
| FT-2 | **Environnement compose** — En tant que développeur, je veux `docker compose up` qui lance Traefik, Keycloak, PostgreSQL, RabbitMQ, Redis, MinIO afin de développer sur une infra identique à la prod. | Tous les conteneurs healthy ; réseaux edge/backend/observability conformes au DAT §9 ; `.env.example` documenté. | Healthchecks = tests ; script `smoke.sh` vérifie chaque endpoint. | FT-1 | 3 |
| FT-3 | **Stack observabilité** — En tant qu'exploitant, je veux Alloy + Prometheus + Loki + Tempo + Grafana provisionnés afin de voir logs, métriques et traces dès le premier service. | Grafana accessible (auth) ; datasources provisionnées en code ; dashboard « Vue d'ensemble » affiche l'état des conteneurs ; une trace de test OTLP visible dans Tempo. | Test d'ingestion : émettre 1 trace + 1 log + 1 métrique synthétiques, les retrouver via l'API Grafana. | FT-2 | 5 |
| FT-4 | **Gateway GraphQL minimal** — En tant que développeur front, je veux un gateway Django/Strawberry exposant `{ sante }` et le socle JWT afin d'avoir le point d'entrée du contrat. | `/graphql` répond ; requête sans JWT → 401 ; avec JWT Keycloak valide → 200 ; spans OTel émis. | *Front d'abord* : test Angular d'un service Apollo mocké ; puis pytest du middleware JWT (token expiré, mauvaise signature, ok). | FT-2 | 3 |
| FT-5 | **Squelette svc-issues + tranche verticale `creerTicket`** — En tant que Membre, je veux créer un ticket minimal (résumé seul) depuis une page Angular afin de prouver la chaîne complète. | Depuis le navigateur : saisie d'un résumé → mutation `creerTicket` → gRPC `CreateIssue` → ligne en base avec clé `FORM-1` → événement `issue.created` publié → consommé par un worker stub ; **la trace unique navigateur→worker est visible dans Tempo** ; logs corrélés par trace_id. | Cycle complet §2 : (1) test composant formulaire ; (2) contrat `.graphql` ; (3) mock vert ; (4) test résolveur ; (5) tests RPC + RG-020 (statut initial) + séquence de clé (extrait Gherkin EF-3.2) ; (6) E2E Playwright. | FT-3, FT-4 | 5 |
| FT-6 | **Gabarit de service réutilisable** — En tant que développeur, je veux un template de service Django+gRPC (logging JSON, OTel, outbox, tests) afin de créer les services suivants en < 1 h. | `cookiecutter` (ou script) générant un service qui passe la CI sans modification ; outbox + publication RabbitMQ incluses et testées. | Test du template : générer `svc-demo`, sa suite de tests passe. | FT-5 | 2 |

### FT-E1 — Comptes & authentification (Sprint 1 — 18 pts)

| ID | Story | CA principaux | Tests TDD clés | Dép. | Pts |
|---|---|---|---|---|---|
| FT-7 | **Connexion OIDC** — En tant qu'utilisateur, je veux me connecter via la page Keycloak (redirection PKCE) afin d'accéder à l'application de façon sécurisée. | Login → retour app avec session ; refresh silencieux ; déconnexion propre ; route protégée inaccessible sans session (guard). | Tests guards Angular (authentifié / non / token expiré) ; E2E login/logout. | FT-4 | 5 |
| FT-8 | **Realm Keycloak versionné** — [Enabler] En tant qu'exploitant, je veux le realm `formuloo` importable depuis un JSON versionné afin de reconstruire l'auth à l'identique (ADR-005, risque R-2). | Import automatique au démarrage compose ; politique de mots de passe et anti-brute-force actives ; email de reset fonctionnel (SMTP dev = MailPit). | Test d'intégration : reset de mot de passe bout-en-bout sur MailPit. | FT-2 | 3 |
| FT-9 | **Invitation d'utilisateurs** — En tant que Kevin (Super Admin), je veux créer un compte (email, nom) qui reçoit un lien d'activation afin d'intégrer un collègue **sans limite de nombre** (EF-1.1). | Écran admin liste + création ; email envoyé ; l'invité définit son mot de passe et se connecte ; doublon d'email refusé avec message clair. | Front d'abord (formulaire + états d'erreur mockés) ; test API admin Keycloak ; E2E invitation. | FT-7, FT-8 | 5 |
| FT-10 | **Profil utilisateur** — En tant que Serge, je veux modifier mon nom affiché, mon avatar et mon mot de passe afin de personnaliser mon compte (EF-1.4). | Avatar uploadé vers MinIO (URL présignée) ; changement de mdp délégué à Keycloak ; modifications visibles immédiatement. | Test composant profil ; test URL présignée (expiration 10 min) ; test propagation nom via gRPC projects. | FT-7 | 3 |
| FT-11 | **Désactivation de compte** — En tant que Kevin, je veux désactiver un compte afin de couper l'accès en conservant tout l'historique (EF-1.5/1.6, Gherkin SFD). | Reprend le Gherkin EF-1.5 : plus de connexion ; historique intact ; absent des listes d'assignation ; réactivation possible. | Tests du Gherkin EF-1.5 traduits en pytest + E2E ; test « suppression interdite si données liées ». | FT-9 | 2 |

### FT-E2 — Projets, membres & rôles (Sprint 2 — 21 pts)

| ID | Story | CA principaux | Tests TDD clés | Dép. | Pts |
|---|---|---|---|---|---|
| FT-12 | **Création de projet** — En tant que Kevin, je veux créer un projet (nom, clé unique 2-10 A-Z, description, responsable) afin d'isoler le travail d'une équipe (EF-2.1/2.2). | Clé validée (format, unicité) et immuable ; workflow par défaut 4 statuts créé (EF-2.7) ; créateur = premier Admin. | Front d'abord (formulaire, validation live de la clé) ; tests RPC : unicité, immuabilité, RG-011. | FT-6, FT-7 | 5 |
| FT-13 | **Liste « Mes projets »** — En tant que Diane, je veux voir la liste des projets dont je suis membre afin de naviguer vers mon travail (RG-029). | Un non-membre ne voit pas le projet (test API direct inclus) ; Super Admin voit tout ; carte projet : nom, clé, responsable, mon rôle. | Test résolveur avec 3 profils (membre, non-membre, super admin). | FT-12 | 2 |
| FT-14 | **Gestion des membres & rôles** — En tant qu'Amina (Admin projet), je veux ajouter/retirer des membres et fixer leur rôle (Admin/Membre/Observateur) afin de gouverner l'accès (EF-2.4). | Auto-complétion sur les comptes actifs ; changement de rôle effectif immédiatement (pas dans le JWT — ADR-005) ; on ne peut pas retirer le dernier Admin. | Tests matrice §7 [R2] : chaque action interdite testée par rôle, **y compris en appel gRPC direct** ; règle « dernier admin ». | FT-12 | 5 |
| FT-15 | **Autorisation transverse** — [Enabler] En tant que développeur, je veux un décorateur d'autorisation unique (`@require_role`) utilisé par tous les RPC afin que la matrice de permissions soit appliquée uniformément (ENF-05). | Toute mutation sans rôle suffisant → `PERMISSION_DENIED` ; testé par fixture paramétrée rejouable sur chaque nouveau RPC. | Suite de tests paramétrée réutilisable (le « harnais permissions »). | FT-14 | 3 |
| FT-16 | **Statuts personnalisables** — En tant qu'Amina, je veux ajouter/renommer/réordonner les statuts du projet (avec catégorie) afin d'adapter le workflow (EF-2.6, RG-010/011). | Drag & drop d'ordre ; suppression bloquée si tickets présents (message explicite) ; toujours ≥ 1 statut par catégorie. | Tests RG-010 et RG-011 (100 % — ENF-11) ; test composant liste réordonnable. | FT-12 | 5 |
| FT-17 | **Archivage de projet** — En tant qu'Amina, je veux archiver/désarchiver un projet afin de garder une instance propre (EF-2.5, RG-012) — *fonction Premium chez Jira*. | Projet archivé : hors listes par défaut, lecture seule, bandeau visible ; désarchivage restaure tout. | Test lecture seule (mutations refusées sur projet archivé) ; test E2E archiver→consulter→désarchiver. | FT-13 | 1 |

### FT-E3 — Tickets : création & consultation (Sprint 3 — 24 pts)

| ID | Story | CA principaux | Tests TDD clés | Dép. | Pts |
|---|---|---|---|---|---|
| FT-18 | **Création complète de ticket** — En tant que Serge, je veux créer un ticket (type, résumé, description riche, priorité, assigné, étiquettes, échéance, estimation) afin d'enregistrer un travail (EF-3.1, RG-020/021/022/025). | Bouton « Créer » global (EF-12.3) ; projet présélectionné ; validations (résumé ≤ 255, points ≥ 0) ; création < 15 s chrono utilisateur (CS-4). | Étend FT-5 ; tests RG-021/022/025 ; test composant éditeur riche (gras, listes, code). | FT-5, FT-15 | 5 |
| FT-19 | **Vue ticket (panneau latéral + URL)** — En tant que Serge, je veux ouvrir un ticket en panneau depuis toute liste, avec URL directe partageable, afin de consulter sans perdre le contexte (EF-12.4). | Panneau latéral ; URL `/t/FORM-42` ouvre directement (EF-7.5) ; 404 propre si clé inconnue. | Test routing Angular (deep link) ; test résolveur `ticket(cle)`. | FT-18 | 3 |
| FT-20 | **Édition en place champ par champ** — En tant que Serge, je veux modifier chaque champ directement dans la vue ticket afin d'aller vite (EF-3.3). | Clic → édition → sauvegarde optimiste → rollback si erreur ; conflit de version signalé (dernier écrit gagne + toast). | Tests composants par type de champ ; test mutation `modifierChampTicket` (champ inconnu → erreur typée). | FT-19 | 5 |
| FT-21 | **Hiérarchie Epic/Story/Sous-tâche** — En tant qu'Amina, je veux rattacher les tickets (epic parent, sous-tâches) afin de structurer le travail (EF-3.4, Gherkin SFD, RG-024). | Reprend le Gherkin EF-3.4 ; panneau sous-tâches avec avancement ; un Epic ne peut être enfant ; sous-tâche sans parent impossible. | Tests du Gherkin EF-3.4 ; tests RG-024. | FT-18 | 5 |
| FT-22 | **Transitions de statut** — En tant que Serge, je veux changer le statut depuis la vue ticket afin de refléter l'avancement (EF-4.1/4.2, EF-3.11). | Menu des statuts du projet ; passage en catégorie Terminé renseigne `resolu_le` (et l'efface en sortie) ; événement `issue.transitioned` publié. | Tests EF-3.11 (aller-retour) ; test publication outbox. | FT-18 | 3 |
| FT-23 | **Historique du ticket** — En tant que Diane, je veux l'onglet « Historique » (qui, quoi, quand, avant→après) afin d'auditer les changements (EF-3.9, ENF-12). | Chaque modification tracée ; lecture seule (aucune API de modification — test) ; pagination. | Test générique : toute mutation crée une entrée (fixture paramétrée) ; test immuabilité. | FT-20 | 2 |
| FT-24 | **Suppression contrôlée** — En tant qu'Amina, je veux supprimer un ticket (avec confirmation, sous-tâches incluses) afin de corriger les erreurs (EF-3.10) — réservé Admin. | Modale de confirmation nommant les sous-tâches ; Membre → interdit (harnais FT-15) ; clé jamais réutilisée (Gherkin EF-3.2). | Test cascade sous-tâches ; test non-réutilisation de clé. | FT-21 | 1 |

### FT-E4 — Tickets : collaboration (Sprint 4 — 21 pts)

| ID | Story | CA principaux | Tests TDD clés | Dép. | Pts |
|---|---|---|---|---|---|
| FT-25 | **Commentaires** — En tant que Serge, je veux commenter un ticket, éditer/supprimer mes commentaires afin de discuter du travail (EF-3.6). | Fil chronologique ; « (modifié) » affiché ; droits (P) de la matrice §7 respectés (Admin peut modérer). | Harnais permissions sur commentaires ; tests composant (édition inline). | FT-19 | 3 |
| FT-26 | **Mentions @** — En tant que Serge, je veux mentionner un membre avec auto-complétion afin de l'alerter (EF-3.7). | `@` déclenche l'auto-complétion (membres du projet uniquement) ; la mention est mise en évidence ; événement `issue.mentioned` publié. | Test parseur de mentions (RG : membres seulement) ; test composant auto-complétion. | FT-25 | 3 |
| FT-27 | **Pièces jointes** — En tant qu'Amina, je veux joindre des fichiers (glisser-déposer), prévisualiser les images, télécharger et supprimer afin de documenter les tickets (EF-3.8, ENF-06) — *2 Go max chez Jira Free, ici illimité côté app*. | Upload direct MinIO (URL présignée, jamais via le gateway) ; limite 20 Mo/fichier configurable ; téléchargement refusé aux non-membres (test URL directe — ENF-06). | Test présignature + expiration ; test ENF-06 ; E2E glisser-déposer. | FT-19, FT-10 | 5 |
| FT-28 | **Liens entre tickets** — En tant qu'Amina, je veux lier deux tickets (bloque / est bloqué par / duplique / relatif à) afin d'expliciter les dépendances (EF-3.5, RG-028). | Lien inverse créé et supprimé automatiquement (RG-028) ; recherche du ticket cible par clé ou texte ; les tickets bloquants apparaissent en avertissement. | Tests RG-028 (symétrie, 100 %) ; test anti-doublon de lien. | FT-19 | 3 |
| FT-29 | **Notifications in-app (socle)** — En tant que Serge, je veux une cloche avec compteur et centre de notifications (assignation, mention, commentaire, transition) afin de ne rien rater (EF-9.1/9.3/9.4). | svc-notifications consomme les événements ; pas d'auto-notification (RG EF-9.3) ; clic → ticket ; « tout marquer lu ». | Tests consommateur idempotent (rejeu d'événement = 1 notification) ; test EF-9.3 ; subscription GraphQL testée. | FT-22, FT-26 | 5 |
| FT-30 | **Emails (assignation & mention)** — En tant que Serge, je veux un email quand on m'assigne ou me mentionne afin d'être joignable hors de l'app (EF-9.2) — *plafonné chez Jira Free, ici sans limite applicative*. | Templates FR propres ; lien direct vers le ticket ; testé sur MailPit ; échec SMTP → retry + DLQ supervisée. | Test worker email (retry, DLQ) ; snapshot des templates. | FT-29 | 2 |

### FT-E5 — Board Kanban (Sprint 5 — 16 pts)

| ID | Story | CA principaux | Tests TDD clés | Dép. | Pts |
|---|---|---|---|---|---|
| FT-31 | **Board Kanban** — En tant que Serge, je veux un board (une colonne par statut, cartes riches) afin de visualiser le flux (EF-5.1) — chargement < 2 s pour 200 tickets (ENF-01). | Cartes : clé, icône type, résumé, priorité, avatar, points, étiquettes ; 1 seule requête GraphQL ; perf mesurée dans Grafana (exemplars). | Front d'abord avec mock 200 tickets ; test de perf reproductible (seed 200 tickets, assertion < 2 s). | FT-22 | 5 |
| FT-32 | **Drag & drop** — En tant que Serge, je veux glisser une carte entre colonnes (= transition) et verticalement (= réordonner) afin de piloter le travail à la souris (EF-5.2). | Optimistic UI + rollback ; ordre persistant (RG-030) ; accessible aussi sans souris (menu carte). | Test du calcul de rang lexicographique (RG-030, insertions massives) ; E2E drag & drop. | FT-31 | 5 |
| FT-33 | **Filtres rapides** — En tant qu'Amina, je veux filtrer le board (Mes tickets, texte, type, assigné, étiquette, epic — combinables) afin de me concentrer (EF-5.3). | Filtres cumulatifs ; état dans l'URL (partageable) ; compteur de résultats. | Tests de combinaison de filtres (logique ET/OU conforme EF-7.2). | FT-31 | 3 |
| FT-34 | **Responsive mobile** — En tant que Serge, je veux utiliser board et vue ticket sur mon téléphone afin de travailler en déplacement (EF-12.1, ENF-09/10). | Utilisable ≥ 360 px (colonnes scrollables) ; bundle initial < 1 Mo gzip vérifié en CI (budget Angular). | Budget de bundle en CI (échec si dépassé) ; tests Playwright viewport mobile. | FT-31 | 3 |

### FT-E6 — Backlog, sprints & epics (Sprint 6 — 22 pts)

| ID | Story | CA principaux | Tests TDD clés | Dép. | Pts |
|---|---|---|---|---|---|
| FT-35 | **Vue Backlog priorisée** — En tant qu'Amina, je veux un backlog ordonnancable par glisser-déposer afin de prioriser (EF-6.1, RG-030). | Tickets non planifiés/non terminés ; rang persistant partagé avec le board ; compteurs (nb, somme des points — EF-6.5). | Réutilise les tests de rang FT-32 ; test des compteurs. | FT-32 | 3 |
| FT-36 | **Création & planification de sprint** — En tant qu'Amina, je veux créer un sprint (nom auto, objectif, dates) et y glisser des tickets afin de préparer l'itération (EF-6.2, RG-023/024). | Sections sprint/backlog dans la même vue ; RG-024 : un Epic n'est pas sprintable (drop refusé avec message). | Tests RG-023/024 (100 %) ; test composant multi-sections. | FT-35 | 5 |
| FT-37 | **Démarrage de sprint** — En tant qu'Amina, je veux démarrer le sprint (≥ 1 ticket, dates obligatoires, 1 seul actif) afin de lancer l'itération (EF-6.3). | Validations EF-6.3 ; board bascule en mode sprint (EF-5.4) : objectif + jours restants en en-tête. | Tests des 3 validations ; test « 2e sprint actif refusé ». | FT-36 | 3 |
| FT-38 | **Clôture de sprint** — En tant qu'Amina, je veux clôturer en choisissant le sort des non-terminés (backlog ou sprint suivant) afin d'enchaîner proprement (EF-6.4, Gherkin SFD, RG-027). | Reprend le Gherkin EF-6.4 intégralement ; vélocité du sprint figée à la clôture (RG-027). | Tests du Gherkin EF-6.4 ; test RG-027 (tickets terminés après clôture non comptés). | FT-37 | 5 |
| FT-39 | **Panneau Epics** — En tant qu'Amina, je veux le panneau epics (filtre + avancement tickets/points) afin de suivre les gros chantiers (EF-6.6). | Avancement = terminés/total (nb et points) ; filtre epic actif sur backlog et board ; couleur par epic sur les cartes. | Test calculs d'avancement (dont tickets sans estimation). | FT-35 | 3 |
| FT-40 | **Snapshots quotidiens** — [Enabler] En tant qu'exploitant, je veux un job quotidien (Celery beat) qui fige l'état des sprints actifs afin d'alimenter le burndown (DAT §6). | Snapshot idempotent (rejouable) ; supervisé (métrique + alerte si absent > 26 h). | Test idempotence ; test rattrapage après jour manqué. | FT-37 | 3 |

### FT-E7 — Recherche & filtres (Sprint 7 — 13 pts)

| ID | Story | CA principaux | Tests TDD clés | Dép. | Pts |
|---|---|---|---|---|---|
| FT-41 | **Recherche globale** — En tant que Diane, je veux une barre de recherche (résumé, description, commentaires, clé exacte) afin de retrouver n'importe quel ticket (EF-7.1, ENF-03). | FTS PostgreSQL (dictionnaire FR) ; clé exacte → redirection directe (EF-7.5) ; résultats limités à mes projets (RG-029). | Test pertinence (accents, pluriels FR) ; test RG-029 ; test perf sur seed 50 k tickets. | FT-19 | 5 |
| FT-42 | **Recherche avancée** — En tant qu'Amina, je veux combiner projet/type/statut/priorité/assigné/étiquettes/sprint/epic/dates afin de construire des vues précises (EF-7.2/7.3). | Logique ET entre critères, OU dans un critère ; tri + pagination curseur ; état dans l'URL. | Tests de la grammaire de filtres (matrice de combinaisons) ; réutilisés par FT-33. | FT-41 | 5 |
| FT-43 | **Filtres sauvegardés** — En tant qu'Amina, je veux sauvegarder/renommer/supprimer mes recherches afin de les rejouer (EF-7.4). | Liste dans la navigation ; le filtre rejoué reproduit exactement les critères (versionnés en JSON). | Test sérialisation/désérialisation des critères. | FT-42 | 2 |
| FT-44 | **Export CSV des résultats** — En tant que Diane, je veux exporter toute liste de tickets en CSV afin d'analyser hors outil (EF-11.4). | Colonnes standards ; encodage UTF-8 BOM (Excel) ; streaming (pas de limite mémoire). | Test intégrité CSV (caractères spéciaux, virgules, sauts de ligne). | FT-42 | 1 |

### FT-E8 — Notifications : préférences & finitions (Sprint 7 — 13 pts)

| ID | Story | CA principaux | Tests TDD clés | Dép. | Pts |
|---|---|---|---|---|---|
| FT-45 | **Préférences de notification** — En tant que Serge, je veux régler quels événements m'envoient un email afin de maîtriser le bruit (EF-9.2, ENF défaut assignation+mention). | Écran préférences ; effet immédiat ; défauts conformes SFD. | Test matrice préférences × événements. | FT-30 | 3 |
| FT-46 | **Temps réel** — En tant que Serge, je veux voir la cloche se mettre à jour sans recharger afin d'être alerté en direct (EF-9.1). | Subscription WebSocket ; reconnexion automatique (réseau instable — CT-10) ; repli en polling si WS indisponible. | Test reconnexion (coupure simulée) ; test repli. | FT-29 | 5 |
| FT-47 | **Purge & pagination** — [Enabler] En tant qu'exploitant, je veux la purge des notifications lues > 90 j et la pagination du centre afin de contenir la base (DAT §6). | Job planifié testé ; pagination infinie côté front. | Test purge (bornes de dates). | FT-29 | 2 |
| FT-48 | **Digest d'événements projet** — En tant qu'Amina, je veux être notifiée des arrivées de membres et clôtures de sprint afin de suivre la vie du projet (événements §5.5 DAT). | Notifications in-app sur `project.member_added`, `sprint.closed`. | Tests consommateurs correspondants. | FT-38 | 3 |

### FT-E9 — Rapports & accueil (Sprint 8 — 16 pts)

| ID | Story | CA principaux | Tests TDD clés | Dép. | Pts |
|---|---|---|---|---|---|
| FT-49 | **Burndown** — En tant qu'Amina, je veux le burndown du sprint actif (points restants/jour vs idéal) afin de détecter les dérives (EF-8.2, RG-027). | Basé sur les snapshots FT-40 ; bascule points/nb tickets ; jours sans données interpolés honnêtement (trou visible). | Tests de calcul sur jeux de données de référence (sprint parfait, ajout en cours, sprint vide). | FT-40 | 5 |
| FT-50 | **Vélocité** — En tant qu'Amina, je veux l'histogramme engagé vs livré des 7 derniers sprints afin de calibrer la capacité (EF-8.3). | « Engagé » figé au démarrage du sprint ; « livré » figé à la clôture (RG-027) ; moyenne affichée. | Tests RG-027 approfondis (ticket ajouté en cours de sprint). | FT-38 | 3 |
| FT-51 | **Répartitions** — En tant que Diane, je veux les camemberts par statut/assigné/priorité/type afin d'avoir une photo du projet (EF-8.4). | Clic sur une part → liste filtrée correspondante (réutilise FT-42) ; export PNG (EF-8.5). | Tests d'agrégation (tickets sans assigné → « Non assigné »). | FT-42 | 3 |
| FT-52 | **Accueil personnel** — En tant que Serge, je veux une page d'accueil (mes tickets en cours, ceux que je rapporte, activité récente, accès rapides) afin de démarrer ma journée (EF-8.1, EF-12.2). | Navigation ≤ 2 clics vers tout (EF-12.2) ; sections vides avec états explicites. | Test résolveur agrégé (DataLoader — 1 requête) ; test états vides. | FT-42 | 3 |
| FT-53 | **Dashboards Grafana finaux** — [Enabler] En tant qu'exploitant, je veux les 7 dashboards du DAT §8.3 et les 10 alertes §8.4 provisionnés afin d'exploiter sereinement. | Dashboards en JSON versionnés ; alertes testées (une panne simulée déclenche l'alerte email). | Test de déclenchement d'alerte (stop d'un service en préprod). | FT-3 | 2 |

### FT-E10 — Automatisations pré-câblées (Sprint 8 — 6 pts)

| ID | Story | CA principaux | Tests TDD clés | Dép. | Pts |
|---|---|---|---|---|---|
| FT-54 | **4 règles activables** — En tant qu'Amina, je veux activer/désactiver les 4 automatisations (auto-assignation créateur ; parent terminé quand sous-tâches finies ; assignation à l'auteur de la transition ; notification du rapporteur) afin d'éliminer les gestes répétitifs (EF-10.1) — *sans quota, contrairement aux 100 runs/mois de Jira Free* (EF-10.3). | Écran de configuration par projet ; actions tracées « Automatisation » dans l'historique (EF-10.2). | 4 tests d'événements (un par règle) + test de désactivation + test de boucle infinie (règle qui se re-déclenche). | FT-38 | 5 |
| FT-55 | **Garde-fous** — [Enabler] En tant qu'exploitant, je veux une limite anti-boucle (profondeur 3) et des métriques par règle afin de garder le contrôle. | Compteur `formuloo_automation_runs_total{regle}` ; boucle coupée + log WARN. | Test de profondeur. | FT-54 | 1 |

### FT-E11 — Import/Export & administration (Sprint 9 — 18 pts)

| ID | Story | CA principaux | Tests TDD clés | Dép. | Pts |
|---|---|---|---|---|---|
| FT-56 | **Import CSV Jira — mapping** — En tant que Kevin, je veux charger l'export CSV Jira, mapper les colonnes et prévisualiser afin de préparer la migration (EF-11.3). | Détection automatique des colonnes Jira usuelles ; mapping statuts/utilisateurs (par email) avec suggestions ; prévisualisation 5 lignes (Gherkin EF-11.3). | Tests du parseur sur de vrais exports Jira (fixtures anonymisées) : multi-lignes, accents, champs multiples. | FT-21 | 5 |
| FT-57 | **Import CSV Jira — exécution** — En tant que Kevin, je veux exécuter l'import avec rapport d'erreurs téléchargeable afin de migrer sans perte (EF-11.3, CS-1). | Reprend le Gherkin EF-11.3 : tout-ou-rien par ligne ; rapport d'erreurs ; liens epic/parent reconstruits ; import streaming gRPC (gros fichiers). | Test transactionnel par ligne ; test reconstruction hiérarchie ; test 10 000 lignes (mémoire bornée). | FT-56 | 5 |
| FT-58 | **Console d'administration** — En tant que Kevin, je veux la console (utilisateurs, projets actifs/archivés, stats d'usage, stockage) afin de piloter l'instance (EF-11.1). | Compteurs exacts ; liens vers les écrans de gestion existants. | Tests d'agrégats. | FT-17 | 3 |
| FT-59 | **Export complet** — En tant que Kevin, je veux exporter toutes les données (JSON + pièces jointes, archive) afin de garantir la réversibilité (EF-11.2). | Archive téléchargeable ; manifeste avec checksums ; testé par ré-import de contrôle. | Test complétude (chaque table exportée) ; test checksums. | FT-58 | 3 |
| FT-60 | **Sauvegardes automatisées** — [Enabler] En tant que Kevin, je veux pgBackRest + miroir MinIO quotidiens supervisés afin de tenir RPO ≤ 24 h / RTO ≤ 4 h (ENF-08, alerte §8.4). | Sauvegarde chiffrée hors serveur ; **une restauration complète réussie en préprod** (critère d'acceptation n°5 [R2 §10]). | La restauration EST le test (procédure scriptée, chronométrée). | FT-2 | 2 |

### FT-E12 — Durcissement, recette & mise en service (Sprints 9-10 — 13 pts)

| ID | Story | CA principaux | Tests TDD clés | Dép. | Pts |
|---|---|---|---|---|---|
| FT-61 | **Campagne permissions** — En tant que Kevin, je veux la preuve qu'aucune action interdite n'est possible (UI **et** API) afin de valider la matrice §7 [R2] (critère n°3). | Le harnais FT-15 rejoué sur 100 % des mutations ; rapport de campagne archivé. | Génération automatique : chaque mutation du schéma doit avoir son test de permission (test qui échoue si une mutation n'est pas couverte). | FT-15, toutes mutations | 3 |
| FT-62 | **Tests de performance** — En tant qu'exploitant, je veux les mesures ENF-01/02/03 sur un jeu 2× la volumétrie réelle afin de valider le critère n°4 [R2 §10]. | Seed reproductible ; k6 (gratuit) en CI nocturne ; résultats dans Grafana. | Les seuils ENF = assertions k6. | FT-31, FT-41 | 3 |
| FT-63 | **Durcissement sécurité** — [Enabler] En tant qu'exploitant, je veux CSP/HSTS, scan Trivy bloquant, revue OWASP ASVS N1 afin de fermer ENF-05. | Checklist ASVS N1 archivée ; 0 vulnérabilité critique dans les images. | Scan en CI ; tests d'en-têtes. | FT-2 | 3 |
| FT-64 | **Sprint pilote & recette** — En tant qu'Amina, je veux conduire un sprint réel complet dans l'outil (critère n°6 [R2 §10]) afin de prononcer la recette. | Import des données réelles (FT-57) ; un sprint planifié→exécuté→clos→rapporté ; retours consignés en tickets. | La recette elle-même (scénarios [R2 §10] rejoués). | Tout | 2 |
| FT-65 | **Mise en service & bascule** — En tant que Kevin, je veux le go-live documenté (runbooks, DNS, gel Jira, communication équipe) afin de quitter Jira proprement. | Runbooks des 10 alertes écrits ; procédure de rollback ; Jira passé en lecture seule après bascule. | Répétition de bascule en préprod. | FT-64 | 2 |

---

## 5. Plan de release (10 sprints ≈ 5 mois)

| Sprint | Objectif de sprint (démontrable) | Stories | Pts |
|---|---|---|---|
| **S0** | « La chaîne complète fonctionne : un ticket créé depuis le navigateur est tracé jusqu'à Grafana » | FT-1→6 | 21 |
| **S1** | « Toute l'équipe peut se connecter, sans limite de comptes » | FT-7→11 | 18 |
| **S2** | « Les projets existent, avec rôles et permissions réels » (fini le tout-le-monde-peut-tout de Jira Free) | FT-12→17 | 21 |
| **S3** | « On crée, consulte, édite et fait avancer des tickets structurés » | FT-18→24 | 24 |
| **S4** | « On collabore : commentaires, mentions, fichiers, notifications » | FT-25→30 | 21 |
| **S5** | « Le board Kanban remplace celui de Jira, y compris sur mobile » | FT-31→34 | 16 |
| **S6** | « On planifie et clôture de vrais sprints » | FT-35→40 | 22 |
| **S7** | « On retrouve tout, on est notifié de tout » | FT-41→48 | 26 ⚠️ |
| **S8** | « Les rapports pilotent, les automatisations soulagent » | FT-49→55 | 22 |
| **S9** | « Les données Jira sont migrées, l'instance est administrable et sauvegardée » | FT-56→63 | 24 ⚠️ |
| **S10** | « Recette prononcée, bascule effectuée » + **amortisseur** | FT-64→65 + reliquats | 4 + buffer |

⚠️ S7 et S9 sont volontairement au-dessus de la vélocité cible : ce sont les **variables d'ajustement**. Si la vélocité mesurée en S1-S2 est < 20, déplacer FT-44/47/48 (S7) et FT-58 (S9) vers S10 — ils sont indépendants (INVEST) et non bloquants.

## 6. Vie du backlog (rituels adaptés au solo)

| Rituel | Cadence | Contenu (adapté à une personne) |
|---|---|---|
| Planification | 1er jour du sprint | Choisir les stories (DoR vérifiée), écrire l'objectif de sprint démontrable |
| Refinement | 1 h en milieu de sprint | Raffiner le sprint suivant : CA précisés, découpages, ré-estimations |
| Revue | Dernier jour | Démo enregistrée (vidéo courte) — utile pour montrer l'avancement à Formuloo et garder une trace |
| Rétrospective | Dernier jour (30 min) | 3 questions : vélocité réelle ? dette créée ? une amélioration de process pour le sprint suivant |
| Mise à jour du backlog | Continue | Toute découverte devient une story estimée, jamais un « je le ferai en passant » |

**Règles anti-dérive solo** : pas plus d'une story en cours à la fois (WIP = 1) ; la DoD n'est jamais négociée avec soi-même ; tout dépassement de 2 sprints sur le plan déclenche une revue de périmètre avec Formuloo (retirer des Should implicites plutôt que rogner la qualité).

---

*Documents liés : [R1] analyse & MVP · [R2] SFD · [R3] DAT · [R5] maquette. Décisions de cadrage intégrées en v1.1 (§2.1/§2.3, §3.1, DoR Sprint 0). Ce backlog est destiné à être importé dans l'outil de suivi (y compris, à terme, dans Formuloo Tracker lui-même — dogfooding dès le sprint 6).*
