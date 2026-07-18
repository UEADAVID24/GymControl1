from flask import Blueprint, jsonify, request
from flask_jwt_extended import (
    get_jwt_identity,
    jwt_required,
)

from app.extensions import db
from app.models.reminder import Reminder

reminders_bp = Blueprint(
    "reminders",
    __name__,
)


def obtener_usuario_id() -> int:
    return int(get_jwt_identity())


def obtener_recordatorio_usuario(
    recordatorio_id: int,
    usuario_id: int,
):
    return db.session.execute(
        db.select(Reminder).where(
            Reminder.id == recordatorio_id,
            Reminder.usuario_id == usuario_id,
        )
    ).scalar_one_or_none()


def validar_datos(
    titulo,
    mensaje,
    dia_semana,
    hora,
    minuto,
):
    if not titulo:
        return "El título es obligatorio."

    if len(titulo) > 100:
        return "El título no puede superar 100 caracteres."

    if len(mensaje) > 300:
        return "El mensaje no puede superar 300 caracteres."

    if dia_semana < 1 or dia_semana > 7:
        return "El día de la semana debe estar entre 1 y 7."

    if hora < 0 or hora > 23:
        return "La hora debe estar entre 0 y 23."

    if minuto < 0 or minuto > 59:
        return "El minuto debe estar entre 0 y 59."

    return None


@reminders_bp.get("/")
@jwt_required()
def listar_recordatorios():
    usuario_id = obtener_usuario_id()

    recordatorios = db.session.execute(
        db.select(Reminder)
        .where(
            Reminder.usuario_id == usuario_id,
        )
        .order_by(
            Reminder.dia_semana.asc(),
            Reminder.hora.asc(),
            Reminder.minuto.asc(),
            Reminder.id.asc(),
        )
    ).scalars().all()

    return jsonify(
        {
            "recordatorios": [
                recordatorio.to_dict()
                for recordatorio in recordatorios
            ],
            "total": len(recordatorios),
        }
    ), 200


@reminders_bp.get("/<int:recordatorio_id>")
@jwt_required()
def obtener_recordatorio(recordatorio_id):
    usuario_id = obtener_usuario_id()

    recordatorio = obtener_recordatorio_usuario(
        recordatorio_id,
        usuario_id,
    )

    if recordatorio is None:
        return jsonify(
            {
                "message": (
                    "El recordatorio no existe o no "
                    "pertenece al usuario autenticado."
                ),
            }
        ), 404

    return jsonify(
        {
            "recordatorio": recordatorio.to_dict(),
        }
    ), 200


@reminders_bp.post("/")
@jwt_required()
def crear_recordatorio():
    usuario_id = obtener_usuario_id()
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify(
            {
                "message": (
                    "Debe enviar los datos en formato JSON."
                ),
            }
        ), 400

    titulo = str(
        data.get("titulo", "")
    ).strip()

    mensaje = str(
        data.get("mensaje", "")
    ).strip()

    try:
        dia_semana = int(
            data.get("dia_semana", 0)
        )
        hora = int(
            data.get("hora", -1)
        )
        minuto = int(
            data.get("minuto", -1)
        )
    except (TypeError, ValueError):
        return jsonify(
            {
                "message": (
                    "El día, la hora y el minuto deben "
                    "ser valores numéricos."
                ),
            }
        ), 400

    activo = data.get("activo", True)

    if not isinstance(activo, bool):
        activo = str(activo).lower() in (
            "true",
            "1",
            "yes",
        )

    error_validacion = validar_datos(
        titulo,
        mensaje,
        dia_semana,
        hora,
        minuto,
    )

    if error_validacion is not None:
        return jsonify(
            {
                "message": error_validacion,
            }
        ), 400

    nuevo_recordatorio = Reminder(
        usuario_id=usuario_id,
        titulo=titulo,
        mensaje=mensaje,
        dia_semana=dia_semana,
        hora=hora,
        minuto=minuto,
        activo=activo,
    )

    try:
        db.session.add(nuevo_recordatorio)
        db.session.commit()
    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "message": (
                    "No se pudo crear el recordatorio."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Recordatorio creado correctamente."
            ),
            "recordatorio": (
                nuevo_recordatorio.to_dict()
            ),
        }
    ), 201


@reminders_bp.put("/<int:recordatorio_id>")
@jwt_required()
def actualizar_recordatorio(recordatorio_id):
    usuario_id = obtener_usuario_id()
    data = request.get_json(silent=True)

    recordatorio = obtener_recordatorio_usuario(
        recordatorio_id,
        usuario_id,
    )

    if recordatorio is None:
        return jsonify(
            {
                "message": (
                    "El recordatorio no existe o no "
                    "pertenece al usuario autenticado."
                ),
            }
        ), 404

    if not isinstance(data, dict):
        return jsonify(
            {
                "message": (
                    "Debe enviar los datos en formato JSON."
                ),
            }
        ), 400

    titulo = str(
        data.get(
            "titulo",
            recordatorio.titulo,
        )
    ).strip()

    mensaje = str(
        data.get(
            "mensaje",
            recordatorio.mensaje,
        )
    ).strip()

    try:
        dia_semana = int(
            data.get(
                "dia_semana",
                recordatorio.dia_semana,
            )
        )
        hora = int(
            data.get(
                "hora",
                recordatorio.hora,
            )
        )
        minuto = int(
            data.get(
                "minuto",
                recordatorio.minuto,
            )
        )
    except (TypeError, ValueError):
        return jsonify(
            {
                "message": (
                    "El día, la hora y el minuto deben "
                    "ser valores numéricos."
                ),
            }
        ), 400

    activo = data.get(
        "activo",
        recordatorio.activo,
    )

    if not isinstance(activo, bool):
        activo = str(activo).lower() in (
            "true",
            "1",
            "yes",
        )

    error_validacion = validar_datos(
        titulo,
        mensaje,
        dia_semana,
        hora,
        minuto,
    )

    if error_validacion is not None:
        return jsonify(
            {
                "message": error_validacion,
            }
        ), 400

    recordatorio.titulo = titulo
    recordatorio.mensaje = mensaje
    recordatorio.dia_semana = dia_semana
    recordatorio.hora = hora
    recordatorio.minuto = minuto
    recordatorio.activo = activo

    try:
        db.session.commit()
    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "message": (
                    "No se pudo actualizar el recordatorio."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Recordatorio actualizado correctamente."
            ),
            "recordatorio": recordatorio.to_dict(),
        }
    ), 200


@reminders_bp.patch(
    "/<int:recordatorio_id>/estado"
)
@jwt_required()
def actualizar_estado_recordatorio(
    recordatorio_id,
):
    usuario_id = obtener_usuario_id()
    data = request.get_json(silent=True)

    recordatorio = obtener_recordatorio_usuario(
        recordatorio_id,
        usuario_id,
    )

    if recordatorio is None:
        return jsonify(
            {
                "message": (
                    "El recordatorio no existe o no "
                    "pertenece al usuario autenticado."
                ),
            }
        ), 404

    if not isinstance(data, dict):
        return jsonify(
            {
                "message": (
                    "Debe enviar los datos en formato JSON."
                ),
            }
        ), 400

    activo = data.get("activo")

    if not isinstance(activo, bool):
        return jsonify(
            {
                "message": (
                    "El campo activo debe ser verdadero "
                    "o falso."
                ),
            }
        ), 400

    recordatorio.activo = activo

    try:
        db.session.commit()
    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "message": (
                    "No se pudo cambiar el estado."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Estado actualizado correctamente."
            ),
            "recordatorio": recordatorio.to_dict(),
        }
    ), 200


@reminders_bp.delete("/<int:recordatorio_id>")
@jwt_required()
def eliminar_recordatorio(recordatorio_id):
    usuario_id = obtener_usuario_id()

    recordatorio = obtener_recordatorio_usuario(
        recordatorio_id,
        usuario_id,
    )

    if recordatorio is None:
        return jsonify(
            {
                "message": (
                    "El recordatorio no existe o no "
                    "pertenece al usuario autenticado."
                ),
            }
        ), 404

    try:
        db.session.delete(recordatorio)
        db.session.commit()
    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "message": (
                    "No se pudo eliminar el recordatorio."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Recordatorio eliminado correctamente."
            ),
        }
    ), 200