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

    Descripción:
    Importación de arbitros a partir del dataset https://colab.research.google.com/drive/1NZY0RHN2LdfaHivrzwsqLK8Fyj7BogP8?usp=sharing 

    Formato arbitros.csv (Ejemplo de registro): 
                    En la tabla Arbitro solo va la informacion del Arbitro Principal
                    pero se añadio en el .csv la informacion de los asistentes por si
                    despues se debe usar tambien
                            
  - arbitro_nombre: "John"
  - arbitro_apellido: "Langenus"
  - arbitro_pais: "Bélgica"
  - asistente1_nombre: "Umberto"
  - asistente1_apellido: "Molinari"
  - asistente1_pais: "Italia"
  - asistente2_nombre: "Emilio"
  - asistente2_apellido: "Alonso"
  - asistente2_pais: "España"
  - categoria: "FIFA"
*/

USE Mundial2026;
GO

CREATE OR ALTER PROCEDURE arbitraje.sp_ImportarArbitros
    @ruta_archivo VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    /* =========================================================================
       VARIABLES DE CONTROL, CONTADORES Y ACUMULACIÓN DE ERRORES
       ========================================================================= */
    DECLARE @fecha_proceso      DATETIME = GETDATE();
    DECLARE @total_procesados   INT = 0;
    DECLARE @total_insertados   INT = 0;
    DECLARE @total_actualizados INT = 0;
    DECLARE @total_fallidos     INT = 0;

    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error  INT = 0;

    /* =========================================================================
       VALIDACIÓN DE ARCHIVO con acumulacion de errores multiples
       ========================================================================= */
    IF @ruta_archivo IS NULL OR LTRIM(RTRIM(@ruta_archivo)) = ''
    BEGIN
        SET @mensaje_error += '(50001) La ruta del archivo CSV no puede ser nula ni vacía. ';
        IF @codigo_error = 0 SET @codigo_error = 50001;
    END
    ELSE
    BEGIN

      -- aca valido que el archivo sea .csv
        IF LOWER(RIGHT(LTRIM(RTRIM(@ruta_archivo)), 4)) <> '.csv'
        BEGIN
            SET @mensaje_error += '(50002) El archivo especificado debe poseer extensión .csv. ';
            IF @codigo_error = 0 SET @codigo_error = 50002;
        END;

      --aca valido que el archivo exista en el disco 
        DECLARE @existe_archivo INT = 0;
        SELECT @existe_archivo = file_exists 
        FROM sys.dm_os_file_exists(@ruta_archivo);

        IF ISNULL(@existe_archivo, 0) = 0
        BEGIN
            SET @mensaje_error += '(50010) El archivo especificado no existe o no es accesible: ' + @ruta_archivo + '. ';
            IF @codigo_error = 0 SET @codigo_error = 50010;
        END;
    END;

    --si fallo alguna validacion la registro en Log.
    IF @codigo_error <> 0
    BEGIN
        INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, fila_origen, tipo_evento, mensaje)
        VALUES (ISNULL(NULLIF(LTRIM(RTRIM(@ruta_archivo)), ''), 'SIN_RUTA'), @fecha_proceso, NULL, 'ERROR', @mensaje_error);

        THROW @codigo_error, @mensaje_error, 1;
    END;

    /* =========================================================================
       CREACIÓN DE TABLAS TEMPORALES 
       ========================================================================= */
    DROP TABLE IF EXISTS #csv_crudo;
    CREATE TABLE #csv_crudo (
        arbitro_nombre     VARCHAR(200),
        arbitro_apellido   VARCHAR(200),
        arbitro_pais       VARCHAR(200),
        asistente1_nombre  VARCHAR(200),
        asistente1_apellido VARCHAR(200),
        asistente1_pais    VARCHAR(200),
        asistente2_nombre  VARCHAR(200),
        asistente2_apellido VARCHAR(200),
        asistente2_pais    VARCHAR(200),
        categoria          VARCHAR(100)
    );

    DROP TABLE IF EXISTS #staging;
    CREATE TABLE #staging (
        id_fila            INT IDENTITY(1,1) PRIMARY KEY,
        
        arbitro_nombre     VARCHAR(200),
        arbitro_apellido   VARCHAR(200),
        arbitro_pais       VARCHAR(200),
        categoria          VARCHAR(100)
    );

    /* =========================================================================
      LECTURA DEL ARCHIVO CSV CON BULK INSERT
       ========================================================================= */
    DECLARE @sql NVARCHAR(MAX) = N'
    BULK INSERT #csv_crudo
    FROM ''' + REPLACE(@ruta_archivo, '''', '''''') + N'''
    WITH (
        FIRSTROW = 2,
        FORMAT = ''CSV'',
        FIELDQUOTE = ''"'',
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''0x0a'',
        CODEPAGE = ''65001''
    );';

    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        SET @codigo_error = 50020;
        SET @mensaje_error = '(50020) Error al leer el archivo CSV de árbitros con BULK INSERT: ' + ERROR_MESSAGE();

        INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, fila_origen, tipo_evento, mensaje)
        VALUES (@ruta_archivo, @fecha_proceso, NULL, 'ERROR', @mensaje_error);

        THROW @codigo_error, @mensaje_error, 1;
    END CATCH;

    -- volcamos solo los datos del árbitro principal a staging, limpiando espacios
    INSERT INTO #staging (arbitro_nombre, arbitro_apellido, arbitro_pais, categoria)
    SELECT 
        LTRIM(RTRIM(arbitro_nombre)),
        LTRIM(RTRIM(arbitro_apellido)),
        LTRIM(RTRIM(arbitro_pais)),
        LTRIM(RTRIM(categoria))
    FROM #csv_crudo
    WHERE arbitro_nombre IS NOT NULL AND arbitro_nombre <> '';

    DROP TABLE IF EXISTS #csv_crudo;

    --valido que el archivo no este vacio 
    IF NOT EXISTS (SELECT 1 FROM #staging)
    BEGIN
        SET @mensaje_error = '(50030) El archivo CSV de árbitros está vacío o no contiene filas válidas.';
        INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, fila_origen, tipo_evento, mensaje)
        VALUES (@ruta_archivo, @fecha_proceso, NULL, 'ADVERTENCIA', @mensaje_error);

        THROW 50030, @mensaje_error, 1;
    END;
     
    /* =========================================================================
       RECORRO FILA POR FILA CON LÓGICA DE UPSERT Y BÚSQUEDA DE PAÍS
       ========================================================================= */
    DECLARE @id_actual INT = 1;
    DECLARE @max_id    INT = 0;
    SELECT @max_id = MAX(id_fila) FROM #staging;

    --con estas guarlo los valores de la fila actual
    DECLARE @v_nombre   VARCHAR(100);
    DECLARE @v_apellido VARCHAR(100);
    DECLARE @v_pais_txt VARCHAR(100);
    DECLARE @v_categoria VARCHAR(50);
    DECLARE @id_pais_fk INT;

    WHILE @id_actual <= @max_id
    BEGIN
    
    --al poner NULL no arrastro basura en cada vuelta
        SET @v_nombre = NULL;
        SET @v_apellido = NULL;
        SET @v_pais_txt = NULL;
        SET @v_categoria = NULL;
        SET @id_pais_fk = NULL;

    --aca leo la fila actual
       SELECT 
            @v_nombre = arbitro_nombre,
            @v_apellido = arbitro_apellido,
            @v_pais_txt = arbitro_pais,
            @v_categoria = categoria
        FROM #staging
        WHERE id_fila = @id_actual;

        BEGIN TRY
            -- Buscar el ID del país en la tabla administracion.Pais por nombre
            SELECT @id_pais_fk = ID 
            FROM administracion.Pais 
            WHERE codigo_iso = @v_pais_txt; -- es universal 

            -- Si el país no esta cargado previamente lanzamos un error controlado
            IF @id_pais_fk IS NULL
            BEGIN
                RAISERROR('El país del árbitro ("%s") no se encuentra registrado en la base de datos.', 16, 1, @v_pais_txt);
            END;

            -- upsert: verificar si el árbitro ya existe (por nombre y apellido)
            IF EXISTS (
                SELECT 1 FROM arbitraje.Arbitro 
                WHERE nombre = @v_nombre AND apellido = @v_apellido
            )
            BEGIN
                -- si existe, busco el ID existente para actualizarlo
                 
                DECLARE @id_arbitro_existente INT;
                SELECT @id_arbitro_existente = ID FROM arbitraje.Arbitro WHERE nombre = @v_nombre AND apellido = @v_apellido;

                -- uso el SP sp_ModificarArbitro
                EXEC arbitraje.sp_ModificarArbitro
                    @ID = @id_arbitro_existente,
                    @nombre = @v_nombre,
                    @apellido = @v_apellido,
                    @categoria = @v_categoria,
                    @ID_Pais = @id_pais_fk;

                SET @total_actualizados += 1;
            END
            ELSE
            BEGIN
                -- si no existe, se debe insertar en la tabla 
                -- uso SP sp_InsertarArbitro

                
                DECLARE @nuevo_id INT;

                EXEC arbitraje.sp_InsertarArbitro
                    @nombre = @v_nombre,
                    @apellido = @v_apellido,
                    @categoria = @v_categoria,
                    @ID_Pais = @id_pais_fk,

                    @ID=@nuevo_id OUTPUT; 


                SET @total_insertados += 1;
            END;

        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            --guardo el error de esta fila y continuo
            INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, fila_origen, tipo_evento, mensaje)
            VALUES (
                @ruta_archivo, 
                @fecha_proceso, 
                CONCAT('Fila ', @id_actual, ' (', ISNULL(@v_nombre, 'N/A'), ' ', ISNULL(@v_apellido, 'N/A'), ')'), 
                'ERROR', 
                ERROR_MESSAGE()
            );

            SET @total_fallidos += 1;
        END CATCH;

        SET @total_procesados += 1;
        SET @id_actual += 1;
    END;

    /* =========================================================================
       REGISTRO DE RESUMEN FINAL Y LIMPIEZA
       ========================================================================= */
    INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, fila_origen, tipo_evento, mensaje)
    VALUES (
        @ruta_archivo,
        @fecha_proceso,
        NULL,
        CASE WHEN @total_fallidos = 0 THEN 'INFO' ELSE 'ADVERTENCIA' END,
        CONCAT('Proceso de importación de árbitros finalizado. Total: ', @total_procesados, 
               ' | Insertados: ', @total_insertados, 
               ' | Actualizados: ', @total_actualizados, 
               ' | Fallidos: ', @total_fallidos)
    );

    DROP TABLE IF EXISTS #staging;

    SELECT 
        @total_procesados   AS total_procesados,
        @total_insertados   AS insertados,
        @total_actualizados AS actualizados,
        @total_fallidos     AS fallidos,
        CASE 
            WHEN @total_fallidos = 0 THEN 'Importación de árbitros completada con éxito.'
            ELSE 'Importación de árbitros finalizada con errores parciales. Ver detalle en dbo.LogImportacion.'
        END AS resultado;
END;
GO