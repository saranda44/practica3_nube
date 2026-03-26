#!/bin/bash
set -e
export AWS_PAGER=cat

RDS_HOST=$(aws secretsmanager get-secret-value \
    --secret-id "filmrentals/rds/host" \
    --query SecretString --output text)

CREDENTIALS=$(aws secretsmanager get-secret-value \
    --secret-id "filmrentals/rds/credentials" \
    --query SecretString --output text)

DB_USER=$(echo "$CREDENTIALS" | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])")
export PGPASSWORD=$(echo "$CREDENTIALS" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")

echo "Creando tablas..."

psql --host="$RDS_HOST" --port=5432 --username="$DB_USER" --dbname="filmrentals" <<'EOF'
CREATE TABLE IF NOT EXISTS movies (
    movieId INTEGER PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    genres VARCHAR(500)
);

CREATE TABLE IF NOT EXISTS rentals (
    id          SERIAL PRIMARY KEY,
    movie_id    INTEGER NOT NULL REFERENCES movies(movieId),
    user_id     VARCHAR(50) NOT NULL,
    rented_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at  TIMESTAMP NOT NULL DEFAULT NOW() + INTERVAL '7 days',
    returned_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    id      SERIAL PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL UNIQUE,
    name    VARCHAR(100) NOT NULL,
    email   VARCHAR(100) NOT NULL
);
EOF

echo "Tablas creadas: movies, rentals, users"
