/* 
   UNIVERSIDAD NACIONAL DE LA MATANZA (UNLaM)
   Departamento de Ingeniería e Investigaciones Tecnológicas
   Asignatura: Bases de Datos Aplicada (3641)
   Comisión: 02-5600 (Viernes Tarde)
   
   TRABAJO PRÁCTICO - SISTEMA DE REGISTRO Y GESTIÓN DEL MUNDIAL DE FÚTBOL 2026
   ENTREGA 7: REPORTES
   
   Integrantes del Grupo:
     - Aleman Flores, Matias Osvaldo 
     - Gamarra Bravo, Sidney Maribel
     - Pereira, Carlos Manuel
     - Villa, Brenda
     
   Script: scripts/REPORTES.sql
   Descripción: Script para ejecución y prueba individual de los 7 reportes del Mundial 2026.
                Cada integrante puede seleccionar el bloque correspondiente a su reporte y presionar F5.
*/

USE Mundial2026;
GO

-- ====================================================================
-- REPORTE 01: GOLEADORES POR SELECCIÓN, FASE Y TORNEO
-- Archivo: scripts/reportes/01_reporte_goleadores.sql
-- ====================================================================
PRINT '>>> [01] GOLEADORES POR SELECCIÓN, FASE Y TORNEO';
-- EXEC partido.sp_ReporteGoleadores;
GO

-- ====================================================================
-- REPORTE 02: TARJETAS POR SELECCIÓN Y JUGADOR CON SUSPENSIONES ACTIVAS
-- Archivo: scripts/reportes/02_reporte_tarjetas_y_suspensiones.sql
-- ====================================================================
PRINT '>>> [02] TARJETAS Y SUSPENSIONES ACTIVAS POR ACUMULACIÓN';
-- EXEC partido.sp_ReporteTarjetasYSuspensiones;
GO

-- ====================================================================
-- REPORTE 03: DESIGNACIONES ARBITRALES Y TARJETAS SEÑALADAS
-- Archivo: scripts/reportes/03_reporte_designaciones_arbitrales.sql
-- ====================================================================
PRINT '>>> [03] DESIGNACIONES ARBITRALES Y TARJETAS SEÑALADAS';
-- EXEC arbitraje.sp_ReporteDesignacionesArbitrales;
GO

-- ====================================================================
-- REPORTE 04: OCUPACIÓN PUBLICITARIA E INGRESOS POR SEDE Y PARTIDO
-- Archivo: scripts/reportes/04_reporte_ocupacion_publicitaria.sql
-- ====================================================================
PRINT '>>> [04] OCUPACIÓN PUBLICITARIA E INGRESOS GENERADOS';
-- EXEC publicidad.sp_ReporteOcupacionPublicitaria;
GO

-- ====================================================================
-- REPORTE 05: MATRIZ DE PRIME TIME (TABLA CRUZADA / PIVOT)
-- Archivo: scripts/reportes/05_reporte_matriz_prime_time.sql
-- ====================================================================
PRINT '>>> [05] MATRIZ DE PRIME TIME POR MERCADOS / PAÍSES';
-- EXEC partido.sp_ReporteMatrizPrimeTime;
GO

-- ====================================================================
-- REPORTE 06: SELECCIONES Y PLANTILLAS (VECTOR ANIDADO - XML)
-- Archivo: scripts/reportes/06_reporte_selecciones_plantillas.sql
-- ====================================================================
PRINT '>>> [06] SELECCIONES Y PLANTILLAS (SALIDA XML)';
-- EXEC administracion.sp_ReporteSeleccionesPlantillasXML;
GO

-- ====================================================================
-- REPORTE 07: RESULTADOS DE LOS ENCUENTROS (SALIDA XML)
-- Archivo: scripts/reportes/07_reporte_resultados_encuentros.sql
-- ====================================================================
PRINT '>>> [07] RESULTADOS DE LOS ENCUENTROS (SALIDA XML)';
-- EXEC partido.sp_ReporteResultadosEncuentrosXML;
GO
