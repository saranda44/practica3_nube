#!/bin/bash
set -e
export AWS_PAGER=cat

TOPIC_NAME="rentals-expiring-soon"

TOPIC_ARN=$(aws sns create-topic --name "$TOPIC_NAME" --query 'TopicArn' --output text)
echo "Topic: $TOPIC_ARN"

# editar correos
declare -a SUBSCRIPTIONS=(
    "1 luis.gonzaleze@iteso.mx"
    "2 sara.aranda@iteso.mx"
    "3 jair.aguilar@iteso.mx"
)

for sub in "${SUBSCRIPTIONS[@]}"; do
    USER_ID=$(echo $sub | awk '{print $1}')
    EMAIL=$(echo $sub | awk '{print $2}')

    echo "Suscribiendo user_id=$USER_ID -> $EMAIL"
    aws sns subscribe \
        --topic-arn "$TOPIC_ARN" \
        --protocol email \
        --notification-endpoint "$EMAIL" > /dev/null
done

echo "se tiene que confirmar los correos antes de avanzar al siguiente paso"