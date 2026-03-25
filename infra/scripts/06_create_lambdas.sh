#!/bin/bash
set -e
export AWS_PAGER=cat

ROLE_ARN=$(aws iam get-role --role-name LabRole --query 'Role.Arn' --output text)
RUNTIME="python3.12"
HANDLER="handler.main"
TIMEOUT="60"
MEMORY="512"

STATE_MACHINE_ARN_ENV="${STATE_MACHINE_ARN:-}"
SNS_TOPIC_ARN_ENV="${SNS_TOPIC_ARN:-}"

# Handling de imprevistos
for dir in src/*; do
    [ -d "$dir" ] || continue

    FUNC_NAME=$(basename "$dir")
    [ "$FUNC_NAME" = "db_utils" ] && continue

    ZIP_FILE="$FUNC_NAME.zip"
    if [ ! -f "$ZIP_FILE" ]; then
        echo "saltando $FUNC_NAME: ZIP no encontrado"
        continue
    fi

    if aws lambda get-function --function-name "$FUNC_NAME" >/dev/null 2>&1; then
        echo "Actualizando: $FUNC_NAME"
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
        fi
        if [ "$FUNC_NAME" = "expiry_alerts" ] && [ -n "$SNS_TOPIC_ARN_ENV" ]; then
            aws lambda update-function-configuration \
                --function-name "$FUNC_NAME" \
                --environment "Variables={SNS_TOPIC_ARN=$SNS_TOPIC_ARN_ENV}" > /dev/null
        fi
    else
        echo "creando: $FUNC_NAME"
        ENV_VARS=""
        if [ "$FUNC_NAME" = "post_rent" ] && [ -n "$STATE_MACHINE_ARN_ENV" ]; then
            ENV_VARS="--environment Variables={STATE_MACHINE_ARN=$STATE_MACHINE_ARN_ENV}"
        fi
        if [ "$FUNC_NAME" = "expiry_alerts" ] && [ -n "$SNS_TOPIC_ARN_ENV" ]; then
            ENV_VARS="--environment Variables={SNS_TOPIC_ARN=$SNS_TOPIC_ARN_ENV}"
        fi

        aws lambda create-function \
            --function-name "$FUNC_NAME" \
            --runtime "$RUNTIME" \
            --role "$ROLE_ARN" \
            --handler "$HANDLER" \
            --zip-file "fileb://$ZIP_FILE" \
            --timeout "$TIMEOUT" \
            --memory-size "$MEMORY" \
            $ENV_VARS
    fi
done

echo "completado"
