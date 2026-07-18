from app.extensions import db


class Training(db.Model):
    __tablename__ = "entrenamientos"

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

    rutina_id = db.Column(
        db.Integer,
        db.ForeignKey(
            "rutinas.id",
            ondelete="SET NULL",
        ),
        nullable=True,
        index=True,
    )

    nombre_rutina = db.Column(
        db.String(100),
        nullable=False,
    )

    fecha = db.Column(
        db.String(10),
        nullable=False,
        index=True,
    )

    duracion_minutos = db.Column(
        db.Integer,
        nullable=False,
    )

    observaciones = db.Column(
        db.String(500),
        nullable=False,
        default="",
    )

    usuario = db.relationship(
        "User",
        back_populates="entrenamientos",
    )

    rutina = db.relationship(
        "Routine",
        back_populates="entrenamientos",
    )

    def to_dict(self):
        return {
            "id": self.id,
            "usuario_id": self.usuario_id,
            "rutina_id": self.rutina_id,
            "nombre_rutina": self.nombre_rutina,
            "fecha": self.fecha,
            "duracion_minutos": self.duracion_minutos,
            "observaciones": self.observaciones,
        }