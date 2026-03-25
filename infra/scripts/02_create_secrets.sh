#!/bin/bash
set -e
export AWS_PAGER=cat

RDS_HOST="$1"
DB_PASSWORD="$2"
DB_USER="postgres"

if [ -z "$RDS_HOST" ] || [ -z "$DB_PASSWORD" ]; then
    echo "Uso: bash 02_create_secrets.sh <rds_host> <password>"
    exit 1
fi

echo "secreto: filmrentals/rds/host"
aws secretsmanager create-secret \
    --name "filmrentals/rds/host" \
    --secret-string "$RDS_HOST" 2>/dev/null || \
aws secretsmanager put-secret-value \
    --secret-id "filmrentals/rds/host" \
    --secret-string "$RDS_HOST"

echo "secreto: filmrentals/rds/credentials"
aws secretsmanager create-secret \
    --name "filmrentals/rds/credentials" \
    --secret-string "{\"username\":\"$DB_USER\",\"password\":\"$DB_PASSWORD\"}" 2>/dev/null || \
aws secretsmanager put-secret-value \
    --secret-id "filmrentals/rds/credentials" \
    --secret-string "{\"username\":\"$DB_USER\",\"password\":\"$DB_PASSWORD\"}"

echo "Secretos creados"
