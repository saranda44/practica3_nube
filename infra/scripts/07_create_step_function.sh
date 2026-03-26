#!/bin/bash
set -e
export AWS_PAGER=cat

STATE_MACHINE_NAME="Practica3StateMachine"
STATE_MACHINE_FILE="infra/state_machines/rental_state_machine.json"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

ROLE_ARN=$(aws iam get-role --role-name filmrentals-lambda-role --query 'Role.Arn' --output text)

# Reemplazar $AWS_ACCOUNT en el archivo con la cuenta real
DEFINITION=$(sed "s/\$AWS_ACCOUNT/$ACCOUNT_ID/g" "$STATE_MACHINE_FILE")

echo "Creando Step Function..."
STATE_MACHINE_ARN=$(aws stepfunctions create-state-machine \
    --name "$STATE_MACHINE_NAME" \
    --definition "$DEFINITION" \
    --role-arn "$ROLE_ARN" \
    --region us-east-1 \
    --query 'stateMachineArn' \
    --output text)

echo "Step Function creada: $STATE_MACHINE_ARN"
echo ""
echo "Para configurar en post_rent Lambda:"
echo "  export STATE_MACHINE_ARN=$STATE_MACHINE_ARN"
echo "  bash scripts/06_create_lambdas.sh"
