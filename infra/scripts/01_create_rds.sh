#!/bin/bash
set -e
export AWS_PAGER=cat

DB_INSTANCE_ID="filmrentals-db"
DB_NAME="filmrentals"
DB_USER="postgres"
DB_PASSWORD="$1"
REGION=$(aws configure get region)

if [ -z "$DB_PASSWORD" ]; then
    echo "Uso: bash 01_create_rds.sh <password>"
    exit 1
fi

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=default" \
    --query 'SecurityGroups[0].GroupId' --output text)

echo "instancia RDS..."

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
    --region "$REGION"

echo "Esperando disponibilidad"
aws rds wait db-instance-available --db-instance-identifier "$DB_INSTANCE_ID"

RDS_HOST=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "RDS: $RDS_HOST"
echo "Siguiente: bash 02_create_secrets.sh $RDS_HOST $DB_PASSWORD"
