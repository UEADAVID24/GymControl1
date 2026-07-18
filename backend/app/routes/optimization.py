from time import perf_counter

from flask import Blueprint, jsonify
from flask_jwt_extended import (
    get_jwt_identity,
    jwt_required,
)
from sqlalchemy import event
from sqlalchemy.orm import (
    Session,
    selectinload,
)

from app.extensions import db
from app.models.routine import Routine
from app.task_queue import (
    agregar_tarea,
    obtener_tarea,
)


optimization_bp = Blueprint(
    "optimization",
    __name__,
)


def obtener_usuario_id() -> int:
    return int(get_jwt_identity())


def ejecutar_y_contar_consultas(
    funcion,
):
    contador = {
        "total": 0,
    }

    def antes_de_ejecutar(
        conn,
        cursor,
        statement,
        parameters,
        context,
        executemany,
    ):
        contador["total"] += 1

    event.listen(
        db.engine,
        "before_cursor_execute",
        antes_de_ejecutar,
    )

    inicio = perf_counter()

    try:
        resultado = funcion()

        tiempo_ms = round(
            (perf_counter() - inicio) * 1000,
            3,
        )

    finally:
        event.remove(
            db.engine,
            "before_cursor_execute",
            antes_de_ejecutar,
        )

    return {
        "consultas_sql": contador["total"],
        "tiempo_ms": tiempo_ms,
        "resultado": resultado,
    }


@optimization_bp.get("/diagnostico-n1")
@jwt_required()
def diagnostico_n1():
    usuario_id = obtener_usuario_id()

    def version_antes():
        # Se utiliza una sesión independiente
        # para medir correctamente las consultas.
        with Session(db.engine) as sesion:
            rutinas = sesion.execute(
                db.select(Routine)
                .where(
                    Routine.usuario_id
                    == usuario_id,
                )
                .order_by(
                    Routine.id.desc(),
                )
            ).scalars().all()

            # Aquí ocurre el patrón N+1:
            # una consulta para las rutinas y
            # una consulta adicional por rutina.
            return [
                {
                    "rutina": rutina.nombre,
                    "total_ejercicios": len(
                        rutina.ejercicios
                    ),
                }
                for rutina in rutinas
            ]

    def version_despues():
        with Session(db.engine) as sesion:
            rutinas = sesion.execute(
                db.select(Routine)
                .options(
                    selectinload(
                        Routine.ejercicios
                    )
                )
                .where(
                    Routine.usuario_id
                    == usuario_id,
                )
                .order_by(
                    Routine.id.desc(),
                )
            ).scalars().all()

            # Los ejercicios ya fueron obtenidos
            # mediante una consulta agrupada.
            return [
                {
                    "rutina": rutina.nombre,
                    "total_ejercicios": len(
                        rutina.ejercicios
                    ),
                }
                for rutina in rutinas
            ]

    antes = ejecutar_y_contar_consultas(
        version_antes
    )

    despues = ejecutar_y_contar_consultas(
        version_despues
    )

    consultas_ahorradas = (
        antes["consultas_sql"]
        - despues["consultas_sql"]
    )

    mejora_porcentual = 0.0

    if antes["consultas_sql"] > 0:
        mejora_porcentual = round(
            (
                consultas_ahorradas
                / antes["consultas_sql"]
            )
            * 100,
            2,
        )

    return jsonify(
        {
            "descripcion": (
                "Comparación entre lazy loading "
                "y eager loading."
            ),
            "antes": antes,
            "despues": despues,
            "consultas_ahorradas": (
                consultas_ahorradas
            ),
            "mejora_porcentual_consultas": (
                mejora_porcentual
            ),
            "problema_detectado": (
                "La versión inicial ejecuta una "
                "consulta para listar rutinas y "
                "otra consulta por cada rutina "
                "para cargar sus ejercicios."
            ),
            "solucion_aplicada": (
                "Se utilizó selectinload para "
                "cargar todos los ejercicios "
                "relacionados mediante una única "
                "consulta adicional agrupada."
            ),
            "estrategia": {
                "relacion": (
                    "Routine.ejercicios"
                ),
                "tipo_anterior": (
                    "lazy loading"
                ),
                "tipo_optimizado": (
                    "eager loading con selectinload"
                ),
                "justificacion": (
                    "selectinload es adecuado para "
                    "una relación uno a muchos, "
                    "porque evita repetir una consulta "
                    "por cada rutina."
                ),
            },
        }
    ), 200


@optimization_bp.post("/tareas/resumen")
@jwt_required()
def crear_tarea_resumen():
    usuario_id = obtener_usuario_id()

    inicio = perf_counter()

    task_id = agregar_tarea(
        "resumen_usuario",
        {
            "usuario_id": usuario_id,
        },
    )

    tiempo_respuesta_ms = round(
        (perf_counter() - inicio) * 1000,
        3,
    )

    return jsonify(
        {
            "message": (
                "La tarea fue enviada a la cola."
            ),
            "task_id": task_id,
            "estado": "pendiente",
            "tiempo_respuesta_ms": (
                tiempo_respuesta_ms
            ),
            "procesamiento": (
                "asíncrono"
            ),
            "consultar_en": (
                "/api/v1/optimizacion/"
                f"tareas/{task_id}"
            ),
        }
    ), 202


@optimization_bp.get(
    "/tareas/<string:task_id>"
)
@jwt_required()
def consultar_tarea(task_id):
    tarea = obtener_tarea(task_id)

    if tarea is None:
        return jsonify(
            {
                "message": (
                    "La tarea no existe."
                ),
            }
        ), 404

    return jsonify(
        {
            "tarea": tarea,
        }
    ), 200