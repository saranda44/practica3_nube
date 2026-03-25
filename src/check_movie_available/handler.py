"""
check_movie_available - Estado 2 de la Step Function

Flujo:
1. Input: { "movie_id": 123, "user_id": "1" }
2. Ejecutar check_movie_available
   - Si película está DISPONIBLE (sin rentas activas) -> pasa al siguiente paso
   - Si película está RENTADA (tiene renta activa) -> retorna output con error
"""

import json
import sys

# Importar la función específica de db_utils
sys.path.insert(0, '/var/task')
from db_utils import get_available_movie_count


def main(event, context):
    try:
        print("=" * 70)
        print("ESTADO 2: check_movie_available")
        print("=" * 70)
        
        # Extraer parámetros del evento
        movie_id = event.get('movie_id')
        user_id = event.get('user_id')
        
        # =====================================================================
        # VERIFICAR QUE LA PELÍCULA ESTÁ DISPONIBLE
        # =====================================================================
        
        print(f"\n Verificando disponibilidad de película {movie_id}...")
        
        # get_available_movie_count() retorna:
        #   el número de rentas activas si la película está rentada
        #   0 si la película está disponible (sin rentas activas)
        active_rental = get_available_movie_count(movie_id)
        
        # Si existe un rental activo, la película NO está disponible
        if active_rental > 0:
            # Retornar objeto de error (sin lanzar excepción)
            # El siguiente paso debe detectar este error y detener el flujo
            error_output = {
                'error': 'Movie is not available',
                'movie_id': movie_id
            }
            
            print(f"error_output: {error_output}")
            
            return error_output
        
        print(f" Película {movie_id} está disponible (sin rentas activas)")
        
        # =====================================================================
        # RETORNAR OUTPUT 
        # =====================================================================
        
        # Retornar el evento
        output = {
            'movie_id': movie_id,
            'user_id': user_id,
        }
        
        print(f"\n check_movie_available completado exitosamente")
        print(f" Pasando al siguiente estado: check_user_limit")
        print("=" * 70)
        
        return output
    
    except Exception as e:
        # Error inesperado
        print(f"\n ERROR INESPERADO: {type(e).__name__}: {str(e)}")
        print("=" * 70)
        raise