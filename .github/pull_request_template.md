<!-- Cette PR cible TOUJOURS `develop` (sauf release develop -> main). Voir MEMORY.md. -->

## Story
Réf. **FT-** <!-- id de la story, ex. FT-18 -->

## Description
<!-- Ce que fait cette PR, en une ou deux phrases -->

## Definition of Done (backlog §2.3)
- [ ] Tests **métier écrits avant le code** (RG / handlers gRPC) ; composants d'UI testés
- [ ] Tous les critères d'acceptation passent (tests automatisés)
- [ ] Couverture : **100 % des RG** touchées ; pas de régression globale
- [ ] Contrats : snapshot GraphQL validé ; `buf breaking` sans rupture
- [ ] Observabilité : spans OTel, logs structurés, métriques RED visibles
- [ ] Sécurité : autorisation vérifiée côté service (test « Observateur ne peut pas »)
- [ ] **CI verte** ; migration de BDD réversible
- [ ] Branche **rebasée sur `develop`** ; cette PR **cible `develop`**

## Vérifications (MEMORY.md)
- [ ] Aucun `.env` ni secret dans la PR (S1/S2)
- [ ] Message(s) de commit en **Conventional Commits** (ADR-019)
