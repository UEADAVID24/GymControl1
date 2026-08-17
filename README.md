# 🏋️ GymControl

Aplicación móvil desarrollada como proyecto académico para la asignatura **Aplicaciones Móviles** de la **Universidad Estatal Amazónica (UEA)**.

GymControl permite gestionar rutinas de entrenamiento, ejercicios, registrar el peso corporal y administrar el perfil del usuario mediante una arquitectura cliente-servidor basada en Flutter y Flask.

---

# 📌 Objetivo

Desarrollar una aplicación móvil multiplataforma que permita organizar rutinas de entrenamiento, registrar ejercicios y controlar el progreso físico del usuario mediante un backend seguro y optimizado.

---

# 🚀 Tecnologías utilizadas

## Frontend

- Flutter 3.44.6
- Dart 3.12.2

## Backend

- Python
- Flask

## Base de datos

- PostgreSQL
- SQLAlchemy

## Seguridad

- JWT (JSON Web Token)

## Herramientas

- Visual Studio Code
- Android SDK 36.0.0
- Google Chrome
- Git
- GitHub
- Postman
- Render

---

# 📱 Framework multiplataforma seleccionado

Para el desarrollo de GymControl se seleccionó **Flutter**, debido a que permite desarrollar aplicaciones multiplataforma utilizando una única base de código escrita en Dart.

Esta elección facilita el mantenimiento del proyecto y permite trabajar con diferentes plataformas sin desarrollar una aplicación independiente para cada una. Además, Flutter dispone de Hot Reload, característica que permite visualizar rápidamente los cambios realizados durante el desarrollo.

---

# 🏗 Arquitectura

El proyecto utiliza una arquitectura Cliente-Servidor.

```text
Flutter
     │
HTTP / JSON
     │
Flask API
     │
JWT
SQLAlchemy
Cache
Worker
     │
PostgreSQL
```

---

# 📂 Estructura del proyecto

```text
GymControl/
│
├── android/
├── backend/
├── docs/
│   ├── 01-Constitucion-del-Proyecto.md
│   ├── 02-SDD.md
│   ├── 03-Arquitectura.md
│   ├── 04-API-REST.md
│   ├── 05-Optimizaciones.md
│   └── 06-Pruebas.md
│
├── ios/
├── lib/
│   ├── database/
│   ├── models/
│   ├── screens/
│   ├── services/
│   └── main.dart
│
├── test/
├── web/
├── pubspec.yaml
└── README.md
```

---

# ✨ Funcionalidades

- Registro de usuarios.
- Inicio de sesión mediante JWT.
- Gestión de rutinas.
- Gestión de ejercicios.
- Registro del peso corporal.
- Actualización del perfil.
- Consulta del historial de peso.
- Recordatorios.
- Procesamiento de tareas en segundo plano.
- Comunicación entre Flutter y la API Flask.

---

# ⚙️ Configuración del entorno de desarrollo

## Versiones verificadas

El entorno utilizado para desarrollar y ejecutar GymControl cuenta con las siguientes versiones:

```text
Flutter: 3.44.6
Dart: 3.12.2
DevTools: 2.57.0
Android SDK: 36.0.0
Java: OpenJDK 21
Sistema operativo: Windows 11 Pro 64-bit
```

---

# 🔍 Verificación del entorno

Para comprobar la instalación y configuración de Flutter se utiliza:

```bash
flutter doctor -v
```

También se pueden consultar los dispositivos disponibles mediante:

```bash
flutter devices
```

Durante las pruebas se detectaron los siguientes destinos:

- Google Chrome (Web)
- Microsoft Edge (Web)
- Windows Desktop

Para este taller se seleccionó **Google Chrome** como destino de ejecución, debido a que permite ejecutar y comprobar el proyecto Flutter utilizando los recursos disponibles en el equipo.

---

# 📦 Instalación de dependencias Flutter

Desde la carpeta principal del proyecto ejecutar:

```bash
flutter pub get
```

---

# ▶️ Ejecución del backend

Ingresar a la carpeta del backend:

```powershell
cd backend
```

Activar el entorno virtual:

```powershell
.\venv\Scripts\Activate.ps1
```

Instalar las dependencias cuando sea necesario:

```powershell
pip install -r requirements.txt
```

Ejecutar el backend:

```powershell
py run.py
```

El servidor local queda disponible en:

```text
http://127.0.0.1:5000
```

---

# 🌐 Configuración de la URL de la API

GymControl utiliza una variable de entorno de compilación para definir la dirección base de la API.

En `api_service.dart` se utiliza:

```dart
static const String apiRootUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:5000',
);
```

Para ejecutar Flutter Web indicando la URL del backend:

```powershell
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

De esta manera:

```text
Flutter Web: http://localhost:8080
Backend Flask: http://127.0.0.1:5000
```

---

# 🔐 Configuración de CORS

Durante el desarrollo se configuró CORS de manera limitada para permitir las solicitudes provenientes del entorno local utilizado por Flutter Web.

```python
cors.init_app(
    app,
    resources={
        r"/api/*": {
            "origins": "http://localhost:8080",
        },
    },
)
```

Esta configuración evita utilizar un origen abierto para todas las solicitudes y limita el acceso al host utilizado durante el desarrollo.

---

# 🔄 Hot Reload

Flutter permite aplicar cambios en la aplicación sin reiniciar completamente la ejecución.

Mientras `flutter run` se encuentra activo, se utiliza:

```text
r
```

La terminal confirma la operación mediante un mensaje similar a:

```text
Performing hot reload...
Reloaded application...
```

---

# 🔗 Verificación de conexión con el backend

Para comprobar la comunicación entre Flutter y Flask se implementó el endpoint:

```text
GET /api/v1/health
```

La aplicación realiza una solicitud HTTP hacia:

```text
http://127.0.0.1:5000/api/v1/health
```

Cuando la comunicación es exitosa, el backend responde con estado HTTP **200 OK** y la aplicación muestra:

```text
GymControl Backend - estado: ok
```

Esta prueba permite comprobar que la aplicación Flutter puede consumir correctamente un endpoint de la API propia de GymControl.

---

# ⚡ Optimizaciones implementadas

Durante el desarrollo del proyecto se aplicaron diversas optimizaciones al backend:

- Implementación de Cache Aside.
- Corrección del problema N+1 mediante Eager Loading (`joinedload()`).
- Procesamiento asíncrono mediante un worker.
- Optimización del proceso de autenticación con JWT.
- Reducción de consultas repetidas hacia PostgreSQL.

---

# 🔐 Seguridad

La aplicación implementa:

- Autenticación mediante JWT.
- Protección de rutas privadas.
- Contraseñas almacenadas mediante hash.
- Validación de usuarios autenticados.
- Variables de entorno para información sensible.
- Restricción CORS durante el desarrollo.

---

# ⚠️ Limitaciones y dificultades encontradas

Durante la configuración se presentaron algunas dificultades relacionadas con la comunicación entre Flutter Web y Flask.

Inicialmente, Chrome bloqueó la solicitud realizada desde Flutter debido a la política CORS, mostrando un error `Failed to fetch`. Para solucionarlo se configuró Flask-CORS y se autorizó específicamente el origen local utilizado por Flutter Web.

También se configuró el puerto 8080 de manera fija para mantener un origen conocido durante las pruebas.

El diagnóstico de Flutter indicó además que Visual Studio no se encuentra instalado para el desarrollo de aplicaciones Windows. Esta situación no afecta la ejecución prevista para este taller, debido a que se utilizó Google Chrome como destino de Flutter Web.

---

# 🧪 Pruebas realizadas

Se verificó el funcionamiento de:

- Ejecución del proyecto Flutter.
- Hot Reload.
- Ejecución del backend Flask.
- Registro de usuarios.
- Inicio de sesión.
- Gestión de rutinas.
- Gestión de ejercicios.
- Registro de peso.
- Perfil de usuario.
- API REST mediante Postman.
- Comunicación Flutter → Flask.
- Endpoint `/api/v1/health`.
- Respuesta HTTP exitosa del backend.

---

# 📖 Documentación

La documentación técnica del proyecto se encuentra en la carpeta **docs/**.

- Constitución del Proyecto.
- Software Design Description (SDD).
- Arquitectura.
- API REST.
- Optimizaciones.
- Pruebas.

---

# 📹 Video de demostración

Agregar aquí el enlace al video solicitado por el docente cuando esté disponible.

```text
https://colocar-aqui-el-enlace-del-video
```

---

# 👨‍💻 Autor

**Clinton David Alvarado Chongo**

Universidad Estatal Amazónica

Carrera de Ingeniería en Tecnologías de la Información

---

# 📅 Periodo académico

2025 - 2026

---

# 📄 Licencia

Proyecto desarrollado con fines exclusivamente académicos para la asignatura **Aplicaciones Móviles**.