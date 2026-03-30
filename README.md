# practica3_nube

<img width="1632" height="713" alt="image" src="https://github.com/user-attachments/assets/4a266a7e-41f0-4719-8c52-5599a552e222" />

En este laboratorio lo que hicimos fue montar una estructura serverless para que el sistema trabaje totalmente bajo demanda. Como se puede ver en nuestro diagrama el flujo arranca con el usuario mandando una petición al API Gateway que es el que recibe todo y decide el camino que debe seguir cada clic. Si solo quieres ver películas o checar tu estatus te manda a una Lambda pero si vas a rentar entra en juego la Step Function. Esta parte es clave porque funciona como un orquestador que valida paso a paso que la película esté disponible y que el usuario no tenga adeudos antes de autorizar el registro final en la base de datos.

Para proteger la información conectamos las Lambdas con Secrets Manager donde guardamos las credenciales de nuestro RDS en PostgreSQL así las contraseñas nunca aparecen escritas en el código que subimos a GitHub. De esta forma el sistema obtiene los permisos solo cuando necesita hacer una consulta SQL para mover datos. Por otro lado también implementamos un sistema de alertas donde una Lambda revisa los tiempos de entrega y le avisa al SNS que es el encargado de mandar el correo automático al usuario.Con este diseño logramos que todos los servicios de AWS se integren correctamente haciendo que la aplicación sea segura escalable y que funcione de manera automática sin necesidad de estar administrando servidores manualmente cada vez que un usuario interactúa con el sistema.

---

## Guia de Despliegue en AWS CloudShell

Para realizar el despliegue completo de la infraestructura en la Sandbox de AWS, sigue los siguientes pasos desde la consola de AWS CloudShell.

---

## 1. Clonacion del Proyecto

Clona el repositorio oficial:

```bash
git clone https://github.com/saranda44/practica3_nube.git
cd practica3_nube
cd infra/scripts/
chmod +x *.sh
```

##Ejecucion por Fases
Fase 1: Capa de Datos (RDS)
```bash
bash 01_create_rds.sh
bash 02_create_secrets.sh
bas 03_setup_tables.sh
bashsh 04_load_movies.sh
```
##Fase 2: Computo y Orquestacion
```bash
bash 05_package_lambdas.sh
bash 06_create_lambdas.sh
bash 07_create_step_function.sh
```
##Fase 3: Exposicion y Notificaciones
```bash
bash 08_create_api_gateway.sh
bash 09_create_sns.sh
bash 09b_apply_filters.sh
bash 10_create_eventbridge.sh
```
