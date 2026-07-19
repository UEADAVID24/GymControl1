# Software Design Description (SDD)

## Proyecto: GymControl

**Autor:** Clinton David Alvarado Chongo

**Asignatura:** Aplicaciones Móviles

---

# 1. Introducción

## 1.1 Propósito

Este documento describe el diseño del software del proyecto GymControl. Su propósito es documentar la arquitectura, los componentes, las decisiones de diseño, las especificaciones funcionales y no funcionales, así como las optimizaciones implementadas en el backend.

Este documento sirve como referencia para comprender la estructura del sistema y facilitar su mantenimiento y evolución.

---

# 2. Descripción General

GymControl es una aplicación móvil que permite administrar rutinas de entrenamiento, ejercicios y el progreso físico de los usuarios.

La aplicación utiliza una arquitectura cliente-servidor, donde Flutter consume una API REST desarrollada en Flask.

Toda la información es almacenada en PostgreSQL mediante SQLAlchemy.

---

# 3. Objetivos del Sistema

## Objetivo General

Desarrollar una aplicación móvil para gestionar rutinas de entrenamiento y registrar el progreso físico mediante un backend seguro y optimizado.

## Objetivos Específicos

- Gestionar usuarios.
- Gestionar rutinas.
- Gestionar ejercicios.
- Registrar peso corporal.
- Administrar perfiles.
- Implementar autenticación JWT.
- Optimizar el rendimiento del backend.

---

# 4. Arquitectura del Sistema

El sistema utiliza una arquitectura cliente-servidor.

Cliente:

- Flutter

Servidor:

- Flask

Persistencia:

- PostgreSQL

ORM:

- SQLAlchemy

Autenticación:

- JWT

Despliegue:

- Render

Control de versiones:

- GitHub

---

# 5. Componentes del Sistema

## Frontend

Responsable de:

- Interfaz gráfica.
- Navegación.
- Consumo de la API REST.
- Gestión de sesiones.

## Backend

Responsable de:

- Lógica del negocio.
- Validación de usuarios.
- Seguridad.
- Optimización.
- Comunicación con PostgreSQL.

## Base de Datos

Almacena:

- Usuarios.
- Rutinas.
- Ejercicios.
- Peso corporal.
- Perfil.
- Resultados de optimización.

---

# 6. Modelo de Datos

Las principales entidades del sistema son:

- Usuario
- Rutina
- Ejercicio
- Peso
- Perfil

Relaciones principales:

- Un usuario puede tener varias rutinas.
- Una rutina puede contener varios ejercicios.
- Un usuario puede registrar múltiples pesos.
- Cada usuario posee un perfil.

---

# 7. Requisitos Funcionales

El sistema permite:

- Registrar usuarios.
- Iniciar sesión.
- Editar perfil.
- Crear rutinas.
- Modificar rutinas.
- Eliminar rutinas.
- Registrar ejercicios.
- Registrar peso corporal.
- Consultar historial.
- Ejecutar optimización.

---

# 8. Requisitos No Funcionales

- Seguridad mediante JWT.
- Alta disponibilidad.
- Código modular.
- Escalabilidad.
- Persistencia de datos.
- Optimización de consultas.
- Bajo tiempo de respuesta.

---

# 9. Seguridad

La autenticación se implementa mediante JSON Web Token (JWT).

Las rutas privadas requieren un token válido.

Las contraseñas se almacenan utilizando hash y nunca en texto plano.

Las claves sensibles son gestionadas mediante variables de entorno.

---

# 10. API REST

Principales endpoints:

| Método | Endpoint | Descripción |
|---------|----------|-------------|
| POST | /auth/register | Registrar usuario |
| POST | /auth/login | Iniciar sesión |
| GET | /auth/me | Obtener usuario autenticado |
| GET | /rutinas | Consultar rutinas |
| POST | /rutinas | Crear rutina |
| PUT | /rutinas/{id} | Actualizar rutina |
| DELETE | /rutinas/{id} | Eliminar rutina |
| GET | /peso | Consultar historial |
| POST | /peso | Registrar peso |
| PUT | /perfil | Actualizar perfil |
| POST | /optimizacion | Ejecutar optimización |

---

# 11. Optimizaciones Implementadas

## Caché

Se implementó una estrategia Cache Aside para reducir consultas repetidas hacia PostgreSQL.

Se configuró un tiempo de vida (TTL) y un mecanismo de invalidación cuando los datos cambian.

## Corrección del problema N+1

Se utilizó Eager Loading mediante `joinedload()` para obtener rutinas y ejercicios en una sola consulta.

Esto disminuye significativamente la cantidad de consultas realizadas al servidor.

## Worker

El proceso de optimización se ejecuta mediante un worker en segundo plano.

Esto evita bloquear la aplicación mientras se procesa la información.

## Eager Loading

Se seleccionó Eager Loading debido a que la aplicación requiere mostrar rutinas junto con sus ejercicios de forma inmediata.

## Autenticación Optimizada

Las rutas protegidas validan el JWT evitando consultas redundantes hacia la base de datos.

---

# 12. Pruebas

Las funcionalidades fueron verificadas mediante:

- Flutter.
- Postman.
- Backend Flask.

Se comprobó:

- Inicio de sesión.
- Gestión de rutinas.
- Gestión de ejercicios.
- Registro de peso.
- Edición de perfil.
- Optimización.
- Persistencia de datos.

---

# 13. Comparación Antes y Después

| Antes | Después |
|--------|----------|
| Consultas N+1 | Eager Loading |
| Sin caché | Cache Aside |
| Procesos bloqueantes | Worker en segundo plano |
| Mayor número de consultas | Menor cantidad de consultas |
| Mayor tiempo de respuesta | Mejor rendimiento |

---

# 14. Mantenibilidad

El sistema fue desarrollado utilizando una arquitectura modular.

Cada componente posee responsabilidades claramente definidas, facilitando futuras ampliaciones y mantenimiento.

---

# 15. Escalabilidad

La arquitectura permite incorporar nuevas funcionalidades sin modificar significativamente los módulos existentes.

Es posible añadir nuevos servicios, endpoints y modelos manteniendo la estructura actual.

---

# 16. Conclusiones

GymControl implementa una arquitectura moderna basada en Flutter, Flask y PostgreSQL.

Las técnicas de optimización aplicadas, como el uso de caché, Eager Loading, procesamiento asíncrono mediante worker y autenticación JWT, mejoran el rendimiento del backend y garantizan una mejor experiencia para el usuario.

La documentación presentada describe el diseño del software y sirve como referencia para futuras mejoras y mantenimiento del sistema.