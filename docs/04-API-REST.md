# Documentación de la API REST

## Proyecto: GymControl

**Autor:** Clinton David Alvarado Chongo

**Asignatura:** Aplicaciones Móviles

---

# 1. Introducción

GymControl utiliza una API REST desarrollada en Flask para permitir la comunicación entre la aplicación móvil desarrollada en Flutter y la base de datos PostgreSQL.

La API permite administrar usuarios, autenticación, rutinas, ejercicios, peso corporal y perfil del usuario, utilizando respuestas en formato JSON.

---

# 2. Características de la API

- Arquitectura REST.
- Comunicación mediante HTTP.
- Formato de intercambio JSON.
- Autenticación mediante JWT.
- Backend desarrollado en Flask.
- Persistencia mediante PostgreSQL.
- ORM SQLAlchemy.

---

# 3. Autenticación

La autenticación se realiza mediante JSON Web Token (JWT).

Después de iniciar sesión correctamente, el servidor genera un token que debe enviarse en cada solicitud protegida.

Ejemplo:

```http
Authorization: Bearer <token>
```

Las rutas privadas verifican automáticamente la validez del token antes de procesar la solicitud.

---

# 4. Endpoints

## 4.1 Registro de usuario

**POST**

```
/auth/register
```

### Descripción

Permite registrar un nuevo usuario.

### Datos enviados

```json
{
  "nombre": "Juan Pérez",
  "email": "juan@email.com",
  "password": "123456"
}
```

### Respuesta

```json
{
  "mensaje": "Usuario registrado correctamente"
}
```

---

## 4.2 Inicio de sesión

**POST**

```
/auth/login
```

### Descripción

Verifica las credenciales del usuario y devuelve un token JWT.

### Datos enviados

```json
{
  "email": "juan@email.com",
  "password": "123456"
}
```

### Respuesta

```json
{
  "access_token": "eyJhbGciOi..."
}
```

---

## 4.3 Obtener usuario autenticado

**GET**

```
/auth/me
```

### Descripción

Obtiene la información del usuario autenticado.

Requiere JWT.

---

## 4.4 Consultar rutinas

**GET**

```
/rutinas
```

### Descripción

Devuelve todas las rutinas pertenecientes al usuario autenticado.

La consulta utiliza **Eager Loading** para cargar los ejercicios asociados y evitar el problema N+1.

---

## 4.5 Crear rutina

**POST**

```
/rutinas
```

### Descripción

Permite registrar una nueva rutina.

Ejemplo:

```json
{
    "nombre":"Pecho",
    "descripcion":"Entrenamiento de pecho"
}
```

---

## 4.6 Actualizar rutina

**PUT**

```
/rutinas/{id}
```

Actualiza la información de una rutina existente.

---

## 4.7 Eliminar rutina

**DELETE**

```
/rutinas/{id}
```

Elimina una rutina registrada.

---

## 4.8 Registrar ejercicio

**POST**

```
/ejercicios
```

Permite agregar ejercicios asociados a una rutina.

---

## 4.9 Consultar ejercicios

**GET**

```
/ejercicios
```

Devuelve los ejercicios registrados.

---

## 4.10 Registrar peso corporal

**POST**

```
/peso
```

Permite registrar el peso del usuario.

Ejemplo:

```json
{
    "peso":75.4
}
```

---

## 4.11 Consultar historial de peso

**GET**

```
/peso
```

Devuelve el historial de peso corporal registrado.

---

## 4.12 Actualizar perfil

**PUT**

```
/perfil
```

Permite modificar los datos personales del usuario.

---

## 4.13 Ejecutar optimización

**POST**

```
/optimizacion
```

Inicia una tarea en segundo plano utilizando un worker.

Inicialmente devuelve estado **Pendiente**.

Cuando el worker termina el proceso, el estado cambia automáticamente a **Completada**.

---

# 5. Códigos HTTP

| Código | Significado |
|---------|-------------|
| 200 | Solicitud exitosa |
| 201 | Recurso creado |
| 400 | Solicitud incorrecta |
| 401 | No autorizado |
| 404 | Recurso no encontrado |
| 500 | Error interno del servidor |

---

# 6. Seguridad

La API implementa:

- JWT.
- Protección de rutas privadas.
- Validación de usuarios.
- Contraseñas cifradas mediante hash.
- Variables de entorno para información sensible.

---

# 7. Optimizaciones de la API

Las optimizaciones implementadas incluyen:

- Caché mediante estrategia Cache Aside.
- Corrección del problema N+1 utilizando `joinedload()`.
- Procesamiento asíncrono mediante un worker.
- Eager Loading para las relaciones Rutina-Ejercicio.
- Reducción de consultas redundantes durante la autenticación.

---

# 8. Flujo General de Comunicación

```text
Flutter
    │
    │ HTTP + JSON
    ▼
Flask API
    │
    ├── JWT
    ├── Caché
    ├── Worker
    ├── SQLAlchemy
    ▼
PostgreSQL
```

---

# 9. Conclusión

La API REST de GymControl proporciona una comunicación segura y eficiente entre la aplicación móvil y la base de datos.

La incorporación de autenticación JWT, caché, consultas optimizadas y procesamiento asíncrono mejora el rendimiento del sistema y facilita el mantenimiento del backend.