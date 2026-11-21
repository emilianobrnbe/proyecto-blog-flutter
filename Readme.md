Aplicación de Blog y Gestión de Usuarios
Este proyecto es un sistema de blog con control de usuarios conectado a una base de datos. Está formado por tres partes principales: una aplicación hecha en Flutter, un servidor en Python (FastAPI) y una base de datos en MySQL.

¿Qué hay en cada carpeta?
backend_API: Es el servidor que recibe las peticiones de la aplicación y guarda o consulta los datos en MySQL.

database: Contiene el archivo bd_aplicacion_movil.sql con las tablas listas para importar en MySQL.

flutter_application_1: Es toda la aplicación visual donde inician sesión los usuarios.

¿Qué puede hacer cada tipo de cuenta?
Administrador:

Crear, editar y eliminar publicaciones del blog (incluyendo subir imágenes).

Borrar comentarios de otros usuarios.

Ver el promedio de calificación de cada publicación.

Crear, editar y eliminar cuentas de usuario, eligiendo si serán administradores o usuarios normales.

Usuario normal:

Ver todas las publicaciones y leer su contenido completo.

Calificar las publicaciones con estrellas (del 1 al 5).

Escribir comentarios en las publicaciones.

Ver y editar los datos de su propio perfil, además de revisar el mapa.

Pasos para instalarlo y usarlo
1. Preparar la base de datos (MySQL)

Abre XAMPP o Laragon y enciende el servicio de MySQL.

Entra a phpMyAdmin en tu navegador.

Crea una base de datos nueva llamada bd_aplicacion_movil.

Entra a la pestaña Importar, selecciona el archivo database/bd_aplicacion_movil.sql y dale en Continuar.

2. Encender el servidor (FastAPI)

Abre una terminal dentro de la carpeta backend_API.

Activa el entorno de Python escribiendo venv\Scripts\activate.

Instala las librerías necesarias escribiendo pip install -r requirements.txt.

Verifica que el archivo .env tenga la ruta de conexión a tu base de datos local (DATABASE_URL=mysql+pymysql://root:@localhost:3306/bd_aplicacion_movil).

Enciende el servidor escribiendo uvicorn main:app --reload.

3. Abrir la aplicación (Flutter)

Abre otra terminal dentro de la carpeta flutter_application_1.

Descarga las librerías del proyecto escribiendo flutter pub get.

Ejecuta la aplicación escribiendo flutter run.