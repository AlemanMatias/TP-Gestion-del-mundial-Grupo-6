/*
  Entrega 5 - Bases de Datos Aplicada - Comisión 02-5600
  Fecha: Octubre 2026
  Integrantes: Aleman Flores Matias, Gamarra Bravo Sidney, Pereira Carlos, Villa Brenda

  Script: 04_sp_administracion.sql
  Descripción:
     Implementación de Stored Procedures (ABM y lógica de negocio) para el esquema 'administracion'.
     Valida reglas oficiales FIFA Copa Mundial 2026: cupo de 48 selecciones (4 por grupo), planteles 
     de hasta 26 jugadores, cuerpo técnico de hasta 11 miembros con exactamente un DT,
     y control etario.
     Acumula todas las condiciones incumplidas por operación (incluyendo el código (500XX) de cada una)
     y las informa en un único mensaje THROW.
*/

USE Mundial2026;
GO

-- =========================================================================================
-- 1. TABLA MAESTRA: administracion.Pais
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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar nombre obligatorio y no vacío
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SET @mensaje_error += '(50001) El nombre del país no puede ser nulo ni estar vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50001;
    END

    -- Validar unicidad del nombre
    IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) <> '' 
       AND EXISTS (SELECT 1 FROM administracion.Pais WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))))
    BEGIN
        SET @mensaje_error += '(50002) Ya existe un país registrado con ese nombre. ';
        IF @codigo_error = 0 SET @codigo_error = 50002;
    END

    -- Validar que el PBI no sea negativo si viene informado
    IF @pbi_percapita IS NOT NULL AND @pbi_percapita < 0
    BEGIN
        SET @mensaje_error += '(50003) El PBI per cápita no puede ser un valor negativo. ';
        IF @codigo_error = 0 SET @codigo_error = 50003;
    END

    -- Validar formato estricto del huso horario (+HH:MM o -HH:MM)
    IF @huso_horario IS NOT NULL AND @huso_horario NOT LIKE '[+-][0-9][0-9]:[0-9][0-9]'
    BEGIN
        SET @mensaje_error += '(50004) El huso horario debe respetar el formato +/-HH:MM (ejemplo: -03:00 o +02:00). ';
        IF @codigo_error = 0 SET @codigo_error = 50004;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    -- Inserción
    INSERT INTO administracion.Pais (nombre, pbi_percapita, huso_horario)
    VALUES (LTRIM(RTRIM(@nombre)), @pbi_percapita, @huso_horario);

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50005) El ID de país especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50005;
    END

    -- Validar nombre obligatorio
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SET @mensaje_error += '(50001) El nombre del país no puede ser nulo ni estar vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50001;
    END

    -- Validar que no colisione con otro país existente
    IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) <> '' 
       AND EXISTS (SELECT 1 FROM administracion.Pais WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))) AND ID <> @id)
    BEGIN
        SET @mensaje_error += '(50002) Ya existe otro país registrado con ese nombre. ';
        IF @codigo_error = 0 SET @codigo_error = 50002;
    END

    -- Validar PBI
    IF @pbi_percapita IS NOT NULL AND @pbi_percapita < 0
    BEGIN
        SET @mensaje_error += '(50003) El PBI per cápita no puede ser un valor negativo. ';
        IF @codigo_error = 0 SET @codigo_error = 50003;
    END

    -- Validar huso horario
    IF @huso_horario IS NOT NULL AND @huso_horario NOT LIKE '[+-][0-9][0-9]:[0-9][0-9]'
    BEGIN
        SET @mensaje_error += '(50004) El huso horario debe respetar el formato +/-HH:MM (ejemplo: -03:00 o +02:00). ';
        IF @codigo_error = 0 SET @codigo_error = 50004;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50005) El ID de país especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50005;
    END

    -- Validar dependencias (Integridad Referencial de negocio)
    IF EXISTS (SELECT 1 FROM administracion.Sede WHERE ID_Pais = @id)
    BEGIN
        SET @mensaje_error += '(50006) No se puede eliminar el país porque posee sedes asociadas. ';
        IF @codigo_error = 0 SET @codigo_error = 50006;
    END

    IF EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID_Pais = @id)
    BEGIN
        SET @mensaje_error += '(50007) No se puede eliminar el país porque posee una selección nacional asociada. ';
        IF @codigo_error = 0 SET @codigo_error = 50007;
    END

    IF EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID_Pais = @id)
    BEGIN
        SET @mensaje_error += '(50008) No se puede eliminar el país porque posee árbitros asociados. ';
        IF @codigo_error = 0 SET @codigo_error = 50008;
    END

    IF EXISTS (SELECT 1 FROM publicidad.Pieza_Pais_Interes WHERE ID_Pais = @id)
    BEGIN
        SET @mensaje_error += '(50009) No se puede eliminar el país porque posee piezas publicitarias de interés asociadas. ';
        IF @codigo_error = 0 SET @codigo_error = 50009;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar nombre no nulo ni vacío
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SET @mensaje_error += '(50010) El nombre de la fase no puede ser nulo ni vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50010;
    END

    -- Validar orden mayor a cero
    IF @orden IS NULL OR @orden <= 0
    BEGIN
        SET @mensaje_error += '(50011) El orden de la fase debe ser un número entero mayor a cero. ';
        IF @codigo_error = 0 SET @codigo_error = 50011;
    END

    -- Validar unicidad del nombre
    IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) <> '' 
       AND EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))))
    BEGIN
        SET @mensaje_error += '(50012) Ya existe una fase registrada con ese nombre. ';
        IF @codigo_error = 0 SET @codigo_error = 50012;
    END

    -- Validar unicidad del número de orden cronológico
    IF @orden IS NOT NULL AND @orden > 0 
       AND EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE orden = @orden)
    BEGIN
        SET @mensaje_error += '(50013) Ya existe una fase con ese número de orden correlativo. ';
        IF @codigo_error = 0 SET @codigo_error = 50013;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50014) El ID de fase especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50014;
    END

    -- Validar nombre
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SET @mensaje_error += '(50010) El nombre de la fase no puede ser nulo ni vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50010;
    END

    -- Validar orden
    IF @orden IS NULL OR @orden <= 0
    BEGIN
        SET @mensaje_error += '(50011) El orden de la fase debe ser un número entero mayor a cero. ';
        IF @codigo_error = 0 SET @codigo_error = 50011;
    END

    -- Validar que otro registro no tenga el mismo nombre
    IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) <> '' 
       AND EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))) AND ID <> @id)
    BEGIN
        SET @mensaje_error += '(50012) Ya existe otra fase registrada con ese nombre. ';
        IF @codigo_error = 0 SET @codigo_error = 50012;
    END

    -- Validar que otro registro no tenga el mismo orden
    IF @orden IS NOT NULL AND @orden > 0 
       AND EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE orden = @orden AND ID <> @id)
    BEGIN
        SET @mensaje_error += '(50013) Ya existe otra fase con ese número de orden correlativo. ';
        IF @codigo_error = 0 SET @codigo_error = 50013;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50014) El ID de fase especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50014;
    END

    -- Validar que no tenga partidos programados
    IF EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @id)
    BEGIN
        SET @mensaje_error += '(50015) No se puede eliminar la fase porque contiene partidos programados o disputados. ';
        IF @codigo_error = 0 SET @codigo_error = 50015;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar nombre no nulo ni vacío
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SET @mensaje_error += '(50020) El nombre del club no puede ser nulo ni vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50020;
    END

    -- Validar unicidad
    IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) <> '' 
       AND EXISTS (SELECT 1 FROM administracion.Club WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))))
    BEGIN
        SET @mensaje_error += '(50021) Ya existe un club registrado con ese nombre. ';
        IF @codigo_error = 0 SET @codigo_error = 50021;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Club WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50022) El ID de club especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50022;
    END

    -- Validar nombre
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SET @mensaje_error += '(50020) El nombre del club no puede ser nulo ni vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50020;
    END

    -- Validar que otro club no tenga el mismo nombre
    IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) <> '' 
       AND EXISTS (SELECT 1 FROM administracion.Club WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))) AND ID <> @id)
    BEGIN
        SET @mensaje_error += '(50021) Ya existe otro club registrado con ese nombre. ';
        IF @codigo_error = 0 SET @codigo_error = 50021;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Club WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50022) El ID de club especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50022;
    END

    -- Validar dependencia con jugadores
    IF EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID_Club = @id)
    BEGIN
        SET @mensaje_error += '(50023) No se puede eliminar el club porque posee jugadores asociados. ';
        IF @codigo_error = 0 SET @codigo_error = 50023;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar nombre no nulo ni vacío
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SET @mensaje_error += '(50030) El nombre del estadio o sede no puede ser nulo ni vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50030;
    END

    -- Validar ciudad no nula ni vacía
    IF @ciudad IS NULL OR LTRIM(RTRIM(@ciudad)) = ''
    BEGIN
        SET @mensaje_error += '(50031) La ciudad de la sede no puede ser nula ni vacía. ';
        IF @codigo_error = 0 SET @codigo_error = 50031;
    END

    -- Validar capacidad positiva
    IF @capacidad IS NULL OR @capacidad <= 0
    BEGIN
        SET @mensaje_error += '(50032) La capacidad de la sede debe ser un valor entero positivo mayor a cero. ';
        IF @codigo_error = 0 SET @codigo_error = 50032;
    END

    -- Validar formato del huso horario (ej: -06:00, +02:00)
    IF @huso_horario IS NULL OR @huso_horario NOT LIKE '[+-][0-1][0-9]:[0-5][0-9]'
    BEGIN
        SET @mensaje_error += '(50033) El huso horario de la sede debe cumplir con el formato ISO +/-HH:MM (ej: -06:00). ';
        IF @codigo_error = 0 SET @codigo_error = 50033;
    END

    -- Validar existencia del país
    IF @id_pais IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @id_pais)
    BEGIN
        SET @mensaje_error += '(50034) El país especificado para la sede no existe en el sistema. ';
        IF @codigo_error = 0 SET @codigo_error = 50034;
    END

    -- Validar que no exista otra sede con el mismo nombre en la misma ciudad
    IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) <> ''
       AND @ciudad IS NOT NULL AND LTRIM(RTRIM(@ciudad)) <> ''
       AND EXISTS (
           SELECT 1 
           FROM administracion.Sede 
           WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))) 
             AND LOWER(ciudad) = LOWER(LTRIM(RTRIM(@ciudad)))
       )
    BEGIN
        SET @mensaje_error += '(50035) Ya existe una sede registrada con ese mismo nombre en esa ciudad. ';
        IF @codigo_error = 0 SET @codigo_error = 50035;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50036) El ID de sede especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50036;
    END

    -- Validar campos obligatorios
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SET @mensaje_error += '(50030) El nombre del estadio o sede no puede ser nulo ni vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50030;
    END

    IF @ciudad IS NULL OR LTRIM(RTRIM(@ciudad)) = ''
    BEGIN
        SET @mensaje_error += '(50031) La ciudad de la sede no puede ser nula ni vacía. ';
        IF @codigo_error = 0 SET @codigo_error = 50031;
    END

    IF @capacidad IS NULL OR @capacidad <= 0
    BEGIN
        SET @mensaje_error += '(50032) La capacidad de la sede debe ser un valor entero positivo mayor a cero. ';
        IF @codigo_error = 0 SET @codigo_error = 50032;
    END

    IF @huso_horario IS NULL OR @huso_horario NOT LIKE '[+-][0-1][0-9]:[0-5][0-9]'
    BEGIN
        SET @mensaje_error += '(50033) El huso horario de la sede debe cumplir con el formato ISO +/-HH:MM (ej: -06:00). ';
        IF @codigo_error = 0 SET @codigo_error = 50033;
    END

    IF @id_pais IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @id_pais)
    BEGIN
        SET @mensaje_error += '(50034) El país especificado para la sede no existe en el sistema. ';
        IF @codigo_error = 0 SET @codigo_error = 50034;
    END

    -- Validar unicidad (que otra sede no coincida en nombre y ciudad)
    IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) <> ''
       AND @ciudad IS NOT NULL AND LTRIM(RTRIM(@ciudad)) <> ''
       AND EXISTS (
           SELECT 1 
           FROM administracion.Sede 
           WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))) 
             AND LOWER(ciudad) = LOWER(LTRIM(RTRIM(@ciudad))) 
             AND ID <> @id
       )
    BEGIN
        SET @mensaje_error += '(50035) Ya existe otra sede registrada con ese mismo nombre en esa ciudad. ';
        IF @codigo_error = 0 SET @codigo_error = 50035;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50036) El ID de sede especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50036;
    END

    -- Validar dependencia con partidos programados o jugados
    IF EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Sede = @id)
    BEGIN
        SET @mensaje_error += '(50037) No se puede eliminar la sede porque tiene partidos programados o disputados asociados. ';
        IF @codigo_error = 0 SET @codigo_error = 50037;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia del país
    IF @id_pais IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @id_pais)
    BEGIN
        SET @mensaje_error += '(50040) El país seleccionado para la delegación no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50040;
    END

    -- Validar unicidad (un país solo puede tener 1 selección)
    IF @id_pais IS NOT NULL AND EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID_Pais = @id_pais)
    BEGIN
        SET @mensaje_error += '(50041) El país seleccionado ya cuenta con una selección nacional registrada. ';
        IF @codigo_error = 0 SET @codigo_error = 50041;
    END

    -- Validar confederación válida
    IF @confederacion IS NULL OR UPPER(LTRIM(RTRIM(@confederacion))) NOT IN ('CONMEBOL', 'UEFA', 'CONCACAF', 'CAF', 'AFC', 'OFC')
    BEGIN
        SET @mensaje_error += '(50042) La confederación debe ser una de las oficiales: CONMEBOL, UEFA, CONCACAF, CAF, AFC u OFC. ';
        IF @codigo_error = 0 SET @codigo_error = 50042;
    END

    -- Validar formato del grupo (de la A a la L para 12 grupos de 4)
    IF @grupo_asignado IS NULL OR UPPER(@grupo_asignado) NOT BETWEEN 'A' AND 'L'
    BEGIN
        SET @mensaje_error += '(50043) El grupo asignado debe ser una letra comprendida entre la A y la L. ';
        IF @codigo_error = 0 SET @codigo_error = 50043;
    END

    -- Regla FIFA 1: Máximo 48 selecciones clasificadas en el Mundial 2026
    IF (SELECT COUNT(*) FROM administracion.Seleccion) >= 48
    BEGIN
        SET @mensaje_error += '(50048) El torneo ya alcanzó el cupo máximo reglamentario de 48 selecciones participantes. ';
        IF @codigo_error = 0 SET @codigo_error = 50048;
    END

    -- Regla FIFA 2: Máximo 4 selecciones por grupo (12 grupos de 4)
    IF @grupo_asignado IS NOT NULL AND UPPER(@grupo_asignado) BETWEEN 'A' AND 'L'
       AND (SELECT COUNT(*) FROM administracion.Seleccion WHERE grupo_asignado = UPPER(@grupo_asignado)) >= 4
    BEGIN
        SET @mensaje_error += '(50049) El grupo asignado ya cuenta con el cupo máximo reglamentario de 4 selecciones. ';
        IF @codigo_error = 0 SET @codigo_error = 50049;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50044) El ID de la selección especificada no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50044;
    END

    IF @id_pais IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @id_pais)
    BEGIN
        SET @mensaje_error += '(50040) El país seleccionado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50040;
    END

    -- Validar que otro registro no esté asignado a ese país
    IF @id_pais IS NOT NULL AND EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID_Pais = @id_pais AND ID <> @id)
    BEGIN
        SET @mensaje_error += '(50041) El país seleccionado ya cuenta con otra selección asignada. ';
        IF @codigo_error = 0 SET @codigo_error = 50041;
    END

    IF @confederacion IS NULL OR UPPER(LTRIM(RTRIM(@confederacion))) NOT IN ('CONMEBOL', 'UEFA', 'CONCACAF', 'CAF', 'AFC', 'OFC')
    BEGIN
        SET @mensaje_error += '(50042) La confederación debe ser una de las oficiales: CONMEBOL, UEFA, CONCACAF, CAF, AFC u OFC. ';
        IF @codigo_error = 0 SET @codigo_error = 50042;
    END

    IF @grupo_asignado IS NULL OR UPPER(@grupo_asignado) NOT BETWEEN 'A' AND 'L'
    BEGIN
        SET @mensaje_error += '(50043) El grupo asignado debe ser una letra entre la A y la L. ';
        IF @codigo_error = 0 SET @codigo_error = 50043;
    END

    -- Si se cambia de grupo, verificar que el grupo destino no supere 4 selecciones
    IF @grupo_asignado IS NOT NULL AND UPPER(@grupo_asignado) BETWEEN 'A' AND 'L'
       AND (SELECT COUNT(*) FROM administracion.Seleccion WHERE grupo_asignado = UPPER(@grupo_asignado) AND ID <> @id) >= 4
    BEGIN
        SET @mensaje_error += '(50049) El grupo asignado ya cuenta con el cupo máximo reglamentario de 4 selecciones. ';
        IF @codigo_error = 0 SET @codigo_error = 50049;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50044) El ID de la selección especificada no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50044;
    END

    -- Validar dependencias
    IF EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Seleccion = @id)
    BEGIN
        SET @mensaje_error += '(50045) No se puede eliminar la selección porque posee convocatorias asociadas. ';
        IF @codigo_error = 0 SET @codigo_error = 50045;
    END

    IF EXISTS (SELECT 1 FROM administracion.Miembro_Cuerpo_Tecnico WHERE ID_Seleccion = @id)
    BEGIN
        SET @mensaje_error += '(50046) No se puede eliminar la selección porque posee miembros de cuerpo técnico asociados. ';
        IF @codigo_error = 0 SET @codigo_error = 50046;
    END

    IF EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Seleccion_Local = @id OR ID_Seleccion_Visitante = @id)
    BEGIN
        SET @mensaje_error += '(50047) No se puede eliminar la selección porque posee partidos programados. ';
        IF @codigo_error = 0 SET @codigo_error = 50047;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validaciones de datos personales
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SET @mensaje_error += '(50050) El nombre del miembro de cuerpo técnico no puede estar vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50050;
    END

    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
    BEGIN
        SET @mensaje_error += '(50051) El apellido del miembro de cuerpo técnico no puede estar vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50051;
    END

    -- Validar lista blanca de cargos oficiales FIFA
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
    BEGIN
        SET @mensaje_error += '(50052) El rol especificado no es un cargo técnico o médico oficial de la delegación. ';
        IF @codigo_error = 0 SET @codigo_error = 50052;
    END

    -- Validar existencia de la selección
    IF @id_seleccion IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID = @id_seleccion)
    BEGIN
        SET @mensaje_error += '(50053) La selección nacional asignada no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50053;
    END

    -- Regla FIFA: No puede haber más de 1 "Director Técnico" principal por selección
    IF @rol IS NOT NULL AND UPPER(LTRIM(RTRIM(@rol))) IN ('DIRECTOR TÉCNICO', 'DIRECTOR TECNICO')
       AND EXISTS (SELECT 1 FROM administracion.Miembro_Cuerpo_Tecnico 
                   WHERE ID_Seleccion = @id_seleccion 
                     AND UPPER(rol) IN ('DIRECTOR TÉCNICO', 'DIRECTOR TECNICO'))
    BEGIN
        SET @mensaje_error += '(50054) La selección ya posee un Director Técnico principal registrado. ';
        IF @codigo_error = 0 SET @codigo_error = 50054;
    END

    -- Regla FIFA: Cupo máximo de 11 miembros de cuerpo técnico por delegación
    IF @id_seleccion IS NOT NULL 
       AND (SELECT COUNT(*) FROM administracion.Miembro_Cuerpo_Tecnico WHERE ID_Seleccion = @id_seleccion) >= 11
    BEGIN
        SET @mensaje_error += '(50058) La selección ya cuenta con el cupo máximo reglamentario de 11 miembros de cuerpo técnico. ';
        IF @codigo_error = 0 SET @codigo_error = 50058;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Miembro_Cuerpo_Tecnico WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50055) El ID de miembro de cuerpo técnico especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50055;
    END

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SET @mensaje_error += '(50050) El nombre no puede estar vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50050;
    END

    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
    BEGIN
        SET @mensaje_error += '(50051) El apellido no puede estar vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50051;
    END

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
    BEGIN
        SET @mensaje_error += '(50052) El rol especificado no es un cargo técnico o médico oficial de la delegación. ';
        IF @codigo_error = 0 SET @codigo_error = 50052;
    END

    IF @id_seleccion IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID = @id_seleccion)
    BEGIN
        SET @mensaje_error += '(50053) La selección nacional especificada no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50053;
    END

    -- Validar que no se asigne un 2do DT principal
    IF @rol IS NOT NULL AND UPPER(LTRIM(RTRIM(@rol))) IN ('DIRECTOR TÉCNICO', 'DIRECTOR TECNICO')
       AND EXISTS (SELECT 1 FROM administracion.Miembro_Cuerpo_Tecnico 
                   WHERE ID_Seleccion = @id_seleccion 
                     AND UPPER(rol) IN ('DIRECTOR TÉCNICO', 'DIRECTOR TECNICO')
                     AND ID <> @id)
    BEGIN
        SET @mensaje_error += '(50054) La selección ya posee otro Director Técnico principal registrado. ';
        IF @codigo_error = 0 SET @codigo_error = 50054;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Miembro_Cuerpo_Tecnico WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50055) El ID de miembro de cuerpo técnico especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50055;
    END

    -- Integridad: no borrar si registra sanciones o tarjetas en partidos
    IF EXISTS (SELECT 1 FROM partido.Tarjeta WHERE ID_Miembro_Cuerpo_Tecnico = @id)
    BEGIN
        SET @mensaje_error += '(50056) No se puede eliminar el miembro técnico porque posee tarjetas disciplinarias registradas. ';
        IF @codigo_error = 0 SET @codigo_error = 50056;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validaciones de nombres
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SET @mensaje_error += '(50060) El nombre del jugador no puede estar vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50060;
    END

    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
    BEGIN
        SET @mensaje_error += '(50061) El apellido del jugador no puede estar vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50061;
    END

    -- Validar fecha de nacimiento no futura
    IF @fecha_nacimiento IS NULL OR @fecha_nacimiento > CAST(GETDATE() AS DATE)
    BEGIN
        SET @mensaje_error += '(50062) La fecha de nacimiento no es válida o es futura. ';
        IF @codigo_error = 0 SET @codigo_error = 50062;
    END

    -- Validar edad mínima reglamentaria (al menos 15 años)
    IF @fecha_nacimiento IS NOT NULL AND @fecha_nacimiento <= CAST(GETDATE() AS DATE)
       AND DATEDIFF(YEAR, @fecha_nacimiento, GETDATE()) < 15
    BEGIN
        SET @mensaje_error += '(50063) El jugador debe tener al menos 15 años de edad. ';
        IF @codigo_error = 0 SET @codigo_error = 50063;
    END

    -- Validar club de procedencia
    IF @id_club IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Club WHERE ID = @id_club)
    BEGIN
        SET @mensaje_error += '(50064) El club asignado al jugador no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50064;
    END

    -- Validar posición habitual válida
    IF @posicion_habitual IS NULL OR UPPER(LTRIM(RTRIM(@posicion_habitual))) NOT IN ('ARQUERO', 'DEFENSOR', 'MEDIOCAMPISTA', 'DELANTERO')
    BEGIN
        SET @mensaje_error += '(50065) La posición habitual debe ser: Arquero, Defensor, Mediocampista o Delantero. ';
        IF @codigo_error = 0 SET @codigo_error = 50065;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50066) El ID de jugador especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50066;
    END

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SET @mensaje_error += '(50060) El nombre del jugador no puede estar vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50060;
    END

    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
    BEGIN
        SET @mensaje_error += '(50061) El apellido del jugador no puede estar vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50061;
    END

    IF @fecha_nacimiento IS NULL OR @fecha_nacimiento > CAST(GETDATE() AS DATE)
    BEGIN
        SET @mensaje_error += '(50062) La fecha de nacimiento no es válida o es futura. ';
        IF @codigo_error = 0 SET @codigo_error = 50062;
    END

    IF @fecha_nacimiento IS NOT NULL AND @fecha_nacimiento <= CAST(GETDATE() AS DATE)
       AND DATEDIFF(YEAR, @fecha_nacimiento, GETDATE()) < 15
    BEGIN
        SET @mensaje_error += '(50063) El jugador debe tener al menos 15 años de edad. ';
        IF @codigo_error = 0 SET @codigo_error = 50063;
    END

    IF @id_club IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Club WHERE ID = @id_club)
    BEGIN
        SET @mensaje_error += '(50064) El club asignado al jugador no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50064;
    END

    IF @posicion_habitual IS NULL OR UPPER(LTRIM(RTRIM(@posicion_habitual))) NOT IN ('ARQUERO', 'DEFENSOR', 'MEDIOCAMPISTA', 'DELANTERO')
    BEGIN
        SET @mensaje_error += '(50065) La posición habitual debe ser: Arquero, Defensor, Mediocampista o Delantero. ';
        IF @codigo_error = 0 SET @codigo_error = 50065;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50066) El ID de jugador especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50066;
    END

    -- Validar dependencias históricas (No borrar si tiene actividad en el torneo)
    IF EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id)
    BEGIN
        SET @mensaje_error += '(50067) No se puede eliminar el jugador porque registra convocatorias en selecciones. ';
        IF @codigo_error = 0 SET @codigo_error = 50067;
    END

    IF EXISTS (SELECT 1 FROM partido.Alineacion WHERE ID_Jugador = @id)
    BEGIN
        SET @mensaje_error += '(50068) No se puede eliminar el jugador porque registra alineaciones en partidos. ';
        IF @codigo_error = 0 SET @codigo_error = 50068;
    END

    IF EXISTS (SELECT 1 FROM partido.Gol WHERE ID_Jugador_autor = @id OR ID_Jugador_asistencia = @id)
    BEGIN
        SET @mensaje_error += '(50069) No se puede eliminar el jugador porque registra goles o asistencias. ';
        IF @codigo_error = 0 SET @codigo_error = 50069;
    END

    IF EXISTS (SELECT 1 FROM partido.Sustitucion WHERE ID_Jugador_Sale = @id OR ID_Jugador_Entra = @id)
    BEGIN
        SET @mensaje_error += '(50070) No se puede eliminar el jugador porque registra sustituciones en partidos. ';
        IF @codigo_error = 0 SET @codigo_error = 50070;
    END

    IF EXISTS (SELECT 1 FROM partido.Tarjeta WHERE ID_Jugador = @id)
    BEGIN
        SET @mensaje_error += '(50071) No se puede eliminar el jugador porque registra tarjetas disciplinarias. ';
        IF @codigo_error = 0 SET @codigo_error = 50071;
    END

    IF EXISTS (SELECT 1 FROM partido.Suspension WHERE ID_Jugador = @id)
    BEGIN
        SET @mensaje_error += '(50072) No se puede eliminar el jugador porque registra suspensiones vigentes o cumplidas. ';
        IF @codigo_error = 0 SET @codigo_error = 50072;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    DELETE FROM administracion.Jugador 
    WHERE ID = @id;
END;
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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia del jugador
    IF @id_jugador IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID = @id_jugador)
    BEGIN
        SET @mensaje_error += '(50070) El jugador especificado no existe en el sistema. ';
        IF @codigo_error = 0 SET @codigo_error = 50070;
    END

    -- Validar existencia de la selección
    IF @id_seleccion IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID = @id_seleccion)
    BEGIN
        SET @mensaje_error += '(50071) La selección nacional especificada no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50071;
    END

    -- Regla FIFA 1: Cupo máximo oficial de 26 jugadores activos por delegación
    IF @id_seleccion IS NOT NULL 
       AND (SELECT COUNT(*) FROM administracion.Convocatoria WHERE ID_Seleccion = @id_seleccion AND estado = 1) >= 26
    BEGIN
        SET @mensaje_error += '(50075) La selección ya alcanzó el cupo máximo reglamentario de 26 jugadores activos. ';
        IF @codigo_error = 0 SET @codigo_error = 50075;
    END

    -- Validar rango reglamentario del dorsal (1 a 26)
    IF @dorsal IS NULL OR @dorsal NOT BETWEEN 1 AND 26
    BEGIN
        SET @mensaje_error += '(50072) El dorsal debe ser un número entero comprendido entre 1 y 26. ';
        IF @codigo_error = 0 SET @codigo_error = 50072;
    END

    -- Regla FIFA: La camiseta número 1 es de uso exclusivo para arqueros
    IF @dorsal = 1 AND @id_jugador IS NOT NULL 
       AND EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID = @id_jugador AND UPPER(posicion_habitual) <> 'ARQUERO')
    BEGIN
        SET @mensaje_error += '(50078) El dorsal número 1 está reservado reglamentariamente de forma exclusiva para un arquero. ';
        IF @codigo_error = 0 SET @codigo_error = 50078;
    END

    -- Regla FIFA: Un jugador solo puede representar a una selección
    IF @id_jugador IS NOT NULL AND EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id_jugador)
    BEGIN
        SET @mensaje_error += '(50073) El jugador ya posee un registro de convocatoria (FIFA prohíbe doble selección). ';
        IF @codigo_error = 0 SET @codigo_error = 50073;
    END

    -- Regla FIFA: El dorsal debe ser único entre los convocados ACTIVOS de esa selección
    IF @id_seleccion IS NOT NULL AND @dorsal IS NOT NULL
       AND EXISTS (SELECT 1 FROM administracion.Convocatoria 
                   WHERE ID_Seleccion = @id_seleccion 
                     AND dorsal = @dorsal 
                     AND estado = 1)
    BEGIN
        SET @mensaje_error += '(50074) El dorsal ya está ocupado por otro jugador activo en la misma selección. ';
        IF @codigo_error = 0 SET @codigo_error = 50074;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Por defecto toma la fecha actual del sistema
    IF @fecha IS NULL
        SET @fecha = CAST(GETDATE() AS DATE);

    -- Validar motivo obligatorio
    IF @motivo IS NULL OR LTRIM(RTRIM(@motivo)) = ''
    BEGIN
        SET @mensaje_error += '(50076) Debe especificar el motivo médico o justificación de la baja. ';
        IF @codigo_error = 0 SET @codigo_error = 50076;
    END

    -- Validar que el jugador esté convocado y actualmente ACTIVO
    IF @id_jugador IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id_jugador AND estado = 1)
    BEGIN
        SET @mensaje_error += '(50077) El jugador no posee una convocatoria activa para dar de baja. ';
        IF @codigo_error = 0 SET @codigo_error = 50077;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- 1. Validaciones previas acumulativas
    IF @motivo_lesion IS NULL OR LTRIM(RTRIM(@motivo_lesion)) = ''
    BEGIN
        SET @mensaje_error += '(50076) Debe especificar el informe médico de la lesión para autorizar el reemplazo. ';
        IF @codigo_error = 0 SET @codigo_error = 50076;
    END

    IF @id_jugador_lesionado IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id_jugador_lesionado AND estado = 1)
    BEGIN
        SET @mensaje_error += '(50077) El jugador a reemplazar no posee una convocatoria activa en ninguna selección. ';
        IF @codigo_error = 0 SET @codigo_error = 50077;
    END

    IF @id_jugador_reemplazo IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID = @id_jugador_reemplazo)
    BEGIN
        SET @mensaje_error += '(50070) El jugador sustituto no existe en el sistema. ';
        IF @codigo_error = 0 SET @codigo_error = 50070;
    END

    IF @id_jugador_reemplazo IS NOT NULL AND EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id_jugador_reemplazo)
    BEGIN
        SET @mensaje_error += '(50073) El jugador sustituto ya cuenta con una convocatoria previa registrada. ';
        IF @codigo_error = 0 SET @codigo_error = 50073;
    END

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

    IF @dorsal_final IS NOT NULL AND @dorsal_final NOT BETWEEN 1 AND 26
    BEGIN
        SET @mensaje_error += '(50072) El dorsal asignado debe ser un número entero entre 1 y 26. ';
        IF @codigo_error = 0 SET @codigo_error = 50072;
    END

    -- Validar que el dorsal no esté ocupado por OTRO jugador activo de esa misma selección
    IF @id_seleccion IS NOT NULL AND @dorsal_final IS NOT NULL
       AND EXISTS (SELECT 1 FROM administracion.Convocatoria 
                   WHERE ID_Seleccion = @id_seleccion 
                     AND dorsal = @dorsal_final 
                     AND estado = 1 
                     AND ID_Jugador <> @id_jugador_lesionado)
    BEGIN
        SET @mensaje_error += '(50074) El dorsal solicitado ya está ocupado por otro jugador activo de la selección. ';
        IF @codigo_error = 0 SET @codigo_error = 50074;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

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

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
