from werkzeug.security import (
    check_password_hash,
    generate_password_hash,
)

from app.extensions import db


class User(db.Model):
    __tablename__ = "usuarios"

    id = db.Column(
        db.Integer,
        primary_key=True,
    )

    nombre = db.Column(
        db.String(100),
        nullable=False,
    )

    correo = db.Column(
        db.String(120),
        unique=True,
        nullable=False,
    )

    password = db.Column(
        db.String(255),
        nullable=False,
    )

    rutinas = db.relationship(
        "Routine",
        back_populates="usuario",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    entrenamientos = db.relationship(
        "Training",
        back_populates="usuario",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    pesos = db.relationship(
        "Weight",
        back_populates="usuario",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    recordatorios = db.relationship(
        "Reminder",
        back_populates="usuario",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    def set_password(self, password):
        self.password = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(
            self.password,
            password,
        )

    def to_dict(self):
        return {
            "id": self.id,
            "nombre": self.nombre,
            "correo": self.correo,
        }