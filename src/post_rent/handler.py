"""
POST /rent

Flujo:
1. API Gateway recibe POST /rent con body: { "movie_id": 123, "user_id": "1" }
2. Esta Lambda valida que los parámetros sean válidos
3. Inicia la Step Function de forma asincrona
4. Retorna execution_arn y estado RUNNING
5. El cliente puede consultar el resultado con GET /status/1

Respuesta exitosa (renta iniciada):
{
  "execution_arn": "arn:aws:states:us-east-1:...",
  "status": "RUNNING",
  "message": "Renta iniciada. Consulta GET /status/1 para ver el resultado"
}
"""

import json
import boto3
import os

# Cliente para Step Functions
sfn_client = boto3.client('stepfunctions', region_name='us-east-1')

# Obtener el ARN de la Step Function desde variables de ambiente
STATE_MACHINE_ARN_LOCAL = os.environ.get('STATE_MACHINE_ARN')


def main(event, context):
    """
    Event de API Gateway (HTTP POST):
    {
      "body": "{\"movie_id\": 123, \"user_id\": \"1\"}",  Body viene como STRING
      "headers": {
        "Content-Type": "application/json"
      }
    }
    """
    
    try:
        print("=" * 70)
        print("INICIANDO: POST /rent")
        print("=" * 70)
        
        # Verificar que la Step Function ARN está configurada
        if not STATE_MACHINE_ARN_LOCAL:
            print("Error: STATE_MACHINE_ARN no esta configurado en variables de ambiente")
            return {
                'statusCode': 500,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'error': 'STATE_MACHINE_ARN no esta configurado en la Lambda'
                })
            }
        
        # Extraer el body de la solicitud
        body = event.get('body')
        
        # Si el body es un string parsearlo como JSON
        if isinstance(body, str):
            try:
                body = json.loads(body)
            except json.JSONDecodeError as e:
                return {
                    'statusCode': 400,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'error': 'Body no es JSON válido'
                    })
                }
        
        # Extraer parámetros del body
        movie_id = body.get('movie_id')
        user_id = body.get('user_id')
        
        # =====================================================================
        # VALIDACIONES DE INPUT
        # =====================================================================
        
        # Validar que movie_id existe
        if movie_id is None:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'error': 'Campo requerido faltante: movie_id'
                })
            }
        
        # Validar que user_id existe
        if not user_id:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'error': 'Campo requerido faltante: user_id'
                })
            }
        
        # Convertir user_id a string (por si acaso viene como número)
        user_id = str(user_id)
        
        # =====================================================================
        # INICIAR STEP FUNCTION
        # =====================================================================
        try:
            execution = sfn_client.start_execution(
                stateMachineArn=STATE_MACHINE_ARN_LOCAL,
                input=json.dumps({
                    'movie_id': movie_id,
                    'user_id': user_id
                })
            )
            
            print(f"Step Function iniciada exitosamente")
            print(f"Execution ARN: {execution['executionArn']}")
            
        except Exception as e:
            print(f"Error al iniciar Step Function: {e}")
            return {
                'statusCode': 500,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'error': 'Error al iniciar la Step Function',
                    'details': str(e)
                })
            }
        
        # =====================================================================
        # RESPUESTA AL CLIENTE
        # =====================================================================
        
        # Respuesta al cliente indicando que el proceso está en curso
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'execution_arn': execution['executionArn'],
                'status': 'RUNNING',
                'message': 'Renta iniciada. Consulta GET /status/{user_id} para ver el resultado'
            })
        }
    
    except Exception as e:
        # Loguear el error inesperado para CloudWatch
        print(f"ERROR en POST /rent: {str(e)}")
        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': 'Error interno del servidor',
                'details': str(e)
            })
        }