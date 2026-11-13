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
     
   Script: scripts/reportes/05_reporte_matriz_prime_time.sql
   
   Descripción:
     Matriz de prime time: tabla cruzada (pivot) que muestre, para cada partido,
     en qué mercados/países su horario cae en prime time.
*/

USE Mundial2026;
GO

CREATE OR ALTER PROCEDURE partido.sp_ReporteMatrizPrimeTime
AS
BEGIN
    SET NOCOUNT ON;

    /*
       Definición de Prime Time:
       Horario televisivo central comprendido entre las 19:00 y las 23:59 hs (hora local).
       Se calcula sumando el huso horario oficial de cada país a la fecha_hora_utc del encuentro.
    */
    WITH MercadosEstrategicos AS (
        SELECT 
            CASE 
                WHEN codigo_iso = 'ARG' THEN 'Argentina'
                WHEN codigo_iso = 'BRA' THEN 'Brasil'
                WHEN codigo_iso = 'USA' THEN 'Estados Unidos'
                WHEN codigo_iso = 'MEX' THEN 'México'
                WHEN codigo_iso = 'ENG' THEN 'Inglaterra'
                WHEN codigo_iso = 'ESP' THEN 'España'
                WHEN codigo_iso = 'DEU' THEN 'Alemania'
                WHEN codigo_iso = 'JPN' THEN 'Japón'
            END AS NombreMercado,
            CAST(SUBSTRING(huso_horario, 1, 3) AS INT) AS OffsetHoras
        FROM administracion.Pais
        WHERE codigo_iso IN ('ARG', 'BRA', 'USA', 'MEX', 'ENG', 'ESP', 'DEU', 'JPN')
    ),
    PartidosMercados AS (
        SELECT 
            p.ID                                                AS [N°],
            CONCAT(p_loc.nombre, ' vs ', p_vis.nombre)          AS [Partido],
            f.nombre                                            AS [Fase],
            FORMAT(p.fecha_hora_utc, 'dd/MM/yyyy HH:mm')        AS [Fecha y Hora UTC],
            m.NombreMercado                                     AS [Mercado],
            CASE 
                WHEN DATEPART(HOUR, DATEADD(hour, m.OffsetHoras, p.fecha_hora_utc)) BETWEEN 19 AND 23 
                    THEN 'SÍ (' + FORMAT(DATEADD(hour, m.OffsetHoras, p.fecha_hora_utc), 'HH:mm') + ')'
                ELSE 'NO (' + FORMAT(DATEADD(hour, m.OffsetHoras, p.fecha_hora_utc), 'HH:mm') + ')'
            END AS [EstadoPrimeTime]
        FROM partido.Partido p
        INNER JOIN administracion.Fase_Torneo f ON f.ID = p.ID_Fase
        INNER JOIN administracion.Seleccion s_loc ON s_loc.ID = p.ID_Seleccion_Local
        INNER JOIN administracion.Pais p_loc ON p_loc.ID = s_loc.ID_Pais
        INNER JOIN administracion.Seleccion s_vis ON s_vis.ID = p.ID_Seleccion_Visitante
        INNER JOIN administracion.Pais p_vis ON p_vis.ID = s_vis.ID_Pais
        CROSS JOIN MercadosEstrategicos m
    )
    SELECT 
        [N°],
        [Partido],
        [Fase],
        [Fecha y Hora UTC],
        [Argentina],
        [Brasil],
        [Estados Unidos],
        [México],
        [Inglaterra],
        [España],
        [Alemania],
        [Japón]
    FROM PartidosMercados
    PIVOT (
        MAX([EstadoPrimeTime])
        FOR [Mercado] IN (
            [Argentina],
            [Brasil],
            [Estados Unidos],
            [México],
            [Inglaterra],
            [España],
            [Alemania],
            [Japón]
        )
    ) AS MatrizPrimeTime
    ORDER BY [N°];
END;
GO
