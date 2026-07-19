# 🏋️ GymControl

Aplicación móvil desarrollada como proyecto académico para la asignatura **Aplicaciones Móviles** de la **Universidad Estatal Amazónica (UEA)**.

GymControl permite gestionar rutinas de entrenamiento, ejercicios, registrar el peso corporal y administrar el perfil del usuario mediante una arquitectura cliente-servidor basada en Flutter y Flask.

---

# 📌 Objetivo

Desarrollar una aplicación móvil que permita organizar rutinas de entrenamiento y registrar el progreso físico del usuario mediante un backend seguro y optimizado.

---

# 🚀 Tecnologías Utilizadas

## Frontend

- Flutter
- Dart

## Backend

- Flask
- Python

## Base de Datos

- PostgreSQL
- SQLAlchemy

## Seguridad

- JWT (JSON Web Token)

## Herramientas

- Visual Studio Code
- Git
- GitHub
- Postman
- Render

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

# 📂 Estructura del Proyecto

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
├── test/
├── web/
├── windows/
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
- Optimización de procesos en segundo plano.

---

# ⚡ Optimizaciones Implementadas

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

---

# 📖 Documentación

La documentación técnica del proyecto se encuentra en la carpeta **docs/**.

- Constitución del Proyecto
- Software Design Description (SDD)
- Arquitectura
- API REST
- Optimizaciones
- Pruebas

---

# ▶️ Ejecución del Proyecto

## Backend

```bash
cd backend
pip install -r requirements.txt
python app.py
```

## Frontend

```bash
flutter pub get
flutter run
```

---

# 🧪 Pruebas

Se verificó el funcionamiento de:

- Registro de usuarios.
- Inicio de sesión.
- Gestión de rutinas.
- Gestión de ejercicios.
- Registro de peso.
- Perfil de usuario.
- Optimizaciones del backend.
- API REST mediante Postman.

---

# 📹 Video de Demostración

Agregar aquí el enlace al video solicitado por el docente cuando esté disponible.

```
https://colocar-aqui-el-enlace-del-video
```

---

# 👨‍💻 Autor

**Clinton David Alvarado Chongo**

Universidad Estatal Amazónica

Carrera de Ingeniería en Tecnologías de la Información

---

# 📅 Periodo Académico

2025 - 2026

---

# 📄 Licencia

Proyecto desarrollado con fines exclusivamente académicos para la asignatura **Aplicaciones Móviles**.