# practica3_nube
Para realizar el despliegue completo de la infraestructura dentro de la Sandbox de AWS, sigue cuidadosamente los pasos desde la consola de AWS CloudShell.

1. Clonación del proyecto

Primero, descarga el repositorio oficial que contiene los scripts de automatización:

git clone https://github.com/saranda44/practica3_nube.git
cd practica3_nube
2. Navegación a los scripts de infraestructura

Todo el proceso de despliegue se encuentra centralizado en la siguiente carpeta:

cd infra/scripts/
3. Ejecución del despliegue automatizado

Los scripts deben ejecutarse en orden numérico, ya que cada uno depende del anterior. Asegúrate de correrlos de forma secuencial.

🔹 Fase 1: Capa de Datos (RDS)

En esta fase se configura la base de datos y su estructura:

sh 01_create_rds.sh

Provisiona una base de datos PostgreSQL en Amazon RDS.

sh 02_create_secrets.sh

Configura credenciales y parámetros de seguridad.

sh 03_setup_tables.sh

Crea las tablas principales (movies y rentals) mediante DDL.

sh 04_load_movies.sh

Realiza la carga inicial del catálogo de películas.

🔹 Fase 2: Cómputo y Orquestación

Aquí se despliega la lógica de negocio usando servicios serverless:

sh 05_package_lambdas.sh

Empaqueta las funciones Lambda junto con sus dependencias.

sh 06_create_lambdas.sh

Crea las funciones Lambda en AWS.

sh 07_create_step_function.sh

Despliega la máquina de estados (Step Functions) para validación de límites.

🔹 Fase 3: Exposición y Notificaciones

En esta fase se habilita la comunicación externa y el sistema de alertas:

sh 08_create_api_gateway.sh

Configura la API HTTP y define las rutas.

sh 09_create_sns.sh

Crea el tópico SNS para el sistema de notificaciones.

sh 09b_apply_filters.sh

Aplica políticas de filtrado (SNS Filter Policies) para el aislamiento de mensajes.

sh 10_create_eventbridge.sh

Configura eventos programados para la ejecución diaria de alertas.
