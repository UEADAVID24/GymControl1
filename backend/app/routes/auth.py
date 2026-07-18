import re
from datetime import timedelta

from flask import Blueprint, jsonify, request
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    get_jwt_identity,
    jwt_required,
)
from sqlalchemy.exc import IntegrityError

from app.extensions import db
from app.models.user import User

auth_bp = Blueprint("auth", __name__)


def correo_valido(correo: str) -> bool:
    patron = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"
    return re.match(patron, correo) is not None


@auth_bp.get("/")
def auth_home():
    return jsonify(
        {
            "message": "Módulo de autenticación activo",
        }
    ), 200


@auth_bp.post("/register")
def register():
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify(
            {
                "error": "Solicitud inválida",
                "message": "Debe enviar los datos en formato JSON.",
            }
        ), 400

    nombre = str(data.get("nombre", "")).strip()
    correo = str(data.get("correo", "")).strip().lower()
    password = str(data.get("password", ""))

    if not nombre or not correo or not password:
        return jsonify(
            {
                "error": "Datos incompletos",
                "message": (
                    "Los campos nombre, correo y password "
                    "son obligatorios."
                ),
            }
        ), 400

    if len(nombre) < 3 or len(nombre) > 100:
        return jsonify(
            {
                "error": "Nombre inválido",
                "message": (
                    "El nombre debe tener entre 3 y 100 caracteres."
                ),
            }
        ), 400

    if not correo_valido(correo):
        return jsonify(
            {
                "error": "Correo inválido",
                "message": "Ingrese un correo electrónico válido.",
            }
        ), 400

    if len(password) < 6:
        return jsonify(
            {
                "error": "Contraseña inválida",
                "message": (
                    "La contraseña debe contener al menos 6 caracteres."
                ),
            }
        ), 400

    usuario_existente = db.session.execute(
        db.select(User).filter_by(correo=correo)
    ).scalar_one_or_none()

    if usuario_existente is not None:
        return jsonify(
            {
                "error": "Correo duplicado",
                "message": (
                    "Ya existe una cuenta registrada con ese correo."
                ),
            }
        ), 409

    nuevo_usuario = User(
        nombre=nombre,
        correo=correo,
    )
    nuevo_usuario.set_password(password)

    try:
        db.session.add(nuevo_usuario)
        db.session.commit()
    except IntegrityError:
        db.session.rollback()

        return jsonify(
            {
                "error": "Correo duplicado",
                "message": (
                    "Ya existe una cuenta registrada con ese correo."
                ),
            }
        ), 409
    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "error": "Error interno",
                "message": "No se pudo registrar el usuario.",
            }
        ), 500

    return jsonify(
        {
            "message": "Usuario registrado correctamente.",
            "usuario": nuevo_usuario.to_dict(),
        }
    ), 201


@auth_bp.post("/login")
def login():
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify(
            {
                "error": "Solicitud inválida",
                "message": "Debe enviar los datos en formato JSON.",
            }
        ), 400

    correo = str(data.get("correo", "")).strip().lower()
    password = str(data.get("password", ""))

    if not correo or not password:
        return jsonify(
            {
                "error": "Datos incompletos",
                "message": "El correo y la contraseña son obligatorios.",
            }
        ), 400

    usuario = db.session.execute(
        db.select(User).filter_by(correo=correo)
    ).scalar_one_or_none()

    if usuario is None or not usuario.check_password(password):
        return jsonify(
            {
                "error": "Credenciales incorrectas",
                "message": "El correo o la contraseña son incorrectos.",
            }
        ), 401

    access_token = create_access_token(
        identity=str(usuario.id),
        additional_claims={
            "nombre": usuario.nombre,
            "correo": usuario.correo,
            "rol": "usuario",
        },
        expires_delta=timedelta(minutes=30),
    )

    refresh_token = create_refresh_token(
        identity=str(usuario.id),
        expires_delta=timedelta(days=7),
    )

    return jsonify(
        {
            "message": "Inicio de sesión correcto.",
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "Bearer",
            "expires_in": 1800,
            "usuario": usuario.to_dict(),
        }
    ), 200


@auth_bp.post("/refresh")
@jwt_required(refresh=True)
def refresh():
    usuario_id = get_jwt_identity()

    nuevo_access_token = create_access_token(
        identity=usuario_id,
        expires_delta=timedelta(minutes=30),
    )

    return jsonify(
        {
            "access_token": nuevo_access_token,
            "token_type": "Bearer",
            "expires_in": 1800,
        }
    ), 200


@auth_bp.get("/me")
@jwt_required()
def obtener_perfil():
    usuario_id = get_jwt_identity()

    usuario = db.session.get(
        User,
        int(usuario_id),
    )

    if usuario is None:
        return jsonify(
            {
                "error": "Usuario no encontrado",
                "message": "El usuario asociado al token no existe.",
            }
        ), 404

    return jsonify(
        {
            "usuario": usuario.to_dict(),
        }
    ), 200