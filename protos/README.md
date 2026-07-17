# protos/

Contrats **gRPC** — source de vérité inter-services (ADR-009), gérés par [`buf`](https://buf.build).

- `buf.yaml` — lint (`DEFAULT`) + breaking (`FILE`, contre `origin/develop`).
- `buf.gen.yaml` — génération Python/gRPC (en CI ; sorties `gen/` git-ignorées).
- `formuloo/<domaine>/v<N>/*.proto` — le chemin doit refléter le `package` (`PACKAGE_DIRECTORY_MATCH`).

```bash
task proto:lint      # buf lint
task proto:breaking  # rupture vs origin/develop
task proto:gen       # génère le code
```
