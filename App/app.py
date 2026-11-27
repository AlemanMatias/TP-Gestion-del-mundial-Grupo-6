"""
UNIVERSIDAD NACIONAL DE LA MATANZA (UNLaM)
Departamento de Ingeniería e Investigaciones Tecnológicas
Asignatura: Bases de Datos Aplicada (3641) - Comisión 02-5600

TRABAJO PRÁCTICO - SISTEMA DE REGISTRO Y GESTIÓN DEL MUNDIAL DE FÚTBOL 2026
ENTREGA 9: Aplicación ABM

Integrantes: Aleman Flores, Matias Osvaldo | Gamarra Bravo, Sidney Maribel |
             Pereira, Carlos Manuel | Villa, Brenda

Descripción: Aplicación web sencilla (Streamlit + pyodbc) para gestionar el ABM
de la tabla administracion.Jugador. Las altas, bajas y modificaciones se hacen
EXCLUSIVAMENTE mediante los Stored Procedures de la Entrega 5
(sp_InsertarJugador, sp_ModificarJugador, sp_EliminarJugador). La app solo
usa SELECT para listar y para llenar los desplegables.
"""

import re
from datetime import date

import pandas as pd
import pyodbc
import streamlit as st

# ----------------------------------------------------------------------------
# CONFIGURACIÓN: cada integrante debe cambiar SOLO esta sección
# ----------------------------------------------------------------------------
# Nombre de tu servidor SQL (el que aparece en SSMS al conectarte, "Nombre del servidor")
SERVIDOR = r"localhost\SQLEXPRESS02"
BASE_DE_DATOS = "Mundial2026"
# Dejar vacíos para usar autenticación de Windows (lo más común)
USUARIO = ""
CONTRASENIA = ""

POSICIONES = ["Arquero", "Defensor", "Mediocampista", "Delantero"]


# ----------------------------------------------------------------------------
# Conexión
# ----------------------------------------------------------------------------
def _driver():
    """Elige el ODBC Driver de SQL Server más nuevo instalado."""
    disponibles = [d for d in pyodbc.drivers() if "SQL Server" in d]
    preferidos = ["ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server"]
    for p in preferidos:
        if p in disponibles:
            return p
    if disponibles:
        return disponibles[-1]
    raise RuntimeError("No se encontró ningún ODBC Driver para SQL Server.")


def get_connection():
    cadena = f"DRIVER={{{_driver()}}};SERVER={SERVIDOR};DATABASE={BASE_DE_DATOS};"
    if USUARIO:
        cadena += f"UID={USUARIO};PWD={CONTRASENIA};"
    else:
        cadena += "Trusted_Connection=yes;"
    cadena += "TrustServerCertificate=yes;"
    return pyodbc.connect(cadena)


def mensaje_sql(error):
    """Extrae el texto del THROW del SP (el mensaje agrupado de validaciones)."""
    texto = str(error.args[1]) if len(error.args) > 1 else str(error)
    m = re.search(r"\[SQL Server\](.*?)(\(SQLExec|\(\d+\)\s*$|$)", texto, re.S)
    return (m.group(1) if m else texto).strip()


# ----------------------------------------------------------------------------
# Acceso a datos
# ----------------------------------------------------------------------------
def listar_clubes():
    with get_connection() as cn:
        filas = cn.cursor().execute(
            "SELECT ID, nombre FROM administracion.Club ORDER BY nombre"
        ).fetchall()
    return {f.ID: f.nombre for f in filas}


def listar_jugadores(filtro=""):
    sql = """
        SELECT j.ID, j.nombre AS Nombre, j.apellido AS Apellido,
               j.fecha_nacimiento AS [Fecha de nacimiento],
               j.posicion_habitual AS Posición,
               c.nombre AS Club, j.ID_Club
        FROM administracion.Jugador j
        JOIN administracion.Club c ON c.ID = j.ID_Club
        WHERE (? = '' OR j.nombre LIKE '%' + ? + '%' OR j.apellido LIKE '%' + ? + '%')
        ORDER BY j.apellido, j.nombre
    """
    with get_connection() as cn:
        return pd.read_sql(sql, cn, params=[filtro, filtro, filtro])


def alta_jugador(nombre, apellido, fecha_nac, id_club, posicion):
    with get_connection() as cn:
        cur = cn.cursor()
        cur.execute(
            """SET NOCOUNT ON;
               DECLARE @id INT;
               EXEC administracion.sp_InsertarJugador ?, ?, ?, ?, ?, @id OUTPUT;
               SELECT @id;""",
            nombre, apellido, fecha_nac, id_club, posicion,
        )
        nuevo_id = cur.fetchone()[0]
        cn.commit()
    return nuevo_id


def modificar_jugador(id_jugador, nombre, apellido, fecha_nac, id_club, posicion):
    with get_connection() as cn:
        cn.cursor().execute(
            "EXEC administracion.sp_ModificarJugador ?, ?, ?, ?, ?, ?",
            id_jugador, nombre, apellido, fecha_nac, id_club, posicion,
        )
        cn.commit()


def baja_jugador(id_jugador):
    with get_connection() as cn:
        cn.cursor().execute("EXEC administracion.sp_EliminarJugador ?", id_jugador)
        cn.commit()


# ----------------------------------------------------------------------------
# Interfaz
# ----------------------------------------------------------------------------
def ejecutar(accion, ok_msg):
    """Ejecuta una acción de BD, deja un mensaje y recarga la pantalla."""
    try:
        accion()
        st.session_state["flash"] = ("ok", ok_msg)
    except pyodbc.Error as e:
        st.session_state["flash"] = ("error", mensaje_sql(e))
    st.rerun()


def mostrar_flash():
    flash = st.session_state.pop("flash", None)
    if flash:
        tipo, texto = flash
        (st.success if tipo == "ok" else st.error)(texto)


def formulario_jugador(clave, clubes, valores=None):
    """Campos comunes de alta/modificación. Devuelve los valores cargados."""
    v = valores or {}
    c1, c2 = st.columns(2)
    nombre = c1.text_input("Nombre", value=v.get("nombre", ""), key=f"{clave}_nom")
    apellido = c2.text_input("Apellido", value=v.get("apellido", ""), key=f"{clave}_ape")
    fecha = c1.date_input(
        "Fecha de nacimiento",
        value=v.get("fecha", date(2000, 1, 1)),
        min_value=date(1950, 1, 1),
        max_value=date.today(),
        key=f"{clave}_fec",
    )
    posicion = c2.selectbox(
        "Posición habitual", POSICIONES,
        index=POSICIONES.index(v["posicion"]) if v.get("posicion") in POSICIONES else 0,
        key=f"{clave}_pos",
    )
    ids = list(clubes.keys())
    idx = ids.index(v["id_club"]) if v.get("id_club") in ids else 0
    id_club = st.selectbox(
        "Club", ids, index=idx, format_func=lambda i: clubes[i], key=f"{clave}_club"
    )
    return nombre, apellido, fecha, id_club, posicion


def main():
    st.set_page_config(page_title="Mundial 2026 - ABM Jugadores", page_icon="⚽", layout="wide")
    st.title("⚽ Mundial 2026 - Gestión de Jugadores")
    st.caption("ABM sobre administracion.Jugador, usando únicamente Stored Procedures.")
    mostrar_flash()

    try:
        clubes = listar_clubes()
    except Exception as e:  # conexión / driver
        st.error(f"No se pudo conectar a la base de datos: {e}")
        st.info("Revisá SERVIDOR y BASE_DE_DATOS al inicio de app.py y que el driver ODBC esté instalado.")
        st.stop()

    if not clubes:
        st.warning("No hay clubes cargados. Cargá el juego de datos antes de usar la app.")
        st.stop()

    tab_lista, tab_alta, tab_mod, tab_baja = st.tabs(
        ["📋 Listado", "➕ Alta", "✏️ Modificación", "🗑️ Baja"]
    )

    # ---------------- Listado ----------------
    with tab_lista:
        filtro = st.text_input("Buscar por nombre o apellido", key="filtro").strip()
        df = listar_jugadores(filtro)
        st.write(f"{len(df)} jugador(es)")
        st.dataframe(df.drop(columns=["ID_Club"]), use_container_width=True, hide_index=True)

    # ---------------- Alta ----------------
    with tab_alta:
        st.subheader("Nuevo jugador")
        nombre, apellido, fecha, id_club, posicion = formulario_jugador("alta", clubes)
        if st.button("Guardar", type="primary", key="btn_alta"):
            ejecutar(
                lambda: alta_jugador(nombre, apellido, fecha, id_club, posicion),
                f"Jugador {nombre} {apellido} dado de alta correctamente.",
            )

    # ---------------- Modificación ----------------
    with tab_mod:
        st.subheader("Modificar jugador")
        df = listar_jugadores()
        if df.empty:
            st.info("No hay jugadores para modificar.")
        else:
            opciones = {int(r.ID): f"{r.Apellido}, {r.Nombre} ({r.Club})" for r in df.itertuples()}
            id_sel = st.selectbox(
                "Jugador", list(opciones.keys()), format_func=lambda i: opciones[i], key="mod_sel"
            )
            fila = df[df["ID"] == id_sel].iloc[0]
            valores = {
                "nombre": fila["Nombre"], "apellido": fila["Apellido"],
                "fecha": pd.to_datetime(fila["Fecha de nacimiento"]).date(),
                "posicion": fila["Posición"], "id_club": int(fila["ID_Club"]),
            }
            # La clave incluye el ID para que los campos se recarguen al cambiar de jugador
            nombre, apellido, fecha, id_club, posicion = formulario_jugador(
                f"mod{id_sel}", clubes, valores
            )
            if st.button("Guardar cambios", type="primary", key="btn_mod"):
                ejecutar(
                    lambda: modificar_jugador(id_sel, nombre, apellido, fecha, id_club, posicion),
                    "Jugador modificado correctamente.",
                )

    # ---------------- Baja ----------------
    with tab_baja:
        st.subheader("Eliminar jugador")
        df = listar_jugadores()
        if df.empty:
            st.info("No hay jugadores para eliminar.")
        else:
            opciones = {int(r.ID): f"{r.Apellido}, {r.Nombre} ({r.Club})" for r in df.itertuples()}
            id_del = st.selectbox(
                "Jugador", list(opciones.keys()), format_func=lambda i: opciones[i], key="del_sel"
            )
            st.warning("Esta acción no se puede deshacer. Si el jugador tiene actividad en el torneo, "
                       "el SP rechazará la baja y mostrará el motivo.")
            confirmar = st.checkbox("Confirmo que quiero eliminar este jugador", key="del_ok")
            if st.button("Eliminar", type="primary", disabled=not confirmar, key="btn_del"):
                ejecutar(lambda: baja_jugador(id_del), "Jugador eliminado correctamente.")


if __name__ == "__main__":
    main()