# frontend

SPA **Angular** (standalone). **Squelette FT-1** — PrimeNG, Apollo et le socle mock MSW arrivent en FT-4/FT-6b.

```bash
pnpm install
pnpm test         # Jest — vert
pnpm run build    # production -> dist/browser
pnpm start        # dev server
pnpm start:mock   # dev server en mode mock (MSW sans backend — FT-6b)
```

Le mode `mock` remplace `environments/environment.ts` par `environment.mock.ts` (`apiMode: 'mock'`).
