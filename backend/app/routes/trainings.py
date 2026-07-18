from datetime import datetime

from flask import Blueprint, jsonify, request
from flask_jwt_extended import (
    get_jwt_identity,
    jwt_required,
)

from app.extensions import db
from app.models.routine import Routine
from app.models.training import Training

trainings_bp = Blueprint(
    "trainings",
    __name__,
)


def obtener_usuario_id() -> int:
    return int(get_jwt_identity())


def fecha_valida(fecha: str) -> bool:
    try:
        datetime.strptime(
            fecha,
            "%Y-%m-%d",
        )
        return True
    except ValueError:
        return False


def buscar_rutina_usuario(
    rutina_id: int,
    usuario_id: int,
):
    return db.session.execute(
        db.select(Routine).where(
            Routine.id == rutina_id,
            Routine.usuario_id == usuario_id,
        )
    ).scalar_one_or_none()


@trainings_bp.get("/")
@jwt_required()
def listar_entrenamientos():
    usuario_id = obtener_usuario_id()

    fecha = request.args.get(
        "fecha",
        default=None,
        type=str,
    )

    consulta = db.select(Training).where(
        Training.usuario_id == usuario_id,
    )

    if fecha:
        if not fecha_valida(fecha):
            return jsonify(
                {
                    "error": "Fecha inválida",
                    "message": (
                        "La fecha debe tener el formato "
                        "AAAA-MM-DD."
                    ),
                }
            ), 400

        consulta = consulta.where(
            Training.fecha == fecha,
        )

    entrenamientos = db.session.execute(
        consulta.order_by(
            Training.fecha.desc(),
            Training.id.desc(),
        )
    ).scalars().all()

    return jsonify(
        {
            "entrenamientos": [
                entrenamiento.to_dict()
                for entrenamiento in entrenamientos
            ],
            "total": len(entrenamientos),
        }
    ), 200


@trainings_bp.get("/<int:entrenamiento_id>")
@jwt_required()
def obtener_entrenamiento(entrenamiento_id):
    usuario_id = obtener_usuario_id()

    entrenamiento = db.session.execute(
        db.select(Training).where(
            Training.id == entrenamiento_id,
            Training.usuario_id == usuario_id,
        )
    ).scalar_one_or_none()

    if entrenamiento is None:
        return jsonify(
            {
                "error": "Entrenamiento no encontrado",
                "message": (
                    "El entrenamiento no existe o no "
                    "pertenece al usuario autenticado."
                ),
            }
        ), 404

    return jsonify(
        {
            "entrenamiento": entrenamiento.to_dict(),
        }
    ), 200


@trainings_bp.post("/")
@jwt_required()
def crear_entrenamiento():
    usuario_id = obtener_usuario_id()
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify(
            {
                "error": "Solicitud inválida",
                "message": (
                    "Debe enviar los datos en formato JSON."
                ),
            }
        ), 400

    try:
        rutina_id = int(
            data.get("rutina_id", 0)
        )
        duracion_minutos = int(
            data.get("duracion_minutos", 0)
        )
    except (TypeError, ValueError):
        return jsonify(
            {
                "error": "Datos inválidos",
                "message": (
                    "La rutina y la duración deben "
                    "ser valores numéricos."
                ),
            }
        ), 400

    fecha = str(
        data.get("fecha", "")
    ).strip()

    observaciones = str(
        data.get("observaciones", "")
    ).strip()

    rutina = buscar_rutina_usuario(
        rutina_id,
        usuario_id,
    )

    if rutina is None:
        return jsonify(
            {
                "error": "Rutina no encontrada",
                "message": (
                    "La rutina no existe o no pertenece "
                    "al usuario autenticado."
                ),
            }
        ), 404

    if not fecha_valida(fecha):
        return jsonify(
            {
                "error": "Fecha inválida",
                "message": (
                    "La fecha debe tener el formato "
                    "AAAA-MM-DD."
                ),
            }
        ), 400

    if duracion_minutos <= 0:
        return jsonify(
            {
                "error": "Duración inválida",
                "message": (
                    "La duración debe ser mayor que cero."
                ),
            }
        ), 400

    if duracion_minutos > 600:
        return jsonify(
            {
                "error": "Duración inválida",
                "message": (
                    "La duración no puede superar "
                    "600 minutos."
                ),
            }
        ), 400

    if len(observaciones) > 500:
        return jsonify(
            {
                "error": "Observaciones inválidas",
                "message": (
                    "Las observaciones no pueden superar "
                    "500 caracteres."
                ),
            }
        ), 400

    nuevo_entrenamiento = Training(
        usuario_id=usuario_id,
        rutina_id=rutina.id,
        nombre_rutina=rutina.nombre,
        fecha=fecha,
        duracion_minutos=duracion_minutos,
        observaciones=observaciones,
    )

    try:
        db.session.add(nuevo_entrenamiento)
        db.session.commit()
    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "error": "Error interno",
                "message": (
                    "No se pudo registrar el entrenamiento."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Entrenamiento registrado correctamente."
            ),
            "entrenamiento": nuevo_entrenamiento.to_dict(),
        }
    ), 201


@trainings_bp.put("/<int:entrenamiento_id>")
@jwt_required()
def actualizar_entrenamiento(entrenamiento_id):
    usuario_id = obtener_usuario_id()
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify(
            {
                "error": "Solicitud inválida",
                "message": (
                    "Debe enviar los datos en formato JSON."
                ),
            }
        ), 400

    entrenamiento = db.session.execute(
        db.select(Training).where(
            Training.id == entrenamiento_id,
            Training.usuario_id == usuario_id,
        )
    ).scalar_one_or_none()

    if entrenamiento is None:
        return jsonify(
            {
                "error": "Entrenamiento no encontrado",
                "message": (
                    "El entrenamiento no existe o no "
                    "pertenece al usuario autenticado."
                ),
            }
        ), 404

    try:
        rutina_id = int(
            data.get(
                "rutina_id",
                entrenamiento.rutina_id,
            )
        )
        duracion_minutos = int(
            data.get(
                "duracion_minutos",
                entrenamiento.duracion_minutos,
            )
        )
    except (TypeError, ValueError):
        return jsonify(
            {
                "error": "Datos inválidos",
                "message": (
                    "La rutina y la duración deben "
                    "ser valores numéricos."
                ),
            }
        ), 400

    fecha = str(
        data.get(
            "fecha",
            entrenamiento.fecha,
        )
    ).strip()

    observaciones = str(
        data.get(
            "observaciones",
            entrenamiento.observaciones,
        )
    ).strip()

    rutina = buscar_rutina_usuario(
        rutina_id,
        usuario_id,
    )

    if rutina is None:
        return jsonify(
            {
                "error": "Rutina no encontrada",
                "message": (
                    "La rutina no existe o no pertenece "
                    "al usuario autenticado."
                ),
            }
        ), 404

    if not fecha_valida(fecha):
        return jsonify(
            {
                "error": "Fecha inválida",
                "message": (
                    "La fecha debe tener el formato "
                    "AAAA-MM-DD."
                ),
            }
        ), 400

    if duracion_minutos <= 0 or duracion_minutos > 600:
        return jsonify(
            {
                "error": "Duración inválida",
                "message": (
                    "La duración debe estar entre "
                    "1 y 600 minutos."
                ),
            }
        ), 400

    if len(observaciones) > 500:
        return jsonify(
            {
                "error": "Observaciones inválidas",
                "message": (
                    "Las observaciones no pueden superar "
                    "500 caracteres."
                ),
            }
        ), 400

    entrenamiento.rutina_id = rutina.id
    entrenamiento.nombre_rutina = rutina.nombre
    entrenamiento.fecha = fecha
    entrenamiento.duracion_minutos = duracion_minutos
    entrenamiento.observaciones = observaciones

    try:
        db.session.commit()
    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "error": "Error interno",
                "message": (
                    "No se pudo actualizar el entrenamiento."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Entrenamiento actualizado correctamente."
            ),
            "entrenamiento": entrenamiento.to_dict(),
        }
    ), 200


@trainings_bp.delete("/<int:entrenamiento_id>")
@jwt_required()
def eliminar_entrenamiento(entrenamiento_id):
    usuario_id = obtener_usuario_id()

    entrenamiento = db.session.execute(
        db.select(Training).where(
            Training.id == entrenamiento_id,
            Training.usuario_id == usuario_id,
        )
    ).scalar_one_or_none()

    if entrenamiento is None:
        return jsonify(
            {
                "error": "Entrenamiento no encontrado",
                "message": (
                    "El entrenamiento no existe o no "
                    "pertenece al usuario autenticado."
                ),
            }
        ), 404

    try:
        db.session.delete(entrenamiento)
        db.session.commit()
    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "error": "Error interno",
                "message": (
                    "No se pudo eliminar el entrenamiento."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Entrenamiento eliminado correctamente."
            ),
        }
    ), 200