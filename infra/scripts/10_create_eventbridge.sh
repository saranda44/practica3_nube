#!/bin/bash
set -e
export AWS_PAGER=cat

RULE_NAME="filmrentals-expiry-check"
LAMBDA_NAME="expiry_alerts"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
LAMBDA_ARN="arn:aws:lambda:us-east-1:$ACCOUNT_ID:function:$LAMBDA_NAME"

# Cron: todos los dias a las 8am
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
    --source-arn "$RULE_ARN"

echo "EventBridge creado: $RULE_NAME -> $LAMBDA_NAME (diario 8am)"
