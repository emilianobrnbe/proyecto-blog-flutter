from datetime import datetime
from pydantic import BaseModel, Field


class UsuarioBase(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150)
    dir_usr: str | None = Field(default=None, max_length=200)
    tip_usu: int = Field(default=2, ge=1, le=2)


class UsuarioCrear(UsuarioBase):
    password: str = Field(min_length=8)


class UsuarioActualizar(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150)
    dir_usr: str | None = None
    tip_usu: int = 2


class UsuarioRespuesta(UsuarioBase):
    id_usr: int

    class Config:
        from_attributes = True


class BlogCrear(BaseModel):
    titulo: str = Field(min_length=2, max_length=150)
    descripcion: str = Field(min_length=1)
    img: str | None = Field(default=None, max_length=500)
    tags: str | None = Field(default=None, max_length=255)


class BlogRespuesta(BaseModel):
    id_blog: int
    titulo: str
    descripcion: str
    img: str | None = None
    tags: str | None = None

    class Config:
        from_attributes = True


class ComentarioCrear(BaseModel):
    comentario: str = Field(min_length=1)
    usr_id: int
    blog_id: int


class ComentarioRespuesta(BaseModel):
    id_com: int
    comentario: str
    fecha: datetime
    estatus: int
    usr_id: int
    blog_id: int
    nom_usr: str | None = None

    class Config:
        from_attributes = True


class LoginRequest(BaseModel):
    mail: str
    password: str


class ValoracionCrear(BaseModel):
    estrellas: int = Field(ge=1, le=5)
    usr_id: int
    blog_id: int