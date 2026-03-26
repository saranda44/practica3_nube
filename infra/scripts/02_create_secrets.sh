#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env"

export AWS_PAGER=cat

echo "Creando secreto: filmrentals/rds/host"
aws secretsmanager create-secret \
    --name "filmrentals/rds/host" \
    --secret-string "$RDSHOST" \
    --region us-east-1

echo "Creando secreto: filmrentals/rds/credentials"
aws secretsmanager create-secret \
    --name "filmrentals/rds/credentials" \
    --secret-string "{\"username\":\"$DB_USER\",\"password\":\"$DB_PASSWORD\"}" \
    --region us-east-1

echo "Secretos creados correctamente."
