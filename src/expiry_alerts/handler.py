"""
expiry_alerts - Lambda disparada por EventBridge diariamente

Flujo:
1. EventBridge dispara esta Lambda una vez al dia
2. Consulta rentas activas que vencen en los proximos 3 dias (modificable para hacer pruebas :o)
3. Por cada renta, publica un mensaje en SNS con el user_id como MessageAttribute
4. SNS Filter Policies se encargan de que cada usuario reciba solo sus alertas
"""

import json
import sys
import boto3
import os
from datetime import datetime

sys.path.insert(0, '/var/task')
from db_utils import get_db_connection

sns_client = boto3.client('sns', region_name='us-east-1')

TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')


def get_expiring_rentals():
    conn = get_db_connection()
    cur = conn.cursor()

    try:
        sql = """
            SELECT r.id, r.user_id, m.title, r.expires_at
            FROM rentals r
            JOIN movies m ON r.movie_id = m.movieId
            WHERE r.returned_at IS NULL
              AND r.expires_at BETWEEN NOW() AND NOW() + INTERVAL '3 days'
            ORDER BY r.expires_at ASC
        """
        cur.execute(sql)
        columns = [desc[0] for desc in cur.description]
        return [dict(zip(columns, row)) for row in cur.fetchall()]
    finally:
        cur.close()


def main(event, context):
    try:
        print("=" * 70)
        print("INICIANDO: expiry_alerts")
        print("=" * 70)

        if not TOPIC_ARN:
            print("Error: SNS_TOPIC_ARN no configurado")
            return {"error": "SNS_TOPIC_ARN no configurado"}

        rentals = get_expiring_rentals()
        print(f"Rentas por vencer: {len(rentals)}")

        for rental in rentals:
            days_left = (rental['expires_at'] - datetime.now()).days
            message = (
                f"Tu renta de '{rental['title']}' vence en {days_left} dia(s). "
                f"Fecha de vencimiento: {rental['expires_at'].isoformat()}"
            )

            print(f"  Enviando alerta a user_id={rental['user_id']}: {rental['title']}")

            sns_client.publish(
                TopicArn=TOPIC_ARN,
                Subject="FilmRentals - Renta por vencer",
                Message=message,
                MessageAttributes={
                    "user_id": {
                        "DataType": "String",
                        "StringValue": str(rental['user_id'])
                    }
                }
            )

        print(f"\n{len(rentals)} alerta(s) enviada(s)")
        return {"alerts_sent": len(rentals)}

    except Exception as e:
        print(f"Error en expiry_alerts: {str(e)}")
        raise
