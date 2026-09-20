# 🏋️ GymControl

Aplicación móvil desarrollada como proyecto académico para la asignatura **Aplicaciones Móviles** de la **Universidad Estatal Amazónica (UEA)**.

GymControl permite gestionar rutinas de entrenamiento, ejercicios, registrar el peso corporal, administrar recordatorios, controlar el progreso y gestionar el perfil del usuario mediante una arquitectura cliente-servidor basada en Flutter y Flask.

---

# 📌 Objetivo

Desarrollar una aplicación móvil que permita organizar rutinas de entrenamiento, registrar ejercicios, controlar el progreso físico del usuario y gestionar de forma segura el acceso a las diferentes funcionalidades.

El proyecto incorpora funcionalidades nativas del dispositivo, como el uso de la cámara para la fotografía de perfil y las notificaciones locales para los recordatorios de entrenamiento.

---

# 🚀 Tecnologías utilizadas

## Frontend

- Flutter 3.44.6
- Dart 3.12.2
- Provider
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
- Manejo de permisos nativos

## Herramientas

- Visual Studio Code
- Android Studio
- Android SDK
- Git
- GitHub
- Postman

---

# 📱 Framework multiplataforma seleccionado

Para el desarrollo de GymControl se seleccionó **Flutter**, debido a que permite desarrollar aplicaciones multiplataforma utilizando una única base de código escrita en Dart.

Flutter facilita el mantenimiento del proyecto y permite integrar funcionalidades propias del dispositivo mediante plugins compatibles con Android e iOS.

---

# 🏗 Arquitectura

GymControl utiliza una arquitectura Cliente-Servidor.

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

El backend procesa las solicitudes, aplica las reglas de negocio, administra la autenticación y se comunica con PostgreSQL.

Para el manejo del estado de autenticación se utiliza **Provider** mediante `SessionProvider`.

---

# 📂 Estructura del proyecto

```text
GymControl/
│
├── android/
├── backend/
├── docs/
├── ios/
├── lib/
│   ├── database/
│   ├── models/
│   ├── providers/
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

La organización del proyecto permite separar pantallas, modelos, servicios, manejo de estado y comunicación con el backend.

---

# ✨ Funcionalidades

GymControl implementa actualmente las siguientes funcionalidades:

- Registro de usuarios.
- Inicio de sesión mediante JWT.
- Validación de formularios.
- Manejo de credenciales incorrectas.
- Manejo del estado mediante Provider.
- Protección de funcionalidades privadas.
- Gestión de rutinas.
- Gestión de ejercicios.
- Gestión de entrenamientos.
- Registro del peso corporal.
- Consulta del historial de peso.
- Gestión de recordatorios.
- Calendario.
- Seguimiento del progreso.
- Visualización y actualización del perfil.
- Fotografía de perfil mediante cámara.
- Persistencia local de la fotografía.
- Notificaciones locales.
- Manejo de permisos nativos.
- Acceso directo a ajustes cuando un permiso está bloqueado.
- Degradación controlada ante permisos no disponibles.
- Comunicación entre Flutter y la API Flask.
- Cierre de sesión seguro.

---

# 📱 Funcionalidades nativas – Semana 14

Durante la Semana 14 se incorporaron dos funcionalidades nativas principales al prototipo de GymControl:

1. **Cámara para fotografía de perfil.**
2. **Notificaciones locales para recordatorios.**

Las funcionalidades fueron probadas directamente en un **dispositivo Android físico**.

---

# 📷 Cámara y fotografía de perfil

GymControl permite utilizar la cámara del dispositivo para tomar una fotografía de perfil.

El permiso de cámara se solicita únicamente cuando el usuario intenta utilizar esta funcionalidad.

Si el permiso es concedido, GymControl abre la cámara del dispositivo y permite tomar una fotografía.

La imagen se copia al directorio de documentos de la aplicación y su ruta se conserva localmente mediante **SharedPreferences**.

Esto permite que la fotografía permanezca disponible después de salir del perfil y volver a ingresar.

Si el permiso está bloqueado o denegado permanentemente, GymControl muestra un mensaje informativo y proporciona la opción:

```text
Abrir ajustes
```

Esta opción dirige al usuario hacia la configuración de Android para que pueda modificar manualmente el permiso.

La selección desde la galería utiliza el selector del sistema, evitando solicitar permisos amplios innecesarios sobre los archivos del dispositivo.

---

# 🔔 Notificaciones locales

GymControl incorpora notificaciones locales para los recordatorios relacionados con rutinas y entrenamientos.

El permiso de notificaciones se gestiona cuando el usuario utiliza la funcionalidad de recordatorios.

Si el permiso está disponible, el recordatorio puede ser guardado y programado mediante el sistema de notificaciones del dispositivo.

Cuando las notificaciones están bloqueadas, GymControl muestra un mensaje informativo y ofrece acceso directo a los ajustes del sistema.

Aunque las notificaciones estén deshabilitadas, la aplicación continúa funcionando y permite utilizar sus demás funcionalidades.

---

# 🔐 Manejo de permisos

GymControl implementa el manejo de permisos mediante el plugin:

```text
permission_handler
```

Los permisos utilizados en Android son:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

Estos permisos se encuentran declarados en:

```text
android/app/src/main/AndroidManifest.xml
```

La aplicación evita solicitar permisos nativos innecesariamente al iniciar.

Los permisos relacionados con las funcionalidades implementadas se gestionan cuando el usuario intenta utilizar la capacidad correspondiente.

---

# 📦 Plugins utilizados para funcionalidades nativas

Para la incorporación de las funcionalidades nativas se utilizaron:

- `permission_handler`
- `image_picker`
- `flutter_local_notifications`
- `flutter_timezone`
- `shared_preferences`

## permission_handler

Permite consultar y gestionar el estado de los permisos del dispositivo.

## image_picker

Permite utilizar la cámara y el selector de imágenes del sistema.

## flutter_local_notifications

Permite programar y administrar notificaciones locales.

## flutter_timezone

Permite trabajar con la zona horaria del dispositivo para la programación de notificaciones.

## shared_preferences

Permite conservar información local necesaria para mantener la fotografía de perfil.

---

# ⚠️ Degradación controlada

GymControl está diseñado para continuar funcionando aunque el usuario no conceda alguno de los permisos nativos.

## Cámara sin permiso

Si la cámara no está disponible:

- La aplicación no se cierra.
- Se informa al usuario.
- Se mantiene disponible el resto de GymControl.
- Si el permiso está bloqueado, se ofrece acceso a los ajustes del sistema.

## Notificaciones sin permiso

Si las notificaciones están deshabilitadas:

- GymControl continúa funcionando.
- Los demás módulos permanecen disponibles.
- Se informa al usuario sobre el estado del permiso.
- Se proporciona acceso directo a los ajustes del sistema.

De esta manera, la ausencia de una capacidad nativa no impide utilizar la funcionalidad principal de la aplicación.

---

# 🤖 Configuración Android

La configuración utilizada actualmente por GymControl es:

```text
targetSdkVersion: 36
compileSdk: 37
```

El proyecto utiliza como objetivo **Android 16 mediante API 36**.

Los permisos nativos correspondientes se encuentran configurados en `AndroidManifest.xml`.

---

# 🍎 Configuración iOS

Para el uso de la cámara se incorporó la descripción correspondiente en:

```text
ios/Runner/Info.plist
```

Con una descripción de propósito para informar al usuario por qué GymControl requiere acceso a la cámara.

Las notificaciones utilizan el mecanismo de autorización proporcionado por el sistema operativo.

---

# 🧪 Pruebas en dispositivo físico

Las funcionalidades nativas de GymControl fueron verificadas en un **dispositivo Android físico**.

Se comprobaron los siguientes casos:

## Caso 1 – Permiso concedido

Se concedió el permiso de cámara y se verificó:

- Apertura de la cámara.
- Captura de fotografía.
- Actualización de la fotografía del perfil.
- Persistencia local de la imagen.

También se concedió el permiso de notificaciones y se verificó la gestión de recordatorios.

## Caso 2 – Permiso denegado

Se comprobó el comportamiento de GymControl cuando el usuario no concede un permiso solicitado.

La aplicación permanece operativa y muestra información comprensible al usuario.

## Caso 3 – Permiso bloqueado o denegado permanentemente

Se comprobó que GymControl detecta el estado del permiso y proporciona acceso directo a los ajustes del sistema.

## Caso 4 – Permiso revocado desde Ajustes

Se revocaron permisos desde la configuración de Android y posteriormente se volvió a utilizar la funcionalidad correspondiente.

GymControl detectó correctamente el nuevo estado del permiso.

## Caso 5 – Capacidad nativa no disponible

Se comprobó que la aplicación mantiene operativa su funcionalidad principal aunque la cámara o las notificaciones no estén disponibles.

No se produce el cierre inesperado de GymControl.

---

# 💾 Persistencia local

La fotografía de perfil seleccionada por el usuario se almacena localmente dentro del espacio de la aplicación.

La ruta correspondiente se conserva mediante SharedPreferences.

Al salir del perfil y volver a ingresar, la fotografía permanece disponible.

---

# 🌐 Integración con backend

GymControl mantiene comunicación con el backend desarrollado en Flask.

La aplicación utiliza una variable de entorno para definir la URL base:

```dart
static const String apiRootUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:5000',
);
```

Durante las pruebas en el dispositivo Android físico se utilizó la comunicación mediante el puerto local del backend.

Para comprobar la conexión se dispone del endpoint:

```text
GET /api/v1/health
```

Cuando la comunicación funciona correctamente, GymControl muestra:

```text
GymControl Backend - estado: ok
```

Los recordatorios también forman parte de las funcionalidades gestionadas mediante los servicios de la aplicación y su API.

---

# 🔑 Autenticación de usuarios

GymControl implementa autenticación conectada directamente con el backend Flask.

El usuario puede registrarse y posteriormente utilizar sus credenciales para iniciar sesión.

Cuando las credenciales son correctas, la API devuelve la información del usuario y los tokens necesarios para realizar solicitudes protegidas.

La aplicación utiliza **JWT** para proteger las operaciones que requieren autenticación.

---

# 🧠 Manejo de estado con Provider

GymControl utiliza **Provider** para administrar el estado de autenticación.

La clase principal se encuentra en:

```text
lib/providers/session_provider.dart
```

`SessionProvider` mantiene información relacionada con:

- Identificador del usuario.
- Nombre.
- Correo electrónico.
- Estado de autenticación.

Los cambios de estado son comunicados mediante:

```dart
notifyListeners();
```

Esto permite mantener la información del usuario durante la navegación.

---

# 🔒 Protección de funcionalidades

Las funcionalidades privadas requieren una sesión autenticada.

Si no existe una sesión válida, el usuario es dirigido al inicio de sesión.

Al cerrar sesión se elimina la información de autenticación y se impide volver a acceder a las pantallas protegidas sin autenticarse nuevamente.

---

# ▶️ Ejecución del backend

Ingresar a la carpeta:

```powershell
cd backend
```

Activar el entorno virtual:

```powershell
.\venv\Scripts\Activate.ps1
```

Ejecutar:

```powershell
py run.py
```

El backend local queda disponible en:

```text
http://127.0.0.1:5000
```

---

# 📲 Ejecución en dispositivo Android físico

Con el dispositivo conectado mediante USB se puede comprobar mediante:

```powershell
adb devices
```

Para permitir que el dispositivo físico acceda al backend local mediante USB se utiliza:

```powershell
adb reverse tcp:5000 tcp:5000
```

Posteriormente GymControl puede ejecutarse indicando la dirección de la API:

```powershell
flutter run -d <ID_DISPOSITIVO> --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

---

# 🧪 Verificaciones realizadas

Durante el desarrollo y las pruebas se comprobó:

- Ejecución de Flutter.
- Ejecución del backend Flask.
- Comunicación Flutter → Flask.
- Endpoint `/api/v1/health`.
- Registro de usuarios.
- Inicio de sesión.
- Validación de formularios.
- Manejo de estado con Provider.
- Gestión de rutinas.
- Gestión de ejercicios.
- Gestión de entrenamientos.
- Registro de peso.
- Perfil de usuario.
- Persistencia de fotografía.
- Cámara en dispositivo físico.
- Permiso de cámara concedido.
- Permiso de cámara denegado.
- Permiso de cámara bloqueado.
- Acceso directo a ajustes.
- Notificaciones locales.
- Permiso de notificaciones concedido.
- Notificaciones bloqueadas.
- Degradación controlada.
- Gestión de recordatorios.
- Comunicación con el backend.
- Cierre de sesión.

---

# 📖 Documentación

La documentación técnica complementaria del proyecto se encuentra en la carpeta:

```text
docs/
```

Esta documentación describe aspectos relacionados con:

- Constitución del proyecto.
- Software Design Description.
- Arquitectura.
- API REST.
- Optimizaciones.
- Pruebas.

---

# 📹 Video de demostración – Semana 14

El video correspondiente a la Semana 14 demuestra:

1. Ejecución de GymControl en un dispositivo Android físico.
2. Comunicación con el backend.
3. Uso de la cámara con permiso concedido.
4. Captura y persistencia de la fotografía de perfil.
5. Comportamiento de la cámara sin permiso.
6. Detección de permiso bloqueado.
7. Acceso directo a los ajustes de Android.
8. Funcionamiento de las notificaciones locales.
9. Gestión de recordatorios.
10. Comportamiento cuando las notificaciones están bloqueadas.
11. Degradación controlada.
12. Configuración de permisos en Android.
13. Configuración de `targetSdkVersion` y `compileSdk`.
14. Código actualizado en GitHub.

## Enlace del video

Agregar el enlace cuando el video se encuentre publicado:

```text
https://colocar-aqui-el-enlace-del-video
```

---

# 🔗 Repositorio

El código fuente de GymControl se encuentra almacenado y versionado mediante Git y GitHub.

Repositorio:

```text
https://github.com/UEADAVID24/GymControl1.git
```

Los cambios correspondientes a las funcionalidades nativas, manejo de permisos, cámara, notificaciones, persistencia local y pruebas de la Semana 14 se encuentran integrados en la rama principal del proyecto.

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