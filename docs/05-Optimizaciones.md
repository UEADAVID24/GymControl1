# Optimizaciones del Backend

## Proyecto: GymControl

**Autor:** Clinton David Alvarado Chongo

**Asignatura:** Aplicaciones Móviles

---

# 1. Introducción

Como parte del Taller Práctico de la Semana 8 se realizaron diversas optimizaciones sobre el backend del proyecto GymControl con el objetivo de mejorar el rendimiento, disminuir la cantidad de consultas hacia la base de datos, reducir el tiempo de respuesta y optimizar el proceso de autenticación.

Las mejoras fueron implementadas directamente sobre el backend desarrollado en Flask utilizando PostgreSQL y SQLAlchemy.

---

# 2. Diagnóstico Inicial

Antes de aplicar las optimizaciones se identificaron los siguientes problemas:

- Existía riesgo de consultas N+1 al cargar rutinas y ejercicios.
- Algunas consultas se repetían innecesariamente.
- El proceso de optimización bloqueaba temporalmente la aplicación.
- La autenticación realizaba validaciones repetidas.

Estos aspectos ocasionaban un mayor uso de recursos del servidor y tiempos de respuesta más altos.

---

# 3. Implementación de Caché

Para reducir consultas repetidas se implementó una estrategia **Cache Aside**.

El funcionamiento consiste en:

1. Consultar primero la información almacenada en caché.
2. Si existe, devolverla inmediatamente.
3. Si no existe, consultar PostgreSQL.
4. Guardar temporalmente el resultado en caché.
5. Enviar la respuesta al cliente.

---

# 4. Tiempo de Vida (TTL)

La información almacenada en caché posee un tiempo de vida determinado (TTL).

Cuando el tiempo expira, la información es eliminada automáticamente para evitar entregar datos desactualizados.

---

# 5. Invalidación del Caché

Cada vez que el usuario:

- crea una rutina,
- modifica una rutina,
- elimina una rutina,
- registra un nuevo peso,

el backend invalida automáticamente la entrada correspondiente del caché.

Esto garantiza que las siguientes consultas recuperen información actualizada.

---

# 6. Corrección del Problema N+1

Inicialmente la carga de rutinas generaba múltiples consultas hacia PostgreSQL.

Por cada rutina se ejecutaba una consulta adicional para recuperar los ejercicios relacionados.

Para corregir este problema se utilizó **Eager Loading** mediante `joinedload()` de SQLAlchemy.

Con esta estrategia toda la información se obtiene mediante una sola consulta.

---

# 7. Justificación del uso de Eager Loading

En GymControl las pantallas muestran simultáneamente la información de la rutina junto con sus ejercicios.

Por esta razón se seleccionó **Eager Loading**, ya que permite cargar todos los datos relacionados en una única consulta, reduciendo considerablemente el número de accesos a la base de datos.

---

# 8. Procesamiento Asíncrono

Se implementó un **worker** para ejecutar procesos largos en segundo plano.

Cuando el usuario solicita una optimización:

- el backend registra la tarea,
- devuelve inmediatamente la respuesta,
- el worker procesa la información,
- finalmente actualiza el estado a **Completada**.

Este mecanismo evita bloquear la aplicación mientras se realiza el procesamiento.

---

# 9. Optimización del Proceso de Autenticación

La autenticación utiliza JWT.

Las rutas protegidas validan el token antes de acceder a la información del usuario.

Además, se redujeron consultas innecesarias durante la validación del usuario autenticado, mejorando el rendimiento del backend.

---

# 10. Comparación Antes y Después

| Antes | Después |
|--------|----------|
| Consultas N+1 | Consulta única mediante Eager Loading |
| Sin caché | Cache Aside implementado |
| Consultas repetidas | Reutilización de información almacenada |
| Procesos bloqueantes | Worker en segundo plano |
| Mayor carga en PostgreSQL | Menor cantidad de consultas |
| Mayor tiempo de respuesta | Mejor rendimiento |

---

# 11. Beneficios Obtenidos

Las optimizaciones implementadas permiten:

- Reducir el número de consultas hacia PostgreSQL.
- Mejorar el tiempo de respuesta.
- Disminuir la carga del servidor.
- Evitar consultas redundantes.
- Ejecutar procesos largos sin bloquear la aplicación.
- Mejorar la experiencia del usuario.

---

# 12. Resultados

Después de aplicar las optimizaciones el backend respondió de manera más eficiente.

Las pruebas realizadas demostraron que:

- La autenticación funciona correctamente.
- Las rutas protegidas continúan operando normalmente.
- Las rutinas y ejercicios se cargan con menor número de consultas.
- El worker ejecuta correctamente las tareas en segundo plano.
- El caché disminuye consultas repetidas.
- La aplicación mantiene un funcionamiento estable.

---

# 13. Conclusiones

La aplicación de técnicas de optimización permitió mejorar el rendimiento general del backend de GymControl.

La incorporación de Cache Aside, Eager Loading, procesamiento asíncrono mediante un worker y autenticación JWT optimizada redujo la carga sobre la base de datos y mejoró la eficiencia del sistema.

Estas optimizaciones cumplen con los objetivos planteados para el Taller Práctico de la Semana 8 y fortalecen la calidad del backend desarrollado.