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
    Importación masiva de países y husos horarios a partir del dataset https://github.com/dr5hn/countries-states-cities-database/blob/master/json/countries.json (countries.json). Del mismo se extrae el nombre oficial del país, su capital y la lista de zonas horarias. En países con múltiples husos horarios, el proceso resuelve el huso horario oficial correspondiente a la capital o capital financiera.

    Formato countries.json
    [
      ...
      {
        "name": "Argentina",
        "capital": "Buenos Aires",
        "timezones": [
              {
                "zoneName": "America/Argentina/Buenos_Aires",
                "gmtOffsetName": "UTC-03:00"
              }
        ]
      },
      ...
    ]
*/

USE Mundial2026;
GO

CREATE OR ALTER PROCEDURE administracion.sp_ImportarPaisesJSON
    @ruta_archivo VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    -- Momento de inicio de la ejecución para agrupar los registros de auditoría
    DECLARE @fecha_proceso DATETIME = GETDATE();

    -- Variables para contabilizar el resultado de la importación
    DECLARE @total_procesados   INT = 0;
    DECLARE @total_insertados   INT = 0;
    DECLARE @total_actualizados INT = 0;
    DECLARE @total_fallidos     INT = 0;

    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar parámetro de ruta no nulo ni vacío
    IF @ruta_archivo IS NULL OR LTRIM(RTRIM(@ruta_archivo)) = ''
    BEGIN
        SET @mensaje_error += '(50001) La ruta del archivo JSON no puede ser nula ni vacía. ';
        IF @codigo_error = 0 SET @codigo_error = 50001;
    END
    ELSE
    BEGIN
        -- Validar extensión .json
        IF LOWER(RIGHT(LTRIM(RTRIM(@ruta_archivo)), 5)) <> '.json'
        BEGIN
            SET @mensaje_error += '(50002) El archivo especificado debe poseer extensión .json. ';
            IF @codigo_error = 0 SET @codigo_error = 50002;
        END;

        -- Validar existencia física del archivo
        DECLARE @existe_archivo INT = 0;
        SELECT @existe_archivo = file_exists 
        FROM sys.dm_os_file_exists(@ruta_archivo);

        IF @existe_archivo IS NULL OR @existe_archivo = 0
        BEGIN
            SET @mensaje_error += '(50010) El archivo especificado no existe o no es accesible: ' + @ruta_archivo + '. ';
            IF @codigo_error = 0 SET @codigo_error = 50010;
        END;
    END;

    -- Si existen errores acumulados en los parámetros, abortar inmediatamente
    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    -- Cargar contenido del archivo JSON
    DECLARE @json_contenido NVARCHAR(MAX);
    DECLARE @sql_lectura NVARCHAR(MAX);

    SET @sql_lectura = N'SELECT @contenido_out = BulkColumn 
                        FROM OPENROWSET(BULK ''' + REPLACE(@ruta_archivo, '''', '''''') + ''', SINGLE_CLOB) AS archivo;';

    BEGIN TRY
        EXEC sp_executesql 
            @stmt = @sql_lectura,
            @params = N'@contenido_out NVARCHAR(MAX) OUTPUT',
            @contenido_out = @json_contenido OUTPUT;
    END TRY
    BEGIN CATCH
        SET @codigo_error = 50011;
        SET @mensaje_error = '(50011) Error al leer el archivo JSON: ' + ERROR_MESSAGE();
        THROW @codigo_error, @mensaje_error, 1;
    END CATCH;

    -- Validar formato JSON
    IF @json_contenido IS NULL OR LTRIM(RTRIM(@json_contenido)) = '' OR ISJSON(@json_contenido) <> 1
    BEGIN
        SET @codigo_error = 50012;
        SET @mensaje_error = '(50012) El archivo especificado no contiene un formato JSON válido.';
        THROW @codigo_error, @mensaje_error, 1;
    END;

    -- Tabla temporal para almacenar los países parseados desde el JSON
    CREATE TABLE #paises_parseados (
        orden INT IDENTITY(1,1) PRIMARY KEY,
        nombre_pais VARCHAR(100),
        codigo_iso CHAR(3),
        capital VARCHAR(100),
        huso_formateado CHAR(6)
    );

    -- Parsear países y resolver el huso horario oficial de la capital
    -- Según el estándar internacional IANA Time Zone Database, en estados federales
    -- la zona horaria lleva el nombre de la metrópoli representativa de la región horaria
    -- (por ejemplo, la capital Washington D.C. pertenece a la zona oficial America/New_York).
    ;WITH EquivalenciaCapitalIANA AS (
        SELECT 'Washington' AS capital, 'America/New_York' AS zona_iana UNION ALL
        SELECT 'Brasilia',   'America/Sao_Paulo'                     UNION ALL
        SELECT 'Ottawa',     'America/Toronto'                       UNION ALL
        SELECT 'Canberra',   'Australia/Sydney'                      UNION ALL
        SELECT 'Beijing',    'Asia/Shanghai'                         UNION ALL
        SELECT 'Ciudad de México', 'America/Mexico_City'
    )
    INSERT INTO #paises_parseados (nombre_pais, codigo_iso, capital, huso_formateado)
    SELECT 
        LTRIM(RTRIM(p.nombre_pais)) AS nombre_pais,
        UPPER(NULLIF(LTRIM(RTRIM(p.iso3)), '')) AS codigo_iso,
        LTRIM(RTRIM(p.capital)) AS capital,
        CASE 
            WHEN COALESCE(huso_capital.texto_huso, huso_por_defecto.texto_huso) LIKE 'UTC[+-]%' 
                THEN SUBSTRING(COALESCE(huso_capital.texto_huso, huso_por_defecto.texto_huso), 4, 6)
            WHEN COALESCE(huso_capital.texto_huso, huso_por_defecto.texto_huso) IS NOT NULL 
                THEN '+00:00'
            ELSE NULL
        END AS huso_formateado
    FROM OPENJSON(@json_contenido)
    WITH (
        nombre_pais          VARCHAR(100)  '$.name',
        iso3                 VARCHAR(10)   '$.iso3',
        capital              VARCHAR(100)  '$.capital',
        zonas_horarias_json  NVARCHAR(MAX) '$.timezones' AS JSON
    ) AS p
    LEFT JOIN EquivalenciaCapitalIANA eq 
        ON LOWER(p.capital) = LOWER(eq.capital)
    -- 1. Intentar coincidencia directa con la capital
    OUTER APPLY (
        SELECT TOP 1 zh.texto_huso
        FROM OPENJSON(p.zonas_horarias_json)
        WITH (
            nombre_zona  VARCHAR(100) '$.zoneName',
            texto_huso   VARCHAR(10)  '$.gmtOffsetName'
        ) AS zh
        WHERE p.capital IS NOT NULL 
          AND LTRIM(RTRIM(p.capital)) <> '' 
          AND (
              zh.nombre_zona LIKE '%' + REPLACE(p.capital, ' ', '_') + '%'
              OR (eq.zona_iana IS NOT NULL AND zh.nombre_zona = eq.zona_iana)
          )
    ) AS huso_capital
    -- 2. Si la capital no coincide con ninguna zona IANA, toma el primer huso del país
    OUTER APPLY (
        SELECT TOP 1 zh_def.texto_huso
        FROM OPENJSON(p.zonas_horarias_json)
        WITH (
            texto_huso VARCHAR(10) '$.gmtOffsetName'
        ) AS zh_def
    ) AS huso_por_defecto;

    -- Variables de iteración mediante bucle WHILE sobre tabla temporal
    DECLARE @nombre_actual VARCHAR(100);
    DECLARE @iso_actual CHAR(3);
    DECLARE @huso_actual CHAR(6);
    DECLARE @id_existente INT;
    DECLARE @pbi_actual DECIMAL(12,2);
    DECLARE @id_nuevo INT;

    DECLARE @id_actual INT = 1;
    DECLARE @max_id INT = 0;

    SELECT @max_id = ISNULL(MAX(orden), 0) FROM #paises_parseados;

    WHILE @id_actual <= @max_id
    BEGIN
        SELECT 
            @nombre_actual = nombre_pais,
            @iso_actual = codigo_iso,
            @huso_actual = huso_formateado
        FROM #paises_parseados
        WHERE orden = @id_actual;

        SET @total_procesados += 1;

        -- Aislamiento de error por registro
        BEGIN TRY
            -- Verificar si el país ya existe en la base de datos
            SET @id_existente = NULL;
            SET @pbi_actual = NULL;

            IF @nombre_actual IS NOT NULL AND LTRIM(RTRIM(@nombre_actual)) <> ''
            BEGIN
                SELECT 
                    @id_existente = ID,
                    @pbi_actual = pbi_percapita
                FROM administracion.Pais
                WHERE LOWER(nombre) = LOWER(@nombre_actual);
            END;

            IF @id_existente IS NULL
            BEGIN
                -- Inserción mediante administracion.sp_InsertarPais
                SET @id_nuevo = NULL;
                EXEC administracion.sp_InsertarPais
                    @nombre = @nombre_actual,
                    @codigo_iso = @iso_actual,
                    @pbi_percapita = NULL,
                    @huso_horario = @huso_actual,
                    @id_generado = @id_nuevo OUTPUT;

                SET @total_insertados += 1;
            END
            ELSE
            BEGIN
                -- Actualización mediante administracion.sp_ModificarPais (preservando PBI existente)
                EXEC administracion.sp_ModificarPais
                    @id = @id_existente,
                    @nombre = @nombre_actual,
                    @codigo_iso = @iso_actual,
                    @pbi_percapita = @pbi_actual,
                    @huso_horario = @huso_actual;

                SET @total_actualizados += 1;
            END
        END TRY
        BEGIN CATCH
            SET @total_fallidos += 1;
            INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, fila_origen, tipo_evento, mensaje)
            VALUES (
                @ruta_archivo,
                @fecha_proceso,
                ISNULL(NULLIF(@nombre_actual, ''), 'Elemento JSON #' + CAST(@id_actual AS VARCHAR(10))),
                'ERROR',
                ERROR_MESSAGE()
            );
        END CATCH;

        SET @id_actual += 1;
    END;

    -- Registrar evento de finalización en el log de auditoría
    INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, fila_origen, tipo_evento, mensaje)
    VALUES (
        @ruta_archivo,
        @fecha_proceso,
        '-',
        CASE WHEN @total_fallidos = 0 THEN 'INFO' ELSE 'ADVERTENCIA' END,
        'Proceso finalizado. Total: ' + CAST(@total_procesados AS VARCHAR(10)) +
        ' | Insertados: ' + CAST(@total_insertados AS VARCHAR(10)) +
        ' | Actualizados: ' + CAST(@total_actualizados AS VARCHAR(10)) +
        ' | Fallidos: ' + CAST(@total_fallidos AS VARCHAR(10))
    );

    -- Resumen final en pantalla
    SELECT 
        @total_procesados   AS total_procesados,
        @total_insertados   AS total_insertados,
        @total_actualizados AS total_actualizados,
        @total_fallidos     AS total_fallidos,
        CASE 
            WHEN @total_fallidos = 0 THEN 'Importación finalizada con éxito.'
            ELSE 'Importación finalizada con errores parciales. Ver detalle en dbo.LogImportacion.'
        END AS resultado;

    DROP TABLE IF EXISTS #paises_parseados;
END;
GO
