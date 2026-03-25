#!/bin/bash
set -e
export AWS_PAGER=cat


TOPIC_ARN=$(aws sns list-topics --query "Topics[?ends_with(TopicArn, ':rentals-expiring-soon')].TopicArn" --output text)

if [ -z "$TOPIC_ARN" ]; then
    echo "Error: topic rentals-expiring-soon no encontrado"
    exit 1
fi

# editar mapeo email a user_id
declare -A EMAIL_TO_USER=(
    ["luis.gonzaleze@iteso.mx"]="1"
    ["sara.aranda@iteso.mx"]="2"
    ["jair.aguilar@iteso.mx"]="3"
)

SUBS=$(aws sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN" \
    --query 'Subscriptions[?Protocol==`email`].[SubscriptionArn,Endpoint]' --output text)

while IFS=$'\t' read -r SUB_ARN EMAIL; do
    if [ "$SUB_ARN" = "PendingConfirmation" ]; then
        echo "$EMAIL -> pendiente, saltando"
        continue
    fi

    USER_ID="${EMAIL_TO_USER[$EMAIL]}"
    if [ -n "$USER_ID" ]; then
        echo "$EMAIL -> filter user_id=$USER_ID"
        aws sns set-subscription-attributes \
            --subscription-arn "$SUB_ARN" \
            --attribute-name FilterPolicy \
            --attribute-value "{\"user_id\":[\"$USER_ID\"]}"
    fi
done <<< "$SUBS"

echo "Filter Policies aplicados"
