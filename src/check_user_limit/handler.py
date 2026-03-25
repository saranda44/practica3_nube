"""
check_user_limit - Estado 3 de la Step Function

Flujo en la Step Function:
1. Input: { "movie_id": 123, "user_id": "1"}
2. Ejecutar check_user_limit
   - Si usuario tiene < 2 rentas activas -> puede rentar -> continuar
   - Si usuario tiene >= 2 rentas activas -> ha alcanzado límite -> retorna error
"""

import json
import sys

# Importar la función específica de db_utils
sys.path.insert(0, '/var/task')
from db_utils import get_user_active_rentals_count


def main(event, context):
    try:
        print("=" * 70)
        print("ESTADO 3: check_user_limit")
        print("=" * 70)
        
        # Extraer parámetros del evento (que vienen del paso anterior)
        movie_id = event.get('movie_id')
        user_id = event.get('user_id')
        
        # =====================================================================
        # VERIFICAR LÍMITE DE RENTAS DEL USUARIO
        # =====================================================================
        
        print(f"\n Verificando límite de rentas del usuario {user_id}...")
        
        # get_user_active_rentals_count() retorna un entero con el número de rentals activos
        rental_count = get_user_active_rentals_count(user_id)
        
        print(f" Usuario {user_id} tiene {rental_count} renta(s) activa(s)")
        
        # Si ya tiene 2, no puede rentar más
        if rental_count >= 2:
            # Retornar objeto de error
            error_output = {
                'error': 'User has reached the rental limit',
                'user_id': user_id
            }
            
            print(f"error_output: {error_output}")
            return error_output
        
        # =====================================================================
        # RETORNAR OUTPUT 
        # =====================================================================
        
        # Retornar el evento para el siguiente paso
        output = {
            'movie_id': movie_id,
            'user_id': user_id
        }
        
        print(f"\n check_user_limit completado exitosamente")
        print(f" Pasando al siguiente estado: create_rental")
        print("=" * 70)
        
        return output
    
    except Exception as e:
        # Error inesperado
        print(f"\n ERROR INESPERADO: {type(e).__name__}: {str(e)}")
        print("=" * 70)
        raise