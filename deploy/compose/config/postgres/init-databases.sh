#!/bin/bash
# DB-per-service (ADR-004) — crée les bases listées dans POSTGRES_EXTRA_DBS. FT-2.
# Lancé par l'entrypoint postgres (initdb.d). Pas d'`exit` au niveau racine (peut être sourcé).
_init_dbs() {
  local list="${POSTGRES_EXTRA_DBS:-}"
  [ -n "$list" ] || { echo "init-databases: POSTGRES_EXTRA_DBS vide"; return 0; }
  local raw db
  IFS=',' read -ra _dbs <<< "$list"
  for raw in "${_dbs[@]}"; do
    db="$(echo "$raw" | tr -d '[:space:]')"
    [ -n "$db" ] || continue
    echo "init-databases: base '$db'"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<SQL
SELECT 'CREATE DATABASE "$db"'
 WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\gexec
SQL
  done
  echo "init-databases: terminé."
}
_init_dbs
