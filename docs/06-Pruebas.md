# Pruebas del Sistema

## Proyecto: GymControl

**Autor:** Clinton David Alvarado Chongo

**Asignatura:** Aplicaciones Móviles

---

# 1. Introducción

Con el objetivo de verificar el correcto funcionamiento del proyecto GymControl se realizaron diferentes pruebas funcionales sobre el backend y la aplicación móvil.

Las pruebas permitieron validar la autenticación, la comunicación entre Flutter y Flask, el acceso a PostgreSQL y las optimizaciones implementadas durante el Taller Práctico de la Semana 8.

---

# 2. Entorno de Pruebas

Las pruebas fueron realizadas utilizando:

- Aplicación Flutter.
- Backend Flask.
- PostgreSQL.
- Postman.
- Render.
- Visual Studio Code.

---

# 3. Pruebas Realizadas

## 3.1 Registro de Usuario

Objetivo:

Verificar que un nuevo usuario pueda registrarse correctamente.

Resultado esperado:

El usuario se almacena correctamente en PostgreSQL.

Resultado obtenido:

La prueba fue satisfactoria.

---

## 3.2 Inicio de Sesión

Objetivo:

Verificar el funcionamiento de la autenticación mediante JWT.

Resultado esperado:

El backend devuelve un token válido.

Resultado obtenido:

El usuario inició sesión correctamente y obtuvo su token JWT.

---

## 3.3 Consulta del Perfil

Objetivo:

Comprobar que únicamente un usuario autenticado pueda consultar su información.

Resultado esperado:

El backend devuelve únicamente los datos correspondientes al usuario autenticado.

Resultado obtenido:

La información fue obtenida correctamente.

---

## 3.4 Gestión de Rutinas

Se verificó:

- Crear rutina.
- Consultar rutina.
- Editar rutina.
- Eliminar rutina.

Resultado:

Todas las operaciones funcionaron correctamente.

---

## 3.5 Gestión de Ejercicios

Se comprobó que la aplicación permite registrar ejercicios asociados a una rutina y recuperarlos correctamente.

Resultado:

Prueba satisfactoria.

---

## 3.6 Registro del Peso Corporal

Se verificó el almacenamiento del peso corporal del usuario.

Resultado:

Los registros fueron almacenados correctamente y posteriormente recuperados desde PostgreSQL.

---

## 3.7 Actualización del Perfil

Se verificó que el usuario pueda modificar su información personal.

Resultado:

Los cambios fueron almacenados correctamente.

---

## 3.8 Tarea Asíncrona

Se ejecutó el proceso de optimización.

Inicialmente la tarea apareció con estado:

Pendiente.

Después de finalizar el procesamiento:

Completada.

Resultado:

El worker funcionó correctamente.

---

# 4. Validación del Caché

Se realizaron consultas repetidas sobre la misma información.

Resultado:

El backend reutilizó los datos almacenados en caché, disminuyendo consultas repetidas hacia PostgreSQL.

---

# 5. Validación de la Corrección N+1

Se verificó la carga de rutinas junto con sus ejercicios.

Resultado:

Las consultas se ejecutaron utilizando Eager Loading mediante `joinedload()`, evitando múltiples consultas innecesarias.

---

# 6. Validación de la Autenticación

Se comprobó que:

- Las rutas privadas requieren JWT.
- Los usuarios sin token reciben acceso denegado.
- Los usuarios autenticados acceden únicamente a su información.

Resultado:

La autenticación funcionó correctamente.

---

# 7. Comparación Antes y Después

| Antes | Después |
|--------|----------|
| Consultas repetidas | Uso de caché |
| Riesgo de consultas N+1 | Consulta única mediante Eager Loading |
| Procesamiento bloqueante | Worker en segundo plano |
| Mayor carga del servidor | Menor carga del servidor |
| Mayor tiempo de respuesta | Respuesta más eficiente |

---

# 8. Evidencias

Las evidencias utilizadas corresponden a:

- Inicio de sesión.
- Creación de rutinas.
- Registro de ejercicios.
- Registro de peso.
- Actualización del perfil.
- Ejecución del proceso de optimización.
- Consultas realizadas mediante Postman.
- Funcionamiento del backend desplegado en Render.

Estas evidencias serán presentadas durante el video solicitado en el Taller Práctico.

---

# 9. Conclusiones

Las pruebas realizadas permitieron comprobar el correcto funcionamiento del proyecto GymControl.

Todas las funcionalidades principales operan correctamente y las optimizaciones implementadas mejoran el rendimiento del backend.

La integración entre Flutter, Flask, PostgreSQL, JWT, caché, Eager Loading y procesamiento asíncrono permitió obtener una aplicación funcional, segura y preparada para futuras ampliaciones.