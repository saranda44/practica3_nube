#!/bin/bash
set -e
export AWS_PAGER=cat

TOPIC_NAME="rentals-expiring-soon"

TOPIC_ARN=$(aws sns create-topic --name "$TOPIC_NAME" --query 'TopicArn' --output text)
echo "Topic creado: $TOPIC_ARN"

# Suscribir correos
echo "Suscribiendo correos..."
aws sns subscribe \
    --topic-arn "$TOPIC_ARN" \
    --protocol email \
    --notification-endpoint "luis.gonzaleze@iteso.mx"

aws sns subscribe \
    --topic-arn "$TOPIC_ARN" \
    --protocol email \
    --notification-endpoint "sara.aranda@iteso.mx"

aws sns subscribe \
    --topic-arn "$TOPIC_ARN" \
    --protocol email \
    --notification-endpoint "jair.aguilar@iteso.mx"

echo "Confirmar los correos antes de continuar"
