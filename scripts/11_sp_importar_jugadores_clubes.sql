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
     
   Script: 11_sp_importar_jugadores_clubes.sql
   Descripción: Procedimiento almacenado para la importación masiva de jugadores y clubes
                desde el archivo SquadLists.csv.
*/

USE Mundial2026;
GO
 
CREATE OR ALTER PROCEDURE administracion.sp_ImportarJugadoresClubes
    @ruta_archivo VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
 
    /* =========================================================================
       PASO 1: VARIABLES DE CONTROL Y CONTADORES
       ========================================================================= */
    DECLARE @fecha_proceso         DATETIME = GETDATE();
    DECLARE @total_procesados      INT = 0;
    DECLARE @total_insertados      INT = 0;
    DECLARE @total_actualizados    INT = 0;
    DECLARE @total_fallidos        INT = 0;
    DECLARE @total_clubes_creados  INT = 0;
    DECLARE @mensaje_error         VARCHAR(2000) = '';
    DECLARE @codigo_error          INT = 0;
 
    /* =========================================================================
       PASO 2: VALIDACIÓN DEL ARCHIVO (acumula todos los errores en un solo mensaje)
       ========================================================================= */
    IF @ruta_archivo IS NULL OR LTRIM(RTRIM(@ruta_archivo)) = ''
    BEGIN
        SET @mensaje_error += '(50001) La ruta del archivo CSV no puede ser nula ni vacía. ';
        IF @codigo_error = 0 SET @codigo_error = 50001;
    END
    ELSE
    BEGIN
        IF LOWER(RIGHT(LTRIM(RTRIM(@ruta_archivo)), 4)) <> '.csv'
        BEGIN
            SET @mensaje_error += '(50002) El archivo especificado debe poseer extensión .csv. ';
            IF @codigo_error = 0 SET @codigo_error = 50002;
        END;
 
        DECLARE @existe_archivo INT = 0;
        SELECT @existe_archivo = file_exists
        FROM sys.dm_os_file_exists(@ruta_archivo);
 
        IF ISNULL(@existe_archivo, 0) = 0
        BEGIN
            SET @mensaje_error += '(50010) El archivo especificado no existe o no es accesible: ' + @ruta_archivo + '. ';
            IF @codigo_error = 0 SET @codigo_error = 50010;
        END;
    END;
 
    IF @codigo_error <> 0
    BEGIN
        INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, fila_origen, tipo_evento, mensaje)
        VALUES (ISNULL(NULLIF(LTRIM(RTRIM(@ruta_archivo)), ''), 'SIN_RUTA'),
                @fecha_proceso, NULL, 'ERROR', LEFT(@mensaje_error, 1000));
        THROW @codigo_error, @mensaje_error, 1;
    END;
 
    /* =========================================================================
       PASO 3: TABLAS TEMPORALES
       #csv_crudo replica 1 a 1 las 13 columnas del CSV (requisito de BULK INSERT).
       #staging conserva solo lo necesario, ya limpio, con id_fila secuencial.
       ========================================================================= */
    DROP TABLE IF EXISTS #csv_crudo;
    CREATE TABLE #csv_crudo (
        team          VARCHAR(200),
        team_code     VARCHAR(200),
        numero        VARCHAR(200),
        posicion      VARCHAR(200),
        player_name   VARCHAR(200),
        first_names   VARCHAR(200),
        last_names    VARCHAR(200),
        name_on_shirt VARCHAR(200),
        dob           VARCHAR(200),
        club          VARCHAR(200),
        height_cm     VARCHAR(200),
        caps          VARCHAR(200),
        goals         VARCHAR(200)   -- última columna: puede traer CHAR(13) al final; no se utiliza
    );
 
    DROP TABLE IF EXISTS #staging;
    CREATE TABLE #staging (
        id_fila       INT IDENTITY(1,1) PRIMARY KEY,
        nombre        VARCHAR(200),
        apellido      VARCHAR(200),
        fecha_txt     VARCHAR(200),
        posicion_txt  VARCHAR(200),
        club          VARCHAR(200)
    );
 
    /* =========================================================================
       PASO 4: LECTURA DEL CSV CON BULK INSERT
       ========================================================================= */
    DECLARE @sql NVARCHAR(MAX) = N'
        BULK INSERT #csv_crudo
        FROM ''' + REPLACE(@ruta_archivo, '''', '''''') + N'''
        WITH (
            FIRSTROW        = 2,
            FORMAT          = ''CSV'',
            FIELDQUOTE      = ''"'',
            FIELDTERMINATOR = '','',
            ROWTERMINATOR   = ''0x0a'',
            CODEPAGE        = ''65001''
        );';
 
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        SET @codigo_error  = 50011;
        SET @mensaje_error = '(50011) Error al leer el archivo CSV con BULK INSERT: ' + ERROR_MESSAGE();
        INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, fila_origen, tipo_evento, mensaje)
        VALUES (@ruta_archivo, @fecha_proceso, NULL, 'ERROR', LEFT(@mensaje_error, 1000));
        THROW @codigo_error, @mensaje_error, 1;
    END CATCH;
 
    INSERT INTO #staging (nombre, apellido, fecha_txt, posicion_txt, club)
    SELECT
        NULLIF(LTRIM(RTRIM(first_names)), ''),
        NULLIF(LTRIM(RTRIM(last_names)), ''),
        NULLIF(LTRIM(RTRIM(dob)), ''),
        NULLIF(LTRIM(RTRIM(posicion)), ''),
        NULLIF(LTRIM(RTRIM(club)), '')
    FROM #csv_crudo
    WHERE team IS NOT NULL OR player_name IS NOT NULL;
 
    DROP TABLE IF EXISTS #csv_crudo;
 
    IF NOT EXISTS (SELECT 1 FROM #staging)
    BEGIN
        SET @mensaje_error = '(50013) El archivo CSV está vacío o no contiene filas válidas.';
        INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, fila_origen, tipo_evento, mensaje)
        VALUES (@ruta_archivo, @fecha_proceso, NULL, 'ADVERTENCIA', @mensaje_error);
        THROW 50013, @mensaje_error, 1;
    END;
 
    /* =========================================================================
       PASO 5: RECORRIDO FILA POR FILA (WHILE) CON AUDITORÍA
       ========================================================================= */
    DECLARE @id_actual INT = 1;
    DECLARE @max_id    INT = 0;
    SELECT @max_id = MAX(id_fila) FROM #staging;
 
    DECLARE @nombre        VARCHAR(200);
    DECLARE @apellido      VARCHAR(200);
    DECLARE @fecha_txt     VARCHAR(200);
    DECLARE @posicion_txt  VARCHAR(200);
    DECLARE @club_csv      VARCHAR(200);
 
    DECLARE @fecha_nac     DATE;
    DECLARE @posicion_bd   VARCHAR(30);
    DECLARE @id_club       INT;
    DECLARE @id_jugador    INT;
    DECLARE @id_generado   INT;
    DECLARE @club_nuevo    BIT;
    DECLARE @es_alta       BIT;
    DECLARE @mensaje_fila  VARCHAR(2000);
 
    WHILE @id_actual <= @max_id
    BEGIN
        SET @nombre = NULL;  SET @apellido = NULL;  SET @fecha_txt = NULL;
        SET @posicion_txt = NULL;  SET @club_csv = NULL;
 
        SELECT
            @nombre       = nombre,
            @apellido     = apellido,
            @fecha_txt    = fecha_txt,
            @posicion_txt = posicion_txt,
            @club_csv     = club
        FROM #staging
        WHERE id_fila = @id_actual;
 
        BEGIN TRY
            /* ---- 5.1 Transformaciones ---- */
            SET @fecha_nac = TRY_CONVERT(DATE, @fecha_txt, 103);   -- dd/mm/aaaa
 
            SET @posicion_bd = CASE UPPER(@posicion_txt)
                                   WHEN 'GK' THEN 'Arquero'
                                   WHEN 'DF' THEN 'Defensor'
                                   WHEN 'MF' THEN 'Mediocampista'
                                   WHEN 'FW' THEN 'Delantero'
                                   ELSE NULL
                               END;
 
            /* ---- 5.2 Validaciones de la fila (un único mensaje agrupado) ---- */
            SET @mensaje_fila = '';
 
            IF @club_csv IS NULL OR LEN(@club_csv) > 100
                SET @mensaje_fila += '(50101) El club es vacío o supera los 100 caracteres. ';
            IF @nombre IS NULL OR LEN(@nombre) > 100
                SET @mensaje_fila += '(50102) El nombre del jugador es vacío o supera los 100 caracteres. ';
            IF @apellido IS NULL OR LEN(@apellido) > 100
                SET @mensaje_fila += '(50103) El apellido del jugador es vacío o supera los 100 caracteres. ';
            IF @posicion_bd IS NULL
                SET @mensaje_fila += '(50104) Posición "' + ISNULL(@posicion_txt, 'NULL')
                                   + '" no reconocida (se esperaba GK, DF, MF o FW). ';
            IF @fecha_nac IS NULL
                SET @mensaje_fila += '(50105) Fecha de nacimiento "' + ISNULL(@fecha_txt, 'NULL')
                                   + '" inválida (formato esperado dd/mm/aaaa). ';
 
            IF @mensaje_fila <> ''
                THROW 50100, @mensaje_fila, 1;
 
            /* ---- 5.3 Upsert relacional (Club -> Jugador) en una transacción por fila ---- */
            BEGIN TRANSACTION;
 
            SET @id_club = NULL;
            SET @club_nuevo = 0;
 
            SELECT @id_club = ID
            FROM administracion.Club
            WHERE nombre = @club_csv;
 
            IF @id_club IS NULL
            BEGIN
                SET @id_generado = NULL;
                EXEC administracion.sp_InsertarClub
                    @nombre       = @club_csv,
                    @id_generado  = @id_generado OUTPUT;
                SET @id_club = @id_generado;
                SET @club_nuevo = 1;
            END;
 
            SET @id_jugador = NULL;
            SELECT TOP 1 @id_jugador = ID
            FROM administracion.Jugador
            WHERE nombre = @nombre
              AND apellido = @apellido
              AND fecha_nacimiento = @fecha_nac
            ORDER BY ID;
 
            IF @id_jugador IS NULL
            BEGIN
                SET @id_generado = NULL;
                EXEC administracion.sp_InsertarJugador
                    @nombre            = @nombre,
                    @apellido          = @apellido,
                    @fecha_nacimiento  = @fecha_nac,
                    @id_club           = @id_club,
                    @posicion_habitual = @posicion_bd,
                    @id_generado       = @id_generado OUTPUT;
                SET @es_alta = 1;
            END
            ELSE
            BEGIN
                EXEC administracion.sp_ModificarJugador
                    @id                = @id_jugador,
                    @nombre            = @nombre,
                    @apellido          = @apellido,
                    @fecha_nacimiento  = @fecha_nac,
                    @id_club           = @id_club,
                    @posicion_habitual = @posicion_bd;
                SET @es_alta = 0;
            END;
 
            COMMIT TRANSACTION;
 
            -- Los contadores se actualizan recién con la fila confirmada
            IF @club_nuevo = 1 SET @total_clubes_creados += 1;
            IF @es_alta = 1 SET @total_insertados += 1;
            ELSE            SET @total_actualizados += 1;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
 
            INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, fila_origen, tipo_evento, mensaje)
            VALUES (
                @ruta_archivo,
                @fecha_proceso,
                LEFT(CONCAT('Fila ', @id_actual, ' (', ISNULL(@nombre, 'N/A'), ' ', ISNULL(@apellido, 'N/A'), ')'), 200),
                'ERROR',
                LEFT(ERROR_MESSAGE(), 1000)
            );
 
            SET @total_fallidos += 1;
        END CATCH;
 
        SET @total_procesados += 1;
        SET @id_actual += 1;
    END;
 
    /* =========================================================================
       PASO 6: RESUMEN FINAL Y LIMPIEZA
       ========================================================================= */
    INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, fila_origen, tipo_evento, mensaje)
    VALUES (
        @ruta_archivo,
        @fecha_proceso,
        NULL,
        CASE WHEN @total_fallidos = 0 THEN 'INFO' ELSE 'ADVERTENCIA' END,
        CONCAT('Proceso finalizado. Total: ', @total_procesados,
               ' | Insertados: ', @total_insertados,
               ' | Actualizados: ', @total_actualizados,
               ' | Fallidos: ', @total_fallidos,
               ' | Clubes creados: ', @total_clubes_creados)
    );
 
    DROP TABLE IF EXISTS #staging;
 
    SELECT
        @total_procesados     AS total_procesados,
        @total_insertados     AS insertados,
        @total_actualizados   AS actualizados,
        @total_fallidos       AS fallidos,
        @total_clubes_creados AS clubes_creados,
        CASE
            WHEN @total_fallidos = 0 THEN 'Importación completada con éxito.'
            ELSE 'Importación finalizada con errores parciales. Ver detalle en dbo.LogImportacion.'
        END AS resultado;
END;
GO
 