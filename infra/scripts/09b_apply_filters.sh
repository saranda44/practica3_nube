#!/bin/bash
set -e
export AWS_PAGER=cat

TOPIC_ARN=$(aws sns list-topics --query "Topics[?ends_with(TopicArn, ':rentals-expiring-soon')].TopicArn" --output text)

echo "Aplicando filtros en: $TOPIC_ARN"

SUBS=$(aws sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN" \
    --query 'Subscriptions[?Protocol==`email`].[SubscriptionArn,Endpoint]' --output text)

while IFS=$'\t' read -r SUB_ARN EMAIL; do
    if [ "$SUB_ARN" = "PendingConfirmation" ]; then
        echo "$EMAIL -> pendiente, saltando"
        continue
    fi

    case "$EMAIL" in
        "luis.gonzaleze@iteso.mx") USER_ID="1" ;;
        "sara.aranda@iteso.mx")   USER_ID="2" ;;
        "jair.aguilar@iteso.mx")  USER_ID="3" ;;
        *) continue ;;
    esac

    echo "$EMAIL -> filter user_id=$USER_ID"
    aws sns set-subscription-attributes \
        --subscription-arn "$SUB_ARN" \
        --attribute-name FilterPolicy \
        --attribute-value "{\"user_id\":[\"$USER_ID\"]}"
done <<< "$SUBS"

echo "Filtros aplicados"
