import os

from dotenv import load_dotenv
from flask import Flask, jsonify

from .extensions import (
    cache,
    cors,
    db,
    jwt,
    migrate,
)

from .task_queue import iniciar_worker


def create_app() -> Flask:
    load_dotenv()

    app = Flask(__name__)

    database_url = os.getenv(
        "DATABASE_URL",
        "sqlite:///gymcontrol.db",
    )

    # Compatibilidad con PostgreSQL en Render.
    if database_url.startswith("postgres://"):
        database_url = database_url.replace(
            "postgres://",
            "postgresql://",
            1,
        )

    app.config["SQLALCHEMY_DATABASE_URI"] = database_url

    app.config[
        "SQLALCHEMY_TRACK_MODIFICATIONS"
    ] = False

    app.config["JWT_SECRET_KEY"] = os.getenv(
        "JWT_SECRET_KEY",
        "gymcontrol-clave-secreta-2026",
    )

    # Configuración del caché
    app.config["CACHE_TYPE"] = os.getenv(
        "CACHE_TYPE",
        "SimpleCache",
    )

    app.config["CACHE_DEFAULT_TIMEOUT"] = 60

    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    cache.init_app(app)

    cors.init_app(
        app,
        resources={
            r"/api/*": {
                "origins": "*",
            },
        },
    )

    from .models import (
        Exercise,
        Reminder,
        Routine,
        Training,
        User,
        Weight,
    )

    from .routes.auth import auth_bp
    from .routes.exercises import exercises_bp
    from .routes.optimization import (
        optimization_bp,
    )
    from .routes.reminders import reminders_bp
    from .routes.routines import routines_bp
    from .routes.trainings import trainings_bp
    from .routes.weights import weights_bp

    app.register_blueprint(
        auth_bp,
        url_prefix="/api/v1/auth",
    )

    app.register_blueprint(
        routines_bp,
        url_prefix="/api/v1/rutinas",
    )

    app.register_blueprint(
        exercises_bp,
        url_prefix="/api/v1",
    )

    app.register_blueprint(
        trainings_bp,
        url_prefix="/api/v1/entrenamientos",
    )

    app.register_blueprint(
        weights_bp,
        url_prefix="/api/v1/pesos",
    )

    app.register_blueprint(
        reminders_bp,
        url_prefix="/api/v1/recordatorios",
    )

    app.register_blueprint(
        optimization_bp,
        url_prefix="/api/v1/optimizacion",
    )

    # Inicia el worker en segundo plano
    iniciar_worker(app)

    @app.get("/")
    def home():
        return jsonify(
            {
                "message": "API de GymControl funcionando",
                "status": "ok",
            }
        ), 200

    @app.get("/api/v1/health")
    def health():
        return jsonify(
            {
                "service": "GymControl Backend",
                "status": "ok",
                "cache": app.config["CACHE_TYPE"],
                "worker": "activo",
            }
        ), 200

    return app