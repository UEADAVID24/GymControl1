from app.extensions import db


class Routine(db.Model):
    __tablename__ = "rutinas"

    id = db.Column(
        db.Integer,
        primary_key=True,
    )

    usuario_id = db.Column(
        db.Integer,
        db.ForeignKey(
            "usuarios.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    nombre = db.Column(
        db.String(100),
        nullable=False,
    )

    descripcion = db.Column(
        db.String(500),
        nullable=False,
        default="",
    )

    usuario = db.relationship(
        "User",
        back_populates="rutinas",
    )

    # Lazy loading por defecto.
    # Se utilizará eager loading explícitamente
    # en las consultas donde se requieran ejercicios.
    ejercicios = db.relationship(
        "Exercise",
        back_populates="rutina",
        cascade="all, delete-orphan",
        passive_deletes=True,
        lazy="select",
    )

    entrenamientos = db.relationship(
        "Training",
        back_populates="rutina",
        passive_deletes=True,
    )

    def to_dict(
        self,
        incluir_ejercicios: bool = False,
    ):
        datos = {
            "id": self.id,
            "usuario_id": self.usuario_id,
            "nombre": self.nombre,
            "descripcion": self.descripcion,
        }

        if incluir_ejercicios:
            datos["ejercicios"] = [
                ejercicio.to_dict()
                for ejercicio in self.ejercicios
            ]

            datos["total_ejercicios"] = len(
                self.ejercicios
            )

        return datos