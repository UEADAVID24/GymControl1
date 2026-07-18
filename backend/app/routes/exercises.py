from flask import Blueprint, jsonify, request
from flask_jwt_extended import (
    get_jwt_identity,
    jwt_required,
)

from app.extensions import db
from app.models.exercise import Exercise
from app.models.routine import Routine

exercises_bp = Blueprint(
    "exercises",
    __name__,
)


def obtener_usuario_id() -> int:
    return int(get_jwt_identity())


def buscar_rutina_del_usuario(
    rutina_id: int,
    usuario_id: int,
):
    return db.session.execute(
        db.select(Routine).where(
            Routine.id == rutina_id,
            Routine.usuario_id == usuario_id,
        )
    ).scalar_one_or_none()


@exercises_bp.get(
    "/rutinas/<int:rutina_id>/ejercicios"
)
@jwt_required()
def listar_ejercicios(rutina_id):
    usuario_id = obtener_usuario_id()

    rutina = buscar_rutina_del_usuario(
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

    ejercicios = db.session.execute(
        db.select(Exercise)
        .where(
            Exercise.rutina_id == rutina_id,
        )
        .order_by(
            Exercise.id.desc(),
        )
    ).scalars().all()

    return jsonify(
        {
            "ejercicios": [
                ejercicio.to_dict()
                for ejercicio in ejercicios
            ],
            "total": len(ejercicios),
        }
    ), 200


@exercises_bp.post(
    "/rutinas/<int:rutina_id>/ejercicios"
)
@jwt_required()
def crear_ejercicio(rutina_id):
    usuario_id = obtener_usuario_id()

    rutina = buscar_rutina_del_usuario(
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

    nombre = str(
        data.get("nombre", "")
    ).strip()

    try:
        series = int(data.get("series", 0))
        repeticiones = int(
            data.get("repeticiones", 0)
        )
        peso = float(data.get("peso", 0))
    except (TypeError, ValueError):
        return jsonify(
            {
                "error": "Datos inválidos",
                "message": (
                    "Series, repeticiones y peso "
                    "deben ser valores numéricos."
                ),
            }
        ), 400

    if len(nombre) < 2 or len(nombre) > 100:
        return jsonify(
            {
                "error": "Nombre inválido",
                "message": (
                    "El nombre debe tener entre "
                    "2 y 100 caracteres."
                ),
            }
        ), 400

    if series <= 0:
        return jsonify(
            {
                "error": "Series inválidas",
                "message": (
                    "La cantidad de series debe ser "
                    "mayor que cero."
                ),
            }
        ), 400

    if repeticiones <= 0:
        return jsonify(
            {
                "error": "Repeticiones inválidas",
                "message": (
                    "La cantidad de repeticiones debe "
                    "ser mayor que cero."
                ),
            }
        ), 400

    if peso < 0:
        return jsonify(
            {
                "error": "Peso inválido",
                "message": (
                    "El peso no puede ser negativo."
                ),
            }
        ), 400

    nuevo_ejercicio = Exercise(
        rutina_id=rutina_id,
        nombre=nombre,
        series=series,
        repeticiones=repeticiones,
        peso=peso,
    )

    try:
        db.session.add(nuevo_ejercicio)
        db.session.commit()
    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "error": "Error interno",
                "message": (
                    "No se pudo crear el ejercicio."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Ejercicio creado correctamente."
            ),
            "ejercicio": nuevo_ejercicio.to_dict(),
        }
    ), 201


@exercises_bp.put(
    "/ejercicios/<int:ejercicio_id>"
)
@jwt_required()
def actualizar_ejercicio(ejercicio_id):
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

    ejercicio = db.session.execute(
        db.select(Exercise)
        .join(Routine)
        .where(
            Exercise.id == ejercicio_id,
            Routine.usuario_id == usuario_id,
        )
    ).scalar_one_or_none()

    if ejercicio is None:
        return jsonify(
            {
                "error": "Ejercicio no encontrado",
                "message": (
                    "El ejercicio no existe o no pertenece "
                    "al usuario autenticado."
                ),
            }
        ), 404

    nombre = str(
        data.get("nombre", ejercicio.nombre)
    ).strip()

    try:
        series = int(
            data.get("series", ejercicio.series)
        )
        repeticiones = int(
            data.get(
                "repeticiones",
                ejercicio.repeticiones,
            )
        )
        peso = float(
            data.get("peso", ejercicio.peso)
        )
    except (TypeError, ValueError):
        return jsonify(
            {
                "error": "Datos inválidos",
                "message": (
                    "Series, repeticiones y peso "
                    "deben ser valores numéricos."
                ),
            }
        ), 400

    if len(nombre) < 2 or len(nombre) > 100:
        return jsonify(
            {
                "error": "Nombre inválido",
                "message": (
                    "El nombre debe tener entre "
                    "2 y 100 caracteres."
                ),
            }
        ), 400

    if series <= 0 or repeticiones <= 0:
        return jsonify(
            {
                "error": "Valores inválidos",
                "message": (
                    "Series y repeticiones deben ser "
                    "mayores que cero."
                ),
            }
        ), 400

    if peso < 0:
        return jsonify(
            {
                "error": "Peso inválido",
                "message": (
                    "El peso no puede ser negativo."
                ),
            }
        ), 400

    ejercicio.nombre = nombre
    ejercicio.series = series
    ejercicio.repeticiones = repeticiones
    ejercicio.peso = peso

    try:
        db.session.commit()
    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "error": "Error interno",
                "message": (
                    "No se pudo actualizar el ejercicio."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Ejercicio actualizado correctamente."
            ),
            "ejercicio": ejercicio.to_dict(),
        }
    ), 200


@exercises_bp.delete(
    "/ejercicios/<int:ejercicio_id>"
)
@jwt_required()
def eliminar_ejercicio(ejercicio_id):
    usuario_id = obtener_usuario_id()

    ejercicio = db.session.execute(
        db.select(Exercise)
        .join(Routine)
        .where(
            Exercise.id == ejercicio_id,
            Routine.usuario_id == usuario_id,
        )
    ).scalar_one_or_none()

    if ejercicio is None:
        return jsonify(
            {
                "error": "Ejercicio no encontrado",
                "message": (
                    "El ejercicio no existe o no pertenece "
                    "al usuario autenticado."
                ),
            }
        ), 404

    try:
        db.session.delete(ejercicio)
        db.session.commit()
    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "error": "Error interno",
                "message": (
                    "No se pudo eliminar el ejercicio."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Ejercicio eliminado correctamente."
            ),
        }
    ), 200