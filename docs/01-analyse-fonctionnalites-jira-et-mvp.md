# Analyse exhaustive des fonctionnalités de Jira & Définition du MVP « Formuloo Tracker »

| Champ | Valeur |
|---|---|
| **Projet** | Formuloo Tracker — Mini Jira interne |
| **Document** | Analyse fonctionnelle comparative & périmètre MVP |
| **Version** | 1.0 |
| **Date** | 03/07/2026 |
| **Statut** | Draft — en attente de validation |
| **Auteur** | Équipe Formuloo (assisté par Claude) |
| **Diffusion** | Interne Formuloo |

---

## 1. Contexte et objectifs

### 1.1 Contexte
Formuloo utilise actuellement **Jira Cloud (plan Free)** pour la gestion de ses projets. Ce plan impose des limitations structurantes qui freinent le travail de l'équipe :

| Limitation du plan Free de Jira | Impact pour Formuloo |
|---|---|
| Maximum **10 utilisateurs** | Bloque la croissance de l'équipe |
| **2 Go** de stockage de fichiers | Pièces jointes rapidement saturées |
| **100 exécutions d'automatisation / mois** | Automatisations inutilisables à l'échelle |
| **Aucun rôle ni permission** (tout le monde peut tout faire) | Pas de gouvernance, risque d'erreurs |
| Notifications email plafonnées (~100/jour) | Perte d'information |
| Pas de roadmap multi-projets (Plans = Premium) | Pas de vision transverse |
| Pas d'archivage de projets, pas de sandbox, pas d'audit log | Instance qui s'encombre, pas de traçabilité admin |
| Support communautaire uniquement | Aucune garantie de service |

### 1.2 Objectif
Développer un outil interne, **« Formuloo Tracker »**, couvrant les fonctionnalités essentielles de Jira **sans limitation de plan** : utilisateurs illimités, permissions complètes, automatisations libres, stockage maîtrisé.

### 1.3 Méthodologie
1. **Inventaire exhaustif** des fonctionnalités de Jira (Cloud), module par module (§2).
2. **Classification** de chaque fonctionnalité selon la méthode **MoSCoW** (Must / Should / Could / Won't) croisée avec un **score de valeur/effort** (§2, colonne « MVP »).
3. **Extraction du périmètre MVP** (§3) puis proposition de **roadmap post-MVP** (§4).

**Légende des colonnes :**
- **Plan Jira** : plan minimal requis chez Atlassian → `Free`, `Std` (Standard), `Prem` (Premium), `Ent` (Enterprise), `App` (nécessite une app Marketplace payante).
- **MVP** : `M` = Must have (MVP), `S` = Should have (V1.1), `C` = Could have (V2), `W` = Won't have (hors périmètre).
- **Valeur** / **Effort** : ★ (faible) à ★★★ (élevé).

---

## 2. Inventaire exhaustif des fonctionnalités de Jira

### 2.1 Module A — Gestion des projets

| ID | Fonctionnalité | Description | Plan Jira | Valeur | Effort | MVP |
|---|---|---|---|---|---|---|
| A-01 | Création de projet | Nom, clé unique (ex. `FORM`), description, avatar | Free | ★★★ | ★ | **M** |
| A-02 | Multi-projets | Plusieurs projets isolés sur la même instance | Free | ★★★ | ★ | **M** |
| A-03 | Modèles de projet (templates) | Scrum, Kanban, gestion de tâches, etc. | Free | ★★ | ★★ | S |
| A-04 | Projets « team-managed » vs « company-managed » | Configuration locale vs schémas partagés | Free | ★ | ★★★ | W |
| A-05 | Responsable de projet (lead) | Un utilisateur désigné responsable | Free | ★★ | ★ | **M** |
| A-06 | Composants (components) | Sous-parties d'un projet avec responsable auto-assigné | Free | ★★ | ★★ | S |
| A-07 | Versions / Releases | Versions cibles (fixVersion), page de release, release notes | Free | ★★ | ★★ | S |
| A-08 | Catégories de projet | Regroupement de projets | Free | ★ | ★ | C |
| A-09 | Archivage de projet | Masquer un projet terminé sans le supprimer | **Prem** | ★★ | ★ | **M** |
| A-10 | Corbeille / restauration de projet | Récupération après suppression | Free | ★★ | ★★ | S |
| A-11 | Pages projet (raccourcis, description enrichie) | Liens et documentation du projet | Free | ★ | ★ | C |

### 2.2 Module B — Tickets (work items / issues)

| ID | Fonctionnalité | Description | Plan Jira | Valeur | Effort | MVP |
|---|---|---|---|---|---|---|
| B-01 | Création / lecture / édition / suppression de ticket | CRUD complet | Free | ★★★ | ★ | **M** |
| B-02 | Types de tickets standards | Epic, Story, Tâche, Bug, Sous-tâche | Free | ★★★ | ★ | **M** |
| B-03 | Types de tickets personnalisés | Création de types propres avec icône | Free | ★ | ★★ | C |
| B-04 | Clé + numérotation auto | `FORM-123`, incrément par projet | Free | ★★★ | ★ | **M** |
| B-05 | Champs standards | Résumé, description, assigné, rapporteur, priorité, étiquettes, échéance | Free | ★★★ | ★ | **M** |
| B-06 | Priorités | Highest → Lowest, personnalisables | Free | ★★★ | ★ | **M** |
| B-07 | Étiquettes (labels) | Tags libres multi-valeurs | Free | ★★★ | ★ | **M** |
| B-08 | Champs personnalisés | Texte, nombre, date, liste, utilisateur, case à cocher… | Free | ★★ | ★★★ | S |
| B-09 | Sous-tâches | Découpage d'un ticket parent | Free | ★★★ | ★★ | **M** |
| B-10 | Hiérarchie Epic → Story → Sous-tâche | Rattachement parent/enfant | Free | ★★★ | ★★ | **M** |
| B-11 | Hiérarchie personnalisée (au-dessus des Epics) | Initiatives, thèmes | **Prem** | ★ | ★★★ | W |
| B-12 | Liens entre tickets | « bloque », « est bloqué par », « duplique », « relatif à » | Free | ★★★ | ★★ | **M** |
| B-13 | Commentaires | Fil de discussion par ticket, édition/suppression | Free | ★★★ | ★ | **M** |
| B-14 | Mentions @utilisateur | Notification de la personne mentionnée | Free | ★★★ | ★★ | **M** |
| B-15 | Éditeur riche (wiki/markdown) | Gras, listes, code, tableaux, emojis | Free | ★★ | ★★ | S |
| B-16 | Pièces jointes | Fichiers et images sur les tickets | Free (2 Go) | ★★★ | ★★ | **M** |
| B-17 | Historique / journal d'activité | Toutes les modifications horodatées (qui, quoi, quand) | Free | ★★★ | ★★ | **M** |
| B-18 | Observateurs (watchers) | S'abonner aux notifications d'un ticket | Free | ★★ | ★★ | S |
| B-19 | Votes | Voter pour un ticket | Free | ★ | ★ | C |
| B-20 | Clonage de ticket | Dupliquer un ticket avec ses champs | Free | ★ | ★ | C |
| B-21 | Déplacement de ticket | Changer de projet ou de type | Free | ★★ | ★★ | S |
| B-22 | Opérations en masse (bulk) | Modifier / transférer / supprimer N tickets | Free | ★★ | ★★ | S |
| B-23 | Estimation | Story points ou temps estimé | Free | ★★★ | ★ | **M** |
| B-24 | Suivi du temps (time tracking) | Temps passé, temps restant, journal de travail | Free | ★★ | ★★ | S |
| B-25 | Résolutions | Done, Won't do, Duplicate, Cannot reproduce… | Free | ★★ | ★ | S |
| B-26 | Flags / signalement d'impediment | Marquer un ticket bloqué (drapeau) | Free | ★★ | ★ | S |
| B-27 | Modèles de tickets | Pré-remplissage récurrent | App | ★ | ★★ | C |

### 2.3 Module C — Workflows

| ID | Fonctionnalité | Description | Plan Jira | Valeur | Effort | MVP |
|---|---|---|---|---|---|---|
| C-01 | Statuts | À faire / En cours / Terminé + statuts personnalisés | Free | ★★★ | ★ | **M** |
| C-02 | Catégories de statut | To do (gris), In progress (bleu), Done (vert) | Free | ★★★ | ★ | **M** |
| C-03 | Transitions | Passage d'un statut à un autre | Free | ★★★ | ★ | **M** |
| C-04 | Éditeur graphique de workflow | Dessin du diagramme de flux | Free | ★★ | ★★★ | C |
| C-05 | Workflows différents par type de ticket | Bug ≠ Story | Free | ★★ | ★★ | S |
| C-06 | Conditions de transition | Ex. seul l'assigné peut passer « En cours » | Std | ★★ | ★★ | S |
| C-07 | Validateurs | Ex. champ obligatoire avant transition | Std | ★★ | ★★ | S |
| C-08 | Post-fonctions | Ex. assigner automatiquement après transition | Std | ★★ | ★★ | S |
| C-09 | Écrans de transition | Formulaire affiché lors d'une transition | Std | ★ | ★★★ | W |

### 2.4 Module D — Tableaux (boards)

| ID | Fonctionnalité | Description | Plan Jira | Valeur | Effort | MVP |
|---|---|---|---|---|---|---|
| D-01 | Tableau Kanban | Colonnes = statuts, glisser-déposer | Free | ★★★ | ★★ | **M** |
| D-02 | Tableau Scrum | Board du sprint actif | Free | ★★★ | ★★ | **M** |
| D-03 | Configuration des colonnes | Mapper plusieurs statuts sur une colonne | Free | ★★ | ★★ | S |
| D-04 | Limites WIP | Nombre max de tickets par colonne, alerte visuelle | Free | ★★ | ★ | S |
| D-05 | Swimlanes (couloirs) | Regroupement par epic, assigné, priorité | Free | ★★ | ★★ | S |
| D-06 | Filtres rapides | Boutons de filtre sur le board (mes tickets, bugs…) | Free | ★★★ | ★ | **M** |
| D-07 | Personnalisation des cartes | Champs affichés, couleurs | Free | ★ | ★★ | C |
| D-08 | Plusieurs boards par projet | Boards basés sur des filtres différents | Free | ★ | ★★ | C |

### 2.5 Module E — Agile : backlog, sprints, roadmap

| ID | Fonctionnalité | Description | Plan Jira | Valeur | Effort | MVP |
|---|---|---|---|---|---|---|
| E-01 | Backlog priorisé | Liste ordonnée par glisser-déposer | Free | ★★★ | ★★ | **M** |
| E-02 | Création / planification de sprint | Nom, objectif, dates, sélection des tickets | Free | ★★★ | ★★ | **M** |
| E-03 | Démarrage / clôture de sprint | Tickets non finis → backlog ou sprint suivant | Free | ★★★ | ★★ | **M** |
| E-04 | Gestion des Epics | Panneau epics, avancement par epic | Free | ★★★ | ★★ | **M** |
| E-05 | Timeline / roadmap mono-projet | Gantt simplifié des epics dans le temps | Free | ★★ | ★★★ | S |
| E-06 | Plans / Advanced Roadmaps (multi-projets) | Planification transverse, dépendances, capacité, scénarios | **Prem** | ★★ | ★★★ | C |
| E-07 | Objectif de sprint (sprint goal) | Texte d'objectif affiché sur le board | Free | ★★ | ★ | **M** |
| E-08 | Sprints parallèles | Plusieurs sprints actifs simultanément | Free | ★ | ★★ | C |
| E-09 | Gestion de la capacité | Charge par personne par sprint | **Prem** | ★★ | ★★★ | C |

### 2.6 Module F — Recherche, filtres et JQL

| ID | Fonctionnalité | Description | Plan Jira | Valeur | Effort | MVP |
|---|---|---|---|---|---|---|
| F-01 | Recherche plein texte | Recherche globale (résumé, description, commentaires) | Free | ★★★ | ★★ | **M** |
| F-02 | Recherche avancée multi-critères | Combinaison projet + type + statut + assigné + étiquette + dates | Free | ★★★ | ★★ | **M** |
| F-03 | JQL (Jira Query Language) | Langage de requête complet avec opérateurs et fonctions | Free | ★★ | ★★★ | C |
| F-04 | Filtres sauvegardés | Enregistrer et nommer une recherche | Free | ★★★ | ★ | **M** |
| F-05 | Partage de filtres | Filtres publics / par équipe | Std | ★★ | ★ | S |
| F-06 | Abonnements aux filtres | Email périodique avec les résultats | Free | ★ | ★★ | W |
| F-07 | Export des résultats (CSV) | Export de la liste de tickets | Free | ★★ | ★ | S |

### 2.7 Module G — Tableaux de bord et rapports

| ID | Fonctionnalité | Description | Plan Jira | Valeur | Effort | MVP |
|---|---|---|---|---|---|---|
| G-01 | Tableau de bord personnel | Vue d'accueil : mes tickets, activité récente | Free | ★★★ | ★★ | **M** |
| G-02 | Dashboards personnalisables (gadgets) | Grille de widgets configurables | Free | ★★ | ★★★ | S |
| G-03 | Burndown chart | Reste à faire du sprint dans le temps | Free | ★★★ | ★★ | **M** |
| G-04 | Burnup chart | Travail accompli vs périmètre | Free | ★★ | ★★ | S |
| G-05 | Rapport de vélocité | Story points livrés par sprint | Free | ★★★ | ★★ | **M** |
| G-06 | Rapport de sprint | Terminé / non terminé / ajouté en cours de sprint | Free | ★★ | ★★ | S |
| G-07 | Diagramme de flux cumulé (CFD) | Répartition des statuts dans le temps | Free | ★★ | ★★ | S |
| G-08 | Control chart / cycle time | Temps de cycle et temps de traversée | Free | ★★ | ★★★ | C |
| G-09 | Créés vs résolus | Tendance du flux entrant/sortant | Free | ★★ | ★★ | S |
| G-10 | Répartitions (camemberts) | Par assigné, priorité, type, statut | Free | ★★★ | ★ | **M** |
| G-11 | Rapport de suivi du temps | Estimé vs passé | Free | ★ | ★★ | C |
| G-12 | Atlassian Analytics / Data Lake | BI avancée | **Ent** | ★ | ★★★ | W |

### 2.8 Module H — Notifications

| ID | Fonctionnalité | Description | Plan Jira | Valeur | Effort | MVP |
|---|---|---|---|---|---|---|
| H-01 | Notifications in-app | Cloche + centre de notifications | Free | ★★★ | ★★ | **M** |
| H-02 | Notifications email | Sur assignation, commentaire, mention, transition | Free (limité) | ★★★ | ★★ | **M** |
| H-03 | Schéma de notification configurable | Qui reçoit quoi, par événement | Std | ★★ | ★★ | S |
| H-04 | Résumé quotidien / digest | Email de synthèse | Free | ★ | ★★ | C |
| H-05 | Préférences individuelles | Chaque utilisateur règle ses notifications | Free | ★★ | ★★ | S |

### 2.9 Module I — Automatisation

| ID | Fonctionnalité | Description | Plan Jira | Valeur | Effort | MVP |
|---|---|---|---|---|---|---|
| I-01 | Règles déclencheur → condition → action | Moteur no-code d'automatisation | Free (**100 runs/mois**) | ★★ | ★★★ | S |
| I-02 | Déclencheurs usuels | Ticket créé, transition, champ modifié, planification (cron) | Free (limité) | ★★ | ★★★ | S |
| I-03 | Actions usuelles | Assigner, transitionner, commenter, modifier champ, notifier | Free (limité) | ★★ | ★★★ | S |
| I-04 | Automatisations pré-câblées simples | Ex. auto-assignation au créateur, fermeture des sous-tâches | Free | ★★★ | ★★ | **M** |
| I-05 | Smart values / variables | Templating dans les actions | Free (limité) | ★ | ★★★ | W |
| I-06 | Automatisation multi-projets illimitée | Règles globales sans quota | **Prem/Ent** | ★★ | ★★ | C |

### 2.10 Module J — Utilisateurs, rôles et permissions

| ID | Fonctionnalité | Description | Plan Jira | Valeur | Effort | MVP |
|---|---|---|---|---|---|---|
| J-01 | Comptes utilisateurs illimités | Au-delà de 10 utilisateurs | **Std (payant/user)** | ★★★ | ★★ | **M** |
| J-02 | Authentification (email + mot de passe) | Connexion sécurisée, session | Free | ★★★ | ★★ | **M** |
| J-03 | Profils utilisateur | Nom, avatar, poste, fuseau | Free | ★★ | ★ | **M** |
| J-04 | Rôles projet | Admin / Membre / Observateur par projet | **Std** | ★★★ | ★★ | **M** |
| J-05 | Permissions granulaires (permission scheme) | Qui peut créer, éditer, supprimer, transitionner, commenter… | **Std** | ★★★ | ★★★ | **M** |
| J-06 | Groupes d'utilisateurs | Regroupement pour attribution en masse | Std | ★★ | ★★ | S |
| J-07 | Sécurité au niveau ticket (issue security) | Restreindre la visibilité de certains tickets | **Std** | ★ | ★★★ | C |
| J-08 | Désactivation d'utilisateurs | Conserver l'historique sans accès | Free | ★★★ | ★ | **M** |
| J-09 | SSO / SAML / SCIM | Identité d'entreprise | **Ent (Guard)** | ★ | ★★★ | W |
| J-10 | Accès anonyme / invités | Consultation sans compte | Std | ★ | ★★ | W |

### 2.11 Module K — Administration de l'instance

| ID | Fonctionnalité | Description | Plan Jira | Valeur | Effort | MVP |
|---|---|---|---|---|---|---|
| K-01 | Console d'administration | Gestion centralisée (utilisateurs, projets, référentiels) | Free | ★★★ | ★★ | **M** |
| K-02 | Référentiels globaux | Priorités, résolutions, types de liens, statuts | Free | ★★ | ★★ | S |
| K-03 | Schémas réutilisables (champs, écrans, workflows) | Mutualisation de configuration | Free | ★ | ★★★ | W |
| K-04 | Journal d'audit (audit log) | Traçabilité des actions d'administration | **Prem** | ★★ | ★★ | S |
| K-05 | Sandbox | Environnement de test | **Prem** | ★ | ★★★ | W |
| K-06 | Data residency | Localisation des données | Std/Prem | ★ | — | N/A (auto-hébergé ✔) |
| K-07 | Sauvegarde / restauration | Export complet des données | Free (manuel) | ★★★ | ★★ | **M** |
| K-08 | Suivi du stockage | Quota et usage des pièces jointes | Free | ★★ | ★ | S |

### 2.12 Module L — Intégrations et extensibilité

| ID | Fonctionnalité | Description | Plan Jira | Valeur | Effort | MVP |
|---|---|---|---|---|---|---|
| L-01 | API REST | CRUD complet par API, authentification par token | Free | ★★★ | ★★ | S |
| L-02 | Webhooks | Événements sortants vers des URL | Free | ★★ | ★★ | S |
| L-03 | Import CSV | Migration de données (depuis Jira notamment) | Free | ★★★ | ★★ | **M** |
| L-04 | Export CSV / JSON | Extraction de données | Free | ★★★ | ★ | **M** |
| L-05 | Intégration Git (GitHub/GitLab/Bitbucket) | Lier commits/PR aux tickets | Free | ★★ | ★★★ | C |
| L-06 | Intégration Slack / Teams / WhatsApp | Notifications vers messagerie | Free/App | ★★ | ★★ | C |
| L-07 | Marketplace d'apps | Écosystème de plugins | Free/App | ★ | ★★★ | W |
| L-08 | Intégration Confluence | Documentation liée | Payant | ★ | ★★★ | W |

### 2.13 Module M — Expérience utilisateur transverse

| ID | Fonctionnalité | Description | Plan Jira | Valeur | Effort | MVP |
|---|---|---|---|---|---|---|
| M-01 | Interface responsive (mobile) | Utilisation sur téléphone | Free | ★★★ | ★★ | **M** |
| M-02 | Application mobile native | Apps iOS/Android | Free | ★ | ★★★ | W |
| M-03 | Mode sombre | Thème clair/sombre | Free | ★ | ★ | C |
| M-04 | Raccourcis clavier | `c` créer, `/` rechercher, `j/k` naviguer | Free | ★ | ★★ | C |
| M-05 | Éléments récents / favoris | Accès rapide aux derniers tickets et projets | Free | ★★ | ★ | S |
| M-06 | Multilingue | FR/EN | Free | ★★ | ★★ | S (FR d'abord) |
| M-07 | Atlassian Intelligence (IA) | Résumés, rédaction assistée, recherche IA | **Prem** | ★ | ★★★ | W |

> **Récapitulatif quantitatif** : 96 fonctionnalités inventoriées — **34 Must (MVP)**, 30 Should (V1.1), 18 Could (V2), 13 Won't / N/A.

---

## 3. Définition du MVP « Formuloo Tracker »

### 3.1 Principe directeur
> **Le MVP doit permettre à Formuloo de quitter Jira du jour au lendemain sans perte de capacité opérationnelle quotidienne**, en récupérant au passage les fonctions payantes critiques : utilisateurs illimités, rôles & permissions, archivage, stockage maîtrisé.

### 3.2 Périmètre fonctionnel du MVP (les 34 « Must »)

| Bloc | Fonctionnalités retenues |
|---|---|
| **1. Comptes & sécurité** | Authentification (J-02), profils (J-03), utilisateurs **illimités** (J-01), désactivation (J-08), rôles projet Admin/Membre/Observateur (J-04), permissions par rôle (J-05) |
| **2. Projets** | Création multi-projets avec clé (A-01, A-02), responsable (A-05), **archivage** (A-09) |
| **3. Tickets** | CRUD (B-01), 5 types standards (B-02), numérotation `CLE-N` (B-04), champs standards (B-05), priorités (B-06), étiquettes (B-07), sous-tâches (B-09), hiérarchie Epic→Story→Sous-tâche (B-10), liens (B-12), commentaires + mentions (B-13, B-14), pièces jointes (B-16), historique complet (B-17), estimation en points (B-23) |
| **4. Workflow** | Statuts personnalisables par projet (C-01), 3 catégories de statut (C-02), transitions libres (C-03) |
| **5. Boards** | Kanban drag & drop (D-01), board de sprint (D-02), filtres rapides (D-06) |
| **6. Agile** | Backlog priorisé (E-01), sprints : planification/démarrage/clôture (E-02, E-03), epics (E-04), objectif de sprint (E-07) |
| **7. Recherche** | Recherche plein texte (F-01), recherche multi-critères (F-02), filtres sauvegardés (F-04) |
| **8. Reporting** | Tableau de bord personnel (G-01), burndown (G-03), vélocité (G-05), répartitions (G-10) |
| **9. Notifications** | In-app (H-01), email (H-02) |
| **10. Automatisation** | 4 règles pré-câblées activables par projet (I-04) |
| **11. Administration & données** | Console d'admin (K-01), sauvegarde/export (K-07), **import CSV depuis Jira** (L-03), export CSV/JSON (L-04) |
| **12. UX** | Interface web responsive FR (M-01) |

### 3.3 Explicitement hors MVP (et pourquoi)

| Exclu du MVP | Raison | Cible |
|---|---|---|
| JQL complet (F-03) | La recherche multi-critères couvre 90 % des besoins ; un langage de requête est coûteux | V2 |
| Éditeur graphique de workflow (C-04) | Une liste ordonnée de statuts suffit au départ | V2 |
| Champs personnalisés (B-08) | Fort générateur de complexité (écrans, recherche, migration) | V1.1 |
| Automatisation no-code générique (I-01→03) | Remplacée au MVP par des règles pré-câblées | V1.1 |
| Plans / roadmap multi-projets (E-06) | Valeur réelle mais effort majeur | V2 |
| SSO/SAML (J-09), sandbox (K-05), apps (L-07) | Sur-dimensionné pour une structure comme Formuloo | Won't |
| Application mobile native (M-02) | Le responsive web suffit | Won't |

### 3.4 Critères de succès du MVP

| # | Critère mesurable |
|---|---|
| CS-1 | 100 % des tickets Jira actuels de Formuloo importés (CSV) sans perte de champs standards |
| CS-2 | L'équipe complète (> 10 personnes) travaille dans l'outil sans coût de licence |
| CS-3 | Un cycle complet backlog → sprint → board → clôture → rapport réalisé sur un sprint réel |
| CS-4 | Temps de création d'un ticket < 15 s ; chargement d'un board < 2 s |
| CS-5 | Aucune action non autorisée possible pour un rôle Observateur (tests de permissions passés) |
| CS-6 | Sauvegarde/export complet réalisable par un admin en < 5 min |

---

## 4. Roadmap proposée après le MVP

| Version | Contenu | Fonctionnalités (IDs) |
|---|---|---|
| **MVP (V1.0)** | Socle complet décrit en §3.2 | Les 34 Must |
| **V1.1** | Confort & configuration : champs personnalisés, composants, versions/releases, WIP limits, swimlanes, timeline mono-projet, watchers, time tracking, workflows conditionnés, moteur d'automatisation no-code, schéma de notifications, groupes, dashboards à gadgets, API REST + webhooks, audit log | Les 30 Should |
| **V2.0** | Puissance : JQL, éditeur graphique de workflow, roadmap multi-projets, capacité, control chart, intégration Git/Slack, mode sombre, raccourcis clavier | Les 18 Could |
| **Won't** | SSO/SCIM, marketplace, apps mobiles natives, IA générative, BI avancée | — |

---

## 5. Annexe — Correspondance « ce que Formuloo récupère des plans payants »

| Fonction payante chez Jira | Plan requis chez Atlassian | Dans Formuloo Tracker |
|---|---|---|
| Plus de 10 utilisateurs | Standard (≈ 7,9 $ /user/mois) | ✔ MVP, illimité |
| Rôles & permissions | Standard | ✔ MVP |
| Stockage > 2 Go | Standard (250 Go) / Premium (illimité) | ✔ MVP (limité par votre propre serveur) |
| Archivage de projets | Premium | ✔ MVP |
| Automatisations sans quota | Premium/Enterprise | ✔ V1.1 (illimité) |
| Journal d'audit | Premium | ✔ V1.1 |
| Roadmap multi-projets (Plans) | Premium | ✔ V2 |
| Data residency | Standard/Premium | ✔ natif (auto-hébergement) |

---

*Document lié : `02-specification-fonctionnelle-formuloo-tracker.md` (spécification fonctionnelle détaillée du MVP).*
