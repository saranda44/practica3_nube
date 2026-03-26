#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env"

export AWS_PAGER=cat

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=default" \
    --query 'SecurityGroups[0].GroupId' --output text)

echo "Creando instancia RDS..."
aws rds create-db-instance \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --db-name "$DB_NAME" \
    --engine postgres \
    --engine-version "16.4" \
    --db-instance-class db.t3.micro \
    --allocated-storage 20 \
    --master-username "$DB_USER" \
    --master-user-password "$DB_PASSWORD" \
    --vpc-security-group-ids "$SG_ID" \
    --publicly-accessible \
    --backup-retention-period 0 \
    --no-multi-az \
    --region us-east-1

echo "Esperando que RDS esté disponible..."
aws rds wait db-instance-available --db-instance-identifier "$DB_INSTANCE_ID"

RDSHOST=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "RDS listo en: $RDSHOST"
echo ""
echo "Guarda este valor para el .env:"
echo "export RDSHOST=$RDSHOST"
