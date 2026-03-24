"""
GET /status/{user_id} - Obtiene todas las rentas activas de un usuario

Flujo:
1. API Gateway recibe GET /status/1
2. Extrae el path parameter {user_id} = "1"
3. Llama a esta Lambda con el user_id
4. Consultamos RDS: obtener todos los rentals activos del usuario
5. Retornamos JSON con título, fecha inicio y fecha expiración

Respuesta esperada:
[
  {
    "rental_id": 1,
    "title": "Toy Story (1995)",
    "rented_at": "2026-03-12T10:00:00",
    "expires_at": "2026-03-19T10:00:00"
  },
]

Si el usuario no tiene rentas activas, retorna:
[]

Errores posibles:
- Path parameter {user_id} no proporcionado -> HTTP 400
- Error en BD -> HTTP 500
"""

import json
import sys

from datetime import date, datetime

# Importar la función específica de db_utils
sys.path.insert(0, '/var/task')
from db_utils import get_user_active_rentals


def json_serializer(value):
    """Convierte fechas/datetimes de PostgreSQL a strings ISO para JSON."""
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    raise TypeError(f"Object of type {type(value).__name__} is not JSON serializable")

def main(event, context):
    """
    Event típico de API Gateway (HTTP API v2):
    {
      "pathParameters": {
        "user_id": "1"
      },
    }
    """
    
    try:
        print("=" * 70)
        print("INICIANDO: GET /status/{user_id}")
        print("=" * 70)
        
        # Extraer parámetro de la ruta
        # pathParameters puede ser None si no hay parámetros
        path_params = event.get('pathParameters') or {}
        user_id = path_params.get('user_id')
        
        # Validar que se proporcionó el path parameter {user_id}
        if not user_id:
            print("path parameter 'user_id' vacío o no proporcionado")
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': json.dumps({
                    'error': 'Path parameter "user_id" requerido y no puede estar vacío',
                    'example': 'GET /status/1'
                })
            }
        
        print(f"Obteniendo rentas activas del usuario: '{user_id}'")
        
        # Llamar a la función específica de db_utils
        # retorna una lista de rentals activos con títulos
        rentals = get_user_active_rentals(user_id)
        
        print(f"Usuario tiene {len(rentals)} renta(s) activa(s)")
        
        # Retornar los rentals como JSON
        # Si no tiene rentas, retorna [] (array vacío)
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps(rentals, default=json_serializer)
        }
    
    except Exception as e:
        print(f"ERROR en GET /status/{user_id}: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'error': 'Error interno del servidor',
                'details': str(e)
            })
        }