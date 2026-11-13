/* 
   UNIVERSIDAD NACIONAL DE LA MATANZA (UNLaM)
   Departamento de Ingeniería e Investigaciones Tecnológicas
   Asignatura: Bases de Datos Aplicada (3641)
   Comisión: 02-5600 (Viernes Tarde)
   
   TRABAJO PRÁCTICO - SISTEMA DE REGISTRO Y GESTIÓN DEL MUNDIAL DE FÚTBOL 2026
   
   Integrantes del Grupo:
     - Aleman Flores, Matias Osvaldo 
     - Gamarra Bravo, Sidney Maribel
     - Pereira, Carlos Manuel
     - Villa, Brenda
     
   Script: 01_administracion_y_planteles.sql
   Descripción: Carga de países, fases, sedes, selecciones, cuerpos técnicos,
                jugadores, convocatorias, reemplazos por lesión y árbitros.
*/

USE Mundial2026;
GO

SET NOCOUNT ON;

-- Habilitar permisos para consumo de APIs
IF EXISTS (SELECT 1 FROM sys.configurations WHERE name = 'Ole Automation Procedures' AND value_in_use = 0)
BEGIN
    EXEC sp_configure 'show advanced options', 1;
    RECONFIGURE WITH OVERRIDE;
    EXEC sp_configure 'Ole Automation Procedures', 1;
    RECONFIGURE WITH OVERRIDE;
END;

PRINT 'Iniciando Script 01: Administración y Planteles...';

-- Obtención dinámica de la carpeta de datasets memorizada en la base de datos
-- Si por algún motivo la función no existe, utiliza la ruta relativa estándar
DECLARE @dir_datasets VARCHAR(500) = '..\..\datasets';
IF OBJECT_ID('administracion.fn_RutaDatasets', 'FN') IS NOT NULL
    SET @dir_datasets = administracion.fn_RutaDatasets();

-- Rutas resueltas automáticamente (cero configuración manual para los integrantes)
DECLARE @ruta_countries  VARCHAR(500) = @dir_datasets + '\countries.json';
DECLARE @ruta_squadlists VARCHAR(500) = @dir_datasets + '\SquadLists.csv';
DECLARE @ruta_arbitros   VARCHAR(500) = @dir_datasets + '\arbitros.csv';

-- =========================================================================
-- 1. PAÍSES, PBI Y JUGADORES
-- =========================================================================
PRINT '1. Importando países y jugadores...';

IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE codigo_iso = 'ARG')
BEGIN
    EXEC administracion.sp_ImportarPaisesJSON @ruta_archivo = @ruta_countries;
END

-- Agregar Inglaterra y Escocia (no vienen separados en countries.json)
IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE codigo_iso = 'ENG')
BEGIN
    DECLARE @id_eng INT;
    EXEC administracion.sp_InsertarPais @nombre = 'Inglaterra', @codigo_iso = 'ENG', @pbi_percapita = 46000, @huso_horario = '+00:00', @id_generado = @id_eng OUTPUT;
END

IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE codigo_iso = 'SCO')
BEGIN
    DECLARE @id_sco INT;
    EXEC administracion.sp_InsertarPais @nombre = 'Escocia', @codigo_iso = 'SCO', @pbi_percapita = 42000, @huso_horario = '+00:00', @id_generado = @id_sco OUTPUT;
END

-- Actualizar PBI desde la API del Banco Mundial
BEGIN TRY
    EXEC administracion.sp_ImportarPbiBancoMundial;
END TRY
BEGIN CATCH
    PRINT 'Aviso API Banco Mundial: ' + ERROR_MESSAGE();
END CATCH;

-- Importar jugadores y clubes desde CSV
IF (SELECT COUNT(*) FROM administracion.Jugador) < 1000
BEGIN
    EXEC administracion.sp_ImportarJugadoresClubes @ruta_archivo = @ruta_squadlists;
END

-- =========================================================================
-- 2. FASES DEL TORNEO
-- =========================================================================
PRINT '2. Cargando fases del torneo...';

DECLARE @id_fase_out INT;

IF NOT EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE nombre = 'Fase de Grupos')
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase de Grupos', @orden = 1, @id_generado = @id_fase_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE nombre = 'Dieciseisavos de Final')
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Dieciseisavos de Final', @orden = 2, @id_generado = @id_fase_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE nombre = 'Octavos de Final')
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Octavos de Final', @orden = 3, @id_generado = @id_fase_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE nombre = 'Cuartos de Final')
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Cuartos de Final', @orden = 4, @id_generado = @id_fase_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE nombre = 'Semifinal')
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Semifinal', @orden = 5, @id_generado = @id_fase_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE nombre = 'Tercer Puesto')
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Tercer Puesto', @orden = 6, @id_generado = @id_fase_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE nombre = 'Final')
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Final', @orden = 7, @id_generado = @id_fase_out OUTPUT;

-- =========================================================================
-- 3. SEDES
-- =========================================================================
PRINT '3. Cargando sedes...';

DECLARE @id_pais_usa INT = (SELECT TOP 1 ID FROM administracion.Pais WHERE codigo_iso = 'USA');
DECLARE @id_pais_mex INT = (SELECT TOP 1 ID FROM administracion.Pais WHERE codigo_iso = 'MEX');
DECLARE @id_pais_can INT = (SELECT TOP 1 ID FROM administracion.Pais WHERE codigo_iso = 'CAN');
DECLARE @id_sede_out INT;

-- Huso -05:00
IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE nombre = 'MetLife Stadium')
    EXEC administracion.sp_InsertarSede @nombre = 'MetLife Stadium', @ciudad = 'East Rutherford', @capacidad = 82500, @huso_horario = '-05:00', @id_pais = @id_pais_usa, @id_generado = @id_sede_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE nombre = 'Hard Rock Stadium')
    EXEC administracion.sp_InsertarSede @nombre = 'Hard Rock Stadium', @ciudad = 'Miami Gardens', @capacidad = 64767, @huso_horario = '-05:00', @id_pais = @id_pais_usa, @id_generado = @id_sede_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE nombre = 'BMO Field')
    EXEC administracion.sp_InsertarSede @nombre = 'BMO Field', @ciudad = 'Toronto', @capacidad = 45000, @huso_horario = '-05:00', @id_pais = @id_pais_can, @id_generado = @id_sede_out OUTPUT;

-- Huso -06:00
IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE nombre = 'Estadio Azteca')
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Azteca', @ciudad = 'Mexico City', @capacidad = 87523, @huso_horario = '-06:00', @id_pais = @id_pais_mex, @id_generado = @id_sede_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE nombre = 'AT&T Stadium')
    EXEC administracion.sp_InsertarSede @nombre = 'AT&T Stadium', @ciudad = 'Arlington', @capacidad = 80000, @huso_horario = '-06:00', @id_pais = @id_pais_usa, @id_generado = @id_sede_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE nombre = 'Estadio Akron')
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Akron', @ciudad = 'Guadalajara', @capacidad = 48071, @huso_horario = '-06:00', @id_pais = @id_pais_mex, @id_generado = @id_sede_out OUTPUT;

-- Huso -08:00
IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE nombre = 'SoFi Stadium')
    EXEC administracion.sp_InsertarSede @nombre = 'SoFi Stadium', @ciudad = 'Inglewood', @capacidad = 70240, @huso_horario = '-08:00', @id_pais = @id_pais_usa, @id_generado = @id_sede_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE nombre = 'BC Place')
    EXEC administracion.sp_InsertarSede @nombre = 'BC Place', @ciudad = 'Vancouver', @capacidad = 54500, @huso_horario = '-08:00', @id_pais = @id_pais_can, @id_generado = @id_sede_out OUTPUT;

-- Cargar coordenadas desde la API Open-Meteo
BEGIN TRY
    EXEC administracion.sp_ImportarGeolocalizacionSedes;
END TRY
BEGIN CATCH
    PRINT 'Aviso API Open-Meteo: ' + ERROR_MESSAGE();
END CATCH;

-- =========================================================================
-- 4. SELECCIONES Y DIRECTORES TÉCNICOS
-- =========================================================================
PRINT '4. Cargando selecciones y directores técnicos...';

DECLARE @t_equipos TABLE (
    id_fila INT IDENTITY(1,1) PRIMARY KEY,
    team_code VARCHAR(3),
    confederacion VARCHAR(15),
    grupo CHAR(1),
    dt_nombre VARCHAR(100),
    dt_apellido VARCHAR(100)
);

INSERT INTO @t_equipos (team_code, confederacion, grupo, dt_nombre, dt_apellido) VALUES
    -- Grupo A
    ('MEX', 'CONCACAF', 'A', 'Javier', 'Aguirre'),
    ('RSA', 'CAF',      'A', 'Hugo', 'Broos'),
    ('KOR', 'AFC',      'A', 'Hong', 'Myung-bo'),
    ('BIH', 'UEFA',     'A', 'Sergej', 'Barbarez'),
    -- Grupo B
    ('CAN', 'CONCACAF', 'B', 'Jesse', 'Marsch'),
    ('ARG', 'CONMEBOL', 'B', 'Lionel', 'Scaloni'),
    ('NZL', 'OFC',      'B', 'Darren', 'Bazeley'),
    ('AUT', 'UEFA',     'B', 'Ralf', 'Rangnick'),
    -- Grupo C
    ('USA', 'CONCACAF', 'C', 'Mauricio', 'Pochettino'),
    ('FRA', 'UEFA',     'C', 'Didier', 'Deschamps'),
    ('SEN', 'CAF',      'C', 'Aliou', 'Cisse'),
    ('AUS', 'AFC',      'C', 'Tony', 'Popovic'),
    -- Grupo D
    ('BRA', 'CONMEBOL', 'D', 'Dorival', 'Junior'),
    ('ESP', 'UEFA',     'D', 'Luis', 'de la Fuente'),
    ('JPN', 'AFC',      'D', 'Hajime', 'Moriyasu'),
    ('MAR', 'CAF',      'D', 'Walid', 'Regragui'),
    -- Grupo E
    ('GER', 'UEFA',     'E', 'Julian', 'Nagelsmann'),
    ('COL', 'CONMEBOL', 'E', 'Nestor', 'Lorenzo'),
    ('ALG', 'CAF',      'E', 'Vladimir', 'Petkovic'),
    ('UZB', 'AFC',      'E', 'Srecko', 'Katanec'),
    -- Grupo F
    ('ENG', 'UEFA',     'F', 'Thomas', 'Tuchel'),
    ('URU', 'CONMEBOL', 'F', 'Marcelo', 'Bielsa'),
    ('EGY', 'CAF',      'F', 'Hossam', 'Hassan'),
    ('QAT', 'AFC',      'F', 'Tintin', 'Marquez'),
    -- Grupo G
    ('POR', 'UEFA',     'G', 'Roberto', 'Martinez'),
    ('PAR', 'CONMEBOL', 'G', 'Gustavo', 'Alfaro'),
    ('CIV', 'CAF',      'G', 'Emerse', 'Fae'),
    ('KSA', 'AFC',      'G', 'Herve', 'Renard'),
    -- Grupo H
    ('NED', 'UEFA',     'H', 'Ronald', 'Koeman'),
    ('ECU', 'CONMEBOL', 'H', 'Sebastian', 'Beccacece'),
    ('GHA', 'CAF',      'H', 'Otto', 'Addo'),
    ('IRN', 'AFC',      'H', 'Amir', 'Ghalenoei'),
    -- Grupo I
    ('BEL', 'UEFA',     'I', 'Domenico', 'Tedesco'),
    ('CRO', 'UEFA',     'I', 'Zlatko', 'Dalic'),
    ('TUN', 'CAF',      'I', 'Kais', 'Yaakoubi'),
    ('IRQ', 'AFC',      'I', 'Jesus', 'Casas'),
    -- Grupo J
    ('SCO', 'UEFA',     'J', 'Steve', 'Clarke'),
    ('SUI', 'UEFA',     'J', 'Murat', 'Yakin'),
    ('COD', 'CAF',      'J', 'Sebastien', 'Desabre'),
    ('JOR', 'AFC',      'J', 'Jamal', 'Sellami'),
    -- Grupo K
    ('TUR', 'UEFA',     'K', 'Vincenzo', 'Montella'),
    ('CZE', 'UEFA',     'K', 'Ivan', 'Hasek'),
    ('CPV', 'CAF',      'K', 'Bubista', 'Brito'),
    ('PAN', 'CONCACAF', 'K', 'Thomas', 'Christiansen'),
    -- Grupo L
    ('SWE', 'UEFA',     'L', 'Jon Dahl', 'Tomasson'),
    ('NOR', 'UEFA',     'L', 'Stale', 'Solbakken'),
    ('HAI', 'CONCACAF', 'L', 'Sebastien', 'Migne'),
    ('CUW', 'CONCACAF', 'L', 'Dick', 'Advocaat');

DECLARE @i_eq INT = 1;
DECLARE @max_eq INT = (SELECT MAX(id_fila) FROM @t_equipos);
DECLARE @eq_code VARCHAR(3), @eq_conf VARCHAR(15), @eq_grp CHAR(1), @dt_nom VARCHAR(100), @dt_ape VARCHAR(100);
DECLARE @eq_id_pais INT, @eq_id_sel INT, @dt_id INT;

WHILE @i_eq <= @max_eq
BEGIN
    SELECT 
        @eq_code = team_code, @eq_conf = confederacion, @eq_grp = grupo, 
        @dt_nom = dt_nombre, @dt_ape = dt_apellido 
    FROM @t_equipos 
    WHERE id_fila = @i_eq;

    DECLARE @iso_busqueda VARCHAR(3) = 
        CASE @eq_code
            WHEN 'ENG' THEN 'ENG'
            WHEN 'SCO' THEN 'SCO'
            WHEN 'SUI' THEN 'CHE'
            WHEN 'GER' THEN 'DEU'
            WHEN 'CRO' THEN 'HRV'
            WHEN 'NED' THEN 'NLD'
            WHEN 'POR' THEN 'PRT'
            WHEN 'RSA' THEN 'ZAF'
            WHEN 'ALG' THEN 'DZA'
            WHEN 'HAI' THEN 'HTI'
            WHEN 'URU' THEN 'URY'
            WHEN 'PAR' THEN 'PRY'
            WHEN 'KSA' THEN 'SAU'
            ELSE @eq_code
        END;

    SELECT @eq_id_pais = ID FROM administracion.Pais WHERE codigo_iso = @iso_busqueda;

    IF @eq_id_pais IS NOT NULL AND NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID_Pais = @eq_id_pais)
    BEGIN
        EXEC administracion.sp_InsertarSeleccion
            @id_pais = @eq_id_pais,
            @confederacion = @eq_conf,
            @grupo_asignado = @eq_grp,
            @id_generado = @eq_id_sel OUTPUT;

        EXEC administracion.sp_InsertarMiembroCuerpoTecnico
            @nombre = @dt_nom,
            @apellido = @dt_ape,
            @rol = 'DIRECTOR TÉCNICO',
            @id_seleccion = @eq_id_sel,
            @id_generado = @dt_id OUTPUT;
    END

    SET @i_eq += 1;
END;

-- =========================================================================
-- 5. CONVOCATORIAS
-- =========================================================================
PRINT '5. Cargando convocatorias...';

DROP TABLE IF EXISTS #csv_convocatorias;
CREATE TABLE #csv_convocatorias (
    team_name    VARCHAR(100),
    team_code    VARCHAR(10),
    dorsal       INT,
    posicion     VARCHAR(20),
    player_name  VARCHAR(200),
    first_names  VARCHAR(200),
    last_names   VARCHAR(200),
    shirt_name   VARCHAR(100),
    dob          VARCHAR(50),
    club         VARCHAR(200),
    height       VARCHAR(50),
    caps         VARCHAR(50),
    goals        VARCHAR(50)
);

DECLARE @sql_bulk NVARCHAR(MAX) = N'
BULK INSERT #csv_convocatorias
FROM ''' + REPLACE(@ruta_squadlists, '''', '''''') + N'''
WITH (
    FIRSTROW = 2,
    FORMAT = ''CSV'',
    FIELDQUOTE = ''"'',
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''0x0a'',
    CODEPAGE = ''65001''
);';

EXEC sp_executesql @sql_bulk;

DROP TABLE IF EXISTS #convocatorias_pendientes;
CREATE TABLE #convocatorias_pendientes (
    id_fila     INT IDENTITY(1,1) PRIMARY KEY,
    id_jugador  INT,
    id_seleccion INT,
    dorsal      INT
);

INSERT INTO #convocatorias_pendientes (id_jugador, id_seleccion, dorsal)
SELECT 
    j.ID AS id_jugador,
    s.ID AS id_seleccion,
    c.dorsal
FROM #csv_convocatorias c
JOIN administracion.Pais p ON p.codigo_iso = 
    CASE c.team_code
        WHEN 'ENG' THEN 'ENG'
        WHEN 'SCO' THEN 'SCO'
        WHEN 'SUI' THEN 'CHE'
        WHEN 'GER' THEN 'DEU'
        WHEN 'CRO' THEN 'HRV'
        WHEN 'NED' THEN 'NLD'
        WHEN 'POR' THEN 'PRT'
        WHEN 'RSA' THEN 'ZAF'
        WHEN 'ALG' THEN 'DZA'
        WHEN 'HAI' THEN 'HTI'
        WHEN 'URU' THEN 'URY'
        WHEN 'PAR' THEN 'PRY'
        WHEN 'KSA' THEN 'SAU'
        ELSE c.team_code
    END
JOIN administracion.Seleccion s ON s.ID_Pais = p.ID
JOIN administracion.Jugador j ON 
    j.nombre = LTRIM(RTRIM(c.first_names)) AND 
    j.apellido = LTRIM(RTRIM(c.last_names)) AND
    j.fecha_nacimiento = CONVERT(DATE, c.dob, 103)
WHERE NOT EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = j.ID);

DECLARE @i_conv INT = 1;
DECLARE @max_conv INT = (SELECT ISNULL(MAX(id_fila), 0) FROM #convocatorias_pendientes);
DECLARE @j_id INT, @sel_id INT, @j_dorsal INT, @conv_id INT;

WHILE @i_conv <= @max_conv
BEGIN
    SELECT 
        @j_id = id_jugador, 
        @sel_id = id_seleccion, 
        @j_dorsal = dorsal 
    FROM #convocatorias_pendientes 
    WHERE id_fila = @i_conv;

    BEGIN TRY
        EXEC administracion.sp_RegistrarConvocatoria
            @id_jugador = @j_id,
            @id_seleccion = @sel_id,
            @dorsal = @j_dorsal,
            @id_generado = @conv_id OUTPUT;
    END TRY
    BEGIN CATCH
        PRINT 'Error en convocatoria: ' + ERROR_MESSAGE();
    END CATCH;

    SET @i_conv += 1;
END;

DROP TABLE IF EXISTS #convocatorias_pendientes;
DROP TABLE IF EXISTS #csv_convocatorias;

-- =========================================================================
-- 6. REEMPLAZOS POR LESIÓN
-- =========================================================================
PRINT '6. Registrando reemplazos por lesión...';

DECLARE @id_reemplazo INT, @id_conv_out INT, @id_lesionado INT;

-- Argentina: Ángel Di María por Nicolás González (dorsal 15)
DECLARE @id_club_benfica INT;
SELECT @id_club_benfica = ID FROM administracion.Club WHERE nombre LIKE '%Benfica%';
IF @id_club_benfica IS NULL SELECT TOP 1 @id_club_benfica = ID FROM administracion.Club;

IF NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE nombre = 'Ángel' AND apellido = 'Di María')
    EXEC administracion.sp_InsertarJugador 
        @nombre = 'Ángel', @apellido = 'Di María', @fecha_nacimiento = '1988-02-14', 
        @id_club = @id_club_benfica, @posicion_habitual = 'Delantero', @id_generado = @id_reemplazo OUTPUT;
ELSE
    SELECT @id_reemplazo = ID FROM administracion.Jugador WHERE nombre = 'Ángel' AND apellido = 'Di María';

IF NOT EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id_reemplazo)
BEGIN
    SELECT @id_lesionado = c.ID_Jugador 
    FROM administracion.Convocatoria c 
    JOIN administracion.Seleccion s ON s.ID = c.ID_Seleccion 
    JOIN administracion.Pais p ON p.ID = s.ID_Pais 
    WHERE p.codigo_iso = 'ARG' AND c.dorsal = 15 AND c.estado = 1;

    -- Remplazo de jugador
    EXEC administracion.sp_ReemplazarConvocadoUltimoMomento
        @id_jugador_lesionado = @id_lesionado,
        @id_jugador_reemplazo = @id_reemplazo,
        @motivo_lesion        = 'Lesión muscular en entrenamiento',
        @id_convocatoria_nueva = @id_conv_out OUTPUT;
END;

-- =========================================================================
-- 7. ÁRBITROS E IDIOMAS
-- =========================================================================
PRINT '7. Cargando árbitros e idiomas...';

IF NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro)
BEGIN
    EXEC arbitraje.sp_ImportarArbitros @ruta_archivo = @ruta_arbitros;
END

DROP TABLE IF EXISTS #asistentes_seed;
CREATE TABLE #asistentes_seed (
    id_fila   INT IDENTITY(1,1) PRIMARY KEY,
    nombre    VARCHAR(100),
    apellido  VARCHAR(100),
    categoria VARCHAR(50),
    iso_pais  VARCHAR(3),
    idioma1   VARCHAR(50),
    idioma2   VARCHAR(50)
);

INSERT INTO #asistentes_seed (nombre, apellido, categoria, iso_pais, idioma1, idioma2)
VALUES
    ('Jan', 'Brem', 'Árbitro Asistente FIFA', 'CHE', 'Alemán', 'Inglés'),
    ('Stéphane', 'De Almeida', 'Árbitro Asistente FIFA', 'CHE', 'Francés', 'Inglés'),
    ('Ole', 'Lund', 'Árbitro Asistente FIFA', 'NOR', 'Noruego', 'Inglés'),
    ('Kim', 'Haglund', 'Árbitro Asistente FIFA', 'NOR', 'Noruego', 'Inglés'),
    ('Fredrik', 'Nilsson', 'Árbitro Asistente FIFA', 'SWE', 'Sueco', 'Inglés'),
    ('Mahbod', 'Beigi', 'Árbitro Asistente FIFA', 'SWE', 'Sueco', 'Inglés'),
    ('Mark', 'Rule', 'Árbitro Asistente FIFA', 'NZL', 'Inglés', 'Español'),
    ('Edward', 'Cook', 'Árbitro Asistente FIFA', 'NZL', 'Inglés', 'Francés'),
    ('Claudio', 'Urrutia', 'Árbitro Asistente FIFA', 'CHL', 'Español', 'Inglés'),
    ('José', 'Retamal', 'Árbitro Asistente FIFA', 'CHL', 'Español', 'Inglés'),
    ('Roberto', 'Cañete', 'Árbitro Asistente FIFA', 'PRY', 'Español', 'Inglés'),
    ('Eduardo', 'Cardozo', 'Árbitro Asistente FIFA', 'PRY', 'Español', 'Inglés'),
    ('Michael', 'Barwegen', 'Árbitro Asistente FIFA', 'CAN', 'Inglés', 'Francés'),
    ('Lyes', 'Arfa', 'Árbitro Asistente FIFA', 'CAN', 'Inglés', 'Francés'),
    ('Andreas', 'Heidenreich', 'Árbitro Asistente FIFA', 'AUT', 'Alemán', 'Inglés'),
    ('Maximilian', 'Weiss', 'Árbitro Asistente FIFA', 'AUT', 'Alemán', 'Inglés'),
    ('Lukas', 'Fähndrich', 'Árbitro VAR FIFA', 'CHE', 'Alemán', 'Inglés'),
    ('Espen', 'Eskås', 'Árbitro VAR FIFA', 'NOR', 'Noruego', 'Inglés'),
    ('Glenn', 'Nyberg', 'Árbitro VAR FIFA', 'SWE', 'Sueco', 'Inglés'),
    ('Campbell-Kirk', 'Kawana-Waugh', 'Cuarto Árbitro FIFA', 'NZL', 'Inglés', 'Español'),
    ('Piero', 'Maza', 'Árbitro VAR FIFA', 'CHL', 'Español', 'Inglés'),
    ('Derlis', 'López', 'Árbitro VAR FIFA', 'PRY', 'Español', 'Inglés'),
    ('Drew', 'Fischer', 'Árbitro VAR FIFA', 'CAN', 'Inglés', 'Francés'),
    ('Sebastian', 'Gishamer', 'Cuarto Árbitro FIFA', 'AUT', 'Alemán', 'Inglés');

DECLARE @id_asist_act INT = 1;
DECLARE @max_asist    INT = (SELECT MAX(id_fila) FROM #asistentes_seed);

WHILE @id_asist_act <= @max_asist
BEGIN
    DECLARE @as_nom VARCHAR(100), @as_ape VARCHAR(100), @as_cat VARCHAR(50), @as_iso VARCHAR(3), @as_id1 VARCHAR(50), @as_id2 VARCHAR(50);
    SELECT 
        @as_nom = nombre, 
        @as_ape = apellido, 
        @as_cat = categoria, 
        @as_iso = iso_pais,
        @as_id1 = idioma1,
        @as_id2 = idioma2
    FROM #asistentes_seed
    WHERE id_fila = @id_asist_act;

    DECLARE @id_pais_asist INT;
    SELECT @id_pais_asist = ID FROM administracion.Pais WHERE codigo_iso = @as_iso;

    IF @id_pais_asist IS NOT NULL AND NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE nombre = @as_nom AND apellido = @as_ape)
    BEGIN
        DECLARE @nuevo_asist_id INT;
        EXEC arbitraje.sp_InsertarArbitro
            @Nombre = @as_nom,
            @Apellido = @as_ape,
            @Categoria = @as_cat,
            @ID_Pais = @id_pais_asist,
            @ID = @nuevo_asist_id OUTPUT;

        IF @nuevo_asist_id IS NOT NULL
        BEGIN
            IF @as_id1 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM arbitraje.Idioma WHERE ID_Arbitro = @nuevo_asist_id AND lengua = @as_id1)
                EXEC arbitraje.sp_InsertarIdiomaArbitro @ID_Arbitro = @nuevo_asist_id, @Lengua = @as_id1;

            IF @as_id2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM arbitraje.Idioma WHERE ID_Arbitro = @nuevo_asist_id AND lengua = @as_id2)
                EXEC arbitraje.sp_InsertarIdiomaArbitro @ID_Arbitro = @nuevo_asist_id, @Lengua = @as_id2;
        END
    END

    SET @id_asist_act += 1;
END

DROP TABLE IF EXISTS #asistentes_seed;

-- Asignar idiomas a los árbitros importados del CSV
DROP TABLE IF EXISTS #arbitros_sin_idioma;
CREATE TABLE #arbitros_sin_idioma (
    id_fila    INT IDENTITY(1,1) PRIMARY KEY,
    id_arbitro INT,
    iso_pais   VARCHAR(3)
);

INSERT INTO #arbitros_sin_idioma (id_arbitro, iso_pais)
SELECT a.ID, p.codigo_iso
FROM arbitraje.Arbitro a
JOIN administracion.Pais p ON a.ID_Pais = p.ID
WHERE NOT EXISTS (SELECT 1 FROM arbitraje.Idioma i WHERE i.ID_Arbitro = a.ID);

DECLARE @id_arb_act INT = 1;
DECLARE @max_arb    INT = (SELECT MAX(id_fila) FROM #arbitros_sin_idioma);

WHILE @id_arb_act <= @max_arb
BEGIN
    DECLARE @target_arb_id INT, @target_iso VARCHAR(3);
    SELECT @target_arb_id = id_arbitro, @target_iso = iso_pais
    FROM #arbitros_sin_idioma
    WHERE id_fila = @id_arb_act;

    DECLARE @idioma_nativo VARCHAR(50) = 
        CASE 
            WHEN @target_iso IN ('ARG', 'ESP', 'MEX', 'URU', 'COL', 'CHI', 'PAR') THEN 'Español'
            WHEN @target_iso IN ('FRA', 'BEL') THEN 'Francés'
            WHEN @target_iso IN ('BRA', 'PRT') THEN 'Portugués'
            WHEN @target_iso IN ('ITA') THEN 'Italiano'
            WHEN @target_iso IN ('DEU', 'AUT', 'CHE') THEN 'Alemán'
            ELSE 'Inglés'
        END;

    IF NOT EXISTS (SELECT 1 FROM arbitraje.Idioma WHERE ID_Arbitro = @target_arb_id AND lengua = @idioma_nativo)
        EXEC arbitraje.sp_InsertarIdiomaArbitro @ID_Arbitro = @target_arb_id, @Lengua = @idioma_nativo;

    IF @idioma_nativo <> 'Inglés' AND NOT EXISTS (SELECT 1 FROM arbitraje.Idioma WHERE ID_Arbitro = @target_arb_id AND lengua = 'Inglés')
        EXEC arbitraje.sp_InsertarIdiomaArbitro @ID_Arbitro = @target_arb_id, @Lengua = 'Inglés';

    SET @id_arb_act += 1;
END

DROP TABLE IF EXISTS #arbitros_sin_idioma;

-- Resumen de datos cargados
SELECT 
    (SELECT COUNT(*) FROM administracion.Pais)                     AS total_paises,
    (SELECT COUNT(*) FROM administracion.Fase_Torneo)              AS total_fases,
    (SELECT COUNT(*) FROM administracion.Sede)                     AS total_sedes,
    (SELECT COUNT(DISTINCT huso_horario) FROM administracion.Sede) AS husos_horarios_distintos,
    (SELECT COUNT(*) FROM administracion.Seleccion)                AS total_selecciones,
    (SELECT COUNT(*) FROM administracion.Miembro_Cuerpo_Tecnico)   AS total_cuerpos_tecnicos,
    (SELECT COUNT(*) FROM administracion.Jugador)                  AS total_jugadores,
    (SELECT COUNT(*) FROM administracion.Convocatoria WHERE estado = 1) AS convocados_activos,
    (SELECT COUNT(*) FROM administracion.Convocatoria WHERE estado = 0) AS bajas_por_lesion,
    (SELECT COUNT(*) FROM arbitraje.Arbitro)                       AS total_arbitros,
    (SELECT COUNT(*) FROM arbitraje.Idioma)                        AS total_idiomas_arbitros;

PRINT 'Script 01 finalizado.';
GO
