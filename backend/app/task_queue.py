import queue
import threading
import time
import uuid
import traceback
from datetime import datetime, timezone

from sqlalchemy import func

from app.extensions import db
from app.models.exercise import Exercise
from app.models.routine import Routine
from app.models.training import Training
from app.models.weight import Weight


task_queue = queue.Queue()
task_results = {}

worker_started = False
worker_lock = threading.Lock()


def fecha_actual_utc() -> str:
    return datetime.now(
        timezone.utc,
    ).isoformat()


def agregar_tarea(
    tipo: str,
    datos: dict,
) -> str:
    task_id = str(uuid.uuid4())

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

    task_queue.put(
        {
            "id": task_id,
            "tipo": tipo,
            "datos": datos,
        }
    )

    return task_id


def obtener_tarea(task_id: str):
    return task_results.get(task_id)


def generar_resumen_usuario(
    usuario_id: int,
):
    # Simula un procesamiento pesado
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
        "total_rutinas": total_rutinas,
        "total_ejercicios": total_ejercicios,
        "total_entrenamientos": total_entrenamientos,
        "peso_actual": peso_actual,
    }


def ejecutar_worker(app):
    print("===== WORKER INICIADO =====")

    while True:
        tarea = None
        task_id = None

        try:
            tarea = task_queue.get()

            task_id = tarea["id"]

            print(f"Procesando tarea {task_id}")

            task_results[task_id][
                "estado"
            ] = "procesando"

            task_results[task_id][
                "iniciada_en"
            ] = fecha_actual_utc()

            with app.app_context():

                if tarea["tipo"] == "resumen_usuario":

                    resultado = generar_resumen_usuario(
                        int(
                            tarea["datos"][
                                "usuario_id"
                            ]
                        )
                    )

                else:
                    raise ValueError(
                        "Tipo de tarea no soportado."
                    )

            task_results[task_id][
                "resultado"
            ] = resultado

            task_results[task_id][
                "estado"
            ] = "completada"

            print(
                f"Tarea {task_id} completada."
            )

        except Exception as error:

            traceback.print_exc()

            if task_id is not None:

                task_results[task_id][
                    "estado"
                ] = "fallida"

                task_results[task_id][
                    "error"
                ] = str(error)

        finally:

            if task_id is not None:

                task_results[task_id][
                    "finalizada_en"
                ] = fecha_actual_utc()

            if tarea is not None:
                task_queue.task_done()


def iniciar_worker(app) -> None:
    global worker_started

    with worker_lock:

        if worker_started:
            return

        print("Iniciando worker...")

        worker = threading.Thread(
            target=ejecutar_worker,
            args=(app,),
            daemon=True,
            name="gymcontrol-worker",
        )

        worker.start()

        worker_started = True

        print("Worker iniciado correctamente.")