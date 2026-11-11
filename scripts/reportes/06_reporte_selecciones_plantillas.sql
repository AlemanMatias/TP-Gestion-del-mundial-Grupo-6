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
     
   Script: scripts/reportes/06_reporte_selecciones_plantillas.sql
   
   Descripción:
     Selecciones y plantillas: listado de selecciones con un vector anidado de convocados (nombre, posición, club, dorsal).
     (Nota: Retorna XML).
*/

USE Mundial2026;
GO

CREATE OR ALTER PROCEDURE administracion.sp_ReporteSeleccionesPlantillas
AS
BEGIN
    SET NOCOUNT ON;

    -- ====================================================================
    -- 1. Selecciones + nombre del país (selección)
    -- ====================================================================
    SELECT
        s.ID        AS SeleccionID,
        p.nombre    AS Nombre,

        -- =================================================================
        -- 2️.  Plantilla (sub‑XML) para cada selección
        -- =================================================================
        (
            SELECT
                CONCAT(j.nombre, ' ', j.apellido) AS [Nombre],
                j.posicion_habitual               AS [Posicion],
                ISNULL(c.nombre, 'Sin Club')      AS [Club],
                co.dorsal                         AS [Dorsal]
            FROM administracion.Convocatoria   co
            JOIN administracion.Jugador        j  ON co.ID_Jugador = j.ID
            LEFT JOIN administracion.Club      c  ON j.ID_Club = c.ID
            WHERE co.ID_Seleccion = s.ID
            ORDER BY co.dorsal    
            FOR XML PATH('Jugador'), TYPE
        ) AS Plantilla
    FROM administracion.Seleccion s
    JOIN administracion.Pais      p  ON s.ID_Pais = p.ID
    ORDER BY s.ID
    FOR XML PATH('Seleccion'), ROOT('Selecciones');
END;
GO
