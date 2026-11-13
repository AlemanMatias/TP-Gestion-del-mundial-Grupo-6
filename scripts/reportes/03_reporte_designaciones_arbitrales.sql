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
     
   Script: scripts/reportes/03_reporte_designaciones_arbitrales.sql
   
   Descripción:
     Designaciones arbitrales: partidos dirigidos por cada árbitro, con las amonestaciones/expulsiones que señaló.
*/

USE Mundial2026;
GO

CREATE OR ALTER PROCEDURE arbitraje.sp_ReporteDesignacionesArbitrales
AS
BEGIN 
    SET NOCOUNT ON;

    SELECT
        CONCAT(a.nombre, ' ', a.apellido)              AS [Árbitro Principal],
        p.ID                                           AS [ N° Partido ],
        FORMAT(p.fecha_hora_local, 'dd/MM/yyyy HH:mm') AS [ Fecha y Hora ],
        CONCAT(p_loc.nombre, ' vs ', p_vis.nombre)     AS [Partido Dirigido],
        ISNULL(t.Amonestaciones,0)                     AS [ Amonestaciones ],
        ISNULL(t.Expulsiones,0)                        AS [ Expulsiones ]

        FROM arbitraje.Arbitro a
        INNER JOIN arbitraje.Designacion_Arbitral d ON d.ID_Arbitro = a.ID
        INNER JOIN partido.Partido p ON p.ID = d.ID_Partido
        INNER JOIN administracion.Seleccion s_loc ON s_loc.ID = p.ID_Seleccion_Local
        INNER JOIN administracion.Pais p_loc ON p_loc.ID = s_loc.ID_Pais
        INNER JOIN administracion.Seleccion s_vis ON s_vis.ID = p.ID_Seleccion_Visitante
        INNER JOIN administracion.Pais p_vis ON p_vis.ID = s_vis.ID_Pais

        -- Subconsulta para calcular las tarjetas por partido
        LEFT JOIN (
            SELECT 
                ID_Partido,
                -- Amonestaciones = solo amarillas simples 
                SUM(CASE WHEN tipo = 'AMARILLA' AND es_doble_amarilla = 0 THEN 1 ELSE 0 END) AS Amonestaciones,
                -- Expulsiones = rojas ó doble amarilla
                SUM(CASE WHEN tipo = 'ROJA' OR (tipo = 'AMARILLA' AND es_doble_amarilla = 1) THEN 1 ELSE 0 END) AS Expulsiones
            FROM partido.Tarjeta
            GROUP BY ID_Partido

        -- Todas las tarjetas del partido que el arbitro dirigió ~ la tarjeta la emitió ese mismo árbitro
        ) t ON t.ID_Partido = p.ID 
        WHERE d.rol = 'Árbitro Principal'
        ORDER BY [Árbitro Principal], p.fecha_hora_local;

END;
GO
