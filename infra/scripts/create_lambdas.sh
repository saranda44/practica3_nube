#!/bin/bash
set -e

export AWS_PAGER=cat

echo "=== Creando/Actualizando Lambdas en AWS ==="

LAB_ROLE_ARN=$(aws iam get-role --role-name LabRole --query 'Role.Arn' --output text)
RUNTIME="python3.12"
HANDLER="handler.main"
TIMEOUT="60"
MEMORY="512"

# Se usa para post_rent (se obtiene al crear la Step Function)
STATE_MACHINE_ARN_ENV="${STATE_MACHINE_ARN:-}"

# Crear o actualizar cada Lambda
for dir in src/*; do
    [ -d "$dir" ] || continue
    
    FUNC_NAME=$(basename "$dir")
    
    # Saltar db_utils (no es una Lambda)
    if [ "$FUNC_NAME" = "db_utils" ]; then
        continue
    fi
    
    ZIP_FILE="$FUNC_NAME.zip"
    
    # Verificar que el ZIP existe
    if [ ! -f "$ZIP_FILE" ]; then
        echo "Saltando $FUNC_NAME: ZIP no encontrado"
        continue
    fi
    
    # Crear o actualizar
    if aws lambda get-function --function-name "$FUNC_NAME" >/dev/null 2>&1; then
        echo "Actualizando Lambda existente: $FUNC_NAME"
        aws lambda update-function-code \
            --function-name "$FUNC_NAME" \
            --zip-file "fileb://$ZIP_FILE"

        aws lambda update-function-configuration \
            --function-name "$FUNC_NAME" \
            --runtime "$RUNTIME" \
            --handler "$HANDLER" \
            --timeout "$TIMEOUT" \
            --memory-size "$MEMORY" > /dev/null

        if [ "$FUNC_NAME" = "post_rent" ] && [ -n "$STATE_MACHINE_ARN_ENV" ]; then
            aws lambda update-function-configuration \
                --function-name "$FUNC_NAME" \
                --environment "Variables={STATE_MACHINE_ARN=$STATE_MACHINE_ARN_ENV}" > /dev/null
            echo "  Variable STATE_MACHINE_ARN configurada en post_rent"
        fi
    else
        echo "Creando Lambda: $FUNC_NAME"
        if [ "$FUNC_NAME" = "post_rent" ] && [ -n "$STATE_MACHINE_ARN_ENV" ]; then
            aws lambda create-function \
                --function-name "$FUNC_NAME" \
                --runtime "$RUNTIME" \
                --role "$LAB_ROLE_ARN" \
                --handler "$HANDLER" \
                --zip-file "fileb://$ZIP_FILE" \
                --timeout "$TIMEOUT" \
                --memory-size "$MEMORY" \
                --environment "Variables={STATE_MACHINE_ARN=$STATE_MACHINE_ARN_ENV}"
            echo "  Variable STATE_MACHINE_ARN configurada en post_rent"
        else
            aws lambda create-function \
                --function-name "$FUNC_NAME" \
                --runtime "$RUNTIME" \
                --role "$LAB_ROLE_ARN" \
                --handler "$HANDLER" \
                --zip-file "fileb://$ZIP_FILE" \
                --timeout "$TIMEOUT" \
                --memory-size "$MEMORY"
        fi
    fi
done

echo ""
echo "=== Completado ==="