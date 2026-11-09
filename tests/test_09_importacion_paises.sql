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
     
   Script: test_09_importacion_paises.sql
   Descripción: Lote de pruebas unitarias para el Stored Procedure administracion.sp_ImportarPaisesJSON.
                Valida validaciones de entrada, captura de fallas múltiples, importación masiva de 250 países,
                resolución de husos de capitales, almacenamiento de código ISO-3 y lógica Upsert.
*/

USE Mundial2026;
GO

SET NOCOUNT ON;

-- Tabla en memoria para consolidar el reporte visual final
DECLARE @Reporte TABLE (
    ID INT IDENTITY(1,1),
    Procedimiento VARCHAR(50),
    Escenario VARCHAR(65),
    Tipo_Prueba VARCHAR(30),
    Resultado VARCHAR(10),
    Detalle VARCHAR(500)
);

-- Configuración de la ruta absoluta del archivo countries.json (aca tienen que poner la ruta del dataset)
DECLARE @dir_datasets VARCHAR(500) = '..\..\datasets';
IF OBJECT_ID('administracion.fn_RutaDatasets', 'FN') IS NOT NULL
    SET @dir_datasets = administracion.fn_RutaDatasets();
DECLARE @ruta_dataset VARCHAR(500) = @dir_datasets + '\countries.json';

-- =========================================================================================
-- 1. PRUEBAS: administracion.sp_ImportarPaisesJSON
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY

    -- 1.A. Error: Ruta nula o vacía
    BEGIN TRY
        EXEC administracion.sp_ImportarPaisesJSON @ruta_archivo = '';
        INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Ruta de archivo vacía', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50001');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Ruta de archivo vacía', 'Caso de Falla', 'OK', ERROR_MESSAGE());
    END CATCH;

    -- 1.B. Error: Archivo con extensión no .json
    BEGIN TRY
        EXEC administracion.sp_ImportarPaisesJSON @ruta_archivo = 'C:\datos\paises.csv';
        INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Extensión no permitida', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50002');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Extensión no permitida', 'Caso de Falla', 'OK', ERROR_MESSAGE());
    END CATCH;

    -- 1.C. Error: Archivo inexistente físicamente
    BEGIN TRY
        EXEC administracion.sp_ImportarPaisesJSON @ruta_archivo = 'C:\ruta_inexistente\no_existe.json';
        INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Archivo inexistente', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50010');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Archivo inexistente', 'Caso de Falla', 'OK', ERROR_MESSAGE());
    END CATCH;

    -- 1.D. Inserción exitosa masiva (250 países de countries.json)
    BEGIN TRY
        EXEC administracion.sp_ImportarPaisesJSON @ruta_archivo = @ruta_dataset;
        
        DECLARE @cant_paises INT = 0;
        SELECT @cant_paises = COUNT(*) FROM administracion.Pais;

        IF @cant_paises = 250
            INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Importación masiva completa', 'Caso de Éxito', 'OK', 'Se importaron exactamente 250 países');
        ELSE
            INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Importación masiva completa', 'Caso de Éxito', 'FALLÓ', 'Cantidad inesperada: ' + CAST(@cant_paises AS VARCHAR(10)));
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Importación masiva completa', 'Caso de Éxito', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- 1.E. Verificación de resolución de huso horario oficial de capitales
    BEGIN TRY
        DECLARE @huso_us CHAR(6), @huso_ar CHAR(6), @huso_fr CHAR(6), @huso_jp CHAR(6);
        SELECT @huso_us = huso_horario FROM administracion.Pais WHERE nombre = 'United States';
        SELECT @huso_ar = huso_horario FROM administracion.Pais WHERE nombre = 'Argentina';
        SELECT @huso_fr = huso_horario FROM administracion.Pais WHERE nombre = 'France';
        SELECT @huso_jp = huso_horario FROM administracion.Pais WHERE nombre = 'Japan';

        IF @huso_us = '-05:00' AND @huso_ar = '-03:00' AND @huso_fr = '+01:00' AND @huso_jp = '+09:00'
            INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Resolución husos por capital', 'Caso de Éxito', 'OK', 'Husos correctos (US: -05:00, AR: -03:00, FR: +01:00, JP: +09:00)');
        ELSE
            INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Resolución husos por capital', 'Caso de Éxito', 'FALLÓ', 'US=' + ISNULL(@huso_us,'NULL') + ', AR=' + ISNULL(@huso_ar,'NULL'));
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Resolución husos por capital', 'Caso de Éxito', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- 1.E.2. Verificación de almacenamiento del Código ISO-3
    BEGIN TRY
        DECLARE @iso_us CHAR(3), @iso_ar CHAR(3), @iso_fr CHAR(3), @iso_jp CHAR(3);
        SELECT @iso_us = codigo_iso FROM administracion.Pais WHERE nombre = 'United States';
        SELECT @iso_ar = codigo_iso FROM administracion.Pais WHERE nombre = 'Argentina';
        SELECT @iso_fr = codigo_iso FROM administracion.Pais WHERE nombre = 'France';
        SELECT @iso_jp = codigo_iso FROM administracion.Pais WHERE nombre = 'Japan';

        IF @iso_us = 'USA' AND @iso_ar = 'ARG' AND @iso_fr = 'FRA' AND @iso_jp = 'JPN'
            INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Carga de código ISO-3', 'Caso de Éxito', 'OK', 'Códigos correctos (US: USA, AR: ARG, FR: FRA, JP: JPN)');
        ELSE
            INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Carga de código ISO-3', 'Caso de Éxito', 'FALLÓ', 'US=' + ISNULL(@iso_us,'NULL') + ', AR=' + ISNULL(@iso_ar,'NULL'));
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Carga de código ISO-3', 'Caso de Éxito', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- 1.F. Reejecución sin duplicar datos
    BEGIN TRY
        EXEC administracion.sp_ImportarPaisesJSON @ruta_archivo = @ruta_dataset;
        
        DECLARE @cant_reejecucion INT = 0;
        SELECT @cant_reejecucion = COUNT(*) FROM administracion.Pais;

        IF @cant_reejecucion = 250
            INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Idempotencia (Upsert sin duplicar)', 'Caso de Éxito', 'OK', 'La tabla conservó 250 países únicos');
        ELSE
            INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Idempotencia (Upsert sin duplicar)', 'Caso de Éxito', 'FALLÓ', 'Se generaron duplicados: ' + CAST(@cant_reejecucion AS VARCHAR(10)));
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Idempotencia (Upsert sin duplicar)', 'Caso de Éxito', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- 1.G. Auditoría en dbo.LogImportacion (Verificar registro de auditoría)
    BEGIN TRY
        DECLARE @cant_logs INT = 0;
        SELECT @cant_logs = COUNT(*) 
        FROM dbo.LogImportacion 
        WHERE archivo = @ruta_dataset;

        IF @cant_logs >= 2
            INSERT INTO @Reporte VALUES ('dbo.LogImportacion', 'Registro histórico de auditoría', 'Caso de Éxito', 'OK', 'Se registraron los eventos INFO de finalización en el log');
        ELSE
            INSERT INTO @Reporte VALUES ('dbo.LogImportacion', 'Registro histórico de auditoría', 'Caso de Éxito', 'FALLÓ', 'No se registraron las ejecuciones en el log');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('dbo.LogImportacion', 'Registro histórico de auditoría', 'Caso de Éxito', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('sp_ImportarPaisesJSON', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;

PRINT '======================================================================';
PRINT 'LOTE DE PRUEBAS FINALIZADO. REVISAR PESTAÑA "RESULTADOS"';
PRINT '======================================================================';

SELECT 
    ID AS [#],
    Procedimiento AS [SP Evaluado],
    Escenario AS [Escenario de Prueba],
    Tipo_Prueba AS [Tipo],
    Resultado AS [Estado],
    Detalle AS [Detalle / Mensaje]
FROM @Reporte
ORDER BY ID;
GO
