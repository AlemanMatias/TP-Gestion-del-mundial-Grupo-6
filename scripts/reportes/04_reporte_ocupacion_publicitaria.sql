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
     
   Script: scripts/reportes/04_reporte_ocupacion_publicitaria.sql
   
   Descripción:
     Ocupación publicitaria por sede y partido: anunciantes exhibidos en los cuatro espacios, e ingresos generados.
*/

USE Mundial2026;
GO

-- TODO: Implementar Stored Procedure para este reporte.
CREATE OR ALTER PROCEDURE publicidad.sp_ReporteOcupacionPublicitaria
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @espacios_por_partido INT = 4;   -- regla de negocio: 4 espacios simultáneos por partido
 
    -- Base única: una fila por partido y espacio publicitario, con su exhibición y anunciante (si existen)
    DROP TABLE IF EXISTS #Base;
    CREATE TABLE #Base (
        ID_Partido        INT           NOT NULL,
        ID_Sede           INT           NOT NULL,
        numero_slot       TINYINT       NULL,
        ID_Anunciante     INT           NULL,
        anunciante        VARCHAR(100)  NULL,
        monto_facturado   DECIMAL(12,2) NULL
    );
 
    INSERT INTO #Base (ID_Partido, ID_Sede, numero_slot, ID_Anunciante, anunciante, monto_facturado)
    SELECT
        p.ID,
        p.ID_Sede,
        ep.numero_slot,
        an.ID,
        an.nombre,
        ex.monto_facturado
    FROM partido.Partido p
    LEFT JOIN publicidad.Espacio_publicitario ep ON ep.ID_Partido = p.ID
    LEFT JOIN publicidad.Exhibicion           ex ON ex.ID_espacio = ep.ID
    LEFT JOIN publicidad.Pieza_Contenido      pc ON pc.ID = ex.ID_Pieza
    LEFT JOIN publicidad.Campania             c  ON c.ID  = pc.ID_Campania
    LEFT JOIN publicidad.Anunciante           an ON an.ID = c.ID_Anunciante;
 
    -- DETALLE POR PARTIDO
    
    SELECT
        s.nombre                                                   AS sede,
        s.ciudad                                                   AS ciudad,
        ps.nombre                                                  AS pais_sede,
        p.ID                                                       AS id_partido,
        f.nombre                                                   AS fase,
        p.fecha_hora_local                                         AS fecha_hora_local,
        pl.nombre + ' vs ' + pv.nombre                             AS encuentro,
        MAX(CASE WHEN b.numero_slot = 1 THEN b.anunciante END)     AS slot_1,
        MAX(CASE WHEN b.numero_slot = 2 THEN b.anunciante END)     AS slot_2,
        MAX(CASE WHEN b.numero_slot = 3 THEN b.anunciante END)     AS slot_3,
        MAX(CASE WHEN b.numero_slot = 4 THEN b.anunciante END)     AS slot_4,
        COUNT(b.anunciante)                                        AS espacios_ocupados,
        CAST(COUNT(b.anunciante) * 100.0 / @espacios_por_partido AS DECIMAL(5,2)) AS ocupacion_pct,
        ISNULL(SUM(b.monto_facturado), 0)                          AS ingresos_partido
    FROM #Base b
    JOIN partido.Partido            p  ON p.ID  = b.ID_Partido
    JOIN administracion.Sede        s  ON s.ID  = p.ID_Sede
    JOIN administracion.Pais        ps ON ps.ID = s.ID_Pais
    JOIN administracion.Fase_Torneo f  ON f.ID  = p.ID_Fase
    JOIN administracion.Seleccion   sl ON sl.ID = p.ID_Seleccion_Local
    JOIN administracion.Pais        pl ON pl.ID = sl.ID_Pais
    JOIN administracion.Seleccion   sv ON sv.ID = p.ID_Seleccion_Visitante
    JOIN administracion.Pais        pv ON pv.ID = sv.ID_Pais
    GROUP BY s.nombre, s.ciudad, ps.nombre, p.ID, f.nombre, p.fecha_hora_local, pl.nombre, pv.nombre
    ORDER BY s.nombre, p.fecha_hora_local, p.ID;
 
    -- RESUMEN POR SEDE
    SELECT
        s.nombre                                                   AS sede,
        s.ciudad                                                   AS ciudad,
        ps.nombre                                                  AS pais_sede,
        COUNT(DISTINCT b.ID_Partido)                               AS partidos,
        COUNT(DISTINCT b.ID_Partido) * @espacios_por_partido       AS espacios_disponibles,
        COUNT(b.anunciante)                                        AS espacios_ocupados,
        CAST(COUNT(b.anunciante) * 100.0
             / NULLIF(COUNT(DISTINCT b.ID_Partido) * @espacios_por_partido, 0) AS DECIMAL(5,2)) AS ocupacion_pct,
        ISNULL(SUM(b.monto_facturado), 0)                          AS ingresos_sede,
        CAST(ISNULL(SUM(b.monto_facturado), 0)
             / NULLIF(COUNT(DISTINCT b.ID_Partido), 0) AS DECIMAL(12,2)) AS ingreso_promedio_por_partido
    FROM #Base b
    JOIN administracion.Sede s  ON s.ID  = b.ID_Sede
    JOIN administracion.Pais ps ON ps.ID = s.ID_Pais
    GROUP BY s.ID, s.nombre, s.ciudad, ps.nombre
    ORDER BY ingresos_sede DESC, s.nombre;
 
    -- RANKING DE ANUNCIANTES POR INGRESOS
    SELECT
        RANK() OVER (ORDER BY SUM(b.monto_facturado) DESC)         AS posicion,
        b.anunciante                                               AS anunciante,
        COUNT(*)                                                   AS exhibiciones,
        COUNT(DISTINCT b.ID_Partido)                               AS partidos_distintos,
        SUM(b.monto_facturado)                                     AS ingresos_generados
    FROM #Base b
    WHERE b.anunciante IS NOT NULL
    GROUP BY b.ID_Anunciante, b.anunciante
    ORDER BY ingresos_generados DESC, b.anunciante;
 
    -- TOTAL GENERAL DEL TORNEO
    SELECT
        COUNT(DISTINCT b.ID_Partido)                               AS partidos,
        COUNT(DISTINCT b.ID_Partido) * @espacios_por_partido       AS espacios_disponibles,
        COUNT(b.anunciante)                                        AS espacios_ocupados,
        CAST(COUNT(b.anunciante) * 100.0
             / NULLIF(COUNT(DISTINCT b.ID_Partido) * @espacios_por_partido, 0) AS DECIMAL(5,2)) AS ocupacion_pct,
        ISNULL(SUM(b.monto_facturado), 0)                          AS ingresos_totales
    FROM #Base b;
 
    DROP TABLE IF EXISTS #Base;
END;
GO
 