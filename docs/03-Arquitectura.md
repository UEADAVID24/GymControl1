# Arquitectura del Sistema

## Proyecto: GymControl

**Autor:** Clinton David Alvarado Chongo  
**Asignatura:** Aplicaciones Móviles

---

# 1. Descripción de la Arquitectura

GymControl utiliza una arquitectura cliente-servidor.

La aplicación móvil, desarrollada en Flutter, funciona como cliente y se comunica mediante solicitudes HTTP con una API REST desarrollada en Flask.

El backend procesa las solicitudes, aplica las reglas de negocio, valida la autenticación del usuario y administra la información almacenada en PostgreSQL.

---

# 2. Arquitectura General

```text
Usuario
   │
   ▼
Aplicación Flutter
   │
   │ Solicitudes HTTP / JSON
   ▼
API REST Flask
   │
   ├── Autenticación JWT
   ├── Lógica de negocio
   ├── Caché
   ├── Worker asíncrono
   └── SQLAlchemy
          │
          ▼
      PostgreSQL
```

---

# 3. Componentes Principales

## 3.1 Aplicación móvil

La aplicación móvil está desarrollada con Flutter y Dart.

Sus principales responsabilidades son:

- Mostrar la interfaz gráfica.
- Permitir la navegación entre pantallas.
- Recibir los datos ingresados por el usuario.
- Consumir los endpoints de la API REST.
- Almacenar y enviar el token JWT.
- Mostrar rutinas, ejercicios, peso y perfil.
- Consultar el estado de las tareas de optimización.

---

## 3.2 Backend

El backend está desarrollado con Flask.

Sus responsabilidades principales son:

- Recibir las solicitudes de la aplicación móvil.
- Validar los datos enviados.
- Aplicar las reglas del negocio.
- Proteger las rutas mediante JWT.
- Consultar y actualizar la base de datos.
- Administrar la caché.
- Evitar consultas N+1.
- Ejecutar tareas en segundo plano.
- Devolver respuestas en formato JSON.

---

## 3.3 Base de datos

La información se almacena en PostgreSQL.

La base de datos conserva:

- Usuarios.
- Datos del perfil.
- Rutinas.
- Ejercicios.
- Historial de peso.
- Tareas y resultados de optimización.

SQLAlchemy se utiliza como ORM para relacionar las clases del backend con las tablas de PostgreSQL.

---

## 3.4 Autenticación

La autenticación utiliza JSON Web Token.

Cuando el usuario inicia sesión, el backend verifica las credenciales y genera un token JWT.

El cliente Flutter envía ese token en las solicitudes posteriores para acceder a rutas protegidas.

Esto permite identificar al usuario y restringir el acceso a información privada.

---

## 3.5 Caché

El backend utiliza una estrategia Cache Aside.

El proceso funciona de la siguiente manera:

1. El backend consulta primero la caché.
2. Si la información existe, la devuelve sin consultar PostgreSQL.
3. Si no existe, consulta la base de datos.
4. Guarda temporalmente el resultado en caché.
5. Devuelve la respuesta al cliente.

La información almacenada en caché tiene un tiempo de vida definido.

Cuando el usuario crea, actualiza o elimina información relacionada, la entrada correspondiente se invalida para evitar datos desactualizados.

---

## 3.6 Carga de relaciones

Para cargar las rutinas junto con sus ejercicios se utiliza Eager Loading mediante `joinedload()`.

Esta decisión evita ejecutar una consulta adicional por cada rutina y corrige el riesgo de consultas N+1.

Se seleccionó esta estrategia porque la aplicación normalmente necesita mostrar la rutina y sus ejercicios al mismo tiempo.

---

## 3.7 Procesamiento asíncrono

La generación del resumen de optimización se ejecuta mediante un worker en segundo plano.

Cuando se crea una tarea:

1. El backend registra la solicitud.
2. La tarea aparece inicialmente con estado pendiente.
3. El worker procesa la información.
4. Al finalizar, el estado cambia a completada.
5. La aplicación consulta posteriormente el resultado.

De esta manera, el servidor no mantiene bloqueada la solicitud mientras se ejecuta el proceso.

---

# 4. Flujo de inicio de sesión

```text
Usuario
   │
   │ Ingresa correo y contraseña
   ▼
Aplicación Flutter
   │
   │ POST /auth/login
   ▼
Backend Flask
   │
   ├── Busca el usuario
   ├── Verifica la contraseña
   └── Genera el token JWT
   │
   ▼
Aplicación Flutter
   │
   ├── Guarda el token
   └── Permite acceder al sistema
```

---

# 5. Flujo de consulta de rutinas

```text
Aplicación Flutter
   │
   │ GET /rutinas + Token JWT
   ▼
Backend Flask
   │
   ├── Valida el token
   ├── Revisa la caché
   ├── Consulta PostgreSQL si es necesario
   └── Carga rutinas y ejercicios con joinedload()
   │
   ▼
Respuesta JSON
   │
   ▼
Aplicación Flutter
```

---

# 6. Flujo de tarea asíncrona

```text
Aplicación Flutter
   │
   │ Solicita optimización
   ▼
Backend Flask
   │
   ├── Crea la tarea
   └── Devuelve estado pendiente
   │
   ▼
Worker
   │
   ├── Procesa la información
   └── Cambia estado a completada
   │
   ▼
Aplicación Flutter consulta el resultado
```

---

# 7. Organización del Proyecto

La estructura general del repositorio es:

```text
GYMCONTROL/
├── android/
├── backend/
├── docs/
├── ios/
├── lib/
├── test/
├── web/
├── windows/
├── pubspec.yaml
└── README.md
```

La carpeta `lib` contiene el código principal de Flutter.

La carpeta `backend` contiene la API Flask, los modelos, las rutas, la autenticación y las optimizaciones.

La carpeta `docs` contiene las especificaciones y documentación técnica del proyecto.

---

# 8. Decisiones de Diseño

Las principales decisiones fueron:

- Usar Flutter para mantener una base de código multiplataforma.
- Utilizar Flask para construir una API REST sencilla y modular.
- Emplear PostgreSQL por su confiabilidad y persistencia.
- Utilizar SQLAlchemy para administrar las consultas y relaciones.
- Implementar JWT para proteger las rutas privadas.
- Aplicar Cache Aside para reducir consultas repetidas.
- Utilizar Eager Loading para prevenir el problema N+1.
- Ejecutar tareas costosas mediante un worker.
- Desplegar el backend en Render.

---

# 9. Ventajas de la Arquitectura

La arquitectura implementada ofrece:

- Separación entre frontend y backend.
- Mejor organización del código.
- Protección de información mediante autenticación.
- Persistencia de datos.
- Facilidad para incorporar nuevas funciones.
- Reducción de consultas innecesarias.
- Procesamiento en segundo plano.
- Posibilidad de utilizar el mismo backend desde diferentes clientes.

---

# 10. Conclusión

La arquitectura de GymControl integra una aplicación Flutter con un backend Flask y una base de datos PostgreSQL.

La incorporación de autenticación JWT, caché, Eager Loading y procesamiento asíncrono permite mantener una estructura segura, organizada y optimizada.

Estas decisiones facilitan el funcionamiento actual de la aplicación y permiten realizar futuras ampliaciones sin alterar completamente el sistema.