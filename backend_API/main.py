from contextlib import asynccontextmanager
from pathlib import Path
import shutil
import uuid

from fastapi import FastAPI, Depends, HTTPException, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from sqlalchemy import select, func
from sqlalchemy.exc import IntegrityError
from pwdlib import PasswordHash

from database import Base, engine, obtener_sesion
from models import Usuario, Blog, Comentario, Valoracion
from schemas import (
    UsuarioCrear,
    UsuarioActualizar,
    UsuarioRespuesta,
    BlogRespuesta,
    ComentarioCrear,
    ComentarioRespuesta,
    LoginRequest,
    ValoracionCrear,
)

password_hash = PasswordHash.recommended()

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(
    title="API de aplicación móvil",
    lifespan=lifespan,
)

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def inicio():
    return {"mensaje": "API funcionando correctamente"}


# ==========================================
# AUTENTICACIÓN / LOGIN
# ==========================================

@app.post("/login")
def login(datos: LoginRequest, db: Session = Depends(obtener_sesion)):
    usuario = db.scalar(
        select(Usuario).where(Usuario.mail == datos.mail.strip().lower())
    )

    pass_db = getattr(usuario, 'password', None) or getattr(usuario, 'pass_hash', None)

    if not usuario or not pass_db or not password_hash.verify(datos.password, pass_db):
        raise HTTPException(
            status_code=401,
            detail="Correo o contraseña incorrectos",
        )

    return {
        "id_usr": usuario.id_usr,
        "nom_usr": usuario.nom_usr,
        "mail": usuario.mail,
        "dir_usr": usuario.dir_usr,
        "tip_usu": usuario.tip_usu,
    }


# ==========================================
# USUARIOS
# ==========================================

@app.get("/usuarios", response_model=list[UsuarioRespuesta])
def listar_usuarios(db: Session = Depends(obtener_sesion)):
    return db.scalars(
        select(Usuario).order_by(Usuario.id_usr)
    ).all()


@app.post("/usuarios", response_model=UsuarioRespuesta, status_code=201)
def crear_usuario(
    datos: UsuarioCrear,
    db: Session = Depends(obtener_sesion),
):
    hash_password = password_hash.hash(datos.password)

    usuario = Usuario(
        nom_usr=datos.nom_usr.strip(),
        mail=datos.mail.strip().lower(),
        pass_hash=hash_password,
        dir_usr=datos.dir_usr,
        tip_usu=datos.tip_usu if datos.tip_usu in (1, 2) else 2,
    )

    db.add(usuario)

    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="El correo ya está registrado",
        )

    return usuario


@app.put("/usuarios/{usuario_id}", response_model=UsuarioRespuesta)
def actualizar_usuario(
    usuario_id: int,
    datos: UsuarioActualizar,
    db: Session = Depends(obtener_sesion),
):
    usuario = db.get(Usuario, usuario_id)
    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    usuario.nom_usr = datos.nom_usr.strip()
    usuario.mail = datos.mail.strip().lower()
    usuario.dir_usr = datos.dir_usr
    usuario.tip_usu = datos.tip_usu

    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="El correo ya está registrado por otro usuario",
        )

    return usuario


@app.delete("/usuarios/{usuario_id}", status_code=200)
def eliminar_usuario(
    usuario_id: int,
    db: Session = Depends(obtener_sesion),
):
    usuario = db.get(Usuario, usuario_id)
    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    db.delete(usuario)
    db.commit()

    return {"mensaje": "Usuario eliminado correctamente"}


# ==========================================
# BLOG / PUBLICACIONES
# ==========================================

@app.get("/blog", response_model=list[BlogRespuesta])
def listar_blog(db: Session = Depends(obtener_sesion)):
    return db.scalars(
        select(Blog).order_by(Blog.id_blog)
    ).all()


@app.get("/blog/{blog_id}", response_model=BlogRespuesta)
def obtener_blog(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
):
    publicacion = db.get(Blog, blog_id)

    if publicacion is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    return publicacion


@app.post("/blog", response_model=BlogRespuesta, status_code=201)
async def crear_blog(
    titulo: str = Form(...),
    descripcion: str = Form(...),
    tags: str = Form(None),
    imagen: UploadFile = File(...),
    db: Session = Depends(obtener_sesion),
):
    extension = Path(imagen.filename or "").suffix.lower()
    if extension not in [".jpg", ".jpeg", ".png", ".webp"]:
        raise HTTPException(
            status_code=400,
            detail="Formato de imagen no permitido",
        )

    nombre_archivo = f"{uuid.uuid4().hex}{extension}"
    ruta_archivo = UPLOAD_DIR / nombre_archivo

    with ruta_archivo.open("wb") as destino:
        shutil.copyfileobj(imagen.file, destino)

    ruta_publica = f"/uploads/{nombre_archivo}"

    desc_val = descripcion.strip()
    publicacion = Blog(
        titulo=titulo.strip(),
        img=ruta_publica,
        tags=tags.strip() if tags and tags.strip() else None,
    )

    if hasattr(Blog, 'desc'):
        setattr(publicacion, 'desc', desc_val)
    elif hasattr(Blog, 'descripcion'):
        setattr(publicacion, 'descripcion', desc_val)

    db.add(publicacion)
    db.commit()
    db.refresh(publicacion)

    return publicacion


@app.put("/blog/{blog_id}", response_model=BlogRespuesta)
async def actualizar_blog(
    blog_id: int,
    titulo: str = Form(...),
    descripcion: str = Form(...),
    tags: str = Form(None),
    usr_id: int | None = Form(None),
    imagen: UploadFile | None = File(None),
    db: Session = Depends(obtener_sesion),
):
    if usr_id is not None:
        solicitante = db.get(Usuario, usr_id)
        if solicitante is None or solicitante.tip_usu != 1:
            raise HTTPException(
                status_code=403,
                detail="Solo un administrador puede editar publicaciones",
            )

    publicacion = db.get(Blog, blog_id)
    if publicacion is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    publicacion.titulo = titulo.strip()
    publicacion.tags = tags.strip() if tags and tags.strip() else None

    desc_val = descripcion.strip()
    if hasattr(Blog, 'desc'):
        setattr(publicacion, 'desc', desc_val)
    elif hasattr(Blog, 'descripcion'):
        setattr(publicacion, 'descripcion', desc_val)

    if imagen is not None and imagen.filename:
        extension = Path(imagen.filename).suffix.lower()
        if extension not in [".jpg", ".jpeg", ".png", ".webp"]:
            raise HTTPException(
                status_code=400,
                detail="Formato de imagen no permitido",
            )

        nombre_archivo = f"{uuid.uuid4().hex}{extension}"
        ruta_archivo = UPLOAD_DIR / nombre_archivo

        with ruta_archivo.open("wb") as destino:
            shutil.copyfileobj(imagen.file, destino)

        publicacion.img = f"/uploads/{nombre_archivo}"

    db.commit()
    db.refresh(publicacion)

    return publicacion


@app.delete("/blog/{blog_id}", status_code=200)
def eliminar_blog(
    blog_id: int,
    usr_id: int | None = None,
    db: Session = Depends(obtener_sesion),
):
    if usr_id is not None:
        solicitante = db.get(Usuario, usr_id)
        if solicitante is None or solicitante.tip_usu != 1:
            raise HTTPException(
                status_code=403,
                detail="Solo un administrador puede eliminar publicaciones",
            )

    publicacion = db.get(Blog, blog_id)
    if publicacion is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    db.delete(publicacion)
    db.commit()

    return {"mensaje": "Publicación eliminada correctamente"}


# ==========================================
# COMENTARIOS
# ==========================================

@app.get("/comentarios", response_model=list[ComentarioRespuesta])
def listar_comentarios(db: Session = Depends(obtener_sesion)):
    resultados = db.execute(
        select(Comentario, Usuario.nom_usr)
        .outerjoin(Usuario, Comentario.usr_id == Usuario.id_usr)
        .order_by(Comentario.id_com)
    ).all()

    lista = []
    for com, nom_usr in resultados:
        lista.append(
            ComentarioRespuesta(
                id_com=com.id_com,
                comentario=com.comentario,
                fecha=com.fecha,
                estatus=com.estatus,
                usr_id=com.usr_id,
                blog_id=com.blog_id,
                nom_usr=nom_usr or f"Usuario #{com.usr_id}",
            )
        )
    return lista


@app.post("/comentarios", response_model=ComentarioRespuesta, status_code=201)
def crear_comentario(
    datos: ComentarioCrear,
    db: Session = Depends(obtener_sesion),
):
    if not datos.comentario.strip():
        raise HTTPException(
            status_code=422,
            detail="El comentario no puede estar vacío",
        )

    usuario = db.get(Usuario, datos.usr_id)
    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    if usuario.tip_usu == 1:
        raise HTTPException(
            status_code=403,
            detail="Los administradores no pueden publicar comentarios",
        )

    if db.get(Blog, datos.blog_id) is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    nuevo = Comentario(
        comentario=datos.comentario.strip(),
        usr_id=datos.usr_id,
        blog_id=datos.blog_id,
        estatus=1,
    )

    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return ComentarioRespuesta(
        id_com=nuevo.id_com,
        comentario=nuevo.comentario,
        fecha=nuevo.fecha,
        estatus=nuevo.estatus,
        usr_id=nuevo.usr_id,
        blog_id=nuevo.blog_id,
        nom_usr=usuario.nom_usr,
    )


@app.delete("/comentarios/{comentario_id}", status_code=200)
def eliminar_comentario(
    comentario_id: int,
    usr_id: int | None = None,
    db: Session = Depends(obtener_sesion),
):
    if usr_id is not None:
        solicitante = db.get(Usuario, usr_id)
        if solicitante is None or solicitante.tip_usu != 1:
            raise HTTPException(
                status_code=403,
                detail="Solo un administrador puede eliminar comentarios",
            )

    comentario = db.get(Comentario, comentario_id)
    if comentario is None:
        raise HTTPException(
            status_code=404,
            detail="Comentario no encontrado",
        )

    db.delete(comentario)
    db.commit()

    return {"mensaje": "Comentario eliminado correctamente"}


# ==========================================
# VALORACIONES (1 A 5 ESTRELLAS)
# ==========================================

@app.get("/valoraciones/{blog_id}")
def obtener_valoracion_blog(
    blog_id: int,
    usr_id: int | None = None,
    db: Session = Depends(obtener_sesion),
):
    promedio, total = db.execute(
        select(func.avg(Valoracion.estrellas), func.count(Valoracion.id_val))
        .where(Valoracion.blog_id == blog_id)
    ).one()

    mi_voto = 0
    if usr_id is not None:
        existente = db.scalar(
            select(Valoracion).where(
                Valoracion.blog_id == blog_id,
                Valoracion.usr_id == usr_id,
            )
        )
        if existente:
            mi_voto = existente.estrellas

    return {
        "blog_id": blog_id,
        "promedio": round(float(promedio), 1) if promedio else 0.0,
        "total": int(total or 0),
        "mi_voto": mi_voto,
    }


@app.post("/valoraciones")
def guardar_valoracion(
    datos: ValoracionCrear,
    db: Session = Depends(obtener_sesion),
):
    usuario = db.get(Usuario, datos.usr_id)
    if usuario is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    if usuario.tip_usu == 1:
        raise HTTPException(
            status_code=403,
            detail="Los administradores no pueden calificar publicaciones",
        )

    if db.get(Blog, datos.blog_id) is None:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")

    existente = db.scalar(
        select(Valoracion).where(
            Valoracion.blog_id == datos.blog_id,
            Valoracion.usr_id == datos.usr_id,
        )
    )

    if existente:
        existente.estrellas = datos.estrellas
    else:
        nueva = Valoracion(
            estrellas=datos.estrellas,
            usr_id=datos.usr_id,
            blog_id=datos.blog_id,
        )
        db.add(nueva)

    db.commit()
    return {"mensaje": "Valoración guardada correctamente"}