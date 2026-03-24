"""
GET /movies?name=toy - Busca películas por título

Flujo:
1. API Gateway recibe GET /movies?name=toy
2. Llama a esta Lambda con un event que contiene queryStringParameters
3. Extraemos el parámetro 'name'
4. Consultamos RDS: SELECT * FROM movies WHERE title ILIKE '%toy%'
5. Para cada película, consultamos si tiene una renta activa
   (renta activa = existe un registro en rentals con movie_id=X y returned_at=NULL)
6. Retornamos JSON con película, título e is_rented

Respuesta esperada:
[
  { "movie_id": 1, "title": "Toy Story (1995)", "is_rented": false },
  { "movie_id": 3114, "title": "Toy Story 2 (1999)", "is_rented": true }
]
"""

import json
import sys

# Importar db_utils que está en la carpeta src/db_utils/
# En el paso de empaquetamiento, db_utils.py se copia junto a handler.py
sys.path.insert(0, '/var/task')  # Path donde Lambda descomprime el zip
from db_utils import get_movies_by_name


def main(event, context):
    """
    Event de API Gateway:
    {
      "queryStringParameters": {
        "name": "toy"
      }
    }
    """
    
    try:
        print("=" * 70)
        print("INICIANDO: GET /movies")
        print("=" * 70)
        # Extraer parámetro 'name' de la query string
        query_params = event.get('queryStringParameters') or {}
        search_term = query_params.get('name')
        
        # Validar que se proporcionó el término de búsqueda
        if not search_term:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Parámetro "name" requerido'
                })
            }
        

        movies = get_movies_by_name(search_term)
        
        # Respuesta exitosa
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps(movies)
        }
    
    except Exception as e:
        print(f"Error en get_movies: {str(e)}")
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Error interno del servidor',
                'details': str(e)
            })
        }