#!/bin/bash
set -e

export AWS_PAGER=cat

STATE_MACHINE_NAME="Practica3StateMachine"
STATE_MACHINE_FILE="infra/state_machines/rental_state_machine.json"
REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=== Creando Step Function ==="

# Obtener Role ARN para Step Function
ROLE_ARN=$(aws iam get-role --role-name LabRole --query 'Role.Arn' --output text)

# Reemplazar $AWS_ACCOUNT en el archivo con la cuenta real
DEFINITION=$(sed "s/\$AWS_ACCOUNT/$ACCOUNT_ID/g" "$STATE_MACHINE_FILE")

echo "Nombre: $STATE_MACHINE_NAME"
echo "Región: $REGION"
echo "Role: $ROLE_ARN"
echo ""

echo "Creando Step Function..."

STATE_MACHINE_ARN=$(aws stepfunctions create-state-machine \
    --name "$STATE_MACHINE_NAME" \
    --definition "$DEFINITION" \
    --role-arn "$ROLE_ARN" \
    --region "$REGION" \
    --query 'stateMachineArn' \
    --output text)

echo " Step Function creada"

echo ""
echo "=== Step Function creada exitosamente ==="
echo ""
echo "State Machine ARN: $STATE_MACHINE_ARN"
echo ""
echo "Para configurar en post_rent Lambda:"
echo "  export STATE_MACHINE_ARN=$STATE_MACHINE_ARN"
echo "  bash infra/scripts/06_create_lambdas.sh"