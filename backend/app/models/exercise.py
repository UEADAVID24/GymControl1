from app.extensions import db


class Exercise(db.Model):
    __tablename__ = "ejercicios"

    id = db.Column(
        db.Integer,
        primary_key=True,
    )

    rutina_id = db.Column(
        db.Integer,
        db.ForeignKey(
            "rutinas.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    nombre = db.Column(
        db.String(100),
        nullable=False,
    )

    series = db.Column(
        db.Integer,
        nullable=False,
    )

    repeticiones = db.Column(
        db.Integer,
        nullable=False,
    )

    peso = db.Column(
        db.Float,
        nullable=False,
        default=0,
    )

    rutina = db.relationship(
        "Routine",
        back_populates="ejercicios",
    )

    def to_dict(self):
        return {
            "id": self.id,
            "rutina_id": self.rutina_id,
            "nombre": self.nombre,
            "series": self.series,
            "repeticiones": self.repeticiones,
            "peso": self.peso,
        }