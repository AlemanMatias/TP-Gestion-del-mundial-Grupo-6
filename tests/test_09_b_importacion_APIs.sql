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
   Descripción: Suite de pruebas para el conector HTTP genérico (administracion.sp_InvocarApi),
                la importación de PBI per cápita desde la API del Banco Mundial
                (administracion.sp_ImportarPbiBancoMundial) y la geolocalización de sedes
                desde la API de Open-Meteo (administracion.sp_ImportarGeolocalizacionSedes).
*/

USE Mundial2026;
GO

SET NOCOUNT ON;

DECLARE @Reporte TABLE (
    Nro     INT IDENTITY(1,1),
    Seccion VARCHAR(50),
    Prueba  VARCHAR(110),
    Estado  VARCHAR(15),
    Detalle VARCHAR(500)
);

BEGIN TRANSACTION;

-- ============================================================================
-- 1. PRUEBAS DE administracion.sp_InvocarApi (CONECTOR HTTP GENÉRICO)
-- ============================================================================
DECLARE @resp   NVARCHAR(MAX);
DECLARE @status INT;
DECLARE @id_gen INT;

-- 1.1 Rechazar URL vacía / nula (Error 50020)
BEGIN TRY
    EXEC administracion.sp_InvocarApi @url = '   ', @metodo = 'GET', @respuesta = @resp OUTPUT, @codigo_estado = @status OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.1 Rechazar URL vacía', 'FALLO', 'No lanzó excepción');
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 50020
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.1 Rechazar URL vacía', 'OK', ERROR_MESSAGE());
    ELSE
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.1 Rechazar URL vacía', 'FALLO', ERROR_MESSAGE());
END CATCH;

-- 1.2 Rechazar URL con protocolo inválido (Error 50020)
BEGIN TRY
    EXEC administracion.sp_InvocarApi @url = 'ftp://api.worldbank.org/v2/country/ARG', @metodo = 'GET', @respuesta = @resp OUTPUT, @codigo_estado = @status OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.2 Rechazar protocolo no HTTP/HTTPS', 'FALLO', 'No lanzó excepción');
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 50020
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.2 Rechazar protocolo no HTTP/HTTPS', 'OK', ERROR_MESSAGE());
    ELSE
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.2 Rechazar protocolo no HTTP/HTTPS', 'FALLO', ERROR_MESSAGE());
END CATCH;

-- 1.3 Rechazar método HTTP no permitido (Error 50021)
BEGIN TRY
    EXEC administracion.sp_InvocarApi @url = 'https://api.worldbank.org/v2/country/ARG?format=json', @metodo = 'OPTIONS', @respuesta = @resp OUTPUT, @codigo_estado = @status OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.3 Rechazar método HTTP no permitido', 'FALLO', 'No lanzó excepción');
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 50021
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.3 Rechazar método HTTP no permitido', 'OK', ERROR_MESSAGE());
    ELSE
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.3 Rechazar método HTTP no permitido', 'FALLO', ERROR_MESSAGE());
END CATCH;

-- 1.4 Rechazar timeout fuera de rango (> 120s o <= 0) (Error 50022)
BEGIN TRY
    EXEC administracion.sp_InvocarApi @url = 'https://api.worldbank.org/v2/country/ARG?format=json', @metodo = 'GET', @timeout_segundos = 999, @respuesta = @resp OUTPUT, @codigo_estado = @status OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.4 Rechazar timeout fuera de rango (> 120s)', 'FALLO', 'No lanzó excepción');
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 50022
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.4 Rechazar timeout fuera de rango (> 120s)', 'OK', ERROR_MESSAGE());
    ELSE
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.4 Rechazar timeout fuera de rango (> 120s)', 'FALLO', ERROR_MESSAGE());
END CATCH;

-- 1.5 Rechazar cabeceras con JSON malformado (Error 50024)
BEGIN TRY
    EXEC administracion.sp_InvocarApi @url = 'https://api.worldbank.org/v2/country/ARG?format=json', @metodo = 'GET', @cabeceras = '{malformado', @respuesta = @resp OUTPUT, @codigo_estado = @status OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.5 Rechazar @cabeceras JSON inválido', 'FALLO', 'No lanzó excepción');
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 50024
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.5 Rechazar @cabeceras JSON inválido', 'OK', ERROR_MESSAGE());
    ELSE
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.5 Rechazar @cabeceras JSON inválido', 'FALLO', ERROR_MESSAGE());
END CATCH;

-- 1.6 Rechazar múltiples errores simultáneos (URL vacía + método inválido + timeout inválido + cabeceras malformadas)
BEGIN TRY
    EXEC administracion.sp_InvocarApi 
        @url              = '', 
        @metodo           = 'OPTIONS', 
        @timeout_segundos = -5, 
        @cabeceras        = 'no_es_json', 
        @respuesta        = @resp OUTPUT, 
        @codigo_estado    = @status OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.6 Fallas múltiples simultáneas (50020+50021+50022+50024)', 'FALLO', 'No lanzó excepción');
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() LIKE '%(50020)%' 
       AND ERROR_MESSAGE() LIKE '%(50021)%' 
       AND ERROR_MESSAGE() LIKE '%(50022)%' 
       AND ERROR_MESSAGE() LIKE '%(50024)%'
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.6 Fallas múltiples simultáneas (50020+50021+50022+50024)', 'OK', ERROR_MESSAGE());
    ELSE
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.6 Fallas múltiples simultáneas (50020+50021+50022+50024)', 'FALLO', ERROR_MESSAGE());
END CATCH;

-- 1.7 Petición GET a la API del Banco Mundial (Argentina)
BEGIN TRY
    SET @resp = NULL;
    SET @status = NULL;
    EXEC administracion.sp_InvocarApi
        @url              = 'https://api.worldbank.org/v2/country/ARG?format=json',
        @metodo           = 'GET',
        @timeout_segundos = 30,
        @respuesta        = @resp OUTPUT,
        @codigo_estado    = @status OUTPUT;

    IF @status = 200 AND ISJSON(@resp) = 1 AND @resp LIKE '%Argentina%'
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.7 Petición GET en vivo (HTTP 200 y JSON válido)', 'OK', 'Status HTTP: ' + CAST(@status AS VARCHAR(10)) + ' | Bytes recibidos: ' + CAST(LEN(@resp) AS VARCHAR(20)));
    ELSE
        INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.7 Petición GET en vivo (HTTP 200 y JSON válido)', 'FALLO', 'Status HTTP: ' + ISNULL(CAST(@status AS VARCHAR(10)), 'NULL'));
END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('sp_InvocarApi', '1.7 Petición GET en vivo (HTTP 200 y JSON válido)', 'FALLO', ERROR_MESSAGE());
END CATCH;


-- ============================================================================
-- 2. PRUEBAS DE administracion.sp_ImportarPbiBancoMundial (API 1: BANCO MUNDIAL)
-- ============================================================================

-- 2.1 Rechazar URL de API vacía (Error 50030)
BEGIN TRY
    EXEC administracion.sp_ImportarPbiBancoMundial @url_api = '';
    INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', '2.1 Rechazar URL vacía', 'FALLO', 'No lanzó excepción');
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 50030
        INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', '2.1 Rechazar URL vacía', 'OK', ERROR_MESSAGE());
    ELSE
        INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', '2.1 Rechazar URL vacía', 'FALLO', ERROR_MESSAGE());
END CATCH;

-- 2.2 Preparar países de prueba en administracion.Pais con @pbi_percapita = NULL (tal como los deja sp_ImportarPaisesJSON)
IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE codigo_iso = 'ARG')
    EXEC administracion.sp_InsertarPais @nombre = 'Argentina', @codigo_iso = 'ARG', @pbi_percapita = NULL, @huso_horario = '-03:00', @id_generado = @id_gen OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE codigo_iso = 'USA')
    EXEC administracion.sp_InsertarPais @nombre = 'United States', @codigo_iso = 'USA', @pbi_percapita = NULL, @huso_horario = '-05:00', @id_generado = @id_gen OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE codigo_iso = 'FRA')
    EXEC administracion.sp_InsertarPais @nombre = 'France', @codigo_iso = 'FRA', @pbi_percapita = NULL, @huso_horario = '+01:00', @id_generado = @id_gen OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE codigo_iso = 'MEX')
    EXEC administracion.sp_InsertarPais @nombre = 'Mexico', @codigo_iso = 'MEX', @pbi_percapita = NULL, @huso_horario = '-06:00', @id_generado = @id_gen OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE codigo_iso = 'CAN')
    EXEC administracion.sp_InsertarPais @nombre = 'Canada', @codigo_iso = 'CAN', @pbi_percapita = NULL, @huso_horario = '-05:00', @id_generado = @id_gen OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE codigo_iso = 'YEM')
    EXEC administracion.sp_InsertarPais @nombre = 'Yemen', @codigo_iso = 'YEM', @pbi_percapita = NULL, @huso_horario = '+03:00', @id_generado = @id_gen OUTPUT;

-- Asegurar que todos inicien con pbi_percapita = NULL antes de llamar a la API del Banco Mundial
DECLARE @id_arg INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'ARG');
DECLARE @nom_arg VARCHAR(100) = (SELECT nombre FROM administracion.Pais WHERE codigo_iso = 'ARG');
DECLARE @huso_arg CHAR(6) = (SELECT huso_horario FROM administracion.Pais WHERE codigo_iso = 'ARG');
EXEC administracion.sp_ModificarPais @id = @id_arg, @nombre = @nom_arg, @codigo_iso = 'ARG', @pbi_percapita = NULL, @huso_horario = @huso_arg;

DECLARE @id_usa INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'USA');
DECLARE @nom_usa VARCHAR(100) = (SELECT nombre FROM administracion.Pais WHERE codigo_iso = 'USA');
DECLARE @huso_usa CHAR(6) = (SELECT huso_horario FROM administracion.Pais WHERE codigo_iso = 'USA');
EXEC administracion.sp_ModificarPais @id = @id_usa, @nombre = @nom_usa, @codigo_iso = 'USA', @pbi_percapita = NULL, @huso_horario = @huso_usa;

DECLARE @id_fra INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'FRA');
DECLARE @nom_fra VARCHAR(100) = (SELECT nombre FROM administracion.Pais WHERE codigo_iso = 'FRA');
DECLARE @huso_fra CHAR(6) = (SELECT huso_horario FROM administracion.Pais WHERE codigo_iso = 'FRA');
EXEC administracion.sp_ModificarPais @id = @id_fra, @nombre = @nom_fra, @codigo_iso = 'FRA', @pbi_percapita = NULL, @huso_horario = @huso_fra;

DECLARE @id_mex INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'MEX');
DECLARE @nom_mex VARCHAR(100) = (SELECT nombre FROM administracion.Pais WHERE codigo_iso = 'MEX');
DECLARE @huso_mex CHAR(6) = (SELECT huso_horario FROM administracion.Pais WHERE codigo_iso = 'MEX');
EXEC administracion.sp_ModificarPais @id = @id_mex, @nombre = @nom_mex, @codigo_iso = 'MEX', @pbi_percapita = NULL, @huso_horario = @huso_mex;

DECLARE @id_can INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'CAN');
DECLARE @nom_can VARCHAR(100) = (SELECT nombre FROM administracion.Pais WHERE codigo_iso = 'CAN');
DECLARE @huso_can CHAR(6) = (SELECT huso_horario FROM administracion.Pais WHERE codigo_iso = 'CAN');
EXEC administracion.sp_ModificarPais @id = @id_can, @nombre = @nom_can, @codigo_iso = 'CAN', @pbi_percapita = NULL, @huso_horario = @huso_can;

DECLARE @id_yem INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'YEM');
DECLARE @nom_yem VARCHAR(100) = (SELECT nombre FROM administracion.Pais WHERE codigo_iso = 'YEM');
DECLARE @huso_yem CHAR(6) = (SELECT huso_horario FROM administracion.Pais WHERE codigo_iso = 'YEM');
EXEC administracion.sp_ModificarPais @id = @id_yem, @nombre = @nom_yem, @codigo_iso = 'YEM', @pbi_percapita = NULL, @huso_horario = @huso_yem;

-- 2.3 Ejecutar importación en vivo desde la API oficial del Banco Mundial
BEGIN TRY
    EXEC administracion.sp_ImportarPbiBancoMundial;

    DECLARE @pbi_arg DECIMAL(12,2) = (SELECT pbi_percapita FROM administracion.Pais WHERE codigo_iso = 'ARG');
    DECLARE @pbi_usa DECIMAL(12,2) = (SELECT pbi_percapita FROM administracion.Pais WHERE codigo_iso = 'USA');
    DECLARE @pbi_fra DECIMAL(12,2) = (SELECT pbi_percapita FROM administracion.Pais WHERE codigo_iso = 'FRA');

    IF @pbi_arg > 0 AND @pbi_usa > 0 AND @pbi_fra > 0
        INSERT INTO @Reporte VALUES (
            'sp_ImportarPbiBancoMundial',
            '2.2 Importación en vivo PBI (ARG, USA, FRA actualizados)',
            'OK',
            'ARG: USD ' + CAST(@pbi_arg AS VARCHAR(20)) + ' | USA: USD ' + CAST(@pbi_usa AS VARCHAR(20)) + ' | FRA: USD ' + CAST(@pbi_fra AS VARCHAR(20))
        );
    ELSE
        INSERT INTO @Reporte VALUES (
            'sp_ImportarPbiBancoMundial',
            '2.2 Importación en vivo PBI (ARG, USA, FRA actualizados)',
            'FALLO',
            'Alguno de los países quedó sin PBI actualizado'
        );
END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', '2.2 Importación en vivo PBI (ARG, USA, FRA actualizados)', 'FALLO', ERROR_MESSAGE());
END CATCH;

-- 2.4 Verificar auditoría de errores parciales y agregados en dbo.LogImportacion
IF EXISTS (
    SELECT 1 
    FROM dbo.LogImportacion 
    WHERE archivo LIKE 'https://api.worldbank.org%'
      AND (mensaje LIKE '%(50034)%' OR mensaje LIKE '%(50036)%')
)
    INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', '2.3 Registro en LogImportacion (50034/50036)', 'OK', 'Se auditaron agregados regionales (50034) y países sin PBI en el Banco Mundial (50036).');
ELSE
    INSERT INTO @Reporte VALUES ('sp_ImportarPbiBancoMundial', '2.3 Registro en LogImportacion (50034/50036)', 'FALLO', 'No se encontraron registros en dbo.LogImportacion.');


-- ============================================================================
-- 3. PRUEBAS DE administracion.sp_ImportarGeolocalizacionSedes (API 2: OPEN-METEO)
-- ============================================================================

-- 3.1 Rechazar URL inválida (Error 50040)
BEGIN TRY
    EXEC administracion.sp_ImportarGeolocalizacionSedes @url_api = 'ftp://url_invalida';
    INSERT INTO @Reporte VALUES ('sp_ImportarGeolocalizacionSedes', '3.1 Rechazar URL con protocolo inválido (50040)', 'FALLO', 'No lanzó excepción');
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 50040
        INSERT INTO @Reporte VALUES ('sp_ImportarGeolocalizacionSedes', '3.1 Rechazar URL con protocolo inválido (50040)', 'OK', ERROR_MESSAGE());
    ELSE
        INSERT INTO @Reporte VALUES ('sp_ImportarGeolocalizacionSedes', '3.1 Rechazar URL con protocolo inválido (50040)', 'FALLO', ERROR_MESSAGE());
END CATCH;

-- 3.2 Insertar 4 sedes reales del Mundial 2026 con su huso horario correspondiente (+/-HH:MM) y coordenadas en NULL:
-- 1) Miami (-05:00), 2) Dallas (-06:00), 3) Mexico City (-06:00), 4) Vancouver (-08:00)
-- Y 1 sede con ciudad inexistente para probar importación con errores parciales (50042)
IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE nombre = 'Hard Rock Stadium Test')
    EXEC administracion.sp_InsertarSede
        @nombre       = 'Hard Rock Stadium Test',
        @ciudad       = 'Miami',
        @capacidad    = 64767,
        @huso_horario = '-05:00',
        @id_pais      = @id_usa,
        @latitud      = NULL,
        @longitud     = NULL,
        @id_generado  = @id_gen OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE nombre = 'AT&T Stadium Test')
    EXEC administracion.sp_InsertarSede
        @nombre       = 'AT&T Stadium Test',
        @ciudad       = 'Dallas',
        @capacidad    = 80000,
        @huso_horario = '-06:00',
        @id_pais      = @id_usa,
        @latitud      = NULL,
        @longitud     = NULL,
        @id_generado  = @id_gen OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE nombre = 'Estadio Azteca Test')
    EXEC administracion.sp_InsertarSede
        @nombre       = 'Estadio Azteca Test',
        @ciudad       = 'Mexico City',
        @capacidad    = 87523,
        @huso_horario = '-06:00',
        @id_pais      = @id_mex,
        @latitud      = NULL,
        @longitud     = NULL,
        @id_generado  = @id_gen OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE nombre = 'BC Place Test')
    EXEC administracion.sp_InsertarSede
        @nombre       = 'BC Place Test',
        @ciudad       = 'Vancouver',
        @capacidad    = 54500,
        @huso_horario = '-08:00',
        @id_pais      = @id_can,
        @latitud      = NULL,
        @longitud     = NULL,
        @id_generado  = @id_gen OUTPUT;

IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE nombre = 'Estadio Fantasma Test')
    EXEC administracion.sp_InsertarSede
        @nombre       = 'Estadio Fantasma Test',
        @ciudad       = 'CiudadInexistenteXYZ999',
        @capacidad    = 45000,
        @huso_horario = '+00:00',
        @id_pais      = @id_usa,
        @latitud      = NULL,
        @longitud     = NULL,
        @id_generado  = @id_gen OUTPUT;

-- 3.3 Ejecutar sp_ImportarGeolocalizacionSedes en vivo (1 sola petición HTTP por sede)
BEGIN TRY
    EXEC administracion.sp_ImportarGeolocalizacionSedes;

    DECLARE @lat_mia  DECIMAL(9,6), @lon_mia  DECIMAL(9,6), @huso_mia  CHAR(6);
    DECLARE @lat_dal  DECIMAL(9,6), @lon_dal  DECIMAL(9,6), @huso_dal  CHAR(6);
    DECLARE @lat_cdmx DECIMAL(9,6), @lon_cdmx DECIMAL(9,6), @huso_cdmx CHAR(6);
    DECLARE @lat_van  DECIMAL(9,6), @lon_van  DECIMAL(9,6), @huso_van  CHAR(6);

    SELECT @lat_mia  = latitud, @lon_mia  = longitud, @huso_mia  = huso_horario FROM administracion.Sede WHERE nombre = 'Hard Rock Stadium Test';
    SELECT @lat_dal  = latitud, @lon_dal  = longitud, @huso_dal  = huso_horario FROM administracion.Sede WHERE nombre = 'AT&T Stadium Test';
    SELECT @lat_cdmx = latitud, @lon_cdmx = longitud, @huso_cdmx = huso_horario FROM administracion.Sede WHERE nombre = 'Estadio Azteca Test';
    SELECT @lat_van  = latitud, @lon_van  = longitud, @huso_van  = huso_horario FROM administracion.Sede WHERE nombre = 'BC Place Test';

    IF @lat_mia IS NOT NULL AND @lon_mia IS NOT NULL AND @huso_mia = '-05:00'
       AND @lat_dal IS NOT NULL AND @lon_dal IS NOT NULL AND @huso_dal = '-06:00'
       AND @lat_cdmx IS NOT NULL AND @lon_cdmx IS NOT NULL AND @huso_cdmx = '-06:00'
       AND @lat_van IS NOT NULL AND @lon_van IS NOT NULL AND @huso_van = '-08:00'
        INSERT INTO @Reporte VALUES (
            'sp_ImportarGeolocalizacionSedes',
            '3.2 Geolocalización en vivo (Miami, Dallas, CDMX, Vancouver)',
            'OK',
            'Miami: (' + CAST(@lat_mia AS VARCHAR(15)) + ', ' + CAST(@lon_mia AS VARCHAR(15)) + ')' +
            ' | Dallas: (' + CAST(@lat_dal AS VARCHAR(15)) + ', ' + CAST(@lon_dal AS VARCHAR(15)) + ')' +
            ' | CDMX: (' + CAST(@lat_cdmx AS VARCHAR(15)) + ', ' + CAST(@lon_cdmx AS VARCHAR(15)) + ')' +
            ' | Vancouver: (' + CAST(@lat_van AS VARCHAR(15)) + ', ' + CAST(@lon_van AS VARCHAR(15)) + ')'
        );
    ELSE
        INSERT INTO @Reporte VALUES (
            'sp_ImportarGeolocalizacionSedes',
            '3.2 Geolocalización en vivo (Miami, Dallas, CDMX, Vancouver)',
            'FALLO',
            'Coordenadas nulas o huso horario alterado inesperadamente.'
        );
END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('sp_ImportarGeolocalizacionSedes', '3.2 Geolocalización en vivo (Miami, Dallas, CDMX, Vancouver)', 'FALLO', ERROR_MESSAGE());
END CATCH;

-- 3.4 Verificar manejo de errores parciales (ciudad inexistente registrada con 50042 en LogImportacion sin abortar las demás)
IF EXISTS (
    SELECT 1
    FROM dbo.LogImportacion
    WHERE archivo LIKE 'https://geocoding-api.open-meteo.com%'
      AND mensaje LIKE '%(50042)%'
)
    INSERT INTO @Reporte VALUES ('sp_ImportarGeolocalizacionSedes', '3.3 Error parcial auditado (50042 ciudad inexistente)', 'OK', 'La sede inválida se registró en dbo.LogImportacion y las 4 sedes válidas se actualizaron.');
ELSE
    INSERT INTO @Reporte VALUES ('sp_ImportarGeolocalizacionSedes', '3.3 Error parcial auditado (50042 ciudad inexistente)', 'FALLO', 'No se encontró el error 50042 en dbo.LogImportacion.');


-- Mostrar vista previa de Países, Sedes geolocalizadas y LogImportacion antes del ROLLBACK
SELECT ID, nombre, codigo_iso, pbi_percapita, huso_horario
FROM administracion.Pais
WHERE codigo_iso IN ('ARG', 'USA', 'FRA', 'MEX', 'CAN', 'YEM');

SELECT ID, nombre, ciudad, capacidad, huso_horario, latitud, longitud, ID_Pais
FROM administracion.Sede;

SELECT TOP 15 id_log, archivo, fecha_proceso, fila_origen, tipo_evento, mensaje
FROM dbo.LogImportacion
ORDER BY id_log DESC;

ROLLBACK TRANSACTION;

-- ============================================================================
-- 4. REPORTE FINAL DE LA SUITE DE PRUEBAS
-- ============================================================================
SELECT * FROM @Reporte ORDER BY Nro;
GO
