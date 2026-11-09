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
     
   Script: scripts/reportes/07_reporte_resultados_encuentros.sql
   
   Descripción:
     Resultados de los encuentros.
     Retorna el fixture complet y la salida XML.
*/

USE Mundial2026;
GO

CREATE OR ALTER PROCEDURE partido.sp_ReporteResultadosEncuentros
AS
BEGIN
    SET NOCOUNT ON;

    -- ====================================================================
    -- 1. FIXTURE DE RESULTADOS
    -- ====================================================================
    SELECT 
        p.ID                                                AS [N°],
        f.nombre                                            AS [Fase / Instancia],
        FORMAT(p.fecha_hora_local, 'dd/MM/yyyy HH:mm')      AS [Fecha y Hora Local],
        sed.nombre + ' (' + sed.ciudad + ')'                AS [Estadio y Sede],
        p_loc.nombre                                        AS [Equipo Local],
        CONCAT(
            p.goles_local,
            CASE WHEN pen.TotalPenales > 0 THEN CONCAT(' (', pen.PenalesLocal, ')') ELSE '' END,
            ' - ',
            p.goles_visitante,
            CASE WHEN pen.TotalPenales > 0 THEN CONCAT(' (', pen.PenalesVisitante, ')') ELSE '' END
        )                                                   AS [Marcador],
        p_vis.nombre                                        AS [Equipo Visitante],
        ISNULL(a.nombre + ' ' + a.apellido, 'Por designar') AS [Árbitro Principal]
    FROM partido.Partido p
    INNER JOIN administracion.Fase_Torneo f ON f.ID = p.ID_Fase
    INNER JOIN administracion.Sede sed ON sed.ID = p.ID_Sede
    INNER JOIN administracion.Seleccion s_loc ON s_loc.ID = p.ID_Seleccion_Local
    INNER JOIN administracion.Pais p_loc ON p_loc.ID = s_loc.ID_Pais
    INNER JOIN administracion.Seleccion s_vis ON s_vis.ID = p.ID_Seleccion_Visitante
    INNER JOIN administracion.Pais p_vis ON p_vis.ID = s_vis.ID_Pais
    LEFT JOIN (
        SELECT 
            p2.ID AS ID_Partido,
            SUM(CASE WHEN g.ID_Seleccion = p2.ID_Seleccion_Local AND g.periodo LIKE '%penal%' THEN 1 ELSE 0 END) AS PenalesLocal,
            SUM(CASE WHEN g.ID_Seleccion = p2.ID_Seleccion_Visitante AND g.periodo LIKE '%penal%' THEN 1 ELSE 0 END) AS PenalesVisitante,
            COUNT(*) AS TotalPenales
        FROM partido.Partido p2
        INNER JOIN partido.Gol g ON g.ID_Partido = p2.ID
        WHERE g.periodo LIKE '%penal%'
        GROUP BY p2.ID
    ) pen ON pen.ID_Partido = p.ID
    LEFT JOIN arbitraje.Designacion_Arbitral da ON da.ID_Partido = p.ID AND da.rol = 'Árbitro Principal'
    LEFT JOIN arbitraje.Arbitro a ON a.ID = da.ID_Arbitro
    ORDER BY p.ID;

    -- ====================================================================
    -- 2. RESULTADO XML
    -- ====================================================================
    SELECT 
        p.ID                                                AS [@Numero],
        f.nombre                                            AS [@Fase],
        FORMAT(p.fecha_hora_local, 'dd/MM/yyyy HH:mm')      AS [FechaHora],
        sed.nombre + ' (' + sed.ciudad + ')'                AS [Sede],
        p_loc.nombre                                        AS [EquipoLocal],
        p.goles_local                                       AS [GolesLocal],
        p_vis.nombre                                        AS [EquipoVisitante],
        p.goles_visitante                                   AS [GolesVisitante],
        CONCAT(
            p_loc.nombre, ' ', p.goles_local,
            CASE WHEN pen.TotalPenales > 0 THEN CONCAT(' (', pen.PenalesLocal, ')') ELSE '' END,
            ' - ',
            p.goles_visitante,
            CASE WHEN pen.TotalPenales > 0 THEN CONCAT(' (', pen.PenalesVisitante, ')') ELSE '' END,
            ' ', p_vis.nombre,
            CASE WHEN pen.TotalPenales > 0 THEN ' [Penales]' ELSE '' END
        )                                                   AS [MarcadorFinal],
        ISNULL(a.nombre + ' ' + a.apellido, 'Por designar') AS [ArbitroPrincipal]
    FROM partido.Partido p
    INNER JOIN administracion.Fase_Torneo f ON f.ID = p.ID_Fase
    INNER JOIN administracion.Sede sed ON sed.ID = p.ID_Sede
    INNER JOIN administracion.Seleccion s_loc ON s_loc.ID = p.ID_Seleccion_Local
    INNER JOIN administracion.Pais p_loc ON p_loc.ID = s_loc.ID_Pais
    INNER JOIN administracion.Seleccion s_vis ON s_vis.ID = p.ID_Seleccion_Visitante
    INNER JOIN administracion.Pais p_vis ON p_vis.ID = s_vis.ID_Pais
    LEFT JOIN (
        SELECT 
            p2.ID AS ID_Partido,
            SUM(CASE WHEN g.ID_Seleccion = p2.ID_Seleccion_Local AND g.periodo LIKE '%penal%' THEN 1 ELSE 0 END) AS PenalesLocal,
            SUM(CASE WHEN g.ID_Seleccion = p2.ID_Seleccion_Visitante AND g.periodo LIKE '%penal%' THEN 1 ELSE 0 END) AS PenalesVisitante,
            COUNT(*) AS TotalPenales
        FROM partido.Partido p2
        INNER JOIN partido.Gol g ON g.ID_Partido = p2.ID
        WHERE g.periodo LIKE '%penal%'
        GROUP BY p2.ID
    ) pen ON pen.ID_Partido = p.ID
    LEFT JOIN arbitraje.Designacion_Arbitral da ON da.ID_Partido = p.ID AND da.rol = 'Árbitro Principal'
    LEFT JOIN arbitraje.Arbitro a ON a.ID = da.ID_Arbitro
    ORDER BY p.ID
    FOR XML PATH('Encuentro'), ROOT('ResultadosEncuentros');
END;
GO
