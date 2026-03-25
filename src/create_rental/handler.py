"""
create_rental - Estado 4 de la Step Function 

Flujo en la Step Function:
1. Input: { "movie_id": 123, "user_id": "1" }
2. Ejecutar create_rental
   - INSERT en tabla rentals
   - Si INSERT es exitoso -> retorna rental_id
   - Si INSERT falla -> retorna error
3. Step Function termina con el resultado
"""

import sys

# Importar la función específica de db_utils
sys.path.insert(0, '/var/task')
from db_utils import create_rental


def main(event, context):
    try:
        print("=" * 70)
        print("ESTADO 4: create_rental (FINAL)")
        print("=" * 70)
        
        # Extraer parámetros del evento (que vienen del paso anterior)
        movie_id = event.get('movie_id')
        user_id = event.get('user_id')
        
        # =====================================================================
        # INSERTAR LA RENTA EN LA BASE DE DATOS
        # =====================================================================
        
        print(f"\n Insertando renta en la base de datos...")
        
        try:
            # create_rental() retorna el rental_id si es exitoso
            rental_id = create_rental(movie_id, user_id)
            
            print(f" Renta insertada exitosamente en la BD")
            
        except Exception as db_error:
            # Error en la base de datos durante el INSERT
            error_output = {
                'error': 'Database error while creating rental',
                'details': str(db_error),
                'movie_id': movie_id,
                'user_id': user_id
            }

            print(f"error_output: {error_output}")
            return error_output
        
        
        # =====================================================================
        # RETORNAR OUTPUT DE ÉXITO
        # =====================================================================
        
        # Retornar información completa de la renta creada
        output = {
            'movie_id': movie_id,
            'user_id': user_id,
            'rental_id': rental_id
        }
        
        print(f"\n create_rental completado exitosamente")
        print(f" Paso FINAL de la Step Function")
        return output
    
    except Exception as e:
        # Error inesperado (no de BD)
        print(f"\n ERROR INESPERADO: {type(e).__name__}: {str(e)}")
        print("=" * 70)
        
        # Retornar error
        error_output = {
            'error': f'Unexpected error: {str(e)}',
            'movie_id': event.get('movie_id'),
            'user_id': event.get('user_id')
        }
        
        return error_output