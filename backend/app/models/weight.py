from app.extensions import db


class Weight(db.Model):
    __tablename__ = "pesos"

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

    peso = db.Column(
        db.Float,
        nullable=False,
    )

    fecha = db.Column(
        db.String(10),
        nullable=False,
        index=True,
    )

    usuario = db.relationship(
        "User",
        back_populates="pesos",
    )

    def to_dict(self):
        return {
            "id": self.id,
            "usuario_id": self.usuario_id,
            "peso": self.peso,
            "fecha": self.fecha,
        }