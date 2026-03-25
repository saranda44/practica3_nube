#!/bin/bash
set -e

export AWS_PAGER=cat

API_NAME="practica3API"
STAGE_NAME="practica3"
REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=== Creando HTTP API Gateway ==="

# Crear HTTP API
echo "Creando API: $API_NAME"
API_ID=$(aws apigatewayv2 create-api \
    --name "$API_NAME" \
    --protocol-type HTTP \
    --query 'ApiId' \
    --output text)

echo "API ID: $API_ID"

# Array de endpoints
declare -a ENDPOINTS=(
    "GET /movies get_movies"
    "GET /status/{user_id} get_status"
    "POST /rent post_rent"
)

# Crear integraciones y rutas
for endpoint in "${ENDPOINTS[@]}"; do
    METHOD=$(echo $endpoint | awk '{print $1}') 
    ROUTE=$(echo $endpoint | awk '{print $2}')
    LAMBDA_NAME=$(echo $endpoint | awk '{print $3}')
    
    echo ""
    echo "Configurando: $METHOD $ROUTE -> $LAMBDA_NAME"
    
    # ARN de la Lambda
    LAMBDA_ARN="arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$LAMBDA_NAME"
    
    # Crear integración
    INTEGRATION_ID=$(aws apigatewayv2 create-integration \
        --api-id "$API_ID" \
        --integration-type AWS_PROXY \
        --integration-uri "$LAMBDA_ARN" \
        --payload-format-version 2.0 \
        --query 'IntegrationId' \
        --output text)
    
    # Crear ruta
    ROUTE_KEY="$METHOD $ROUTE"
    aws apigatewayv2 create-route \
        --api-id "$API_ID" \
        --route-key "$ROUTE_KEY" \
        --target "integrations/$INTEGRATION_ID" > /dev/null
    
    # Permitir que API Gateway invoque la Lambda
    SOURCE_ARN="arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/$METHOD${ROUTE//\{user_id\}/\*}"
    aws lambda add-permission \
        --function-name "$LAMBDA_NAME" \
        --statement-id "apigateway-$API_ID-$LAMBDA_NAME" \
        --action "lambda:InvokeFunction" \
        --principal apigateway.amazonaws.com \
        --source-arn "$SOURCE_ARN" 2>/dev/null || echo "  (permiso ya existe)"
    
    echo " $ROUTE configurado"
done

# Crear stage y hacer auto-deploy
echo ""
echo "Creando stage: $STAGE_NAME"
aws apigatewayv2 create-stage \
    --api-id "$API_ID" \
    --stage-name "$STAGE_NAME" \
    --auto-deploy > /dev/null

# Obtener URL de invocación
API_URL="https://$API_ID.execute-api.$REGION.amazonaws.com/$STAGE_NAME"

echo ""
echo "=== API Gateway creado exitosamente ==="
echo ""
echo "API ID: $API_ID"
echo "URL: $API_URL"
echo ""
echo "Endpoints:"
echo "  GET    $API_URL/movies"
echo "  GET    $API_URL/status/{user_id}"
echo "  POST   $API_URL/rent"