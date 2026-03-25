#!/bin/bash
set -e
export AWS_PAGER=cat

MOVIES_CSV="$1"

if [ -z "$MOVIES_CSV" ] || [ ! -f "$MOVIES_CSV" ]; then
    echo "Uso: bash 04_load_movies.sh <ruta_al_movies.csv>"
    exit 1
fi

RDS_HOST=$(aws secretsmanager get-secret-value \
    --secret-id "filmrentals/rds/host" \
    --query SecretString --output text)

CREDENTIALS=$(aws secretsmanager get-secret-value \
    --secret-id "filmrentals/rds/credentials" \
    --query SecretString --output text)

DB_USER=$(echo "$CREDENTIALS" | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])")
export PGPASSWORD=$(echo "$CREDENTIALS" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")

echo "cargando peliculas"

psql --host="$RDS_HOST" --port=5432 --username="$DB_USER" --dbname="filmrentals" <<EOF
\COPY movies(movieId, title, genres) FROM '$MOVIES_CSV' WITH (FORMAT csv, HEADER true);
EOF

COUNT=$(psql --host="$RDS_HOST" --port=5432 --username="$DB_USER" --dbname="filmrentals" \
    -t -c "SELECT COUNT(*) FROM movies;")

echo "conteo peliculas: $COUNT"
