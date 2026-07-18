from datetime import datetime

from flask import Blueprint, jsonify, request
from flask_jwt_extended import (
    get_jwt_identity,
    jwt_required,
)

from app.extensions import db
from app.models.weight import Weight

weights_bp = Blueprint(
    "weights",
    __name__,
)


def obtener_usuario_id() -> int:
    return int(get_jwt_identity())


def fecha_valida(fecha: str) -> bool:
    try:
        datetime.strptime(fecha, "%Y-%m-%d")
        return True
    except ValueError:
        return False


@weights_bp.get("/")
@jwt_required()
def listar_pesos():
    usuario_id = obtener_usuario_id()

    registros = db.session.execute(
        db.select(Weight)
        .where(Weight.usuario_id == usuario_id)
        .order_by(
            Weight.fecha.asc(),
            Weight.id.asc(),
        )
    ).scalars().all()

    return jsonify(
        {
            "pesos": [
                registro.to_dict()
                for registro in registros
            ],
            "total": len(registros),
        }
    ), 200


@weights_bp.post("/")
@jwt_required()
def crear_peso():
    usuario_id = obtener_usuario_id()
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify(
            {
                "message": "Debe enviar los datos en formato JSON.",
            }
        ), 400

    try:
        peso = float(data.get("peso", 0))
    except (TypeError, ValueError):
        return jsonify(
            {
                "message": "El peso debe ser numérico.",
            }
        ), 400

    fecha = str(data.get("fecha", "")).strip()

    if peso <= 0 or peso > 500:
        return jsonify(
            {
                "message": "El peso debe estar entre 1 y 500 kg.",
            }
        ), 400

    if not fecha_valida(fecha):
        return jsonify(
            {
                "message": "La fecha debe tener el formato AAAA-MM-DD.",
            }
        ), 400

    nuevo_registro = Weight(
        usuario_id=usuario_id,
        peso=peso,
        fecha=fecha,
    )

    try:
        db.session.add(nuevo_registro)
        db.session.commit()
    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "message": "No se pudo registrar el peso.",
            }
        ), 500

    return jsonify(
        {
            "message": "Peso registrado correctamente.",
            "peso": nuevo_registro.to_dict(),
        }
    ), 201


@weights_bp.put("/<int:peso_id>")
@jwt_required()
def actualizar_peso(peso_id):
    usuario_id = obtener_usuario_id()
    data = request.get_json(silent=True)

    registro = db.session.execute(
        db.select(Weight).where(
            Weight.id == peso_id,
            Weight.usuario_id == usuario_id,
        )
    ).scalar_one_or_none()

    if registro is None:
        return jsonify(
            {
                "message": "El registro de peso no existe.",
            }
        ), 404

    if not isinstance(data, dict):
        return jsonify(
            {
                "message": "Debe enviar los datos en formato JSON.",
            }
        ), 400

    try:
        peso = float(
            data.get(
                "peso",
                registro.peso,
            )
        )
    except (TypeError, ValueError):
        return jsonify(
            {
                "message": "El peso debe ser numérico.",
            }
        ), 400

    fecha = str(
        data.get(
            "fecha",
            registro.fecha,
        )
    ).strip()

    if peso <= 0 or peso > 500:
        return jsonify(
            {
                "message": "El peso debe estar entre 1 y 500 kg.",
            }
        ), 400

    if not fecha_valida(fecha):
        return jsonify(
            {
                "message": "La fecha debe tener el formato AAAA-MM-DD.",
            }
        ), 400

    registro.peso = peso
    registro.fecha = fecha

    try:
        db.session.commit()
    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "message": "No se pudo actualizar el peso.",
            }
        ), 500

    return jsonify(
        {
            "message": "Peso actualizado correctamente.",
            "peso": registro.to_dict(),
        }
    ), 200


@weights_bp.delete("/<int:peso_id>")
@jwt_required()
def eliminar_peso(peso_id):
    usuario_id = obtener_usuario_id()

    registro = db.session.execute(
        db.select(Weight).where(
            Weight.id == peso_id,
            Weight.usuario_id == usuario_id,
        )
    ).scalar_one_or_none()

    if registro is None:
        return jsonify(
            {
                "message": "El registro de peso no existe.",
            }
        ), 404

    try:
        db.session.delete(registro)
        db.session.commit()
    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "message": "No se pudo eliminar el peso.",
            }
        ), 500

    return jsonify(
        {
            "message": "Peso eliminado correctamente.",
        }
    ), 200