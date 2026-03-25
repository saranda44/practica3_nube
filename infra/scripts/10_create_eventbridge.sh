#!/bin/bash
set -e
export AWS_PAGER=cat

# extraemos variables a traves de aws cli
RULE_NAME="filmrentals-expiry-check"
LAMBDA_NAME="expiry_alerts"
REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
LAMBDA_ARN="arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$LAMBDA_NAME"

# Cron: todos los dias a las 8am (se tiene que cambiar para hacer pruebas)
RULE_ARN=$(aws events put-rule \
    --name "$RULE_NAME" \
    --schedule-expression "cron(0 8 * * ? *)" \
    --state ENABLED \
    --query 'RuleArn' \
    --output text)

aws events put-targets --rule "$RULE_NAME" --targets "Id=1,Arn=$LAMBDA_ARN"

aws lambda add-permission \
    --function-name "$LAMBDA_NAME" \
    --statement-id "eventbridge-$RULE_NAME" \
    --action "lambda:InvokeFunction" \
    --principal events.amazonaws.com \
    --source-arn "$RULE_ARN" 2>/dev/null || true

echo "EventBridge: $RULE_NAME - $LAMBDA_NAME (diario 8am)"
