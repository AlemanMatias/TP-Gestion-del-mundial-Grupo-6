/* 
   UNIVERSIDAD NACIONAL DE LA MATANZA (UNLaM)
   Departamento de Ingeniería e Investigaciones Tecnológicas
   Asignatura: Bases de Datos Aplicada (3641)
   Comisión: 02-5600 (Viernes Tarde)
   
   TRABAJO PRÁCTICO - SISTEMA DE REGISTRO Y GESTIÓN DEL MUNDIAL DE FÚTBOL 2026
   
   Integrantes del Grupo:
     - Aleman Flores, Matias Osvaldo
     - Gamarra Bravo, Sidney Maribel
     - Perreira, Carlos Manuel
     - Villa, Brenda
     
   Script: 03_creacion_tablas.sql
   Descripción: Creación limpia de las 25 tablas con sus restricciones.
*/

USE Mundial2026;
GO

-- =========================================================================================
-- BLOQUE A: TABLAS MAESTRAS BASE E INDEPENDIENTES
-- =========================================================================================

-- 1. Tabla: administracion.Pais
CREATE TABLE administracion.Pais (
    ID INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    pbi_percapita DECIMAL(12,2) NULL,
    huso_horario CHAR(6) NULL,

    CONSTRAINT PK_Pais PRIMARY KEY (ID),
    CONSTRAINT UQ_Pais_nombre UNIQUE (nombre)
);
GO

-- 2. Tabla: administracion.Fase_Torneo
CREATE TABLE administracion.Fase_Torneo (
    ID INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    orden SMALLINT NOT NULL,

    CONSTRAINT PK_Fase_Torneo PRIMARY KEY (ID),
    CONSTRAINT UQ_Fase_Torneo_nombre UNIQUE (nombre),
    CONSTRAINT UQ_Fase_Torneo_orden UNIQUE (orden),
    CONSTRAINT CK_Fase_Torneo_orden CHECK (orden > 0)
);
GO

-- 3. Tabla: administracion.Club
CREATE TABLE administracion.Club (
    ID INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(100) NOT NULL,

    CONSTRAINT PK_Club PRIMARY KEY (ID),
    CONSTRAINT UQ_Club_nombre UNIQUE (nombre)
);
GO

-- 4. Tabla: publicidad.Anunciante
CREATE TABLE publicidad.Anunciante (
    ID INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(100) NOT NULL,

    CONSTRAINT PK_Anunciante PRIMARY KEY (ID),
    CONSTRAINT UQ_Anunciante_nombre UNIQUE (nombre)
);
GO

-- 5. Tabla: administracion.Sede
CREATE TABLE administracion.Sede (
    ID INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100) NOT NULL,
    capacidad INT NOT NULL,
    huso_horario CHAR(6) NOT NULL,
    ID_Pais INT NOT NULL,

    CONSTRAINT PK_Sede PRIMARY KEY (ID),
    CONSTRAINT CK_Sede_capacidad CHECK (capacidad > 0),
    CONSTRAINT FK_Sede_Pais FOREIGN KEY (ID_Pais) 
        REFERENCES administracion.Pais(ID)
);
GO

-- =========================================================================================
-- BLOQUE B: DELEGACIONES, PLANTELES Y ÁRBITROS
-- =========================================================================================

-- 6. Tabla: administracion.Seleccion
CREATE TABLE administracion.Seleccion (
    ID INT IDENTITY(1,1) NOT NULL,
    ID_Pais INT NOT NULL,
    confederacion VARCHAR(15) NOT NULL,
    grupo_asignado CHAR(1) NOT NULL,

    CONSTRAINT PK_Seleccion PRIMARY KEY (ID),
    CONSTRAINT UQ_Seleccion_Pais UNIQUE (ID_Pais),
    CONSTRAINT CK_Seleccion_grupo CHECK (grupo_asignado BETWEEN 'A' AND 'L'),
    CONSTRAINT FK_Seleccion_Pais FOREIGN KEY (ID_Pais) 
        REFERENCES administracion.Pais(ID)
);
GO

-- 7. Tabla: administracion.Miembro_Cuerpo_Tecnico
CREATE TABLE administracion.Miembro_Cuerpo_Tecnico (
    ID INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    rol VARCHAR(50) NOT NULL,
    ID_Seleccion INT NOT NULL,

    CONSTRAINT PK_Miembro_Cuerpo_Tecnico PRIMARY KEY (ID),
    CONSTRAINT FK_MCT_Seleccion FOREIGN KEY (ID_Seleccion) 
        REFERENCES administracion.Seleccion(ID)
);
GO

-- 8. Tabla: administracion.Jugador
CREATE TABLE administracion.Jugador (
    ID INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    ID_Club INT NOT NULL,
    posicion_habitual VARCHAR(30) NOT NULL,

    CONSTRAINT PK_Jugador PRIMARY KEY (ID),
    CONSTRAINT FK_Jugador_Club FOREIGN KEY (ID_Club) 
        REFERENCES administracion.Club(ID)
);
GO

-- 9. Tabla: administracion.Convocatoria
CREATE TABLE administracion.Convocatoria (
    ID INT IDENTITY(1,1) NOT NULL,
    ID_Jugador INT NOT NULL,
    ID_Seleccion INT NOT NULL,
    estado BIT NOT NULL,
    dorsal TINYINT NOT NULL,
    fecha DATE NULL,
    motivo VARCHAR(255) NULL,

    CONSTRAINT PK_Convocatoria PRIMARY KEY (ID),
    CONSTRAINT UQ_Convocatoria_Jugador UNIQUE (ID_Jugador),
    CONSTRAINT CK_Convocatoria_dorsal CHECK (dorsal BETWEEN 1 AND 99),
    CONSTRAINT FK_Convocatoria_Jugador FOREIGN KEY (ID_Jugador) 
        REFERENCES administracion.Jugador(ID),
    CONSTRAINT FK_Convocatoria_Seleccion FOREIGN KEY (ID_Seleccion) 
        REFERENCES administracion.Seleccion(ID)
);
GO

-- 10. Tabla: arbitraje.Arbitro
CREATE TABLE arbitraje.Arbitro (
    ID INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    ID_Pais INT NOT NULL,

    CONSTRAINT PK_Arbitro PRIMARY KEY (ID),
    CONSTRAINT FK_Arbitro_Pais FOREIGN KEY (ID_Pais) 
        REFERENCES administracion.Pais(ID)
);
GO

-- 11. Tabla: arbitraje.Idioma
CREATE TABLE arbitraje.Idioma (
    ID INT IDENTITY(1,1) NOT NULL,
    lengua VARCHAR(50) NOT NULL,
    ID_Arbitro INT NOT NULL,

    CONSTRAINT PK_Idioma PRIMARY KEY (ID),
    CONSTRAINT FK_Idioma_Arbitro FOREIGN KEY (ID_Arbitro) 
        REFERENCES arbitraje.Arbitro(ID)
);
GO

-- =========================================================================================
-- BLOQUE C: EL ENCUENTRO, FORMACIONES Y TERNAS ARBITRALES
-- =========================================================================================

-- 12. Tabla: partido.Partido
CREATE TABLE partido.Partido (
    ID INT IDENTITY(1,1) NOT NULL,
    fecha_hora_local DATETIME NOT NULL,
    fecha_hora_utc DATETIME NOT NULL,
    ID_Fase INT NOT NULL,
    ID_Sede INT NOT NULL,
    ID_Seleccion_Local INT NOT NULL,
    ID_Seleccion_Visitante INT NOT NULL,
    goles_local TINYINT NULL,
    goles_visitante TINYINT NULL,
    asistencia_publico INT NULL,

    CONSTRAINT PK_Partido PRIMARY KEY (ID),
    CONSTRAINT CK_Partido_rivales_distintos CHECK (ID_Seleccion_Local <> ID_Seleccion_Visitante),
    CONSTRAINT FK_Partido_Fase FOREIGN KEY (ID_Fase) 
        REFERENCES administracion.Fase_Torneo(ID),
    CONSTRAINT FK_Partido_Sede FOREIGN KEY (ID_Sede) 
        REFERENCES administracion.Sede(ID),
    CONSTRAINT FK_Partido_Local FOREIGN KEY (ID_Seleccion_Local) 
        REFERENCES administracion.Seleccion(ID),
    CONSTRAINT FK_Partido_Visitante FOREIGN KEY (ID_Seleccion_Visitante) 
        REFERENCES administracion.Seleccion(ID)
);
GO

-- 13. Tabla: partido.Formacion_Partido
CREATE TABLE partido.Formacion_Partido (
    ID INT IDENTITY(1,1) NOT NULL,
    ID_Partido INT NOT NULL,
    ID_Seleccion INT NOT NULL,
    esquema_tactico VARCHAR(10) NOT NULL,

    CONSTRAINT PK_Formacion_Partido PRIMARY KEY (ID),
    CONSTRAINT UQ_Formacion_Partido UNIQUE (ID_Partido, ID_Seleccion),
    CONSTRAINT FK_Formacion_Partido FOREIGN KEY (ID_Partido) 
        REFERENCES partido.Partido(ID),
    CONSTRAINT FK_Formacion_Seleccion FOREIGN KEY (ID_Seleccion) 
        REFERENCES administracion.Seleccion(ID)
);
GO

-- 14. Tabla: partido.Alineacion
CREATE TABLE partido.Alineacion (
    ID INT IDENTITY(1,1) NOT NULL,
    ID_Formacion INT NOT NULL,
    ID_Jugador INT NOT NULL,
    es_titular BIT NOT NULL,

    CONSTRAINT PK_Alineacion PRIMARY KEY (ID),
    CONSTRAINT UQ_Alineacion_Jugador UNIQUE (ID_Formacion, ID_Jugador),
    CONSTRAINT FK_Alineacion_Formacion FOREIGN KEY (ID_Formacion) 
        REFERENCES partido.Formacion_Partido(ID),
    CONSTRAINT FK_Alineacion_Jugador FOREIGN KEY (ID_Jugador) 
        REFERENCES administracion.Jugador(ID)
);
GO

-- 15. Tabla: arbitraje.Designacion_Arbitral
CREATE TABLE arbitraje.Designacion_Arbitral (
    ID INT IDENTITY(1,1) NOT NULL,
    ID_Partido INT NOT NULL,
    ID_Arbitro INT NOT NULL,
    rol VARCHAR(30) NOT NULL,
    informe VARCHAR(1000) NULL,

    CONSTRAINT PK_Designacion_Arbitral PRIMARY KEY (ID),
    CONSTRAINT UQ_Designacion_Arbitro UNIQUE (ID_Partido, ID_Arbitro),
    CONSTRAINT FK_Designacion_Partido FOREIGN KEY (ID_Partido) 
        REFERENCES partido.Partido(ID),
    CONSTRAINT FK_Designacion_Arbitro FOREIGN KEY (ID_Arbitro) 
        REFERENCES arbitraje.Arbitro(ID)
);
GO

-- =========================================================================================
-- BLOQUE D: EVENTOS DE PARTIDO, DISCIPLINA Y PUBLICIDAD
-- =========================================================================================

-- 16. Tabla: partido.Sustitucion
CREATE TABLE partido.Sustitucion (
    ID INT IDENTITY(1,1) NOT NULL,
    ID_Partido INT NOT NULL,
    ID_Jugador_Sale INT NOT NULL,
    ID_Jugador_Entra INT NOT NULL,
    minuto SMALLINT NOT NULL,
    motivo VARCHAR(50) NOT NULL,

    CONSTRAINT PK_Sustitucion PRIMARY KEY (ID),
    CONSTRAINT CK_Sustitucion_minuto CHECK (minuto > 0 AND minuto <= 140),
    CONSTRAINT CK_Sustitucion_jugadores_distintos CHECK (ID_Jugador_Sale <> ID_Jugador_Entra),
    CONSTRAINT FK_Sustitucion_Partido FOREIGN KEY (ID_Partido) 
        REFERENCES partido.Partido(ID),
    CONSTRAINT FK_Sustitucion_Sale FOREIGN KEY (ID_Jugador_Sale) 
        REFERENCES administracion.Jugador(ID),
    CONSTRAINT FK_Sustitucion_Entra FOREIGN KEY (ID_Jugador_Entra) 
        REFERENCES administracion.Jugador(ID)
);
GO

-- 17. Tabla: partido.Gol
CREATE TABLE partido.Gol (
    ID INT IDENTITY(1,1) NOT NULL,
    ID_Partido INT NOT NULL,
    ID_Jugador_autor INT NOT NULL,
    ID_Jugador_asistencia INT NULL,
    ID_Seleccion INT NOT NULL,
    minuto SMALLINT NOT NULL,
    tipo VARCHAR(30) NOT NULL,
    periodo VARCHAR(30) NOT NULL,

    CONSTRAINT PK_Gol PRIMARY KEY (ID),
    CONSTRAINT CK_Gol_minuto CHECK (minuto > 0 AND minuto <= 140),
    CONSTRAINT FK_Gol_Partido FOREIGN KEY (ID_Partido) 
        REFERENCES partido.Partido(ID),
    CONSTRAINT FK_Gol_Autor FOREIGN KEY (ID_Jugador_autor) 
        REFERENCES administracion.Jugador(ID),
    CONSTRAINT FK_Gol_Asistencia FOREIGN KEY (ID_Jugador_asistencia) 
        REFERENCES administracion.Jugador(ID),
    CONSTRAINT FK_Gol_Seleccion FOREIGN KEY (ID_Seleccion) 
        REFERENCES administracion.Seleccion(ID)
);
GO

-- 18. Tabla: partido.Tarjeta
CREATE TABLE partido.Tarjeta (
    ID INT IDENTITY(1,1) NOT NULL,
    ID_Partido INT NOT NULL,
    ID_Jugador INT NULL,
    ID_Miembro_Cuerpo_Tecnico INT NULL,
    minuto SMALLINT NOT NULL,
    motivo VARCHAR(100) NOT NULL,
    tipo VARCHAR(10) NOT NULL,
    es_doble_amarilla BIT NOT NULL,

    CONSTRAINT PK_Tarjeta PRIMARY KEY (ID),
    CONSTRAINT CK_Tarjeta_minuto CHECK (minuto > 0 AND minuto <= 140),
    CONSTRAINT CK_Tarjeta_destinatario CHECK (
        (ID_Jugador IS NOT NULL AND ID_Miembro_Cuerpo_Tecnico IS NULL) OR
        (ID_Jugador IS NULL AND ID_Miembro_Cuerpo_Tecnico IS NOT NULL)
    ),
    CONSTRAINT FK_Tarjeta_Partido FOREIGN KEY (ID_Partido) 
        REFERENCES partido.Partido(ID),
    CONSTRAINT FK_Tarjeta_Jugador FOREIGN KEY (ID_Jugador) 
        REFERENCES administracion.Jugador(ID),
    CONSTRAINT FK_Tarjeta_CuerpoTecnico FOREIGN KEY (ID_Miembro_Cuerpo_Tecnico) 
        REFERENCES administracion.Miembro_Cuerpo_Tecnico(ID)
);
GO

-- 19. Tabla: partido.Suspension
CREATE TABLE partido.Suspension (
    ID INT IDENTITY(1,1) NOT NULL,
    ID_Jugador INT NOT NULL,
    ID_Partido INT NOT NULL,
    partidos_totales TINYINT NOT NULL,
    partidos_descontados TINYINT NOT NULL,
    motivo VARCHAR(100) NOT NULL,

    CONSTRAINT PK_Suspension PRIMARY KEY (ID),
    CONSTRAINT CK_Suspension_fechas CHECK (partidos_descontados <= partidos_totales),
    CONSTRAINT FK_Suspension_Jugador FOREIGN KEY (ID_Jugador) 
        REFERENCES administracion.Jugador(ID),
    CONSTRAINT FK_Suspension_Partido FOREIGN KEY (ID_Partido) 
        REFERENCES partido.Partido(ID)
);
GO

-- 20. Tabla: partido.Partido_Perdido_Suspension
CREATE TABLE partido.Partido_Perdido_Suspension (
    ID INT IDENTITY(1,1) NOT NULL,
    ID_Suspension INT NOT NULL,
    ID_Partido INT NOT NULL,

    CONSTRAINT PK_Partido_Perdido_Suspension PRIMARY KEY (ID),
    CONSTRAINT UQ_Partido_Suspension UNIQUE (ID_Suspension, ID_Partido),
    CONSTRAINT FK_PPS_Suspension FOREIGN KEY (ID_Suspension) 
        REFERENCES partido.Suspension(ID),
    CONSTRAINT FK_PPS_Partido FOREIGN KEY (ID_Partido) 
        REFERENCES partido.Partido(ID)
);
GO

-- 21. Tabla: publicidad.Campania
CREATE TABLE publicidad.Campania (
    ID INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    ID_Anunciante INT NOT NULL,

    CONSTRAINT PK_Campania PRIMARY KEY (ID),
    CONSTRAINT CK_Campania_fechas CHECK (fecha_inicio <= fecha_fin),
    CONSTRAINT FK_Campania_Anunciante FOREIGN KEY (ID_Anunciante) 
        REFERENCES publicidad.Anunciante(ID)
);
GO

-- 22. Tabla: publicidad.Pieza_Contenido
CREATE TABLE publicidad.Pieza_Contenido (
    ID INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    idioma VARCHAR(30) NOT NULL,
    costo DECIMAL(12,2) NOT NULL,
    ID_Campania INT NOT NULL,

    CONSTRAINT PK_Pieza_Contenido PRIMARY KEY (ID),
    CONSTRAINT CK_Pieza_costo CHECK (costo >= 0),
    CONSTRAINT FK_Pieza_Campania FOREIGN KEY (ID_Campania) 
        REFERENCES publicidad.Campania(ID)
);
GO

-- 23. Tabla: publicidad.Pieza_Pais_Interes
CREATE TABLE publicidad.Pieza_Pais_Interes (
    ID INT IDENTITY(1,1) NOT NULL,
    ID_Pieza INT NOT NULL,
    ID_Pais INT NOT NULL,

    CONSTRAINT PK_Pieza_Pais_Interes PRIMARY KEY (ID),
    CONSTRAINT UQ_Pieza_Pais UNIQUE (ID_Pieza, ID_Pais),
    CONSTRAINT FK_PPI_Pieza FOREIGN KEY (ID_Pieza) 
        REFERENCES publicidad.Pieza_Contenido(ID),
    CONSTRAINT FK_PPI_Pais FOREIGN KEY (ID_Pais) 
        REFERENCES administracion.Pais(ID)
);
GO

-- 24. Tabla: publicidad.Espacio_publicitario
CREATE TABLE publicidad.Espacio_publicitario (
    ID INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    numero_slot TINYINT NOT NULL,
    ID_Partido INT NOT NULL,

    CONSTRAINT PK_Espacio_publicitario PRIMARY KEY (ID),
    CONSTRAINT CK_Espacio_slot CHECK (numero_slot BETWEEN 1 AND 4),
    CONSTRAINT UQ_Espacio_Partido_Slot UNIQUE (ID_Partido, numero_slot),
    CONSTRAINT FK_Espacio_Partido FOREIGN KEY (ID_Partido) 
        REFERENCES partido.Partido(ID)
);
GO

-- 25. Tabla: publicidad.Exhibicion
CREATE TABLE publicidad.Exhibicion (
    ID INT IDENTITY(1,1) NOT NULL,
    ID_espacio INT NOT NULL,
    ID_Pieza INT NOT NULL,
    orden_prioridad TINYINT NOT NULL,
    monto_facturado DECIMAL(12,2) NOT NULL,

    CONSTRAINT PK_Exhibicion PRIMARY KEY (ID),
    CONSTRAINT UQ_Exhibicion_espacio UNIQUE (ID_espacio),
    CONSTRAINT CK_Exhibicion_prioridad CHECK (orden_prioridad IN (1, 2, 3)),
    CONSTRAINT CK_Exhibicion_monto CHECK (monto_facturado >= 0),
    CONSTRAINT FK_Exhibicion_Espacio FOREIGN KEY (ID_espacio) 
        REFERENCES publicidad.Espacio_publicitario(ID),
    CONSTRAINT FK_Exhibicion_Pieza FOREIGN KEY (ID_Pieza) 
        REFERENCES publicidad.Pieza_Contenido(ID)
);
GO

PRINT 'OK: 25 tablas y todas sus restricciones creadas exitosamente en Mundial2026.';
GO
