from time import perf_counter

from flask import Blueprint, jsonify, request
from flask_jwt_extended import (
    get_jwt_identity,
    jwt_required,
)
from sqlalchemy.orm import joinedload

from app.extensions import cache, db
from app.models.routine import Routine


routines_bp = Blueprint(
    "routines",
    __name__,
)

CACHE_TTL_SEGUNDOS = 60


def obtener_usuario_id() -> int:
    return int(get_jwt_identity())


def obtener_clave_cache(
    usuario_id: int,
) -> str:
    return f"rutinas_usuario:{usuario_id}"


def invalidar_cache_rutinas(
    usuario_id: int,
) -> None:
    cache.delete(
        obtener_clave_cache(usuario_id)
    )


@routines_bp.get("/")
@jwt_required()
def listar_rutinas():
    usuario_id = obtener_usuario_id()

    clave_cache = obtener_clave_cache(
        usuario_id
    )

    inicio = perf_counter()

    # Estrategia Cache Aside:
    # primero se busca la información en caché.
    datos_cache = cache.get(clave_cache)

    if datos_cache is not None:
        tiempo_ms = round(
            (perf_counter() - inicio) * 1000,
            3,
        )

        return jsonify(
            {
                **datos_cache,
                "cache": {
                    "estado": "HIT",
                    "ttl_segundos": (
                        CACHE_TTL_SEGUNDOS
                    ),
                },
                "tiempo_ms": tiempo_ms,
            }
        ), 200

    # Si los datos no están en caché,
    # se consulta la base de datos.
    #
    # joinedload aplica Eager Loading para
    # obtener las rutinas y sus ejercicios
    # sin generar el problema N+1.
    resultado = (
        db.session.execute(
            db.select(Routine)
            .options(
                joinedload(
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
        )
        .unique()
        .scalars()
        .all()
    )

    respuesta = {
        "rutinas": [
            rutina.to_dict(
                incluir_ejercicios=True
            )
            for rutina in resultado
        ],
        "total": len(resultado),
    }

    # Se guarda la respuesta en caché
    # durante 60 segundos.
    cache.set(
        clave_cache,
        respuesta,
        timeout=CACHE_TTL_SEGUNDOS,
    )

    tiempo_ms = round(
        (perf_counter() - inicio) * 1000,
        3,
    )

    return jsonify(
        {
            **respuesta,
            "cache": {
                "estado": "MISS",
                "ttl_segundos": (
                    CACHE_TTL_SEGUNDOS
                ),
            },
            "tiempo_ms": tiempo_ms,
        }
    ), 200


@routines_bp.get("/<int:rutina_id>")
@jwt_required()
def obtener_rutina(rutina_id):
    usuario_id = obtener_usuario_id()

    # También se usa joinedload para recuperar
    # la rutina con todos sus ejercicios.
    rutina = (
        db.session.execute(
            db.select(Routine)
            .options(
                joinedload(
                    Routine.ejercicios
                )
            )
            .where(
                Routine.id == rutina_id,
                Routine.usuario_id
                == usuario_id,
            )
        )
        .unique()
        .scalar_one_or_none()
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

    return jsonify(
        {
            "rutina": rutina.to_dict(
                incluir_ejercicios=True
            ),
        }
    ), 200


@routines_bp.post("/")
@jwt_required()
def crear_rutina():
    usuario_id = obtener_usuario_id()
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify(
            {
                "error": "Solicitud inválida",
                "message": (
                    "Debe enviar los datos "
                    "en formato JSON."
                ),
            }
        ), 400

    nombre = str(
        data.get("nombre", "")
    ).strip()

    descripcion = str(
        data.get("descripcion", "")
    ).strip()

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

    if len(descripcion) > 500:
        return jsonify(
            {
                "error": "Descripción inválida",
                "message": (
                    "La descripción no puede superar "
                    "los 500 caracteres."
                ),
            }
        ), 400

    rutina_existente = db.session.execute(
        db.select(Routine).where(
            Routine.usuario_id == usuario_id,
            db.func.lower(Routine.nombre)
            == nombre.lower(),
        )
    ).scalar_one_or_none()

    if rutina_existente is not None:
        return jsonify(
            {
                "error": "Rutina duplicada",
                "message": (
                    "Ya tienes una rutina "
                    "con ese nombre."
                ),
            }
        ), 409

    nueva_rutina = Routine(
        usuario_id=usuario_id,
        nombre=nombre,
        descripcion=descripcion,
    )

    try:
        db.session.add(nueva_rutina)
        db.session.commit()

        # Al crear una rutina se elimina
        # la información anterior del caché.
        invalidar_cache_rutinas(
            usuario_id
        )

    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "error": "Error interno",
                "message": (
                    "No se pudo crear la rutina."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Rutina creada correctamente."
            ),
            "rutina": nueva_rutina.to_dict(),
            "cache_invalidada": True,
        }
    ), 201


@routines_bp.put("/<int:rutina_id>")
@jwt_required()
def actualizar_rutina(rutina_id):
    usuario_id = obtener_usuario_id()
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify(
            {
                "error": "Solicitud inválida",
                "message": (
                    "Debe enviar los datos "
                    "en formato JSON."
                ),
            }
        ), 400

    rutina = db.session.execute(
        db.select(Routine).where(
            Routine.id == rutina_id,
            Routine.usuario_id == usuario_id,
        )
    ).scalar_one_or_none()

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

    nombre = str(
        data.get(
            "nombre",
            rutina.nombre,
        )
    ).strip()

    descripcion = str(
        data.get(
            "descripcion",
            rutina.descripcion,
        )
    ).strip()

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

    if len(descripcion) > 500:
        return jsonify(
            {
                "error": "Descripción inválida",
                "message": (
                    "La descripción no puede superar "
                    "los 500 caracteres."
                ),
            }
        ), 400

    rutina_duplicada = db.session.execute(
        db.select(Routine).where(
            Routine.usuario_id == usuario_id,
            Routine.id != rutina_id,
            db.func.lower(Routine.nombre)
            == nombre.lower(),
        )
    ).scalar_one_or_none()

    if rutina_duplicada is not None:
        return jsonify(
            {
                "error": "Rutina duplicada",
                "message": (
                    "Ya tienes otra rutina "
                    "con ese nombre."
                ),
            }
        ), 409

    rutina.nombre = nombre
    rutina.descripcion = descripcion

    try:
        db.session.commit()

        # Se invalida el caché porque
        # la información fue modificada.
        invalidar_cache_rutinas(
            usuario_id
        )

    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "error": "Error interno",
                "message": (
                    "No se pudo actualizar "
                    "la rutina."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Rutina actualizada correctamente."
            ),
            "rutina": rutina.to_dict(),
            "cache_invalidada": True,
        }
    ), 200


@routines_bp.delete("/<int:rutina_id>")
@jwt_required()
def eliminar_rutina(rutina_id):
    usuario_id = obtener_usuario_id()

    rutina = db.session.execute(
        db.select(Routine).where(
            Routine.id == rutina_id,
            Routine.usuario_id == usuario_id,
        )
    ).scalar_one_or_none()

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

    try:
        db.session.delete(rutina)
        db.session.commit()

        # Se invalida el caché porque
        # una rutina fue eliminada.
        invalidar_cache_rutinas(
            usuario_id
        )

    except Exception:
        db.session.rollback()

        return jsonify(
            {
                "error": "Error interno",
                "message": (
                    "No se pudo eliminar la rutina."
                ),
            }
        ), 500

    return jsonify(
        {
            "message": (
                "Rutina eliminada correctamente."
            ),
            "cache_invalidada": True,
        }
    ), 200