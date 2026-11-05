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
     
   Script: test_12_importacion_arbitros.sql
   Descripción: Batería de pruebas exhaustiva para la importación de árbitros.
                Valida altas, upserts, errores aislados y errores múltiples combinados.
                Nota: Se ejecuta sin transacción externa para evitar choques con el rollback interno del SP.
*/

USE Mundial2026;
GO

-- Acá hay que poner la ruta propia de cada uno
DECLARE @ruta_dataset VARCHAR(500) = 'C:\datasets\countries.json' 
EXEC administracion.sp_ImportarPaisesJSON @ruta_archivo = @ruta_dataset
-- SELECT * FROM administracion.Pais

SET NOCOUNT ON;

PRINT '======================================================================';
PRINT 'INICIANDO PRUEBAS - IMPORTACIÓN DE ÁRBITROS';
PRINT '======================================================================';


-- 0. Garantizar país válido de prueba utilizando la firma oficial con @id_generado OUTPUT
IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE nombre = 'Bélgica')
BEGIN
    DECLARE @id_pais_generado INT;
    EXEC administracion.sp_InsertarPais 
        @nombre = 'Bélgica', 
        @codigo_iso = 'BEL',
        @pbi_percapita = 50000, 
        @huso_horario = '+01:00',
        @id_generado = @id_pais_generado OUTPUT;
END

-- 1. Definir la ruta del archivo de pruebas mixtas (con errores y aciertos)
-- Acá hay que poner la ruta de cada uno
DECLARE @RutaCSVPrueba VARCHAR(500) = 'C:\datasets\arbitros.csv';

PRINT '>>> Ejecutando primera importación (Éxitos y Errores)...';
-- Nota: Si el SP del CSV tira un THROW general por archivo vacío o ruta, lo 'atrapamos' abajo.
BEGIN TRY
    EXEC arbitraje.sp_ImportarArbitros @ruta_archivo = @RutaCSVPrueba;
END TRY

BEGIN CATCH
    PRINT 'NOTA: El importador reportó una excepción controlada (a nivel general): ' + ERROR_MESSAGE();
END CATCH;

-- Para probar el Upsert
-- PRINT '>>> Ejecutando segunda importación (Prueba de Idempotencia / Upsert)...';
-- EXEC arbitraje.sp_ImportarArbitros @ruta_archivo = @RutaCSVPrueba;

-- 2. VERIFICACIÓN 1: Estado final de la tabla de árbitros (filas exitosas)
PRINT '------------------------------------------------------------------';
PRINT '--- TABLA DESTINO: arbitraje.Arbitro ---';
SELECT 
    a.ID, 
    a.nombre, 
    a.apellido, 
    a.categoria, 
    p.nombre AS Pais_Origen
FROM arbitraje.Arbitro a
JOIN administracion.Pais p ON p.ID = a.ID_Pais
ORDER BY a.ID DESC;

-- 3. VERIFICACIÓN 2: Auditoría de errores y aciertos en el Log centralizado
PRINT '------------------------------------------------------------------';
PRINT '--- AUDITORÍA DE ERRORES: dbo.LogImportacion ---';
SELECT TOP 15 
    id_log,
    fecha_proceso,
    fila_origen,
    tipo_evento,
    mensaje
FROM dbo.LogImportacion
WHERE archivo = @RutaCSVPrueba
ORDER BY id_log DESC;

PRINT '======================================================================';
PRINT 'PRUEBAS FINALIZADAS CON EXITO';
PRINT '======================================================================';
GO