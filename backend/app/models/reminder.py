from app.extensions import db


class Reminder(db.Model):
    __tablename__ = "recordatorios"

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

    titulo = db.Column(
        db.String(100),
        nullable=False,
    )

    mensaje = db.Column(
        db.String(300),
        nullable=False,
        default="",
    )

    dia_semana = db.Column(
        db.Integer,
        nullable=False,
    )

    hora = db.Column(
        db.Integer,
        nullable=False,
    )

    minuto = db.Column(
        db.Integer,
        nullable=False,
    )

    activo = db.Column(
        db.Boolean,
        nullable=False,
        default=True,
    )

    usuario = db.relationship(
        "User",
        back_populates="recordatorios",
    )

    def to_dict(self):
        return {
            "id": self.id,
            "usuario_id": self.usuario_id,
            "titulo": self.titulo,
            "mensaje": self.mensaje,
            "dia_semana": self.dia_semana,
            "hora": self.hora,
            "minuto": self.minuto,
            "activo": self.activo,
        }