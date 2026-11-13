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
     
   Script: scripts/reportes/02_reporte_tarjetas_y_suspensiones.sql
   
   Descripción:
     Tarjetas (amarillas y rojas) por selección y jugador, con detalle de suspensiones activas por acumulación.
*/


USE Mundial2026;
GO

SET ANSI_NULLS ON -- sirve para cuando comparo where columna=NULL se obliga a usar isnull
GO
SET QUOTED_IDENTIFIER ON --sirve si las tablas que se usan tienen índices filtrados, columnas calculadas o XML
GO


CREATE OR ALTER PROCEDURE partido.sp_ReporteTarjetasYSuspensiones
    @Codigo_ISO CHAR(3) = NULL -- Código ISO de la selección (ej: 'ARG'). Si es NULL, devuelve todas las selecciones.
AS
BEGIN
    SET NOCOUNT ON;

    -- Normalizar y validar parámetro si fue provisto
    SET @Codigo_ISO = NULLIF(UPPER(LTRIM(RTRIM(@Codigo_ISO))), '');

    DECLARE @ID_Seleccion_Filtro INT = NULL;
    IF @Codigo_ISO IS NOT NULL
    BEGIN
        SELECT TOP 1 @ID_Seleccion_Filtro = s.ID
        FROM administracion.Seleccion s
        JOIN administracion.Pais p ON p.ID = s.ID_Pais
        WHERE p.codigo_iso = @Codigo_ISO;

        IF @ID_Seleccion_Filtro IS NULL
            THROW 50050, '(50050) El código ISO especificado no corresponde a ninguna selección registrada.', 1;
    END;

    SELECT 
        p_pais.nombre AS Seleccion,
        j.apellido + ', ' + j.nombre AS Jugador,
        c.dorsal AS Dorsal,
        ISNULL(tarjetas_resumen.amarillas, 0) AS Total_Amarillas,
        ISNULL(tarjetas_resumen.rojas, 0) AS Total_Rojas,
        ISNULL(s.partidos_totales, 0) AS Suspension_Total_Partidos,
        ISNULL(s.partidos_descontados, 0) AS Suspension_Partidos_Descontados,
        s.motivo AS Motivo_Suspension
    FROM administracion.Jugador j
    INNER JOIN administracion.Convocatoria c ON j.ID = c.ID_Jugador
    INNER JOIN administracion.Seleccion sel ON c.ID_Seleccion = sel.ID
    INNER JOIN administracion.Pais p_pais ON sel.ID_Pais = p_pais.ID

    -- Subconsulta para agrupar las tarjetas amarillas y rojas por jugador
    LEFT JOIN (
        SELECT 
            t.ID_Jugador,
            SUM(CASE WHEN t.tipo = 'Amarilla' THEN 1 ELSE 0 END) AS amarillas,
            SUM(CASE WHEN t.tipo = 'Roja' OR t.es_doble_amarilla = 1 THEN 1 ELSE 0 END) AS rojas
        FROM partido.Tarjeta t
        WHERE t.ID_Jugador IS NOT NULL
        GROUP BY t.ID_Jugador
    ) tarjetas_resumen ON j.ID = tarjetas_resumen.ID_Jugador


    -- Información de suspensiones vigentes o registradas
    LEFT JOIN partido.Suspension s ON j.ID = s.ID_Jugador
    WHERE (@ID_Seleccion_Filtro IS NULL OR sel.ID = @ID_Seleccion_Filtro)
      AND (tarjetas_resumen.amarillas > 0 
           OR tarjetas_resumen.rojas > 0 
           OR s.ID IS NOT NULL)
    ORDER BY p_pais.nombre, j.apellido, j.nombre;

END
GO
