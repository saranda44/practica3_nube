#!/bin/bash
set -e
export AWS_PAGER=cat

ROLE_ARN=$(aws iam get-role --role-name filmrentals-lambda-role --query 'Role.Arn' --output text)
RUNTIME="python3.12"
HANDLER="handler.main"

for dir in src/*; do
    [ -d "$dir" ] || continue

    FUNC_NAME=$(basename "$dir")
    [ "$FUNC_NAME" = "db_utils" ] && continue

    ZIP_FILE="$FUNC_NAME.zip"

    if aws lambda get-function --function-name "$FUNC_NAME" >/dev/null 2>&1; then
        echo "Actualizando Lambda existente: $FUNC_NAME"
        aws lambda update-function-code \
            --function-name "$FUNC_NAME" \
            --zip-file "fileb://$ZIP_FILE"
    else
        echo "Creando Lambda: $FUNC_NAME"
        aws lambda create-function \
            --function-name "$FUNC_NAME" \
            --runtime "$RUNTIME" \
            --role "$ROLE_ARN" \
            --handler "$HANDLER" \
            --zip-file "fileb://$ZIP_FILE" \
            --timeout 60 \
            --memory-size 512
    fi
done
