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


# =========================
# FUNCIONES AUXILIARES
# =========================

def correo_valido(correo: str) -> bool:
    patron = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"
    return re.match(patron, correo) is not None


def obtener_usuario_autenticado():
    usuario_id = int(get_jwt_identity())

    return db.session.get(
        User,
        usuario_id,
    )


# =========================
# RUTA PRINCIPAL
# =========================

@auth_bp.get("/")
def auth_home():
    return jsonify(
        {
            "message": "Módulo de autenticación activo",
        }
    ), 200


# =========================
# REGISTRO
# =========================

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

    nombre = str(
        data.get("nombre", "")
    ).strip()

    correo = str(
        data.get("correo", "")
    ).strip().lower()

    password = str(
        data.get("password", "")
    )

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
                "message": (
                    "Ingrese un correo electrónico válido."
                ),
            }
        ), 400

    if len(password) < 6:
        return jsonify(
            {
                "error": "Contraseña inválida",
                "message": (
                    "La contraseña debe contener al menos "
                    "6 caracteres."
                ),
            }
        ), 400

    usuario_existente = db.session.execute(
        db.select(User).filter_by(
            correo=correo,
        )
    ).scalar_one_or_none()

    if usuario_existente is not None:
        return jsonify(
            {
                "error": "Correo duplicado",
                "message": (
                    "Ya existe una cuenta registrada "
                    "con ese correo."
                ),
            }
        ), 409

    nuevo_usuario = User(
        nombre=nombre,
        correo=correo,
    )

    nuevo_usuario.set_password(
        password,
    )

    try:
        db.session.add(
            nuevo_usuario,
        )

        db.session.commit()

    except IntegrityError:
        db.session.rollback()

        return jsonify(
            {
                "error": "Correo duplicado",
                "message": (
                    "Ya existe una cuenta registrada "
                    "con ese correo."
                ),
            }
        ), 409

    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "error": "Error interno",
                "message": (
                    "No se pudo registrar el usuario."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Usuario registrado correctamente."
            ),
            "usuario": nuevo_usuario.to_dict(),
        }
    ), 201


# =========================
# INICIO DE SESIÓN
# =========================

@auth_bp.post("/login")
def login():
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

    correo = str(
        data.get("correo", "")
    ).strip().lower()

    password = str(
        data.get("password", "")
    )

    if not correo or not password:
        return jsonify(
            {
                "error": "Datos incompletos",
                "message": (
                    "El correo y la contraseña "
                    "son obligatorios."
                ),
            }
        ), 400

    usuario = db.session.execute(
        db.select(User).filter_by(
            correo=correo,
        )
    ).scalar_one_or_none()

    if (
        usuario is None
        or not usuario.check_password(password)
    ):
        return jsonify(
            {
                "error": "Credenciales incorrectas",
                "message": (
                    "El correo o la contraseña "
                    "son incorrectos."
                ),
            }
        ), 401

    access_token = create_access_token(
        identity=str(usuario.id),
        additional_claims={
            "nombre": usuario.nombre,
            "correo": usuario.correo,
            "rol": "usuario",
        },
        expires_delta=timedelta(
            minutes=30,
        ),
    )

    refresh_token = create_refresh_token(
        identity=str(usuario.id),
        expires_delta=timedelta(
            days=7,
        ),
    )

    return jsonify(
        {
            "message": (
                "Inicio de sesión correcto."
            ),
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "Bearer",
            "expires_in": 1800,
            "usuario": usuario.to_dict(),
        }
    ), 200


# =========================
# RENOVAR TOKEN
# =========================

@auth_bp.post("/refresh")
@jwt_required(refresh=True)
def refresh():
    usuario_id = get_jwt_identity()

    nuevo_access_token = create_access_token(
        identity=usuario_id,
        expires_delta=timedelta(
            minutes=30,
        ),
    )

    return jsonify(
        {
            "access_token": nuevo_access_token,
            "token_type": "Bearer",
            "expires_in": 1800,
        }
    ), 200


# =========================
# OBTENER PERFIL
# =========================

@auth_bp.get("/me")
@jwt_required()
def obtener_perfil():
    usuario = obtener_usuario_autenticado()

    if usuario is None:
        return jsonify(
            {
                "error": "Usuario no encontrado",
                "message": (
                    "El usuario asociado al token "
                    "no existe."
                ),
            }
        ), 404

    return jsonify(
        {
            "usuario": usuario.to_dict(),
        }
    ), 200


# =========================
# ACTUALIZAR PERFIL
# =========================

@auth_bp.put("/me")
@jwt_required()
def actualizar_perfil():
    usuario = obtener_usuario_autenticado()

    if usuario is None:
        return jsonify(
            {
                "error": "Usuario no encontrado",
                "message": (
                    "El usuario asociado al token "
                    "no existe."
                ),
            }
        ), 404

    data = request.get_json(
        silent=True,
    )

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
        data.get(
            "nombre",
            usuario.nombre,
        )
    ).strip()

    correo = str(
        data.get(
            "correo",
            usuario.correo,
        )
    ).strip().lower()

    if not nombre or not correo:
        return jsonify(
            {
                "error": "Datos incompletos",
                "message": (
                    "El nombre y el correo "
                    "son obligatorios."
                ),
            }
        ), 400

    if len(nombre) < 3 or len(nombre) > 100:
        return jsonify(
            {
                "error": "Nombre inválido",
                "message": (
                    "El nombre debe tener entre "
                    "3 y 100 caracteres."
                ),
            }
        ), 400

    if not correo_valido(correo):
        return jsonify(
            {
                "error": "Correo inválido",
                "message": (
                    "Ingrese un correo electrónico válido."
                ),
            }
        ), 400

    correo_existente = db.session.execute(
        db.select(User).where(
            User.correo == correo,
            User.id != usuario.id,
        )
    ).scalar_one_or_none()

    if correo_existente is not None:
        return jsonify(
            {
                "error": "Correo duplicado",
                "message": (
                    "Ese correo ya está registrado "
                    "por otro usuario."
                ),
            }
        ), 409

    usuario.nombre = nombre
    usuario.correo = correo

    try:
        db.session.commit()

    except IntegrityError:
        db.session.rollback()

        return jsonify(
            {
                "error": "Correo duplicado",
                "message": (
                    "Ese correo ya está registrado "
                    "por otro usuario."
                ),
            }
        ), 409

    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "error": "Error interno",
                "message": (
                    "No se pudo actualizar el perfil."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Perfil actualizado correctamente."
            ),
            "usuario": usuario.to_dict(),
        }
    ), 200


# =========================
# CAMBIAR CONTRASEÑA
# =========================

@auth_bp.put("/password")
@jwt_required()
def cambiar_password():
    usuario = obtener_usuario_autenticado()

    if usuario is None:
        return jsonify(
            {
                "error": "Usuario no encontrado",
                "message": (
                    "El usuario asociado al token "
                    "no existe."
                ),
            }
        ), 404

    data = request.get_json(
        silent=True,
    )

    if not isinstance(data, dict):
        return jsonify(
            {
                "error": "Solicitud inválida",
                "message": (
                    "Debe enviar los datos en formato JSON."
                ),
            }
        ), 400

    password_actual = str(
        data.get(
            "password_actual",
            "",
        )
    )

    password_nueva = str(
        data.get(
            "password_nueva",
            "",
        )
    )

    if not password_actual or not password_nueva:
        return jsonify(
            {
                "error": "Datos incompletos",
                "message": (
                    "La contraseña actual y la nueva "
                    "son obligatorias."
                ),
            }
        ), 400

    if not usuario.check_password(
        password_actual,
    ):
        return jsonify(
            {
                "error": "Contraseña incorrecta",
                "message": (
                    "La contraseña actual es incorrecta."
                ),
            }
        ), 401

    if len(password_nueva) < 6:
        return jsonify(
            {
                "error": "Contraseña inválida",
                "message": (
                    "La nueva contraseña debe contener "
                    "al menos 6 caracteres."
                ),
            }
        ), 400

    if usuario.check_password(
        password_nueva,
    ):
        return jsonify(
            {
                "error": "Contraseña repetida",
                "message": (
                    "La nueva contraseña debe ser "
                    "diferente de la actual."
                ),
            }
        ), 400

    usuario.set_password(
        password_nueva,
    )

    try:
        db.session.commit()

    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "error": "Error interno",
                "message": (
                    "No se pudo cambiar la contraseña."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Contraseña actualizada correctamente."
            ),
        }
    ), 200


# =========================
# ELIMINAR CUENTA
# =========================

@auth_bp.delete("/me")
@jwt_required()
def eliminar_cuenta():
    usuario = obtener_usuario_autenticado()

    if usuario is None:
        return jsonify(
            {
                "error": "Usuario no encontrado",
                "message": (
                    "El usuario asociado al token "
                    "no existe."
                ),
            }
        ), 404

    data = request.get_json(
        silent=True,
    )

    if not isinstance(data, dict):
        return jsonify(
            {
                "error": "Solicitud inválida",
                "message": (
                    "Debe enviar la contraseña "
                    "para confirmar."
                ),
            }
        ), 400

    password = str(
        data.get(
            "password",
            "",
        )
    )

    if not password:
        return jsonify(
            {
                "error": "Contraseña requerida",
                "message": (
                    "Ingrese su contraseña "
                    "para eliminar la cuenta."
                ),
            }
        ), 400

    if not usuario.check_password(
        password,
    ):
        return jsonify(
            {
                "error": "Contraseña incorrecta",
                "message": (
                    "La contraseña ingresada "
                    "es incorrecta."
                ),
            }
        ), 401

    try:
        db.session.delete(
            usuario,
        )

        db.session.commit()

    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "error": "Error interno",
                "message": (
                    "No se pudo eliminar la cuenta."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Cuenta eliminada correctamente."
            ),
        }
    ), 200