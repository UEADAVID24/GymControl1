# Constitución del Proyecto

## 1. Información General

**Nombre del proyecto:** GymControl

**Autor:** Clinton David Alvarado Chongo

**Asignatura:** Aplicaciones Móviles

**Período académico:** 2026

---

# 2. Descripción del Proyecto

GymControl es una aplicación móvil desarrollada para facilitar la administración de rutinas de entrenamiento, ejercicios y el seguimiento del progreso físico de los usuarios. El sistema permite registrar información personal, controlar el peso corporal y gestionar rutinas de manera segura mediante una arquitectura cliente-servidor.

La aplicación está compuesta por un cliente desarrollado en Flutter y un backend construido con Flask, el cual expone una API REST protegida mediante autenticación JWT y almacena la información en PostgreSQL.

---

# 3. Problema

Muchas personas que realizan entrenamiento físico utilizan hojas de papel o aplicaciones poco personalizables para registrar sus rutinas y controlar su progreso.

Además, algunas aplicaciones presentan limitaciones para administrar ejercicios, consultar el historial de peso o visualizar la información de forma organizada.

---

# 4. Justificación

GymControl fue desarrollado con el propósito de ofrecer una solución móvil que permita administrar rutinas de entrenamiento de manera sencilla y segura.

El proyecto también sirve como aplicación integradora para poner en práctica los conocimientos adquiridos durante la asignatura Aplicaciones Móviles, incorporando autenticación, consumo de APIs REST y técnicas de optimización del backend.

---

# 5. Objetivo General

Desarrollar una aplicación móvil que permita gestionar rutinas de entrenamiento y registrar el progreso físico de los usuarios mediante un backend seguro, escalable y optimizado.

---

# 6. Objetivos Específicos

- Implementar autenticación segura mediante JWT.
- Administrar rutinas y ejercicios.
- Registrar el peso corporal del usuario.
- Permitir la actualización del perfil.
- Optimizar el backend mediante caché y consultas eficientes.
- Ejecutar procesos de optimización en segundo plano mediante un worker.

---

# 7. Alcance

El proyecto permite:

- Registro de usuarios.
- Inicio de sesión.
- Gestión de rutinas.
- Gestión de ejercicios.
- Registro del peso corporal.
- Consulta del historial.
- Actualización del perfil.
- Procesamiento de tareas de optimización.

No contempla funcionalidades como pagos electrónicos, integración con dispositivos inteligentes o redes sociales.

---

# 8. Tecnologías Utilizadas

## Frontend

- Flutter
- Dart

## Backend

- Flask
- SQLAlchemy

## Base de Datos

- PostgreSQL

## Seguridad

- JWT (JSON Web Token)

## Despliegue

- Render

## Control de versiones

- Git y GitHub

---

# 9. Arquitectura General

La aplicación sigue una arquitectura cliente-servidor.

El cliente Flutter consume una API REST desarrollada en Flask.

La API procesa las solicitudes, valida la autenticación mediante JWT y almacena la información en PostgreSQL utilizando SQLAlchemy como ORM.

---

# 10. Organización del Proyecto

El proyecto se encuentra dividido en dos componentes principales:

- Frontend desarrollado en Flutter.
- Backend desarrollado en Flask.

Además, el repositorio contiene documentación técnica correspondiente a la arquitectura, especificaciones del sistema, optimizaciones implementadas y pruebas realizadas.

---

# 11. Riesgos del Proyecto

Durante el desarrollo se identificaron los siguientes riesgos:

- Consultas repetitivas hacia la base de datos.
- Problemas de rendimiento ocasionados por consultas N+1.
- Bloqueo del servidor durante procesos largos.
- Accesos no autorizados.

Estos riesgos fueron mitigados mediante caché, eager loading, tareas asíncronas y autenticación JWT.

---

# 12. Conclusiones

GymControl constituye un proyecto integrador que aplica los conocimientos adquiridos durante la asignatura Aplicaciones Móviles.

La implementación de técnicas de optimización, autenticación y organización del código permitió obtener una aplicación funcional, segura y preparada para futuras mejoras.