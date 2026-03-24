"""
Funciones:
  - get_movies_by_name(search_term)      -> Busca películas y retorna si están rentadas
  - get_movie_by_id(movie_id)            -> Valida que existe una película
  - get_available_movie(movie_id)        -> Obtiene el conteo de rentals activos de una película (si existe)
  - get_user_active_rentals(user_id)     -> Obtiene todos los rentals activos de un usuario
  - get_user_active_rentals_count(user_id) -> Obtiene el conteo de rentals activos de un usuario
  - create_rental(movie_id, user_id)     -> Crea una nueva renta
"""

import json
import pg8000
import boto3
from typing import List, Dict, Any, Optional

# Cliente de Secrets Manager para obtener credenciales
secrets_client = boto3.client('secretsmanager', region_name='us-east-1')

# Variable global para cachear la conexión
_db_connection = None


def get_secrets() -> Dict[str, str]:
    """
    Obtiene las credenciales de RDS desde Secrets Manager
    
    Retorna diccionario con:
      - 'host': hostname de RDS
      - 'username': usuario 
      - 'password': contraseña
    """
    try:
        # Obtener hostname de RDS
        host_secret = secrets_client.get_secret_value(
            SecretId='filmrentals/rds/host'
        )
        host = host_secret['SecretString'].strip()
        
        # Obtener username y password como JSON
        credentials_secret = secrets_client.get_secret_value(
            SecretId='filmrentals/rds/credentials'
        )
        credentials = json.loads(credentials_secret['SecretString'])
        username = credentials.get('username')
        password = credentials.get('password')
        
        return {
            'host': host,
            'username': username,
            'password': password
        }
    except Exception as e:
        print(f"Error al obtener secretos de Secrets Manager: {e}")
        raise


def get_db_connection():
    """
    Establece una conexión a RDS PostgreSQL
    cachear la conexión en Lambda para reutilizarla entre invocaciones
    """
    global _db_connection
    
    # Si ya existe una conexión y está abierta, reutilizarla
    if _db_connection is not None:
        try:
            # Verificar que la conexión sigue viva 
            cur = _db_connection.cursor()
            cur.execute("SELECT 1")
            cur.close()
            print("Reutilizando conexión existente a RDS")
            return _db_connection
        except:
            # Si conexión murió, crearla de nuevo
            print("Conexión anterior falló, creando nueva...")
            _db_connection = None
    
    # Obtener credenciales desde Secrets Manager
    secrets = get_secrets()
    
    try:
        # Conectar a RDS
        _db_connection = pg8000.connect(
            host=secrets['host'],
            port=5432,
            database='filmrentals',
            user=secrets['username'],
            password=secrets['password'],
            ssl_context=True, 
            timeout=5
        )
        print("Conexión a RDS establecida exitosamente")
        return _db_connection
    
    except pg8000.OperationalError as e:
        print(f"Error al conectar a RDS: {e}")
        raise

# ============================================================================
# Queries
# ============================================================================

def get_movies_by_name(search_term: str, limit: int = 20) -> List[Dict[str, Any]]:
    """
    Busca películas por nombre
    verifica si tiene una renta activa (sin returned_at)
    
    Args:
      search_term: término a buscar 
      limit: máximo número de resultados
    
    Retorna:
      Lista de diccionarios con:
        - movie_id (int): ID de la película
        - title (str): Título de la película
        - is_rented (bool): True si tiene una renta activa, False si está disponible
    
    Ejemplo:
      movies = get_movies_by_name("toy")
      # [
      #   {"movie_id": 1, "title": "Toy Story (1995)", "is_rented": false},
      #   {"movie_id": 3114, "title": "Toy Story 2 (1999)", "is_rented": true}
      # ]
    """
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        sql = """
          SELECT movieId AS movie_id, title
          FROM movies
          WHERE title ILIKE $1
          LIMIT $2
        """
        # %term% para buscar el término en cualquier parte del título (case-insensitive)
        cur.execute(sql, (f'%{search_term}%', limit))
        
        columns = [desc[0] for desc in cur.description]
        movies = [dict(zip(columns, row)) for row in cur.fetchall()]
        
        # Para cada película, verificar si está rentada
        result = []
        for movie in movies:
            movie_id = movie['movie_id']
            
            # Contar rentas activas de esta película
            rental_sql = """
                SELECT COUNT(*) as count 
                FROM rentals 
                WHERE movie_id = $1 AND returned_at IS NULL
            """
            cur.execute(rental_sql, (movie_id,))
            rental_count = cur.fetchone()[0]
            is_rented = rental_count > 0
            
            result.append({
                'movie_id': movie_id,
                'title': movie['title'],
                'is_rented': is_rented
            })
        print(f"Resultados procesados con estado de renta (rentada o disponible)")
        print(result)
        
        return result
    
    except Exception as e:
        print(f"Error en get_movies_by_name: {e}")
        raise
    
    finally:
        cur.close()


def get_movie_by_id(movie_id: int) -> Optional[Dict[str, Any]]:
    """
    Obtiener una película por ID
    
    Args:
      movie_id
    
    Retorna:
      Diccionario con: movie_id, title, genres
      None si la película no existe
    
    Ejemplo:
      movie = get_movie_by_id(1)
      # {"movie_id": 1, "title": "Toy Story (1995)", "genres": "Adventure|Animation|Children|Comedy|Fantasy"}
      
      movie = get_movie_by_id(99999)
      # None
    """
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        sql = """
            SELECT movieId as movie_id, title, genres 
            FROM movies 
            WHERE movieId = $1
        """
        
        cur.execute(sql, (movie_id,))
        row = cur.fetchone()
        
        if not row:
            print(f"Película con ID {movie_id} no encontrada")
            return None
        
        columns = [desc[0] for desc in cur.description]
        result = dict(zip(columns, row))
        
        print(f"Película encontrada: {result['title']}")
        return result
    
    except Exception as e:
        print(f"Error en get_movie_by_id: {e}")
        raise
    
    finally:
        cur.close()


def get_available_movie_count(movie_id: int) -> int:
    """
    Cuenta cuántas rentas activas tiene una película
    renta activa = no tiene returned_at

    Args:
      movie_id: ID de la película

    Retorna:
      int: número de rentas activas (puede ser 0)

    Ejemplo:
      # Película está rentada
      count = get_available_movie_count(1)
      # 1

      # Película está disponible
      count = get_available_movie_count(3)
      # 0
      
      # Película está disponible (no hay rentas activas)
      count = get_available_movie_count(3)
      # 0
    """
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        # Buscar rentas activas para esta película
        sql = """
            SELECT COUNT(*) as count
            FROM rentals 
            WHERE movie_id = $1 AND returned_at IS NULL
        """
        
        cur.execute(sql, (movie_id,))
        row = cur.fetchone()
        
        if not row:
            print(f"Película {movie_id} está disponible (sin rentas activas)")
            return 0
        
        columns = [desc[0] for desc in cur.description]
        result = dict(zip(columns, row))
        
        print(f"Película {movie_id} tiene {result['count']} renta(s) activa(s)")
        return result['count']
    
    except Exception as e:
        print(f"Error en get_available_movie_count: {e}")
        raise
    
    finally:
        cur.close()


def get_user_active_rentals(user_id: str) -> List[Dict[str, Any]]:
    """
    Obtiene todos los rentals activos de un usuario

      rentals = get_user_active_rentals("1")
      # [
      #   {
      #     "id": 1,
      #     "movie_id": 1,
      #     "title": "Toy Story (1995)",
      #     "rented_at": "2026-03-12T10:00:00",
      #     "expires_at": "2026-03-19T10:00:00",
      #     "returned_at": None
      #   },
      # ]
      
      # Usuario sin rentas activas
      rentals = get_user_active_rentals("5")
      # []
    """
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        sql = """
            SELECT 
                r.id,
                r.movie_id,
                m.title,
                r.rented_at,
                r.expires_at,
                r.returned_at
            FROM rentals r
            JOIN movies m ON r.movie_id = m.movieId
            WHERE r.user_id = $1 AND r.returned_at IS NULL
            ORDER BY r.expires_at ASC
        """
        
        cur.execute(sql, (user_id,))
        
        columns = [desc[0] for desc in cur.description]
        results = [dict(zip(columns, row)) for row in cur.fetchall()]
        
        print(f"Usuario {user_id} tiene {len(results)} renta(s) activa(s)")
        
        return results
    
    except Exception as e:
        print(f"Error en get_user_active_rentals: {e}")
        raise
    
    finally:
        cur.close()

def get_user_active_rentals_count(user_id: str) -> int:
    """
    Obtiene el número de rentals activos de un usuario
    """
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        sql = """
            SELECT COUNT(*) 
            FROM rentals 
            WHERE user_id = $1 AND returned_at IS NULL
        """
        
        cur.execute(sql, (user_id,))
        count = cur.fetchone()[0]
        
        print(f"Usuario {user_id} tiene {count} renta(s) activa(s)")
        
        return count
    
    except Exception as e:
        print(f"Error en get_user_active_rentals_count: {e}")
        raise
    
    finally:
        cur.close()

def create_rental(movie_id: int, user_id: str) -> int:
    """
    Crea una nueva renta 
    """
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        sql = """
            INSERT INTO rentals (movie_id, user_id, rented_at, expires_at)
            VALUES ($1, $2, NOW(), NOW() + INTERVAL '7 days')
            RETURNING id
        """
        
        cur.execute(sql, (movie_id, user_id))
        
        # Obtener el ID de la renta creada
        result = cur.fetchone()
        rental_id = result[0] if result else -1
        
        # Confirmar los cambios en la BD
        conn.commit()
        
        print(f"Renta creada: ID {rental_id} (película {movie_id}, usuario {user_id})")
        return rental_id
    
    except Exception as e:
        # Si hay error, deshacer los cambios
        conn.rollback()
        print(f"Error en create_rental: {e}")
        raise
    
    finally:
        cur.close()


def close_connection():
    """
    Cierra la conexión a RDS
    """
    global _db_connection
    if _db_connection is not None:
        _db_connection.close()
        _db_connection = None
        print("Conexión a RDS cerrada")