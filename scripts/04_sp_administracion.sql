/*
  Entrega 5 - Bases de Datos Aplicada - Comisión 02-5600
  Fecha: Octubre 2026
  Integrantes: Aleman Flores Matias, Gamarra Bravo Sidney, Pereira Carlos, Villa Brenda

  Script: 04_administracion.sql
  Descripción:
     Implementación de Stored Procedures (ABM y lógica de negocio) para el esquema 'administracion'.
     Valida reglas oficiales FIFA Copa Mundial 2026: cupo de 48 selecciones (4 por grupo), planteles 
     de hasta 26 jugadores , cuerpo técnico de hasta 11 miembros con exactamente un DT,
     y control etario. 
*/

USE Mundial2026;
GO
-- =========================================================================================
-- TABLA MAESTRA: administracion.Pais
-- =========================================================================================

-- 1.1. ALTA DE PAÍS
CREATE OR ALTER PROCEDURE administracion.sp_InsertarPais
    @nombre VARCHAR(100),
    @pbi_percapita DECIMAL(12,2) = NULL,
    @huso_horario CHAR(6) = NULL,
    @id_generado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    -- Validar nombre obligatorio y no vacío
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50001, 'El nombre del país no puede ser nulo ni estar vacío.', 1;
    -- Validar unicidad del nombre
    IF EXISTS (SELECT 1 FROM administracion.Pais WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))))
        THROW 50002, 'Ya existe un país registrado con ese nombre.', 1;
    -- Validar que el PBI no sea negativo si viene informado
    IF @pbi_percapita IS NOT NULL AND @pbi_percapita < 0
        THROW 50003, 'El PBI per cápita no puede ser un valor negativo.', 1;
    -- Validar formato estricto del huso horario (+HH:MM o -HH:MM)
    IF @huso_horario IS NOT NULL AND @huso_horario NOT LIKE '[+-][0-9][0-9]:[0-9][0-9]'
        THROW 50004, 'El huso horario debe respetar el formato [+-]HH:MM (ejemplo: -03:00 o +02:00).', 1;
    -- Inserción
    INSERT INTO administracion.Pais (nombre, pbi_percapita, huso_horario)
    VALUES (LTRIM(RTRIM(@nombre)), @pbi_percapita, @huso_horario);
    -- Devolver ID generado
    SET @id_generado = SCOPE_IDENTITY();
END;
GO
-- 1.2. MODIFICACIÓN DE PAÍS
CREATE OR ALTER PROCEDURE administracion.sp_ModificarPais
    @id INT,
    @nombre VARCHAR(100),
    @pbi_percapita DECIMAL(12,2) = NULL,
    @huso_horario CHAR(6) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @id)
        THROW 50005, 'El ID de país especificado no existe.', 1;
    -- Validar nombre obligatorio
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50001, 'El nombre del país no puede ser nulo ni estar vacío.', 1;
    -- Validar que no colisione con otro país existente
    IF EXISTS (SELECT 1 FROM administracion.Pais WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))) AND ID <> @id)
        THROW 50002, 'Ya existe otro país registrado con ese nombre.', 1;
    -- Validar PBI
    IF @pbi_percapita IS NOT NULL AND @pbi_percapita < 0
        THROW 50003, 'El PBI per cápita no puede ser un valor negativo.', 1;
    -- Validar huso horario
    IF @huso_horario IS NOT NULL AND @huso_horario NOT LIKE '[+-][0-9][0-9]:[0-9][0-9]'
        THROW 50004, 'El huso horario debe respetar el formato [+-]HH:MM (ejemplo: -03:00 o +02:00).', 1;
    -- Actualización
    UPDATE administracion.Pais
    SET nombre = LTRIM(RTRIM(@nombre)),
        pbi_percapita = @pbi_percapita,
        huso_horario = @huso_horario
    WHERE ID = @id;
END;
GO
-- 1.3. BAJA DE PAÍS
CREATE OR ALTER PROCEDURE administracion.sp_EliminarPais
    @id INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @id)
        THROW 50005, 'El ID de país especificado no existe.', 1;
    -- Validar dependencias (Integridad Referencial de negocio)
    IF EXISTS (SELECT 1 FROM administracion.Sede WHERE ID_Pais = @id)
        THROW 50006, 'No se puede eliminar el país porque posee sedes asociadas.', 1;
    IF EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID_Pais = @id)
        THROW 50007, 'No se puede eliminar el país porque posee una selección nacional asociada.', 1;
    IF EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID_Pais = @id)
        THROW 50008, 'No se puede eliminar el país porque posee árbitros asociados.', 1;
    IF EXISTS (SELECT 1 FROM publicidad.Pieza_Pais_Interes WHERE ID_Pais = @id)
        THROW 50009, 'No se puede eliminar el país porque posee piezas publicitarias de interés asociadas.', 1;
    -- Eliminación física
    DELETE FROM administracion.Pais 
    WHERE ID = @id;
END;
GO

-- =========================================================================================
-- 2. TABLA MAESTRA: administracion.Fase_Torneo
-- =========================================================================================

-- 2.1. ALTA DE FASE
CREATE OR ALTER PROCEDURE administracion.sp_InsertarFaseTorneo
    @nombre VARCHAR(50),
    @orden SMALLINT,
    @id_generado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar nombre no nulo ni vacío
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50010, 'El nombre de la fase no puede ser nulo ni vacío.', 1;

    -- Validar orden mayor a cero
    IF @orden IS NULL OR @orden <= 0
        THROW 50011, 'El orden de la fase debe ser un número entero mayor a cero.', 1;

    -- Validar unicidad del nombre
    IF EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))))
        THROW 50012, 'Ya existe una fase registrada con ese nombre.', 1;

    -- Validar unicidad del número de orden cronológico
    IF EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE orden = @orden)
        THROW 50013, 'Ya existe una fase con ese número de orden correlativo.', 1;

    INSERT INTO administracion.Fase_Torneo (nombre, orden)
    VALUES (LTRIM(RTRIM(@nombre)), @orden);

    SET @id_generado = SCOPE_IDENTITY();
END;
GO

-- 2.2. MODIFICACIÓN DE FASE
CREATE OR ALTER PROCEDURE administracion.sp_ModificarFaseTorneo
    @id INT,
    @nombre VARCHAR(50),
    @orden SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE ID = @id)
        THROW 50014, 'El ID de fase especificado no existe.', 1;

    -- Validar nombre
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50010, 'El nombre de la fase no puede ser nulo ni vacío.', 1;

    -- Validar orden
    IF @orden IS NULL OR @orden <= 0
        THROW 50011, 'El orden de la fase debe ser un número entero mayor a cero.', 1;

    -- Validar que otro registro no tenga el mismo nombre
    IF EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))) AND ID <> @id)
        THROW 50012, 'Ya existe otra fase registrada con ese nombre.', 1;

    -- Validar que otro registro no tenga el mismo orden
    IF EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE orden = @orden AND ID <> @id)
        THROW 50013, 'Ya existe otra fase con ese número de orden correlativo.', 1;

    UPDATE administracion.Fase_Torneo
    SET nombre = LTRIM(RTRIM(@nombre)),
        orden = @orden
    WHERE ID = @id;
END;
GO

-- 2.3. BAJA DE FASE
CREATE OR ALTER PROCEDURE administracion.sp_EliminarFaseTorneo
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE ID = @id)
        THROW 50014, 'El ID de fase especificado no existe.', 1;

    -- Validar que no tenga partidos programados
    IF EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @id)
        THROW 50015, 'No se puede eliminar la fase porque contiene partidos programados o disputados.', 1;

    DELETE FROM administracion.Fase_Torneo 
    WHERE ID = @id;
END;
GO

-- =========================================================================================
-- 3. TABLA MAESTRA: administracion.Club
-- =========================================================================================

-- 3.1. ALTA DE CLUB
CREATE OR ALTER PROCEDURE administracion.sp_InsertarClub
    @nombre VARCHAR(100),
    @id_generado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar nombre no nulo ni vacío
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50020, 'El nombre del club no puede ser nulo ni vacío.', 1;

    -- Validar unicidad
    IF EXISTS (SELECT 1 FROM administracion.Club WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))))
        THROW 50021, 'Ya existe un club registrado con ese nombre.', 1;

    INSERT INTO administracion.Club (nombre)
    VALUES (LTRIM(RTRIM(@nombre)));

    SET @id_generado = SCOPE_IDENTITY();
END;
GO

-- 3.2. MODIFICACIÓN DE CLUB
CREATE OR ALTER PROCEDURE administracion.sp_ModificarClub
    @id INT,
    @nombre VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Club WHERE ID = @id)
        THROW 50022, 'El ID de club especificado no existe.', 1;

    -- Validar nombre
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50020, 'El nombre del club no puede ser nulo ni vacío.', 1;

    -- Validar que otro club no tenga el mismo nombre
    IF EXISTS (SELECT 1 FROM administracion.Club WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))) AND ID <> @id)
        THROW 50021, 'Ya existe otro club registrado con ese nombre.', 1;

    UPDATE administracion.Club
    SET nombre = LTRIM(RTRIM(@nombre))
    WHERE ID = @id;
END;
GO

-- 3.3. BAJA DE CLUB
CREATE OR ALTER PROCEDURE administracion.sp_EliminarClub
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Club WHERE ID = @id)
        THROW 50022, 'El ID de club especificado no existe.', 1;

    -- Validar dependencia con jugadores
    IF EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID_Club = @id)
        THROW 50023, 'No se puede eliminar el club porque posee jugadores asociados.', 1;

    DELETE FROM administracion.Club 
    WHERE ID = @id;
END;
GO

-- =========================================================================================
-- 4. TABLA MAESTRA: administracion.Sede
-- =========================================================================================

-- 4.1. ALTA DE SEDE
CREATE OR ALTER PROCEDURE administracion.sp_InsertarSede
    @nombre VARCHAR(100),
    @ciudad VARCHAR(100),
    @capacidad INT,
    @huso_horario CHAR(6),
    @id_pais INT,
    @id_generado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar nombre no nulo ni vacío
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50030, 'El nombre del estadio o sede no puede ser nulo ni vacío.', 1;

    -- Validar ciudad no nula ni vacía
    IF @ciudad IS NULL OR LTRIM(RTRIM(@ciudad)) = ''
        THROW 50031, 'La ciudad de la sede no puede ser nula ni vacía.', 1;

    -- Validar capacidad positiva
    IF @capacidad IS NULL OR @capacidad <= 0
        THROW 50032, 'La capacidad de la sede debe ser un valor entero positivo mayor a cero.', 1;

    -- Validar formato del huso horario (ej: -06:00, +02:00)
    IF @huso_horario IS NULL OR @huso_horario NOT LIKE '[+-][0-1][0-9]:[0-5][0-9]'
        THROW 50033, 'El huso horario de la sede debe cumplir con el formato ISO +/-HH:MM (ej: -06:00).', 1;

    -- Validar existencia del país
    IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @id_pais)
        THROW 50034, 'El país especificado para la sede no existe en el sistema.', 1;

    -- Validar que no exista otra sede con el mismo nombre en la misma ciudad
    IF EXISTS (
        SELECT 1 
        FROM administracion.Sede 
        WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))) 
          AND LOWER(ciudad) = LOWER(LTRIM(RTRIM(@ciudad)))
    )
        THROW 50035, 'Ya existe una sede registrada con ese mismo nombre en esa ciudad.', 1;

    INSERT INTO administracion.Sede (nombre, ciudad, capacidad, huso_horario, ID_Pais)
    VALUES (LTRIM(RTRIM(@nombre)), LTRIM(RTRIM(@ciudad)), @capacidad, @huso_horario, @id_pais);

    SET @id_generado = SCOPE_IDENTITY();
END;
GO

-- 4.2. MODIFICACIÓN DE SEDE
CREATE OR ALTER PROCEDURE administracion.sp_ModificarSede
    @id INT,
    @nombre VARCHAR(100),
    @ciudad VARCHAR(100),
    @capacidad INT,
    @huso_horario CHAR(6),
    @id_pais INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE ID = @id)
        THROW 50036, 'El ID de sede especificado no existe.', 1;

    -- Validar campos obligatorios
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50030, 'El nombre del estadio o sede no puede ser nulo ni vacío.', 1;

    IF @ciudad IS NULL OR LTRIM(RTRIM(@ciudad)) = ''
        THROW 50031, 'La ciudad de la sede no puede ser nula ni vacía.', 1;

    IF @capacidad IS NULL OR @capacidad <= 0
        THROW 50032, 'La capacidad de la sede debe ser un valor entero positivo mayor a cero.', 1;

    IF @huso_horario IS NULL OR @huso_horario NOT LIKE '[+-][0-1][0-9]:[0-5][0-9]'
        THROW 50033, 'El huso horario de la sede debe cumplir con el formato ISO +/-HH:MM (ej: -06:00).', 1;

    IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @id_pais)
        THROW 50034, 'El país especificado para la sede no existe en el sistema.', 1;

    -- Validar unicidad (que otra sede no coincida en nombre y ciudad)
    IF EXISTS (
        SELECT 1 
        FROM administracion.Sede 
        WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))) 
          AND LOWER(ciudad) = LOWER(LTRIM(RTRIM(@ciudad))) 
          AND ID <> @id
    )
        THROW 50035, 'Ya existe otra sede registrada con ese mismo nombre en esa ciudad.', 1;

    UPDATE administracion.Sede
    SET nombre = LTRIM(RTRIM(@nombre)),
        ciudad = LTRIM(RTRIM(@ciudad)),
        capacidad = @capacidad,
        huso_horario = @huso_horario,
        ID_Pais = @id_pais
    WHERE ID = @id;
END;
GO

-- 4.3. BAJA DE SEDE
CREATE OR ALTER PROCEDURE administracion.sp_EliminarSede
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE ID = @id)
        THROW 50036, 'El ID de sede especificado no existe.', 1;

    -- Validar dependencia con partidos programados o jugados
    IF EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Sede = @id)
        THROW 50037, 'No se puede eliminar la sede porque tiene partidos programados o disputados asociados.', 1;

    DELETE FROM administracion.Sede 
    WHERE ID = @id;
END;
GO

-- =========================================================================================
-- 5. TABLA: administracion.Seleccion
-- =========================================================================================

-- 5.1. ALTA DE SELECCIÓN
CREATE OR ALTER PROCEDURE administracion.sp_InsertarSeleccion
    @id_pais INT,
    @confederacion VARCHAR(15),
    @grupo_asignado CHAR(1),
    @id_generado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia del país
    IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @id_pais)
        THROW 50040, 'El país seleccionado para la delegación no existe.', 1;

    -- Validar unicidad (un país solo puede tener 1 selección)
    IF EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID_Pais = @id_pais)
        THROW 50041, 'El país seleccionado ya cuenta con una selección nacional registrada.', 1;

    -- Validar confederación válida
    IF @confederacion IS NULL OR UPPER(LTRIM(RTRIM(@confederacion))) NOT IN ('CONMEBOL', 'UEFA', 'CONCACAF', 'CAF', 'AFC', 'OFC')
        THROW 50042, 'La confederación debe ser una de las oficiales: CONMEBOL, UEFA, CONCACAF, CAF, AFC u OFC.', 1;

    -- Validar formato del grupo (de la A a la L para 12 grupos de 4)
    IF @grupo_asignado IS NULL OR UPPER(@grupo_asignado) NOT BETWEEN 'A' AND 'L'
        THROW 50043, 'El grupo asignado debe ser una letra comprendida entre la A y la L.', 1;

    -- Regla FIFA 1: Máximo 48 selecciones clasificadas en el Mundial 2026
    IF (SELECT COUNT(*) FROM administracion.Seleccion) >= 48
        THROW 50048, 'El torneo ya alcanzó el cupo máximo reglamentario de 48 selecciones participantes.', 1;

    -- Regla FIFA 2: Máximo 4 selecciones por grupo (12 grupos de 4)
    IF (SELECT COUNT(*) FROM administracion.Seleccion WHERE grupo_asignado = UPPER(@grupo_asignado)) >= 4
        THROW 50049, 'El grupo asignado ya cuenta con el cupo máximo reglamentario de 4 selecciones.', 1;

    INSERT INTO administracion.Seleccion (ID_Pais, confederacion, grupo_asignado)
    VALUES (@id_pais, UPPER(LTRIM(RTRIM(@confederacion))), UPPER(@grupo_asignado));

    SET @id_generado = SCOPE_IDENTITY();
END;
GO

-- 5.2. MODIFICACIÓN DE SELECCIÓN
CREATE OR ALTER PROCEDURE administracion.sp_ModificarSeleccion
    @id INT,
    @id_pais INT,
    @confederacion VARCHAR(15),
    @grupo_asignado CHAR(1)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID = @id)
        THROW 50044, 'El ID de la selección especificada no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @id_pais)
        THROW 50040, 'El país seleccionado no existe.', 1;

    -- Validar que otro registro no esté asignado a ese país
    IF EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID_Pais = @id_pais AND ID <> @id)
        THROW 50041, 'El país seleccionado ya cuenta con otra selección asignada.', 1;

    IF @confederacion IS NULL OR UPPER(LTRIM(RTRIM(@confederacion))) NOT IN ('CONMEBOL', 'UEFA', 'CONCACAF', 'CAF', 'AFC', 'OFC')
        THROW 50042, 'La confederación debe ser una de las oficiales: CONMEBOL, UEFA, CONCACAF, CAF, AFC u OFC.', 1;

    IF @grupo_asignado IS NULL OR UPPER(@grupo_asignado) NOT BETWEEN 'A' AND 'L'
        THROW 50043, 'El grupo asignado debe ser una letra entre la A y la L.', 1;

    -- Si se cambia de grupo, verificar que el grupo destino no supere 4 selecciones
    IF (SELECT COUNT(*) FROM administracion.Seleccion WHERE grupo_asignado = UPPER(@grupo_asignado) AND ID <> @id) >= 4
        THROW 50049, 'El grupo asignado ya cuenta con el cupo máximo reglamentario de 4 selecciones.', 1;

    UPDATE administracion.Seleccion
    SET ID_Pais = @id_pais,
        confederacion = UPPER(LTRIM(RTRIM(@confederacion))),
        grupo_asignado = UPPER(@grupo_asignado)
    WHERE ID = @id;
END;
GO

-- 5.3. BAJA DE SELECCIÓN
CREATE OR ALTER PROCEDURE administracion.sp_EliminarSeleccion
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID = @id)
        THROW 50044, 'El ID de la selección especificada no existe.', 1;

    -- Validar dependencias
    IF EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Seleccion = @id)
        THROW 50045, 'No se puede eliminar la selección porque posee convocatorias asociadas.', 1;

    IF EXISTS (SELECT 1 FROM administracion.Miembro_Cuerpo_Tecnico WHERE ID_Seleccion = @id)
        THROW 50046, 'No se puede eliminar la selección porque posee miembros de cuerpo técnico asociados.', 1;

    IF EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Seleccion_Local = @id OR ID_Seleccion_Visitante = @id)
        THROW 50047, 'No se puede eliminar la selección porque posee partidos programados.', 1;

    DELETE FROM administracion.Seleccion 
    WHERE ID = @id;
END;
GO

-- =========================================================================================
-- 6. TABLA: administracion.Miembro_Cuerpo_Tecnico
-- =========================================================================================

-- 6.1. ALTA DE MIEMBRO DE CUERPO TÉCNICO
CREATE OR ALTER PROCEDURE administracion.sp_InsertarMiembroCuerpoTecnico
    @nombre VARCHAR(100),
    @apellido VARCHAR(100),
    @rol VARCHAR(50),
    @id_seleccion INT,
    @id_generado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validaciones de datos personales
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50050, 'El nombre del miembro de cuerpo técnico no puede estar vacío.', 1;

    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
        THROW 50051, 'El apellido del miembro de cuerpo técnico no puede estar vacío.', 1;

    -- Validar lista blanca de cargos oficiales FIFA (Bloquea "carnicero", "asador", etc.)
    IF @rol IS NULL OR UPPER(LTRIM(RTRIM(@rol))) NOT IN (
        'DIRECTOR TÉCNICO', 'DIRECTOR TECNICO',
        'AYUDANTE DE CAMPO',
        'PREPARADOR FÍSICO', 'PREPARADOR FISICO',
        'ENTRENADOR DE ARQUEROS',
        'MÉDICO', 'MEDICO',
        'KINESIÓLOGO', 'KINESIOLOGO',
        'ANALISTA DE VIDEO',
        'UTILERO'
    )
        THROW 50052, 'El rol especificado no es un cargo técnico o médico oficial de la delegación.', 1;

    -- Validar existencia de la selección
    IF NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID = @id_seleccion)
        THROW 50053, 'La selección nacional asignada no existe.', 1;

    -- Regla FIFA: No puede haber más de 1 "Director Técnico" principal por selección
    IF UPPER(LTRIM(RTRIM(@rol))) IN ('DIRECTOR TÉCNICO', 'DIRECTOR TECNICO')
       AND EXISTS (SELECT 1 FROM administracion.Miembro_Cuerpo_Tecnico 
                   WHERE ID_Seleccion = @id_seleccion 
                     AND UPPER(rol) IN ('DIRECTOR TÉCNICO', 'DIRECTOR TECNICO'))
        THROW 50054, 'La selección ya posee un Director Técnico principal registrado.', 1;

    -- Regla FIFA: Cupo máximo de 11 miembros de cuerpo técnico por delegación
    IF (SELECT COUNT(*) FROM administracion.Miembro_Cuerpo_Tecnico WHERE ID_Seleccion = @id_seleccion) >= 11
        THROW 50058, 'La selección ya cuenta con el cupo máximo reglamentario de 11 miembros de cuerpo técnico.', 1;

    INSERT INTO administracion.Miembro_Cuerpo_Tecnico (nombre, apellido, rol, ID_Seleccion)
    VALUES (LTRIM(RTRIM(@nombre)), LTRIM(RTRIM(@apellido)), LTRIM(RTRIM(@rol)), @id_seleccion);

    SET @id_generado = SCOPE_IDENTITY();
END;
GO

-- 6.2. MODIFICACIÓN DE MIEMBRO DE CUERPO TÉCNICO
CREATE OR ALTER PROCEDURE administracion.sp_ModificarMiembroCuerpoTecnico
    @id INT,
    @nombre VARCHAR(100),
    @apellido VARCHAR(100),
    @rol VARCHAR(50),
    @id_seleccion INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Miembro_Cuerpo_Tecnico WHERE ID = @id)
        THROW 50055, 'El ID de miembro de cuerpo técnico especificado no existe.', 1;

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50050, 'El nombre no puede estar vacío.', 1;

    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
        THROW 50051, 'El apellido no puede estar vacío.', 1;

    -- Validar lista blanca de roles
    IF @rol IS NULL OR UPPER(LTRIM(RTRIM(@rol))) NOT IN (
        'DIRECTOR TÉCNICO', 'DIRECTOR TECNICO',
        'AYUDANTE DE CAMPO',
        'PREPARADOR FÍSICO', 'PREPARADOR FISICO',
        'ENTRENADOR DE ARQUEROS',
        'MÉDICO', 'MEDICO',
        'KINESIÓLOGO', 'KINESIOLOGO',
        'ANALISTA DE VIDEO',
        'UTILERO'
    )
        THROW 50052, 'El rol especificado no es un cargo técnico o médico oficial de la delegación.', 1;

    IF NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID = @id_seleccion)
        THROW 50053, 'La selección nacional especificada no existe.', 1;

    -- Validar que no se asigne un 2do DT principal
    IF UPPER(LTRIM(RTRIM(@rol))) IN ('DIRECTOR TÉCNICO', 'DIRECTOR TECNICO')
       AND EXISTS (SELECT 1 FROM administracion.Miembro_Cuerpo_Tecnico 
                   WHERE ID_Seleccion = @id_seleccion 
                     AND UPPER(rol) IN ('DIRECTOR TÉCNICO', 'DIRECTOR TECNICO')
                     AND ID <> @id)
        THROW 50054, 'La selección ya posee otro Director Técnico principal registrado.', 1;

    UPDATE administracion.Miembro_Cuerpo_Tecnico
    SET nombre = LTRIM(RTRIM(@nombre)),
        apellido = LTRIM(RTRIM(@apellido)),
        rol = LTRIM(RTRIM(@rol)),
        ID_Seleccion = @id_seleccion
    WHERE ID = @id;
END;
GO

-- 6.3. BAJA DE MIEMBRO DE CUERPO TÉCNICO
CREATE OR ALTER PROCEDURE administracion.sp_EliminarMiembroCuerpoTecnico
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Miembro_Cuerpo_Tecnico WHERE ID = @id)
        THROW 50055, 'El ID de miembro de cuerpo técnico especificado no existe.', 1;

    -- Integridad: no borrar si registra sanciones o tarjetas en partidos
    IF EXISTS (SELECT 1 FROM partido.Tarjeta WHERE ID_Miembro_Cuerpo_Tecnico = @id)
        THROW 50056, 'No se puede eliminar el miembro técnico porque posee tarjetas disciplinarias registradas.', 1;

    DELETE FROM administracion.Miembro_Cuerpo_Tecnico 
    WHERE ID = @id;
END;
GO

-- =========================================================================================
-- 7. TABLA: administracion.Jugador
-- =========================================================================================

-- 7.1. ALTA DE JUGADOR
CREATE OR ALTER PROCEDURE administracion.sp_InsertarJugador
    @nombre VARCHAR(100),
    @apellido VARCHAR(100),
    @fecha_nacimiento DATE,
    @id_club INT,
    @posicion_habitual VARCHAR(30),
    @id_generado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validaciones de nombres
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50060, 'El nombre del jugador no puede estar vacío.', 1;

    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
        THROW 50061, 'El apellido del jugador no puede estar vacío.', 1;

    -- Validar fecha de nacimiento no futura
    IF @fecha_nacimiento IS NULL OR @fecha_nacimiento > CAST(GETDATE() AS DATE)
        THROW 50062, 'La fecha de nacimiento no es válida o es futura.', 1;

    -- Validar edad mínima reglamentaria (al menos 15 años)
    IF DATEDIFF(YEAR, @fecha_nacimiento, GETDATE()) < 15
        THROW 50063, 'El jugador debe tener al menos 15 años de edad.', 1;

    -- Validar club de procedencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Club WHERE ID = @id_club)
        THROW 50064, 'El club asignado al jugador no existe.', 1;

    -- Validar posición habitual válida
    IF @posicion_habitual IS NULL OR UPPER(LTRIM(RTRIM(@posicion_habitual))) NOT IN ('ARQUERO', 'DEFENSOR', 'MEDIOCAMPISTA', 'DELANTERO')
        THROW 50065, 'La posición habitual debe ser: Arquero, Defensor, Mediocampista o Delantero.', 1;

    INSERT INTO administracion.Jugador (nombre, apellido, fecha_nacimiento, ID_Club, posicion_habitual)
    VALUES (LTRIM(RTRIM(@nombre)), LTRIM(RTRIM(@apellido)), @fecha_nacimiento, @id_club, LTRIM(RTRIM(@posicion_habitual)));

    SET @id_generado = SCOPE_IDENTITY();
END;
GO

-- 7.2. MODIFICACIÓN DE JUGADOR
CREATE OR ALTER PROCEDURE administracion.sp_ModificarJugador
    @id INT,
    @nombre VARCHAR(100),
    @apellido VARCHAR(100),
    @fecha_nacimiento DATE,
    @id_club INT,
    @posicion_habitual VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID = @id)
        THROW 50066, 'El ID de jugador especificado no existe.', 1;

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50060, 'El nombre del jugador no puede estar vacío.', 1;

    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
        THROW 50061, 'El apellido del jugador no puede estar vacío.', 1;

    IF @fecha_nacimiento IS NULL OR @fecha_nacimiento > CAST(GETDATE() AS DATE)
        THROW 50062, 'La fecha de nacimiento no es válida o es futura.', 1;

    IF DATEDIFF(YEAR, @fecha_nacimiento, GETDATE()) < 15
        THROW 50063, 'El jugador debe tener al menos 15 años de edad.', 1;

    IF NOT EXISTS (SELECT 1 FROM administracion.Club WHERE ID = @id_club)
        THROW 50064, 'El club asignado al jugador no existe.', 1;

    IF @posicion_habitual IS NULL OR UPPER(LTRIM(RTRIM(@posicion_habitual))) NOT IN ('ARQUERO', 'DEFENSOR', 'MEDIOCAMPISTA', 'DELANTERO')
        THROW 50065, 'La posición habitual debe ser: Arquero, Defensor, Mediocampista o Delantero.', 1;

    UPDATE administracion.Jugador
    SET nombre = LTRIM(RTRIM(@nombre)),
        apellido = LTRIM(RTRIM(@apellido)),
        fecha_nacimiento = @fecha_nacimiento,
        ID_Club = @id_club,
        posicion_habitual = LTRIM(RTRIM(@posicion_habitual))
    WHERE ID = @id;
END;
GO

-- 7.3. BAJA DE JUGADOR
CREATE OR ALTER PROCEDURE administracion.sp_EliminarJugador
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID = @id)
        THROW 50066, 'El ID de jugador especificado no existe.', 1;

    -- Validar dependencias históricas (No borrar si tiene actividad en el torneo)
    IF EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id)
        THROW 50067, 'No se puede eliminar el jugador porque registra convocatorias en selecciones.', 1;

    IF EXISTS (SELECT 1 FROM partido.Alineacion WHERE ID_Jugador = @id)
        THROW 50068, 'No se puede eliminar el jugador porque registra alineaciones en partidos.', 1;

    IF EXISTS (SELECT 1 FROM partido.Gol WHERE ID_Jugador_autor = @id OR ID_Jugador_asistencia = @id)
        THROW 50069, 'No se puede eliminar el jugador porque registra goles o asistencias.', 1;

    IF EXISTS (SELECT 1 FROM partido.Sustitucion WHERE ID_Jugador_Sale = @id OR ID_Jugador_Entra = @id)
        THROW 50070, 'No se puede eliminar el jugador porque registra sustituciones en partidos.', 1;

    IF EXISTS (SELECT 1 FROM partido.Tarjeta WHERE ID_Jugador = @id)
        THROW 50071, 'No se puede eliminar el jugador porque registra tarjetas disciplinarias.', 1;

    IF EXISTS (SELECT 1 FROM partido.Suspension WHERE ID_Jugador = @id)
        THROW 50072, 'No se puede eliminar el jugador porque registra suspensiones vigentes o cumplidas.', 1;

    DELETE FROM administracion.Jugador 
    WHERE ID = @id;
END;
GO

USE Mundial2026;
GO

-- =========================================================================================
-- 8. LÓGICA DE NEGOCIO TRANSACCIONAL: administracion.Convocatoria
-- =========================================================================================

-- 8.1. ALTA OFICIAL DE CONVOCADO A UNA SELECCIÓN
CREATE OR ALTER PROCEDURE administracion.sp_RegistrarConvocatoria
    @id_jugador INT,
    @id_seleccion INT,
    @dorsal TINYINT,
    @id_generado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia del jugador
    IF NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID = @id_jugador)
        THROW 50070, 'El jugador especificado no existe en el sistema.', 1;

    -- Validar existencia de la selección
    IF NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID = @id_seleccion)
        THROW 50071, 'La selección nacional especificada no existe.', 1;

    -- Regla FIFA 1: Cupo máximo oficial de 26 jugadores activos por delegación
    IF (SELECT COUNT(*) FROM administracion.Convocatoria WHERE ID_Seleccion = @id_seleccion AND estado = 1) >= 26
        THROW 50075, 'La selección ya alcanzó el cupo máximo reglamentario de 26 jugadores activos.', 1;



    -- Validar rango reglamentario del dorsal (1 a 26)
    IF @dorsal IS NULL OR @dorsal NOT BETWEEN 1 AND 26
        THROW 50072, 'El dorsal debe ser un número entero comprendido entre 1 y 26.', 1;

    -- Regla FIFA: La camiseta número 1 es de uso exclusivo para arqueros
    IF @dorsal = 1 AND (SELECT UPPER(posicion_habitual) FROM administracion.Jugador WHERE ID = @id_jugador) <> 'ARQUERO'
        THROW 50078, 'El dorsal número 1 está reservado reglamentariamente de forma exclusiva para un arquero.', 1;

    -- Regla FIFA 1: Un jugador solo puede representar a una selección
    IF EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id_jugador)
        THROW 50073, 'El jugador ya posee un registro de convocatoria (FIFA prohíbe doble selección).', 1;

    -- Regla FIFA 2: El dorsal debe ser único entre los convocados ACTIVOS de esa selección
    IF EXISTS (SELECT 1 FROM administracion.Convocatoria 
               WHERE ID_Seleccion = @id_seleccion 
                 AND dorsal = @dorsal 
                 AND estado = 1)
        THROW 50074, 'El dorsal ya está ocupado por otro jugador activo en la misma selección.', 1;





    -- Inserción del convocado activo (estado = 1)
    INSERT INTO administracion.Convocatoria (ID_Jugador, ID_Seleccion, estado, dorsal, fecha, motivo)
    VALUES (@id_jugador, @id_seleccion, 1, @dorsal, NULL, NULL);

    SET @id_generado = SCOPE_IDENTITY();
END;
GO

-- 8.2. BAJA DE ÚLTIMO MOMENTO POR LESIÓN O CAUSA MÉDICA JUSTIFICADA
CREATE OR ALTER PROCEDURE administracion.sp_RegistrarBajaConvocatoria
    @id_jugador INT,
    @motivo VARCHAR(255),
    @fecha DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Por defecto toma la fecha actual del sistema
    IF @fecha IS NULL
        SET @fecha = CAST(GETDATE() AS DATE);

    -- Validar motivo obligatorio
    IF @motivo IS NULL OR LTRIM(RTRIM(@motivo)) = ''
        THROW 50076, 'Debe especificar el motivo médico o justificación de la baja.', 1;

    -- Validar que el jugador esté convocado y actualmente ACTIVO
    IF NOT EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id_jugador AND estado = 1)
        THROW 50077, 'El jugador no posee una convocatoria activa para dar de baja.', 1;

    -- Pasar a inactivo (estado = 0) registrando motivo y fecha
    UPDATE administracion.Convocatoria
    SET estado = 0,
        motivo = LTRIM(RTRIM(@motivo)),
        fecha = @fecha
    WHERE ID_Jugador = @id_jugador 
      AND estado = 1;
END;
GO

-- 8.3. REEMPLAZO DE ÚLTIMO MOMENTO (BAJA MÉDICA + ALTA DEL SUSTITUTO)
CREATE OR ALTER PROCEDURE administracion.sp_ReemplazarConvocadoUltimoMomento
    @id_jugador_lesionado INT,
    @id_jugador_reemplazo INT,
    @motivo_lesion VARCHAR(255),
    @dorsal_nuevo TINYINT = NULL,   -- Si es NULL, hereda automáticamente la camiseta del lesionado
    @id_convocatoria_nueva INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Validaciones previas
    IF @motivo_lesion IS NULL OR LTRIM(RTRIM(@motivo_lesion)) = ''
        THROW 50076, 'Debe especificar el informe médico de la lesión para autorizar el reemplazo.', 1;

    IF NOT EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id_jugador_lesionado AND estado = 1)
        THROW 50077, 'El jugador a reemplazar no posee una convocatoria activa en ninguna selección.', 1;

    IF NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID = @id_jugador_reemplazo)
        THROW 50070, 'El jugador sustituto no existe en el sistema.', 1;

    IF EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id_jugador_reemplazo)
        THROW 50073, 'El jugador sustituto ya cuenta con una convocatoria previa registrada.', 1;

    -- Obtener la selección y el dorsal del jugador lesionado
    DECLARE @id_seleccion INT;
    DECLARE @dorsal_heredado TINYINT;

    SELECT 
        @id_seleccion = ID_Seleccion,
        @dorsal_heredado = dorsal
    FROM administracion.Convocatoria
    WHERE ID_Jugador = @id_jugador_lesionado AND estado = 1;

    -- Definir dorsal final (hereda el del lesionado o usa el nuevo especificado)
    DECLARE @dorsal_final TINYINT = COALESCE(@dorsal_nuevo, @dorsal_heredado);

    IF @dorsal_final NOT BETWEEN 1 AND 26
        THROW 50072, 'El dorsal asignado debe ser un número entero entre 1 y 26.', 1;

    -- Validar que el dorsal no esté ocupado por OTRO jugador activo de esa misma selección
    IF EXISTS (SELECT 1 FROM administracion.Convocatoria 
               WHERE ID_Seleccion = @id_seleccion 
                 AND dorsal = @dorsal_final 
                 AND estado = 1 
                 AND ID_Jugador <> @id_jugador_lesionado)
        THROW 50074, 'El dorsal solicitado ya está ocupado por otro jugador activo de la selección.', 1;

    -- 2. BLOQUE TRANSACCIONAL ATÓMICO
    BEGIN TRY
        BEGIN TRANSACTION;

        -- PASO A: Desafectar al jugador lesionado (baja médica)
        UPDATE administracion.Convocatoria
        SET estado = 0,
            motivo = LTRIM(RTRIM(@motivo_lesion)),
            fecha = CAST(GETDATE() AS DATE)
        WHERE ID_Jugador = @id_jugador_lesionado 
          AND estado = 1;

        -- PASO B: Inscribir oficialmente al nuevo jugador sustituto
        INSERT INTO administracion.Convocatoria (ID_Jugador, ID_Seleccion, estado, dorsal, fecha, motivo)
        VALUES (@id_jugador_reemplazo, @id_seleccion, 1, @dorsal_final, NULL, NULL);

        SET @id_convocatoria_nueva = SCOPE_IDENTITY();

        -- Si ambos pasos se completaron con éxito, confirmamos los cambios
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Si ocurrió cualquier error en el medio, revertimos todo
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Relanzamos el error para que SSMS informe el fallo
        THROW;
    END CATCH;
END;
GO