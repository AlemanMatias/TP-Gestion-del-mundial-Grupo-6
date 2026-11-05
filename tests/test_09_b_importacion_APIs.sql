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
     
   Script: test_09_b_importacion_APIs.sql
   Descripción: TESTS
                1. administracion.sp_InvocarApi
                2. administracion.sp_ImportarPbiBancoMundial (Consumo de API Banco Mundial)
*/

USE Mundial2026;
GO

SET NOCOUNT ON;

-- Tabla en memoria para consolidar el reporte visual final
DECLARE @Reporte TABLE (
    ID INT IDENTITY(1,1),
    Procedimiento VARCHAR(50),
    Escenario VARCHAR(70),
    Tipo_Prueba VARCHAR(30),
    Resultado VARCHAR(10),
    Detalle VARCHAR(500)
);

BEGIN TRANSACTION;
BEGIN TRY

    -- =========================================================================================
    -- 1. PRUEBAS: administracion.sp_InvocarApi
    -- =========================================================================================

    -- 1.A. Error: URL nula o vacía
    BEGIN TRY
        DECLARE @resp1 NVARCHAR(MAX), @status1 INT;
        EXEC administracion.sp_InvocarApi @url = '', @respuesta = @resp1 OUTPUT, @codigo_estado = @status1 OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', 'URL nula o vacía', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50020');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', 'URL nula o vacía', 'Caso de Falla', 'OK', ERROR_MESSAGE());
    END CATCH;

    -- 1.B. Error: URL sin protocolo HTTP/HTTPS válido
    BEGIN TRY
        DECLARE @resp_proto NVARCHAR(MAX), @status_proto INT;
        EXEC administracion.sp_InvocarApi @url = 'ftp://api.worldbank.org', @respuesta = @resp_proto OUTPUT, @codigo_estado = @status_proto OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', 'Protocolo de URL inválido', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50020');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', 'Protocolo de URL inválido', 'Caso de Falla', 'OK', ERROR_MESSAGE());
    END CATCH;

    -- 1.C. Error: Método HTTP inválido
    BEGIN TRY
        DECLARE @resp2 NVARCHAR(MAX), @status2 INT;
        EXEC administracion.sp_InvocarApi @url = 'https://api.worldbank.org', @metodo = 'METODO_FALSO', @respuesta = @resp2 OUTPUT, @codigo_estado = @status2 OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', 'Método HTTP inválido', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50021');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', 'Método HTTP inválido', 'Caso de Falla', 'OK', ERROR_MESSAGE());
    END CATCH;

    -- 1.D. Error: Timeout fuera de rango (<= 0 o > 120s)
    BEGIN TRY
        DECLARE @resp3 NVARCHAR(MAX), @status3 INT;
        EXEC administracion.sp_InvocarApi @url = 'https://api.worldbank.org', @timeout_segundos = 300, @respuesta = @resp3 OUTPUT, @codigo_estado = @status3 OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', 'Timeout fuera de rango permitido', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50022');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', 'Timeout fuera de rango permitido', 'Caso de Falla', 'OK', ERROR_MESSAGE());
    END CATCH;

    -- 1.E. Error: Fallas múltiples acumuladas en una sola invocación (50020 + 50021 + 50022 + 50024)
    BEGIN TRY
        DECLARE @resp_mult NVARCHAR(MAX), @status_mult INT;
        EXEC administracion.sp_InvocarApi 
            @url = 'ftp://url_sin_https',
            @metodo = 'METODO_INEXISTENTE',
            @cabeceras = 'json_invalido',
            @timeout_segundos = -5,
            @respuesta = @resp_mult OUTPUT,
            @codigo_estado = @status_mult OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', 'Fallas múltiples acumuladas (50020+50021+50022+50024)', 'Fallas Múltiples', 'FALLÓ', 'Debió arrojar errores concatenados');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', 'Fallas múltiples acumuladas (50020+50021+50022+50024)', 'Fallas Múltiples', 'OK', ERROR_MESSAGE());
    END CATCH;

    -- 1.F. Éxito: Invocación HTTP real a endpoint público del Banco Mundial
    BEGIN TRY
        DECLARE @resp_real NVARCHAR(MAX), @status_real INT;
        EXEC administracion.sp_InvocarApi 
            @url = 'https://api.worldbank.org/v2/country/ARG/indicator/NY.GDP.PCAP.CD?format=json&date=2020:2024',
            @metodo = 'GET',
            @respuesta = @resp_real OUTPUT,
            @codigo_estado = @status_real OUTPUT;

        IF @status_real = 200 AND ISJSON(@resp_real) = 1
            INSERT INTO @Reporte VALUES ('sp_InvocarApi', 'Petición GET real a API Banco Mundial', 'Caso de Éxito', 'OK', 'HTTP 200 OK - Payload JSON válido recibido (' + CAST(LEN(@resp_real) AS VARCHAR(20)) + ' caracteres).');
        ELSE
            INSERT INTO @Reporte VALUES ('sp_InvocarApi', 'Petición GET real a API Banco Mundial', 'Caso de Éxito', 'FALLÓ', 'Estado HTTP: ' + ISNULL(CAST(@status_real AS VARCHAR(10)), 'NULL'));
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', 'Petición GET real a API Banco Mundial', 'Caso de Éxito', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================================
    -- 2. PRUEBAS: administracion.sp_ImportarPbiBancoMundial (API Real en Vivo + Paginación)
    -- =========================================================================================

    -- 2.A. Error: URL de API vacía
    BEGIN TRY
        EXEC administracion.sp_ImportarPbiBancoMundial @url_api = '';
        INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', 'URL API nula o vacía', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50030');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', 'URL API nula o vacía', 'Caso de Falla', 'OK', ERROR_MESSAGE());
    END CATCH;

    -- Insertar países testigo con administracion.sp_InsertarPais
    DECLARE @id_pais_test INT;
    EXEC administracion.sp_InsertarPais @nombre = 'Argentina',     @codigo_iso = 'ARG', @huso_horario = '-03:00', @id_generado = @id_pais_test OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'United States', @codigo_iso = 'USA', @huso_horario = '-05:00', @id_generado = @id_pais_test OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'France',        @codigo_iso = 'FRA', @huso_horario = '+01:00', @id_generado = @id_pais_test OUTPUT;

    -- 2.B. Ejecutar importación masiva paginada consumiendo la API real del Banco Mundial
    EXEC administracion.sp_ImportarPbiBancoMundial;

    -- 2.C. Verificar PBI real cargado para Argentina (ARG)
    DECLARE @pbi_arg DECIMAL(12,2);
    SELECT @pbi_arg = pbi_percapita FROM administracion.Pais WHERE codigo_iso = 'ARG';

    IF @pbi_arg IS NOT NULL AND @pbi_arg > 0
        INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', 'PBI real actualizado: Argentina (ARG)', 'Integración API Real', 'OK', 'PBI obtenido de API: ' + CAST(@pbi_arg AS VARCHAR(30)) + ' USD');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', 'PBI real actualizado: Argentina (ARG)', 'Integración API Real', 'FALLÓ', 'El PBI quedó en NULL o 0');

    -- 2.D. Verificar PBI real cargado para Estados Unidos (USA)
    DECLARE @pbi_usa DECIMAL(12,2);
    SELECT @pbi_usa = pbi_percapita FROM administracion.Pais WHERE codigo_iso = 'USA';

    IF @pbi_usa IS NOT NULL AND @pbi_usa > 0
        INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', 'PBI real actualizado: Estados Unidos (USA)', 'Integración API Real', 'OK', 'PBI obtenido de API: ' + CAST(@pbi_usa AS VARCHAR(30)) + ' USD');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', 'PBI real actualizado: Estados Unidos (USA)', 'Integración API Real', 'FALLÓ', 'El PBI quedó en NULL o 0');

    -- 2.E. Verificar PBI real cargado para Francia (FRA)
    DECLARE @pbi_fra DECIMAL(12,2);
    SELECT @pbi_fra = pbi_percapita FROM administracion.Pais WHERE codigo_iso = 'FRA';

    IF @pbi_fra IS NOT NULL AND @pbi_fra > 0
        INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', 'PBI real actualizado: Francia (FRA)', 'Integración API Real', 'OK', 'PBI obtenido de API: ' + CAST(@pbi_fra AS VARCHAR(30)) + ' USD');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', 'PBI real actualizado: Francia (FRA)', 'Integración API Real', 'FALLÓ', 'El PBI quedó en NULL o 0');

    -- 2.F. Verificar registro de auditoría, agregados omitidos y resumen en dbo.LogImportacion
    IF EXISTS (
        SELECT 1 FROM dbo.LogImportacion 
        WHERE archivo LIKE 'https://api.worldbank.org%' 
          AND tipo_evento IN ('INFO', 'ADVERTENCIA')
          AND mensaje LIKE '%Importación PBI Banco Mundial finalizada%'
    ) AND EXISTS (
        SELECT 1 FROM dbo.LogImportacion
        WHERE archivo LIKE 'https://api.worldbank.org%'
          AND fila_origen IS NOT NULL
    )
        INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', 'Auditoría detallada y resumen en LogImportacion', 'Auditoría', 'OK', 'Se registraron las filas con su fila_origen y el resumen final.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', 'Auditoría detallada y resumen en LogImportacion', 'Auditoría', 'FALLÓ', 'No se encontraron los registros esperados en dbo.LogImportacion.');

    -- Muestra de países actualizados desde la API antes del Rollback
    SELECT TOP 15
        ID,
        nombre,
        codigo_iso,
        pbi_percapita AS pbi_percapita_usd,
        huso_horario
    FROM administracion.Pais
    WHERE pbi_percapita IS NOT NULL
    ORDER BY pbi_percapita DESC;

    -- Mostrar los registros generados en dbo.LogImportacion antes del Rollback
    SELECT 
        id_log,
        archivo,
        fecha_proceso,
        fila_origen,
        tipo_evento,
        mensaje
    FROM dbo.LogImportacion
    ORDER BY id_log DESC;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('GENERAL', 'Excepción global no capturada', 'Crítico', 'FALLÓ', ERROR_MESSAGE());
END CATCH;

-- Revertir todos los cambios realizados durante el test para mantener la base limpia
ROLLBACK TRANSACTION;

-- Mostrar reporte consolidado de pruebas
SELECT 
    ID,
    Procedimiento,
    Escenario,
    Tipo_Prueba,
    Resultado,
    Detalle
FROM @Reporte
ORDER BY ID;
GO
