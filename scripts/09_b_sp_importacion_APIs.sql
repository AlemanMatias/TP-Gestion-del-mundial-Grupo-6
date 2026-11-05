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
     
   Script: 09_b_sp_importacion_APIs.sql
   Descripción: Procedimientos almacenados para el consumo e integración en vivo con APIs REST externas.
                Incluye:
                1. administracion.sp_InvocarApi: Conector HTTP/HTTPS genérico y reutilizable basado en
                   MSXML2.ServerXMLHTTP, con validación de protocolo, límite máximo de timeout,
                   verificación estricta de códigos HRESULT en cada operación COM y captura de
                   respuestas extensas en NVARCHAR(MAX).
                2. administracion.sp_ImportarPbiBancoMundial: Consumo paginado en vivo de la API oficial
                   del Banco Mundial (World Bank Indicator API - NY.GDP.PCAP.CD, per_page=1000) con
                   recorrido automático de páginas ($[0].pages), particionamiento por código ISO-3,
                   distinción entre agregados regionales y países registrados, y actualización mediante
                   administracion.sp_ModificarPais.

   ARQUITECTURA Y SEGURIDAD (OLE Automation Procedures):
                La habilitación de 'Ole Automation Procedures' a nivel de instancia permite invocar
                objetos COM (MSXML2.ServerXMLHTTP) directamente desde T-SQL.
                En un entorno productivo real, habilitar componentes COM amplía la superficie de exposición
                del servidor y requiere permisos de salida de red para el servicio SQL Server; por ello,
                en producción se recomienda delegar las peticiones HTTP a un orquestador externo (SSIS,
                Azure Data Factory o microservicio de integración) o utilizar sp_invoke_external_rest_endpoint
                en entornos Azure SQL / SQL Server 2022 gestionados.
*/

USE Mundial2026;
GO

PRINT '======================================================================';
PRINT 'CONFIGURANDO MOTOR Y COMPILANDO SPs DE INTEGRACIÓN CON APIs REST';
PRINT '======================================================================';
GO

-- =========================================================================================
-- 0. HABILITACIÓN DE OLE AUTOMATION PROCEDURES EN LA INSTANCIA
-- =========================================================================================
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE WITH OVERRIDE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE WITH OVERRIDE;
GO

-- =========================================================================================
-- 1. SP GENÉRICO: administracion.sp_InvocarApi
-- =========================================================================================
PRINT '>> Creando / actualizando [administracion].[sp_InvocarApi]...';
GO

CREATE OR ALTER PROCEDURE administracion.sp_InvocarApi
    @url              NVARCHAR(2000),
    @metodo           VARCHAR(10)      = 'GET',
    @cabeceras        NVARCHAR(MAX)    = NULL,
    @cuerpo           NVARCHAR(MAX)    = NULL,
    @timeout_segundos INT              = 30,
    @respuesta        NVARCHAR(MAX)    OUTPUT,
    @codigo_estado    INT              OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validaciones defensivas de parámetros de entrada
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error  INT = 0;

    SET @url = LTRIM(RTRIM(@url));

    IF @url IS NULL OR @url = ''
    BEGIN
        SET @mensaje_error += '(50020) La URL del servicio REST no puede ser nula ni vacía. ';
        IF @codigo_error = 0 SET @codigo_error = 50020;
    END
    ELSE IF LOWER(@url) NOT LIKE 'https://%' AND LOWER(@url) NOT LIKE 'http://%'
    BEGIN
        SET @mensaje_error += '(50020) La URL especificada debe iniciar con un protocolo válido (https:// o http://). ';
        IF @codigo_error = 0 SET @codigo_error = 50020;
    END;

    SET @metodo = UPPER(ISNULL(LTRIM(RTRIM(@metodo)), 'GET'));
    IF @metodo NOT IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH')
    BEGIN
        SET @mensaje_error += '(50021) El método HTTP especificado (' + ISNULL(@metodo, '') + ') no es válido. ';
        IF @codigo_error = 0 SET @codigo_error = 50021;
    END;

    -- Validar rango de timeout (entre 1 y 120 segundos máximo para evitar bloqueos indefinidos)
    IF @timeout_segundos IS NULL OR @timeout_segundos <= 0 OR @timeout_segundos > 120
    BEGIN
        SET @mensaje_error += '(50022) El tiempo de espera (timeout) debe estar comprendido entre 1 y 120 segundos. ';
        IF @codigo_error = 0 SET @codigo_error = 50022;
    END;

    -- Validar que @cabeceras sea un JSON válido si fue informado
    IF @cabeceras IS NOT NULL AND LTRIM(RTRIM(@cabeceras)) <> '' AND ISJSON(@cabeceras) <> 1
    BEGIN
        SET @mensaje_error += '(50024) El parámetro @cabeceras debe contener un formato JSON válido. ';
        IF @codigo_error = 0 SET @codigo_error = 50024;
    END;

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    -- Inicializar parámetros de salida
    SET @respuesta = NULL;
    SET @codigo_estado = NULL;

    -- Variables para el manejo del componente COM MSXML2.ServerXMLHTTP
    DECLARE @objeto_http INT;
    DECLARE @hr          INT;
    DECLARE @src         VARCHAR(255);
    DECLARE @desc        VARCHAR(1000);
    DECLARE @timeout_ms  INT = @timeout_segundos * 1000;

    -- 1. Instanciar ServerXMLHTTP versión 6.0 (o versión estándar como respaldo)
    EXEC @hr = sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @objeto_http OUT;
    IF @hr <> 0
        EXEC @hr = sp_OACreate 'MSXML2.ServerXMLHTTP', @objeto_http OUT;

    IF @hr <> 0
    BEGIN
        EXEC sp_OAGetErrorInfo @objeto_http, @src OUT, @desc OUT;
        SET @mensaje_error = '(50023) Error al inicializar componente OLE HTTP (MSXML2.ServerXMLHTTP). Verifique que Ole Automation Procedures esté habilitado. Detalle: ' + ISNULL(@desc, 'HRESULT ' + CAST(@hr AS VARCHAR(20)));
        THROW 50023, @mensaje_error, 1;
    END;

    BEGIN TRY
        -- 2. Configurar apertura de conexión sincrónica: open(metodo, url, async=false)
        EXEC @hr = sp_OAMethod @objeto_http, 'open', NULL, @metodo, @url, 'false';
        IF @hr <> 0
        BEGIN
            EXEC sp_OAGetErrorInfo @objeto_http, @src OUT, @desc OUT;
            SET @mensaje_error = '(50024) Error al abrir la solicitud HTTP hacia (' + @url + '): ' + ISNULL(@desc, 'HRESULT ' + CAST(@hr AS VARCHAR(20)));
            THROW 50024, @mensaje_error, 1;
        END;

        -- 3. Configurar tiempos de espera (resolve, connect, send, receive en milisegundos)
        EXEC @hr = sp_OAMethod @objeto_http, 'setTimeouts', NULL, @timeout_ms, @timeout_ms, @timeout_ms, @timeout_ms;
        IF @hr <> 0
        BEGIN
            EXEC sp_OAGetErrorInfo @objeto_http, @src OUT, @desc OUT;
            SET @mensaje_error = '(50024) Error al configurar setTimeouts en el objeto HTTP: ' + ISNULL(@desc, 'HRESULT ' + CAST(@hr AS VARCHAR(20)));
            THROW 50024, @mensaje_error, 1;
        END;

        -- 4. Configurar cabeceras HTTP estándar con control de HRESULT
        EXEC @hr = sp_OAMethod @objeto_http, 'setRequestHeader', NULL, 'Accept', 'application/json';
        IF @hr <> 0
        BEGIN
            EXEC sp_OAGetErrorInfo @objeto_http, @src OUT, @desc OUT;
            SET @mensaje_error = '(50024) Error al configurar cabecera Accept: ' + ISNULL(@desc, 'HRESULT ' + CAST(@hr AS VARCHAR(20)));
            THROW 50024, @mensaje_error, 1;
        END;

        EXEC @hr = sp_OAMethod @objeto_http, 'setRequestHeader', NULL, 'User-Agent', 'SQLServer-Mundial2026/1.0';
        IF @hr <> 0
        BEGIN
            EXEC sp_OAGetErrorInfo @objeto_http, @src OUT, @desc OUT;
            SET @mensaje_error = '(50024) Error al configurar cabecera User-Agent: ' + ISNULL(@desc, 'HRESULT ' + CAST(@hr AS VARCHAR(20)));
            THROW 50024, @mensaje_error, 1;
        END;

        -- 5. Cabeceras personalizadas provistas en formato JSON: {"Header": "Valor"}
        IF @cabeceras IS NOT NULL AND LTRIM(RTRIM(@cabeceras)) <> ''
        BEGIN
            IF ISJSON(@cabeceras) <> 1
            BEGIN
                SET @mensaje_error = '(50024) El parámetro @cabeceras debe contener un formato JSON válido.';
                THROW 50024, @mensaje_error, 1;
            END;

            DECLARE @h_nombre NVARCHAR(100);
            DECLARE @h_valor  NVARCHAR(500);

            DECLARE @tabla_headers TABLE (
                orden INT IDENTITY(1,1) PRIMARY KEY,
                clave NVARCHAR(100),
                valor NVARCHAR(500)
            );

            INSERT INTO @tabla_headers (clave, valor)
            SELECT [key], [value] FROM OPENJSON(@cabeceras);

            DECLARE @idx_h INT = 1, @max_h INT = 0;
            SELECT @max_h = ISNULL(MAX(orden), 0) FROM @tabla_headers;

            WHILE @idx_h <= @max_h
            BEGIN
                SELECT @h_nombre = clave, @h_valor = valor FROM @tabla_headers WHERE orden = @idx_h;
                EXEC @hr = sp_OAMethod @objeto_http, 'setRequestHeader', NULL, @h_nombre, @h_valor;
                IF @hr <> 0
                BEGIN
                    EXEC sp_OAGetErrorInfo @objeto_http, @src OUT, @desc OUT;
                    SET @mensaje_error = '(50024) Error al configurar cabecera personalizada (' + ISNULL(@h_nombre, '') + '): ' + ISNULL(@desc, 'HRESULT ' + CAST(@hr AS VARCHAR(20)));
                    THROW 50024, @mensaje_error, 1;
                END;
                SET @idx_h += 1;
            END;
        END;

        -- 6. Enviar solicitud HTTP
        IF @cuerpo IS NOT NULL
            EXEC @hr = sp_OAMethod @objeto_http, 'send', NULL, @cuerpo;
        ELSE
            EXEC @hr = sp_OAMethod @objeto_http, 'send';

        IF @hr <> 0
        BEGIN
            EXEC sp_OAGetErrorInfo @objeto_http, @src OUT, @desc OUT;
            SET @mensaje_error = '(50025) Error de red al invocar la API (' + @url + '): ' + ISNULL(@desc, 'HRESULT ' + CAST(@hr AS VARCHAR(20)));
            THROW 50025, @mensaje_error, 1;
        END;

        -- 7. Obtener código de estado HTTP (200, 404, 500, etc.) con control de HRESULT
        EXEC @hr = sp_OAGetProperty @objeto_http, 'status', @codigo_estado OUT;
        IF @hr <> 0
        BEGIN
            EXEC sp_OAGetErrorInfo @objeto_http, @src OUT, @desc OUT;
            SET @mensaje_error = '(50026) Error al leer la propiedad HTTP status: ' + ISNULL(@desc, 'HRESULT ' + CAST(@hr AS VARCHAR(20)));
            THROW 50026, @mensaje_error, 1;
        END;

        -- 8. Capturar el cuerpo completo de la respuesta mediante inserción tabular desde sp_OAGetProperty
        --    y verificar su código HRESULT.
        DECLARE @tabla_respuesta TABLE (contenido NVARCHAR(MAX));
        INSERT INTO @tabla_respuesta (contenido)
        EXEC @hr = sp_OAGetProperty @objeto_http, 'responseText';

        IF @hr <> 0
        BEGIN
            EXEC sp_OAGetErrorInfo @objeto_http, @src OUT, @desc OUT;
            SET @mensaje_error = '(50026) Error al leer el cuerpo de la respuesta (responseText): ' + ISNULL(@desc, 'HRESULT ' + CAST(@hr AS VARCHAR(20)));
            THROW 50026, @mensaje_error, 1;
        END;

        SELECT TOP 1 @respuesta = contenido FROM @tabla_respuesta;

        -- 9. Destruir el objeto OLE para liberar recursos del servidor
        EXEC sp_OADestroy @objeto_http;
        SET @objeto_http = NULL;
    END TRY
    BEGIN CATCH
        IF @objeto_http IS NOT NULL
            EXEC sp_OADestroy @objeto_http;

        IF ERROR_NUMBER() >= 50000
            THROW;
        ELSE
        BEGIN
            SET @mensaje_error = '(50026) Fallo no controlado durante la invocación HTTP: ' + ERROR_MESSAGE();
            THROW 50026, @mensaje_error, 1;
        END;
    END CATCH;
END;
GO

PRINT 'OK: Stored Procedure [administracion].[sp_InvocarApi] creado exitosamente.';
GO

-- =========================================================================================
-- 2. SP DE IMPORTACIÓN: administracion.sp_ImportarPbiBancoMundial
-- =========================================================================================
PRINT '>> Creando / actualizando [administracion].[sp_ImportarPbiBancoMundial]...';
GO

CREATE OR ALTER PROCEDURE administracion.sp_ImportarPbiBancoMundial
    @url_api NVARCHAR(2000) = 'https://api.worldbank.org/v2/country/all/indicator/NY.GDP.PCAP.CD?format=json&per_page=1000&date=2020:2024'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @fecha_proceso DATETIME = GETDATE();
    DECLARE @origen_log    VARCHAR(500);

    -- Variables de métricas para auditoría
    DECLARE @total_procesados   INT = 0;
    DECLARE @total_actualizados INT = 0;
    DECLARE @total_agregados    INT = 0; -- Entidades agregadas/regionales de la API que no son países registrados
    DECLARE @total_fallidos     INT = 0; -- Países registrados cuyo dato vino nulo o falló al actualizar

    DECLARE @mensaje_error  VARCHAR(2000) = '';
    DECLARE @codigo_error   INT = 0;

    -- Validar que la URL de la API no sea nula ni vacía
    IF @url_api IS NULL OR LTRIM(RTRIM(@url_api)) = ''
    BEGIN
        SET @codigo_error = 50030;
        SET @mensaje_error = '(50030) La URL de la API del Banco Mundial no puede ser nula ni vacía.';
        THROW @codigo_error, @mensaje_error, 1;
    END;

    SET @url_api = LTRIM(RTRIM(@url_api));
    SET @origen_log = LEFT(@url_api, 500);

    -- Variable de tabla en memoria para acumular los registros crudos de todas las páginas
    DECLARE @raw_banco_mundial TABLE (
        countryiso3code VARCHAR(10)  NULL,
        nombre_api      VARCHAR(150) NULL,
        anio            VARCHAR(10)  NULL,
        valor_pbi       VARCHAR(50)  NULL
    );

    -- Variables de control de paginación ($[0].page y $[0].pages)
    DECLARE @pagina_actual  INT = 1;
    DECLARE @total_paginas  INT = 1;
    DECLARE @url_paginada   NVARCHAR(2000);
    DECLARE @json_contenido NVARCHAR(MAX);
    DECLARE @codigo_estado  INT;
    DECLARE @json_datos     NVARCHAR(MAX);

    -- Bucle de descarga paginada (límite de 1.000 registros por página)
    WHILE @pagina_actual <= @total_paginas
    BEGIN
        -- Construir URL con el número de página actual si no se especificó manualmente page=
        IF CHARINDEX('page=', LOWER(@url_api)) > 0 AND CHARINDEX('per_page=', LOWER(@url_api)) = 0
            SET @url_paginada = @url_api;
        ELSE IF CHARINDEX('?', @url_api) > 0
            SET @url_paginada = @url_api + N'&page=' + CAST(@pagina_actual AS NVARCHAR(10));
        ELSE
            SET @url_paginada = @url_api + N'?page=' + CAST(@pagina_actual AS NVARCHAR(10));

        SET @json_contenido = NULL;
        SET @codigo_estado  = NULL;

        -- Invocar la API REST mediante el conector genérico administracion.sp_InvocarApi
        BEGIN TRY
            EXEC administracion.sp_InvocarApi
                @url              = @url_paginada,
                @metodo           = 'GET',
                @timeout_segundos = 60,
                @respuesta        = @json_contenido OUTPUT,
                @codigo_estado    = @codigo_estado OUTPUT;
        END TRY
        BEGIN CATCH
            INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, tipo_evento, mensaje)
            VALUES (@origen_log, @fecha_proceso, 'ERROR', 'Fallo de conectividad en página ' + CAST(@pagina_actual AS VARCHAR(10)) + ': ' + ERROR_MESSAGE());
            THROW;
        END CATCH;

        -- Verificar código de respuesta HTTP 200 OK
        IF @codigo_estado <> 200 OR @json_contenido IS NULL
        BEGIN
            SET @codigo_error = 50031;
            SET @mensaje_error = '(50031) La API del Banco Mundial respondió con código de estado HTTP ' + ISNULL(CAST(@codigo_estado AS VARCHAR(10)), 'NULL') + ' en la página ' + CAST(@pagina_actual AS VARCHAR(10)) + '.';
            INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, tipo_evento, mensaje)
            VALUES (@origen_log, @fecha_proceso, 'ERROR', @mensaje_error);
            THROW @codigo_error, @mensaje_error, 1;
        END;

        -- Validar que el cuerpo devuelto sea un documento JSON válido
        IF ISJSON(@json_contenido) <> 1
        BEGIN
            SET @codigo_error = 50032;
            SET @mensaje_error = '(50032) La respuesta recibida en la página ' + CAST(@pagina_actual AS VARCHAR(10)) + ' no contiene una estructura JSON válida.';
            INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, tipo_evento, mensaje)
            VALUES (@origen_log, @fecha_proceso, 'ERROR', @mensaje_error);
            THROW @codigo_error, @mensaje_error, 1;
        END;

        -- En la primera página, leer el total de páginas informado en los metadatos ($[0].pages)
        IF @pagina_actual = 1
        BEGIN
            SET @total_paginas = ISNULL(TRY_CAST(JSON_VALUE(@json_contenido, '$[0].pages') AS INT), 1);
            IF @total_paginas < 1 SET @total_paginas = 1;
        END;

        -- Extraer el arreglo de mediciones anuales del indicador ($[1])
        SET @json_datos = JSON_QUERY(@json_contenido, '$[1]');

        IF @pagina_actual = 1 AND (@json_datos IS NULL OR ISJSON(@json_datos) <> 1)
        BEGIN
            SET @codigo_error = 50033;
            SET @mensaje_error = '(50033) La respuesta JSON de la API del Banco Mundial no contiene el nodo de datos esperado ($[1]).';
            INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, tipo_evento, mensaje)
            VALUES (@origen_log, @fecha_proceso, 'ERROR', @mensaje_error);
            THROW @codigo_error, @mensaje_error, 1;
        END;

        -- Acumular los registros de la página actual en @raw_banco_mundial
        IF @json_datos IS NOT NULL AND ISJSON(@json_datos) = 1
        BEGIN
            INSERT INTO @raw_banco_mundial (countryiso3code, nombre_api, anio, valor_pbi)
            SELECT 
                countryiso3code,
                nombre_api,
                anio,
                valor_pbi
            FROM OPENJSON(@json_datos)
            WITH (
                countryiso3code VARCHAR(10)  '$.countryiso3code',
                nombre_api      VARCHAR(150) '$.country.value',
                anio            VARCHAR(10)  '$.date',
                valor_pbi       VARCHAR(50)  '$.value'
            );
        END;

        SET @pagina_actual += 1;
    END;

    -- Variable de tabla en memoria para almacenar una única fila consolidada por entidad/código ISO-3
    DECLARE @pbi_parseado TABLE (
        orden           INT IDENTITY(1,1) PRIMARY KEY,
        codigo_iso      VARCHAR(10)   NULL,
        nombre_api      VARCHAR(150)  NULL,
        pbi_nuevo       DECIMAL(12,2) NULL,
        anio_dato       INT           NULL
    );

    -- Agrupar y particionar por el código ISO-3 (countryiso3code), priorizando el año más reciente con valor no nulo.
    -- Para los agregados regionales que vienen con countryiso3code vacío (''), se particiona por su nombre en la API.
    ;WITH PbiRankeado AS (
        SELECT 
            UPPER(NULLIF(LTRIM(RTRIM(raw.countryiso3code)), '')) AS iso3,
            LTRIM(RTRIM(raw.nombre_api)) AS nombre_api,
            TRY_CAST(raw.anio AS INT) AS anio,
            CAST(ROUND(TRY_CAST(raw.valor_pbi AS DECIMAL(18,4)), 2) AS DECIMAL(12,2)) AS pbi,
            ROW_NUMBER() OVER (
                PARTITION BY COALESCE(UPPER(NULLIF(LTRIM(RTRIM(raw.countryiso3code)), '')), LTRIM(RTRIM(raw.nombre_api)))
                ORDER BY 
                    CASE WHEN raw.valor_pbi IS NOT NULL THEN 0 ELSE 1 END ASC,
                    TRY_CAST(raw.anio AS INT) DESC
            ) AS rn
        FROM @raw_banco_mundial AS raw
    )
    INSERT INTO @pbi_parseado (codigo_iso, nombre_api, pbi_nuevo, anio_dato)
    SELECT 
        iso3,
        nombre_api,
        pbi,
        anio
    FROM PbiRankeado
    WHERE rn = 1;

    -- Iteración sobre los registros consolidados mediante bucle WHILE
    DECLARE @iso_actual    VARCHAR(10);
    DECLARE @nombre_api    VARCHAR(150);
    DECLARE @pbi_nuevo     DECIMAL(12,2);
    DECLARE @anio_dato     INT;

    DECLARE @pais_id       INT;
    DECLARE @pais_nombre   VARCHAR(100);
    DECLARE @pais_huso     CHAR(6);

    DECLARE @id_actual INT = 1;
    DECLARE @max_id    INT = 0;

    SELECT @max_id = ISNULL(MAX(orden), 0) FROM @pbi_parseado;

    WHILE @id_actual <= @max_id
    BEGIN
        SELECT 
            @iso_actual = codigo_iso,
            @nombre_api = nombre_api,
            @pbi_nuevo  = pbi_nuevo,
            @anio_dato  = anio_dato
        FROM @pbi_parseado
        WHERE orden = @id_actual;

        SET @total_procesados += 1;

        -- Buscar si el código ISO-3 corresponde a un país registrado en administracion.Pais
        SET @pais_id     = NULL;
        SET @pais_nombre = NULL;
        SET @pais_huso   = NULL;

        IF @iso_actual IS NOT NULL AND LEN(@iso_actual) = 3
        BEGIN
            SELECT 
                @pais_id     = ID,
                @pais_nombre = nombre,
                @pais_huso   = huso_horario
            FROM administracion.Pais
            WHERE codigo_iso = @iso_actual;
        END;

        -- Distinguir entre:
        --   A) Entidades agregadas/regionales de la API (ej. WLD - World, EUU - European Union) o países no cargados en la tabla
        --   B) Países reales registrados en administracion.Pais que deben actualizarse
        IF @pais_id IS NULL
        BEGIN
            SET @total_agregados += 1;
            INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, fila_origen, tipo_evento, mensaje)
            VALUES (
                @origen_log,
                @fecha_proceso,
                ISNULL(@iso_actual, 'S/ISO') + ' - ' + ISNULL(@nombre_api, 'Desconocido'),
                'ADVERTENCIA',
                '(50034) Entidad de la API omitida: no corresponde a un país registrado en administracion.Pais (agregado regional o código no cargado).'
            );
        END
        ELSE
        BEGIN
            BEGIN TRY
                -- Validar que el país registrado tenga un valor numérico de PBI no nulo en la API
                IF @pbi_nuevo IS NULL
                BEGIN
                    SET @mensaje_error = '(50036) Dato incompleto en API Banco Mundial: el país ' + @iso_actual + ' (' + @pais_nombre + ') tiene valor de PBI nulo (value = NULL) en el período consultado.';
                    THROW 50036, @mensaje_error, 1;
                END;

                -- Actualizar mediante el Stored Procedure oficial administracion.sp_ModificarPais
                EXEC administracion.sp_ModificarPais
                    @id            = @pais_id,
                    @nombre        = @pais_nombre,
                    @codigo_iso    = @iso_actual,
                    @pbi_percapita = @pbi_nuevo,
                    @huso_horario  = @pais_huso;

                SET @total_actualizados += 1;
            END TRY
            BEGIN CATCH
                SET @total_fallidos += 1;
                INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, fila_origen, tipo_evento, mensaje)
                VALUES (
                    @origen_log,
                    @fecha_proceso,
                    @iso_actual + ' - ' + @pais_nombre,
                    'ERROR',
                    ERROR_MESSAGE()
                );
            END CATCH;
        END;

        SET @id_actual += 1;
    END;

    -- Registrar evento final de cierre en la tabla centralizada de auditoría
    INSERT INTO dbo.LogImportacion (archivo, fecha_proceso, tipo_evento, mensaje)
    VALUES (
        @origen_log,
        @fecha_proceso,
        CASE WHEN @total_fallidos = 0 THEN 'INFO' ELSE 'ADVERTENCIA' END,
        'Importación PBI Banco Mundial finalizada (' + CAST(@total_paginas AS VARCHAR(10)) + ' pág.). ' +
        'Total entidades API: ' + CAST(@total_procesados AS VARCHAR(10)) +
        ' | Países actualizados: ' + CAST(@total_actualizados AS VARCHAR(10)) +
        ' | Agregados/No registrados omitidos: ' + CAST(@total_agregados AS VARCHAR(10)) +
        ' | Países fallidos (sin PBI): ' + CAST(@total_fallidos AS VARCHAR(10))
    );

    -- Resumen final por pantalla
    SELECT 
        @total_paginas      AS paginas_consultadas,
        @total_procesados   AS total_entidades_api,
        @total_actualizados AS paises_actualizados,
        @total_agregados    AS agregados_omitidos,
        @total_fallidos     AS paises_fallidos_sin_pbi,
        CASE 
            WHEN @total_fallidos = 0 THEN 'Actualización de PBI per cápita desde API Banco Mundial finalizada con éxito.'
            ELSE 'Actualización de PBI finalizada con países sin dato en la API. Consulte el detalle en dbo.LogImportacion.'
        END AS resultado;
END;
GO

PRINT 'OK: Stored Procedure [administracion].[sp_ImportarPbiBancoMundial] creado exitosamente.';
GO
