import threading
import time
import traceback
import uuid
from datetime import datetime, timezone

from flask import current_app
from sqlalchemy import func

from app.extensions import db
from app.models.exercise import Exercise
from app.models.routine import Routine
from app.models.training import Training
from app.models.weight import Weight


task_results = {}
task_results_lock = threading.Lock()

worker_started = False
worker_lock = threading.Lock()


def fecha_actual_utc() -> str:
    return datetime.now(
        timezone.utc,
    ).isoformat()


def obtener_tarea(task_id: str):
    with task_results_lock:
        tarea = task_results.get(task_id)

        if tarea is None:
            return None

        return dict(tarea)


def generar_resumen_usuario(
    usuario_id: int,
):
    # Simula una tarea que tarda varios segundos.
    time.sleep(2)

    total_rutinas = db.session.scalar(
        db.select(
            func.count(Routine.id),
        ).where(
            Routine.usuario_id == usuario_id,
        )
    ) or 0

    total_ejercicios = db.session.scalar(
        db.select(
            func.count(Exercise.id),
        )
        .join(
            Routine,
            Exercise.rutina_id == Routine.id,
        )
        .where(
            Routine.usuario_id == usuario_id,
        )
    ) or 0

    total_entrenamientos = db.session.scalar(
        db.select(
            func.count(Training.id),
        ).where(
            Training.usuario_id == usuario_id,
        )
    ) or 0

    peso_actual = db.session.execute(
        db.select(Weight.peso)
        .where(
            Weight.usuario_id == usuario_id,
        )
        .order_by(
            Weight.fecha.desc(),
            Weight.id.desc(),
        )
        .limit(1)
    ).scalar_one_or_none()

    return {
        "usuario_id": usuario_id,
        "total_rutinas": int(total_rutinas),
        "total_ejercicios": int(total_ejercicios),
        "total_entrenamientos": int(
            total_entrenamientos
        ),
        "peso_actual": (
            float(peso_actual)
            if peso_actual is not None
            else None
        ),
    }


def procesar_tarea(
    app,
    task_id: str,
    tipo: str,
    datos: dict,
) -> None:
    print(
        f"Procesando tarea {task_id}",
        flush=True,
    )

    with task_results_lock:
        if task_id not in task_results:
            return

        task_results[task_id][
            "estado"
        ] = "procesando"

        task_results[task_id][
            "iniciada_en"
        ] = fecha_actual_utc()

    try:
        with app.app_context():
            if tipo == "resumen_usuario":
                resultado = generar_resumen_usuario(
                    int(
                        datos["usuario_id"]
                    )
                )
            else:
                raise ValueError(
                    "Tipo de tarea no soportado."
                )

        with task_results_lock:
            task_results[task_id][
                "resultado"
            ] = resultado

            task_results[task_id][
                "estado"
            ] = "completada"

            task_results[task_id][
                "error"
            ] = None

        print(
            f"Tarea {task_id} completada.",
            flush=True,
        )

    except Exception as error:
        traceback.print_exc()

        with task_results_lock:
            if task_id in task_results:
                task_results[task_id][
                    "estado"
                ] = "fallida"

                task_results[task_id][
                    "error"
                ] = str(error)

        print(
            f"Tarea {task_id} fallida: {error}",
            flush=True,
        )

    finally:
        with task_results_lock:
            if task_id in task_results:
                task_results[task_id][
                    "finalizada_en"
                ] = fecha_actual_utc()

        try:
            with app.app_context():
                db.session.remove()
        except Exception:
            pass


def agregar_tarea(
    tipo: str,
    datos: dict,
) -> str:
    task_id = str(uuid.uuid4())

    app = current_app._get_current_object()

    with task_results_lock:
        task_results[task_id] = {
            "id": task_id,
            "tipo": tipo,
            "estado": "pendiente",
            "creada_en": fecha_actual_utc(),
            "iniciada_en": None,
            "finalizada_en": None,
            "resultado": None,
            "error": None,
        }

    print(
        f"Tarea {task_id} agregada.",
        flush=True,
    )

    thread = threading.Thread(
        target=procesar_tarea,
        args=(
            app,
            task_id,
            tipo,
            datos,
        ),
        daemon=True,
        name=f"gymcontrol-task-{task_id[:8]}",
    )

    thread.start()

    return task_id


def iniciar_worker(app) -> None:
    global worker_started

    with worker_lock:
        if worker_started:
            return

        print(
            "Iniciando sistema de tareas...",
            flush=True,
        )

        worker_started = True

        print(
            "Sistema de tareas iniciado correctamente.",
            flush=True,
        )