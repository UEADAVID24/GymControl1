# 🏋️ GymControl

Aplicación móvil desarrollada como proyecto académico para la asignatura **Aplicaciones Móviles** de la **Universidad Estatal Amazónica (UEA)**.

GymControl permite gestionar rutinas de entrenamiento, ejercicios, registrar el peso corporal, administrar el perfil del usuario y mantener una sesión autenticada mediante una arquitectura cliente-servidor basada en Flutter y Flask.

---

# 📌 Objetivo

Desarrollar una aplicación móvil multiplataforma que permita organizar rutinas de entrenamiento, registrar ejercicios, controlar el progreso físico del usuario y gestionar de forma segura el acceso a las diferentes funcionalidades mediante autenticación y manejo de estado.

---

# 🚀 Tecnologías utilizadas

## Frontend

- Flutter 3.44.6
- Dart 3.12.2
- Provider 6.1.5+1
- HTTP
- SharedPreferences

## Backend

- Python
- Flask

## Base de datos

- PostgreSQL
- SQLAlchemy

## Seguridad

- JWT (JSON Web Token)
- Protección de funcionalidades autenticadas
- Validación de credenciales

## Herramientas

- Visual Studio Code
- Android Studio
- Android SDK 36.0.0
- Visual Studio Community 2026
- Windows SDK
- Google Chrome
- Git
- GitHub
- Postman
- Render

---

# 📱 Framework multiplataforma seleccionado

Para el desarrollo de GymControl se seleccionó **Flutter**, debido a que permite desarrollar aplicaciones multiplataforma utilizando una única base de código escrita en Dart.

Esta elección facilita el mantenimiento del proyecto y permite trabajar con diferentes plataformas sin desarrollar una aplicación independiente para cada una. Además, Flutter dispone de **Hot Reload**, característica que permite visualizar rápidamente los cambios realizados durante el desarrollo.

Flutter también proporciona herramientas para compilar y ejecutar aplicaciones en Android, web y escritorio, lo que facilita las pruebas del proyecto utilizando diferentes destinos de ejecución.

---

# 🏗 Arquitectura

El proyecto utiliza una arquitectura Cliente-Servidor.

```text
Flutter
   │
   │ HTTP / JSON
   │
Flask API
   │
   ├── JWT
   ├── SQLAlchemy
   ├── Cache
   └── Worker
   │
PostgreSQL
```

Flutter funciona como cliente y realiza solicitudes HTTP hacia la API REST desarrollada con Flask.

El backend se encarga de procesar las solicitudes, aplicar las reglas de negocio, gestionar la autenticación y comunicarse con la base de datos.

Para el manejo del estado de autenticación en Flutter se utiliza **Provider**, permitiendo conservar los datos del usuario durante la navegación entre las diferentes pantallas.

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
│   ├── providers/
│   │   └── session_provider.dart
│   ├── screens/
│   ├── services/
│   └── main.dart
│
├── test/
├── web/
├── windows/
├── pubspec.yaml
└── README.md
```

La organización del código permite separar los modelos, pantallas, servicios y manejo de estado utilizados por la aplicación.

---

# ✨ Funcionalidades

GymControl implementa actualmente las siguientes funcionalidades:

- Registro de usuarios.
- Inicio de sesión mediante JWT.
- Validación de formularios.
- Manejo de credenciales incorrectas.
- Manejo del estado de autenticación mediante Provider.
- Protección de funcionalidades privadas.
- Navegación entre diferentes módulos.
- Gestión de rutinas.
- Gestión de ejercicios.
- Gestión de entrenamientos.
- Registro del peso corporal.
- Consulta del historial de peso.
- Gestión de recordatorios.
- Visualización y actualización del perfil.
- Persistencia del estado del usuario durante la navegación.
- Cierre de sesión.
- Protección del acceso después del cierre de sesión.
- Procesamiento de tareas en segundo plano.
- Comunicación entre Flutter y la API Flask.

---

# 🔑 Autenticación de usuarios

GymControl implementa un flujo de autenticación conectado directamente con el backend desarrollado en Flask.

El usuario puede registrarse mediante la aplicación y posteriormente utilizar sus credenciales para iniciar sesión.

Durante el inicio de sesión, Flutter envía las credenciales al backend. Si son correctas, la API devuelve la información correspondiente al usuario y los tokens de autenticación necesarios para realizar solicitudes protegidas.

Cuando la autenticación es correcta, la aplicación permite acceder al Dashboard y a las funcionalidades privadas de GymControl.

Cuando las credenciales son incorrectas, la aplicación no permite el acceso y muestra un mensaje comprensible al usuario.

Ejemplo:

```text
El correo o la contraseña son incorrectos.
```

---

# 📝 Formularios y validaciones

Los formularios de registro e inicio de sesión implementan validaciones antes de enviar información al backend.

## Inicio de sesión

El formulario comprueba:

- Correo electrónico obligatorio.
- Contraseña obligatoria.
- Formato válido del correo electrónico.
- Longitud mínima de la contraseña.
- Credenciales válidas.

Al dejar los campos vacíos se muestran mensajes como:

```text
El correo electrónico es obligatorio.
La contraseña es obligatoria.
```

Cuando el correo no posee un formato válido se muestra:

```text
Ingrese un correo electrónico válido.
```

## Registro

El formulario de creación de cuenta comprueba:

- Nombre obligatorio.
- Nombre con una longitud mínima.
- Correo electrónico obligatorio.
- Formato válido del correo.
- Contraseña obligatoria.
- Longitud mínima de la contraseña.

Ejemplos de mensajes:

```text
El nombre es obligatorio.
El correo electrónico es obligatorio.
La contraseña es obligatoria.
```

Estas validaciones evitan enviar información incompleta o con un formato incorrecto al backend.

---

# 🧠 Manejo de estado con Provider

GymControl utiliza **Provider** como mecanismo para administrar el estado de autenticación de la aplicación.

La dependencia utilizada es:

```text
provider: ^6.1.5+1
```

La clase responsable del estado de sesión se encuentra en:

```text
lib/providers/session_provider.dart
```

`SessionProvider` extiende `ChangeNotifier` y mantiene información relacionada con el usuario autenticado.

Entre los datos administrados se encuentran:

- Identificador del usuario.
- Nombre del usuario.
- Correo electrónico.
- Estado de autenticación.

Cuando el usuario inicia sesión correctamente, los datos recibidos desde el backend son almacenados en `SessionProvider`.

Esto permite conservar la información del usuario mientras navega entre diferentes pantallas de GymControl.

Cuando el estado cambia se utiliza:

```dart
notifyListeners();
```

De esta manera, los componentes que dependen del estado pueden reaccionar ante los cambios realizados en la sesión.

---

# 🧭 Navegación

GymControl permite navegar entre diferentes funcionalidades después de iniciar sesión.

Entre las principales pantallas disponibles se encuentran:

- Dashboard.
- Rutinas.
- Entrenamientos.
- Calendario.
- Recordatorios.
- Progreso.
- Peso.
- Perfil.
- Optimización.

Durante las pruebas se verificó especialmente el siguiente flujo:

```text
Login
  ↓
Dashboard
  ↓
Rutinas
  ↓
Dashboard
  ↓
Peso
  ↓
Dashboard
  ↓
Perfil
```

Durante este recorrido la sesión permanece activa y la información del usuario continúa disponible.

---

# 🔒 Protección de funcionalidades

Las funcionalidades privadas de GymControl requieren que exista una sesión autenticada.

El Dashboard consulta el estado administrado por `SessionProvider`.

Si no existe una sesión válida, el usuario es redirigido a:

```text
/login
```

Antes de abrir funcionalidades privadas también se comprueba el estado de autenticación.

De esta manera, un usuario que no haya iniciado sesión no debe acceder al contenido protegido de la aplicación.

---

# 🚪 Cierre de sesión

GymControl permite finalizar la sesión desde las funcionalidades correspondientes, incluyendo el perfil del usuario.

Antes de cerrar la sesión se solicita confirmación.

Al confirmar el cierre:

1. Se eliminan los datos de autenticación utilizados por la aplicación.
2. Se limpia la información almacenada en `SessionProvider`.
3. El estado de autenticación cambia a no autenticado.
4. Se elimina la navegación anterior correspondiente al área protegida.
5. El usuario es enviado nuevamente al inicio de sesión.

Después de cerrar sesión se comprobó que utilizar la navegación anterior del navegador no permite recuperar el Dashboard o las funcionalidades privadas.

Para acceder nuevamente es necesario iniciar sesión.

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
Visual Studio: Community 2026
Sistema operativo: Windows 11 Pro 64-bit
```

---

# 🖥️ Editor y extensiones

Para el desarrollo del proyecto se utilizó **Visual Studio Code** como editor de código.

Las principales extensiones utilizadas son:

- Flutter
- Dart

Estas extensiones permiten integrar las herramientas del SDK de Flutter con Visual Studio Code, ejecutar la aplicación, utilizar Hot Reload, depurar el código y facilitar el desarrollo en Dart.

También se utilizó **Android Studio** para disponer del Android SDK y de la cadena de herramientas necesaria para el desarrollo de aplicaciones Android.

Para completar la cadena de herramientas de Windows se instaló **Visual Studio Community 2026** con los componentes de desarrollo de escritorio con C++ requeridos por Flutter.

---

# 🔍 Verificación del entorno

Para comprobar la instalación y configuración de Flutter se utiliza:

```powershell
flutter doctor -v
```

Después de instalar y configurar todas las herramientas necesarias, el diagnóstico final confirmó correctamente:

- Flutter.
- Dart.
- Android SDK.
- Java.
- Google Chrome.
- Visual Studio Community 2026.
- Windows SDK.
- Dispositivos disponibles.
- Recursos de red.

El resultado final del diagnóstico fue:

```text
No issues found!
```

Esto confirma que el entorno de desarrollo requerido por Flutter se encuentra correctamente configurado.

También se pueden consultar los dispositivos disponibles mediante:

```powershell
flutter devices
```

Durante las pruebas se detectaron los siguientes destinos:

- Windows Desktop.
- Google Chrome (Web).
- Microsoft Edge (Web).

Para las pruebas se seleccionó **Google Chrome** como destino principal de ejecución, debido a que permite ejecutar y comprobar el proyecto mediante Flutter Web utilizando los recursos disponibles en el equipo.

Además, Chrome facilita las pruebas de comunicación entre la aplicación Flutter y el backend Flask ejecutado localmente.

---

# 📦 Instalación de dependencias Flutter

Desde la carpeta principal del proyecto ejecutar:

```powershell
flutter pub get
```

Este comando instala las dependencias declaradas en el archivo `pubspec.yaml`.

Entre las dependencias utilizadas se encuentra Provider para el manejo del estado:

```text
provider: ^6.1.5+1
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

Cuando Flask se encuentra funcionando correctamente, la terminal muestra que el servidor está disponible en el puerto 5000.

---

# 🌐 Configuración de la URL de la API

GymControl utiliza una variable de entorno de compilación para definir la dirección base de la API.

En el archivo:

```text
lib/services/api_service.dart
```

se utiliza:

```dart
static const String apiRootUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:5000',
);

static const String baseUrl = '$apiRootUrl/api/v1';
```

Para ejecutar Flutter Web indicando la dirección del backend se utiliza:

```powershell
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

De esta manera, el entorno utilizado durante la prueba queda configurado de la siguiente forma:

```text
Flutter Web: http://localhost:8080
Backend Flask: http://127.0.0.1:5000
```

El puerto 8080 se establece de forma fija para mantener un origen conocido durante las pruebas de comunicación con el backend.

La utilización de `API_BASE_URL` permite modificar la dirección del servidor sin cambiar directamente el código de la aplicación.

---

# 🔐 Configuración de CORS

Durante el desarrollo se configuró CORS de manera limitada para permitir únicamente las solicitudes provenientes del entorno local utilizado por Flutter Web.

En el backend Flask se utiliza:

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

Esta configuración evita utilizar un origen abierto para todas las solicitudes y limita el acceso al origen local utilizado durante el desarrollo.

Por lo tanto:

```text
Origen autorizado:
http://localhost:8080
```

De esta manera se autoriza de forma acotada el tráfico desde Flutter Web hacia el backend local.

---

# 🔄 Hot Reload

Flutter permite aplicar cambios en la aplicación sin reiniciar completamente su ejecución.

Primero se ejecuta la aplicación:

```powershell
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

Mientras `flutter run` se encuentra activo, se utiliza:

```text
r
```

La terminal confirma la operación mediante un mensaje similar a:

```text
Performing hot reload...
Reloaded application...
```

Esta funcionalidad facilita las pruebas y permite visualizar rápidamente los cambios realizados en el código.

Durante las pruebas de GymControl se comprobó correctamente el funcionamiento de Hot Reload.

Cuando se requiere reiniciar completamente el estado de la aplicación se puede utilizar:

```text
R
```

para realizar Hot Restart.

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

El endpoint devuelve información sobre el estado del servicio, caché y worker del backend.

Un ejemplo de la información devuelta por el backend es:

```json
{
  "service": "GymControl Backend",
  "status": "ok",
  "cache": "SimpleCache",
  "worker": "activo"
}
```

Desde Flutter se implementó una función encargada de realizar la solicitud HTTP hacia este endpoint.

En la interfaz de GymControl se agregó el botón:

```text
Probar conexión con API
```

Al presionarlo, Flutter realiza la solicitud hacia Flask.

Cuando la comunicación es exitosa, el backend responde con estado HTTP:

```text
200 OK
```

Y la aplicación muestra:

```text
GymControl Backend - estado: ok
```

Esta prueba comprueba que la aplicación Flutter puede realizar una solicitud hacia un endpoint de su propia API y recibir correctamente la respuesta enviada por el backend Flask.

---

# 🔐 Autenticación con el backend

El inicio de sesión de GymControl utiliza la API Flask para comprobar las credenciales del usuario.

Flutter envía el correo y la contraseña al endpoint de autenticación correspondiente.

Cuando la autenticación es correcta, el backend devuelve los datos del usuario y los tokens correspondientes.

Posteriormente, las solicitudes que requieren autenticación utilizan el token JWT.

El estado del usuario autenticado también se registra en `SessionProvider` para mantener la información disponible durante la navegación.

---

# ⚠️ Tratamiento de sesión no válida

Cuando una solicitud protegida devuelve un estado HTTP **401**, la aplicación interpreta que la autenticación ya no es válida.

En este caso se procede a cerrar la sesión y redirigir al usuario nuevamente al inicio de sesión.

Esto evita mantener al usuario dentro de una funcionalidad protegida cuando su autenticación ya no es válida.

---

# ⚡ Optimizaciones implementadas

Durante el desarrollo del proyecto se aplicaron diversas optimizaciones al backend:

- Implementación de Cache Aside.
- Corrección del problema N+1 mediante Eager Loading (`joinedload()`).
- Procesamiento asíncrono mediante un worker.
- Optimización del proceso de autenticación con JWT.
- Reducción de consultas repetidas hacia PostgreSQL.

---

# 🛡️ Seguridad

La aplicación implementa:

- Autenticación mediante JWT.
- Protección de funcionalidades privadas.
- Contraseñas almacenadas mediante hash en el backend.
- Validación de usuarios autenticados.
- Validaciones en formularios.
- Manejo del estado de autenticación.
- Limpieza de la sesión durante el logout.
- Variables de entorno para configuración.
- Restricción CORS durante el desarrollo.
- Control del acceso después de cerrar sesión.

No se deben almacenar contraseñas, claves privadas ni otras credenciales sensibles directamente dentro del repositorio público.

---

# ⚠️ Limitaciones y dificultades encontradas

Durante la configuración y desarrollo se presentaron algunas dificultades que fueron solucionadas.

Inicialmente, Google Chrome bloqueó la solicitud realizada desde Flutter debido a la política CORS y se presentó el error:

```text
Failed to fetch
```

Para solucionarlo se configuró Flask-CORS y se autorizó específicamente el origen local:

```text
http://localhost:8080
```

También fue necesario establecer el puerto 8080 de manera fija para Flutter Web, permitiendo mantener un origen conocido durante las pruebas y configurar correctamente CORS.

Otra dificultad presentada fue encontrar el puerto 8080 ocupado por una ejecución anterior de Flutter. Para solucionarlo se cerró la sesión anterior antes de volver a ejecutar la aplicación.

Durante el diagnóstico inicial mediante:

```powershell
flutter doctor -v
```

se detectó que Visual Studio no se encontraba instalado para el desarrollo de aplicaciones Windows.

Para resolver este hallazgo se instaló **Visual Studio Community 2026** con la carga de trabajo correspondiente al desarrollo de escritorio con C++ y los componentes necesarios.

Después de completar la instalación y reiniciar el equipo, se ejecutó nuevamente:

```powershell
flutter doctor -v
```

El diagnóstico reconoció correctamente Visual Studio y todos los demás componentes del entorno.

El resultado final fue:

```text
No issues found!
```

De esta manera se resolvieron todos los hallazgos reportados por el comando de diagnóstico de Flutter.

Durante la implementación del flujo de autenticación también fue necesario incorporar un mecanismo centralizado de manejo de estado. Para ello se agregó **Provider** y se creó `SessionProvider`, permitiendo mantener la información del usuario durante la navegación y limpiarla correctamente al cerrar sesión.

---

# 🧪 Pruebas realizadas

Se verificó el funcionamiento de:

## Entorno

- Configuración del entorno Flutter.
- Instalación de Flutter SDK y Dart.
- Configuración de Visual Studio Code.
- Extensiones Flutter y Dart.
- Android SDK.
- Visual Studio Community 2026.
- Ejecución de `flutter doctor -v`.
- Diagnóstico final `No issues found!`.
- Detección de dispositivos mediante `flutter devices`.
- Ejecución del proyecto Flutter en Google Chrome.
- Funcionamiento de Hot Reload y Hot Restart.

## Backend y comunicación

- Ejecución del backend Flask.
- API REST mediante Postman.
- Configuración de `API_BASE_URL`.
- Configuración limitada de CORS.
- Comunicación Flutter → Flask.
- Endpoint `/api/v1/health`.
- Respuesta HTTP 200 del backend.
- Visualización del mensaje `GymControl Backend - estado: ok`.

## Autenticación y formularios

- Registro de usuarios.
- Validación de campos obligatorios en el registro.
- Validación del formato del correo electrónico.
- Validación de longitud mínima de contraseña.
- Inicio de sesión.
- Validación de campos obligatorios en el login.
- Detección de credenciales incorrectas.
- Inicio de sesión con un usuario válido.
- Acceso al Dashboard después de autenticarse.

## Navegación y manejo de estado

- Manejo del estado mediante Provider.
- Funcionamiento de `SessionProvider`.
- Persistencia de la información del usuario durante la navegación.
- Navegación entre Dashboard y Rutinas.
- Navegación entre Dashboard y Peso.
- Navegación entre Dashboard y Perfil.
- Visualización de los datos del usuario en el perfil.
- Acceso a funcionalidades protegidas únicamente con sesión activa.

## Cierre de sesión

- Confirmación antes del cierre de sesión.
- Eliminación de la información de autenticación.
- Limpieza del estado de `SessionProvider`.
- Redirección al inicio de sesión.
- Intento de regresar mediante la navegación anterior después del logout.
- Bloqueo del acceso a las funcionalidades protegidas sin volver a autenticarse.

## Funcionalidades del proyecto

- Gestión de rutinas.
- Gestión de ejercicios.
- Gestión de entrenamientos.
- Registro de peso.
- Historial de peso.
- Perfil de usuario.
- Recordatorios.
- Calendario.
- Progreso.

---

# 📖 Documentación

La documentación técnica del proyecto se encuentra en la carpeta **docs/**.

- Constitución del Proyecto.
- Software Design Description (SDD).
- Arquitectura.
- API REST.
- Optimizaciones.
- Pruebas.

Esta documentación complementa el README y describe diferentes aspectos técnicos relacionados con el desarrollo de GymControl.

---

# 📹 Video de demostración

El video correspondiente al flujo de autenticación, navegación, manejo de estado y formularios demuestra:

1. Ejecución de GymControl.
2. Formulario de registro.
3. Validaciones de campos obligatorios.
4. Validación del formato del correo.
5. Formulario de inicio de sesión.
6. Comportamiento frente a credenciales incorrectas.
7. Autenticación correcta.
8. Acceso al Dashboard protegido.
9. Navegación entre al menos tres funcionalidades.
10. Persistencia de la información del usuario durante la navegación.
11. Manejo del estado mediante Provider y `SessionProvider`.
12. Organización del código en pantallas, servicios, modelos y providers.
13. Cierre de sesión.
14. Intento de acceso a una funcionalidad protegida después del logout.
15. Código actualizado en el repositorio GitHub.

## Enlace del video

Agregar el enlace del video cuando esté disponible:

```text
https://colocar-aqui-el-enlace-del-video
```

---

# 🔗 Repositorio

El código fuente de GymControl se encuentra almacenado y versionado mediante Git y GitHub.

Los cambios correspondientes a autenticación, navegación, manejo de estado, validaciones y protección de funcionalidades se encuentran integrados en la rama principal del proyecto.

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