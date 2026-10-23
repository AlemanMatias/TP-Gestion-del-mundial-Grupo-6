/* 
   UNIVERSIDAD NACIONAL DE LA MATANZA (UNLaM)
   Departamento de Ingeniería e Investigaciones Tecnológicas
   Asignatura: Bases de Datos Aplicada (3641)
   Comisión: 02-5600 (Viernes Tarde)
   
   TRABAJO PRÁCTICO - SISTEMA DE REGISTRO Y GESTIÓN DEL MUNDIAL DE FÚTBOL 2026
   
   Integrantes del Grupo:
     - Aleman Flores, Matias Osvaldo 
     - Gamarra Bravo, Sidney Maribel
     - Perreira, Carlos Manuel
     - Villa, Brenda
     
   Script: test_07_publicidad.sql
   Descripción: Script de pruebas para validar ABMs de publicidad y asignación,
                demostrando casos de éxito y captura de errores por separado.
*/

USE Mundial2026;
GO

SET NOCOUNT ON;

PRINT '======================================================================';
PRINT 'INICIANDO PRUEBAS UNITARIAS - MÓDULO PUBLICIDAD (07)';
PRINT '======================================================================';

-- =========================================================================================
-- 1. PRUEBAS: sp_GenerarEspaciosPartido
-- =========================================================================================
PRINT '--- PRUEBA 1: Éxito - Generar espacios para un partido válido ---';
BEGIN TRY
    -- Usamos el Partido 3 de los datos semilla
    EXEC publicidad.sp_GenerarEspaciosPartido @id_partido = 3;
    PRINT 'ÉXITO: Se generaron los 4 espacios publicitarios para el partido 3.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '--- PRUEBA 2: Error - Generar espacios de un partido inexistente ---';
BEGIN TRY
    EXEC publicidad.sp_GenerarEspaciosPartido @id_partido = 999;
    PRINT 'FALLO: El SP permitió generar espacios para un partido fantasma.';
END TRY
BEGIN CATCH
    PRINT 'ÉXITO (Error capturado correctamente): ' + ERROR_MESSAGE();
END CATCH
GO


-- =========================================================================================
-- 2. PRUEBAS: sp_RegistrarAnunciante
-- =========================================================================================
PRINT '--- PRUEBA 3: Éxito - Registrar nuevo anunciante ---';
BEGIN TRY
    EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Sony PlayStation';
    PRINT 'ÉXITO: Anunciante registrado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '--- PRUEBA 4: Error - Registrar anunciante con nombre vacío ---';
BEGIN TRY
    EXEC publicidad.sp_RegistrarAnunciante @nombre = '   ';
    PRINT 'FALLO: El SP permitió registrar un anunciante en blanco.';
END TRY
BEGIN CATCH
    PRINT 'ÉXITO (Error capturado correctamente): ' + ERROR_MESSAGE();
END CATCH
GO


-- =========================================================================================
-- 3. PRUEBAS: sp_RegistrarCampania
-- =========================================================================================
PRINT '--- PRUEba 5: Éxito - Registrar nueva campaña ---';
BEGIN TRY
    -- Usamos el anunciante ID 1 de los datos semilla
    EXEC publicidad.sp_RegistrarCampania 
        @nombre = 'Pasión 2026', 
        @fecha_inicio = '2026-06-01', 
        @fecha_fin = '2026-07-30', 
        @id_anunciante = 1;
    PRINT 'ÉXITO: Campaña registrada correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '--- PRUEBA 6: Error - Fechas de campaña invertidas ---';
BEGIN TRY
    EXEC publicidad.sp_RegistrarCampania 
        @nombre = 'Campaña Fallida', 
        @fecha_inicio = '2026-12-01', 
        @fecha_fin = '2026-01-01', 
        @id_anunciante = 1;
    PRINT 'FALLO: El SP permitió registrar una campaña con fechas inválidas.';
END TRY
BEGIN CATCH
    PRINT 'ÉXITO (Error capturado correctamente): ' + ERROR_MESSAGE();
END CATCH
GO


-- =========================================================================================
-- 4. PRUEBAS: sp_AsignarPublicidadPartido
-- =========================================================================================
PRINT '--- PRUEBA 7: Éxito - Asignar publicidad (Partido 1) ---';
BEGIN TRY
    -- El Partido 1 ya tiene sus 4 espacios generados por los datos semilla
    EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = 1;
    PRINT 'ÉXITO: Se asignaron las 4 publicidades para el Partido 1.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '--- PRUEBA 8: Error - Intentar asignar publicidad a un partido sin espacios ---';
BEGIN TRY
    -- Usamos el Partido 2 que no tiene espacios publicitarios generados
    EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = 2;
    PRINT 'FALLO: El SP permitió asignar publicidad a un partido sin slots.';
END TRY
BEGIN CATCH
    PRINT 'ÉXITO (Error capturado correctamente): ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '=== FIN DE PRUEBAS DE PUBLICIDAD ===';
GO

-- Verificación visual de la exhibición generada en el Partido 1
SELECT 
    ep.nombre AS [Slot], 
    pc.nombre AS [Pieza Publicitaria], 
    ex.orden_prioridad AS [Prioridad], 
    ex.monto_facturado AS [Monto ($)]
FROM publicidad.Exhibicion ex
JOIN publicidad.Espacio_publicitario ep ON ep.ID = ex.ID_espacio
JOIN publicidad.Pieza_Contenido pc ON pc.ID = ex.ID_Pieza
WHERE ep.ID_Partido = 1;
GO