"""
check_movie_exists - Estado 1 de la Step Function

Flujo:
1. Input: { "movie_id": 123, "user_id": "1" }
2. Ejecutar check_movie_exists
   - Si movie_id existe en tabla movies -> devuelve el evento 
   - Si movie_id NO existe -> retorna output con error
"""

import json
import sys

# Importar la función específica de db_utils
sys.path.insert(0, '/var/task')
from db_utils import get_movie_by_id


def main(event, context):
    try:
        print("=" * 70)
        print("ESTADO 1: check_movie_exists")
        print("=" * 70)
        
        # Extraer parámetros del evento
        movie_id = event.get('movie_id')
        user_id = event.get('user_id')
        
        # =====================================================================
        # VERIFICAR QUE LA PELÍCULA EXISTE
        # =====================================================================
        
        print(f"\n Verificando que película {movie_id} existe en la BD...")
        
        # Llamar a db_utils para obtener la película
        # get_movie_by_id() retorna un dict si existe, None si no existe
        movie = get_movie_by_id(movie_id)
        
        # Si no encontramos la película, retornar error
        if movie is None:
            # Retornar objeto de error (sin lanzar excepción)
            # El siguiente paso debe detectar este error y detener el flujo
            error_output = {
                'error': 'Movie does not exist',
                'movie_id': movie_id
            }
            
            print(f"error_output: {error_output}")            
            return error_output
        
        # =====================================================================
        # RETORNAR OUTPUT
        # =====================================================================
        
        # Retornar el evento 
        output = {
            'movie_id': movie_id,
            'user_id': user_id
        }
        
        print(f"\n check_movie_exists completado exitosamente")
        print(f" Pasando al siguiente estado: check_movie_available")
        print("=" * 70)
        
        return output
    
    except Exception as e:
        # Error inesperado
        print(f"\n ERROR INESPERADO: {type(e).__name__}: {str(e)}")
        print("=" * 70)
        raise