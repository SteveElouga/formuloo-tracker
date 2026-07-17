# gateway-graphql

Point d'entrée **GraphQL** (Strawberry) : schéma unique, contrôle JWT, agrégation des services gRPC.
**Squelette FT-1** — health `/sante/`. Le schéma GraphQL et le socle JWT arrivent en **FT-4**.

```bash
uv sync
uv run pytest                     # smoke test vert
uv run python manage.py runserver # http://localhost:8000/sante/  -> {"status":"SERVING"}
```
