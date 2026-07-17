# services/

Services backend (Django), un par sous-dossier. Chaque service : exposition **gRPC**, images multi-stage non-root (12 facteurs — DAT ADR-008), **base-per-service** (ADR-004).

- `gateway-graphql/` — point d'entrée **GraphQL** (Strawberry), contrôle JWT, agrège les services. *(squelette FT-1 ; complété en FT-4)*

À venir, créés par leur story via le gabarit **FT-6** : `svc-projects` (FT-E2), `svc-issues` (FT-5), `svc-agile`, `svc-notifications`.
