#!/bin/bash
set -e
export AWS_PAGER=cat

API_NAME="practica3API"
STAGE_NAME="practica3"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

# Crear HTTP API
echo "Creando API: $API_NAME"
API_ID=$(aws apigatewayv2 create-api \
    --name "$API_NAME" \
    --protocol-type HTTP \
    --query 'ApiId' \
    --output text)

# GET /movies -> get_movies
LAMBDA_ARN="arn:aws:lambda:$REGION:$ACCOUNT_ID:function:get_movies"
INTEGRATION_ID=$(aws apigatewayv2 create-integration \
    --api-id "$API_ID" \
    --integration-type AWS_PROXY \
    --integration-uri "$LAMBDA_ARN" \
    --payload-format-version 2.0 \
    --query 'IntegrationId' --output text)
aws apigatewayv2 create-route \
    --api-id "$API_ID" \
    --route-key "GET /movies" \
    --target "integrations/$INTEGRATION_ID"
aws lambda add-permission \
    --function-name get_movies \
    --statement-id "apigateway-get-movies" \
    --action "lambda:InvokeFunction" \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/GET/movies"

# GET /status/{user_id} -> get_status
LAMBDA_ARN="arn:aws:lambda:$REGION:$ACCOUNT_ID:function:get_status"
INTEGRATION_ID=$(aws apigatewayv2 create-integration \
    --api-id "$API_ID" \
    --integration-type AWS_PROXY \
    --integration-uri "$LAMBDA_ARN" \
    --payload-format-version 2.0 \
    --query 'IntegrationId' --output text)
aws apigatewayv2 create-route \
    --api-id "$API_ID" \
    --route-key "GET /status/{user_id}" \
    --target "integrations/$INTEGRATION_ID"
aws lambda add-permission \
    --function-name get_status \
    --statement-id "apigateway-get-status" \
    --action "lambda:InvokeFunction" \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/GET/status/*"

# POST /rent -> post_rent
LAMBDA_ARN="arn:aws:lambda:$REGION:$ACCOUNT_ID:function:post_rent"
INTEGRATION_ID=$(aws apigatewayv2 create-integration \
    --api-id "$API_ID" \
    --integration-type AWS_PROXY \
    --integration-uri "$LAMBDA_ARN" \
    --payload-format-version 2.0 \
    --query 'IntegrationId' --output text)
aws apigatewayv2 create-route \
    --api-id "$API_ID" \
    --route-key "POST /rent" \
    --target "integrations/$INTEGRATION_ID"
aws lambda add-permission \
    --function-name post_rent \
    --statement-id "apigateway-post-rent" \
    --action "lambda:InvokeFunction" \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/POST/rent"

# Deploy
echo "Creando stage: $STAGE_NAME"
aws apigatewayv2 create-stage \
    --api-id "$API_ID" \
    --stage-name "$STAGE_NAME" \
    --auto-deploy

API_URL="https://$API_ID.execute-api.$REGION.amazonaws.com/$STAGE_NAME"

echo "API Gateway creado: $API_URL"
echo ""
echo "Endpoints:"
echo "  GET    $API_URL/movies"
echo "  GET    $API_URL/status/{user_id}"
echo "  POST   $API_URL/rent"
