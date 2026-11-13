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
     
   Script: scripts/reportes/01_reporte_goleadores.sql
   
   Descripción:
     Goleadores por selección, fase y torneo.
*/

USE Mundial2026;
GO

CREATE OR ALTER PROCEDURE partido.sp_ReporteGoleadores
    @Codigo_ISO CHAR(3) = NULL -- Código ISO de la selección (ej: 'ARG'). Si es NULL, devuelve todo el torneo.
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
 
    -- Goles válidos para el ranking de goleadores (sin tanda de penales ni goles en contra)
    DROP TABLE IF EXISTS #GolesValidos;
    CREATE TABLE #GolesValidos (
        ID_Gol         INT          NOT NULL PRIMARY KEY,
        ID_Partido     INT          NOT NULL,
        ID_Fase        INT          NOT NULL,
        ID_Seleccion   INT          NOT NULL,
        ID_Jugador     INT          NOT NULL,
        tipo           VARCHAR(30)  NOT NULL
    );
 
    INSERT INTO #GolesValidos (ID_Gol, ID_Partido, ID_Fase, ID_Seleccion, ID_Jugador, tipo)
    SELECT g.ID, g.ID_Partido, p.ID_Fase, g.ID_Seleccion, g.ID_Jugador_autor, g.tipo
    FROM partido.Gol g
    JOIN partido.Partido p ON p.ID = g.ID_Partido
    WHERE g.periodo <> 'Definición por penales'
      AND g.tipo    <> 'En contra'
      AND (@ID_Seleccion_Filtro IS NULL OR g.ID_Seleccion = @ID_Seleccion_Filtro);
 
    -- Asistencias por jugador (solo sobre goles válidos)
    DROP TABLE IF EXISTS #Asistencias;
    SELECT g.ID_Jugador_asistencia AS ID_Jugador, COUNT(*) AS asistencias
    INTO #Asistencias
    FROM partido.Gol g
    WHERE g.ID_Jugador_asistencia IS NOT NULL
      AND g.periodo <> 'Definición por penales'
      AND g.tipo    <> 'En contra'
      AND (@ID_Seleccion_Filtro IS NULL OR g.ID_Seleccion = @ID_Seleccion_Filtro)
    GROUP BY g.ID_Jugador_asistencia;
 
    
    -- GOLEADORES DEL TORNEO

    SELECT
        RANK() OVER (ORDER BY COUNT(*) DESC)                       AS posicion,
        j.apellido + ', ' + j.nombre                               AS jugador,
        pa.nombre                                                  AS seleccion,
        COUNT(*)                                                   AS goles,
        SUM(CASE WHEN gv.tipo = 'Penal' THEN 1 ELSE 0 END)         AS goles_de_penal,
        COUNT(DISTINCT gv.ID_Partido)                              AS partidos_con_gol,
        ISNULL(MAX(a.asistencias), 0)                              AS asistencias
    FROM #GolesValidos gv
    JOIN administracion.Jugador   j  ON j.ID  = gv.ID_Jugador
    JOIN administracion.Seleccion s  ON s.ID  = gv.ID_Seleccion
    JOIN administracion.Pais      pa ON pa.ID = s.ID_Pais
    LEFT JOIN #Asistencias        a  ON a.ID_Jugador = gv.ID_Jugador
    GROUP BY gv.ID_Jugador, j.apellido, j.nombre, pa.nombre
    ORDER BY goles DESC, jugador;
 
    -- GOLEADORES POR SELECCIÓN
    SELECT
        pa.nombre                                                  AS seleccion,
        RANK() OVER (PARTITION BY gv.ID_Seleccion ORDER BY COUNT(*) DESC) AS posicion_en_seleccion,
        j.apellido + ', ' + j.nombre                               AS jugador,
        COUNT(*)                                                   AS goles,
        SUM(COUNT(*)) OVER (PARTITION BY gv.ID_Seleccion)          AS goles_de_jugadores_de_la_seleccion
    FROM #GolesValidos gv
    JOIN administracion.Jugador   j  ON j.ID  = gv.ID_Jugador
    JOIN administracion.Seleccion s  ON s.ID  = gv.ID_Seleccion
    JOIN administracion.Pais      pa ON pa.ID = s.ID_Pais
    GROUP BY gv.ID_Seleccion, gv.ID_Jugador, pa.nombre, j.apellido, j.nombre
    ORDER BY pa.nombre, goles DESC, jugador;
 
    -- GOLEADORES POR FASE DEL TORNEO
    SELECT
        f.orden                                                    AS orden_fase,
        f.nombre                                                   AS fase,
        RANK() OVER (PARTITION BY gv.ID_Fase ORDER BY COUNT(*) DESC) AS posicion_en_fase,
        j.apellido + ', ' + j.nombre                               AS jugador,
        pa.nombre                                                  AS seleccion,
        COUNT(*)                                                   AS goles
    FROM #GolesValidos gv
    JOIN administracion.Fase_Torneo f  ON f.ID  = gv.ID_Fase
    JOIN administracion.Jugador     j  ON j.ID  = gv.ID_Jugador
    JOIN administracion.Seleccion   s  ON s.ID  = gv.ID_Seleccion
    JOIN administracion.Pais        pa ON pa.ID = s.ID_Pais
    GROUP BY gv.ID_Fase, f.orden, f.nombre, gv.ID_Jugador, j.apellido, j.nombre, pa.nombre
    ORDER BY f.orden, goles DESC, jugador;
 
    -- 
    -- RESUMEN DE GOLES POR SELECCIÓN
 
    SELECT
        pa.nombre                                                  AS seleccion,
        SUM(CASE WHEN g.tipo <> 'En contra' THEN 1 ELSE 0 END)     AS goles_de_sus_jugadores,
        SUM(CASE WHEN g.tipo =  'En contra' THEN 1 ELSE 0 END)     AS goles_en_contra_del_rival,
        COUNT(*)                                                   AS goles_totales
    FROM partido.Gol g
    JOIN administracion.Seleccion s  ON s.ID  = g.ID_Seleccion
    JOIN administracion.Pais      pa ON pa.ID = s.ID_Pais
    WHERE g.periodo <> 'Definición por penales'
      AND (@ID_Seleccion_Filtro IS NULL OR g.ID_Seleccion = @ID_Seleccion_Filtro)
    GROUP BY g.ID_Seleccion, pa.nombre
    ORDER BY goles_totales DESC, pa.nombre;
 
    DROP TABLE IF EXISTS #Asistencias;
    DROP TABLE IF EXISTS #GolesValidos;
END;
GO
 