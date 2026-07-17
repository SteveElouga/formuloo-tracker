# contracts/

Contrats **non-gRPC** publiés, versionnés (ADR-022).

- `graphql/schema.graphql` — **SDL** GraphQL publié depuis le gateway. C'est la **frontière d'intégration** front/back : le frontend en dérive ses types (GraphQL Code Generator) et ses mocks (MSW), et tourne ainsi **sans backend** (FT-6b). Une vérif CI valide les opérations du front contre ce SDL.
