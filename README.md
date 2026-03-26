# practica3_nube
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
