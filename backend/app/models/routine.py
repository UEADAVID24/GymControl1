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

    ejercicios = db.relationship(
        "Exercise",
        back_populates="rutina",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    entrenamientos = db.relationship(
        "Training",
        back_populates="rutina",
        passive_deletes=True,
    )

    def to_dict(self):
        return {
            "id": self.id,
            "usuario_id": self.usuario_id,
            "nombre": self.nombre,
            "descripcion": self.descripcion,
        }